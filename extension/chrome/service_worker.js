const MINI_WINDOW_IDS_KEY = "miniWindowIds";
const MINI_WINDOW_SESSION_KEY = "miniWindowIdsSession";
const LOG_PREFIX = "[PeekLink]";

function logInfo(...args) {
  console.info(LOG_PREFIX, ...args);
}

function logWarn(...args) {
  console.warn(LOG_PREFIX, ...args);
}

function logError(...args) {
  console.error(LOG_PREFIX, ...args);
}

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "peeklink-open-link-in-mini",
    title: "Open Link in Mini",
    contexts: ["link"]
  });
  chrome.contextMenus.create({
    id: "peeklink-promote-to-main",
    title: "Promote to Main Window",
    contexts: ["page", "link"]
  });
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === "peeklink-open-link-in-mini" && info.linkUrl) {
    await openMiniWindow(info.linkUrl);
  } else if (info.menuItemId === "peeklink-promote-to-main" && tab && tab.windowId) {
    await promoteMiniWindow(tab.windowId, tab.id);
  }
});

chrome.commands.onCommand.addListener(async (command) => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab || !tab.id || !tab.windowId) return;

  if (command === "open-current-tab-in-mini" && tab.url) {
    await openMiniWindow(tab.url);
  } else if (command === "promote-mini-window") {
    await promoteMiniWindow(tab.windowId, tab.id);
  } else if (command === "close-mini-window") {
    await closeMiniWindow(tab.windowId);
  }
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === "openMiniWindow") {
    if (message.url) {
      openMiniWindow(message.url);
    }
    if (sender.tab && sender.tab.id) {
      chrome.tabs.remove(sender.tab.id).catch((e) => {
        logWarn("Failed to remove bridge tab:", e.message);
      });
    }
    sendResponse({ success: true });
    return false;
  } else if (message.action === "checkMiniWindow") {
    if (!sender.tab || !sender.tab.windowId) {
      sendResponse({ isMiniWindow: false });
      return false;
    }
    isMiniWindow(sender.tab.windowId, sender.tab).then(result => {
      sendResponse({ isMiniWindow: result });
    });
    return true;
  } else if (message.action === "promoteCurrentWindow") {
    if (sender.tab && sender.tab.windowId) {
      promoteMiniWindow(sender.tab.windowId, sender.tab.id);
    }
    return false;
  }
});

chrome.windows.onRemoved.addListener(async (windowId) => {
  const ids = await getMiniWindowIds();
  if (!ids.includes(windowId)) {
    return;
  }
  await removeFromMiniWindowIds(windowId);
  logInfo("Mini window removed:", windowId);
});

chrome.webNavigation.onCreatedNavigationTarget.addListener(async (details) => {
  const miniWindowIds = await getMiniWindowIds();
  try {
    const sourceTab = await chrome.tabs.get(details.sourceTabId);
    if (sourceTab && miniWindowIds.includes(sourceTab.windowId)) {
      await chrome.tabs.update(details.sourceTabId, { url: details.url });
      await chrome.tabs.remove(details.tabId);
      logInfo("Redirected popup to mini window:", details.url);
    }
  } catch (e) {
    logWarn("Failed to redirect popup:", e.message, {
      sourceTabId: details.sourceTabId,
      targetTabId: details.tabId,
      url: details.url
    });
  }
});

async function isMiniWindow(windowId, tab) {
  const ids = await getMiniWindowIds();
  if (ids.includes(windowId)) return true;

  const sessionIds = await getSessionWindowIds();
  if (sessionIds.includes(windowId)) {
    await setMiniWindowIds([...new Set([...ids, windowId])]);
    logInfo("Recovered mini window via session storage:", windowId);
    return true;
  }

  try {
    const win = await chrome.windows.get(windowId);
    if (win.type === "popup") {
      const displays = await chrome.system.display.getInfo();
      const display = displays.find(d => d.isPrimary) || displays[0];
      if (display) {
        const expectedW = Math.round(display.workArea.width * 0.8);
        const expectedH = Math.round(display.workArea.height * 0.8);
        if (win.width === expectedW && win.height === expectedH) {
          await setMiniWindowIds([...new Set([...ids, windowId])]);
          logInfo("Recovered mini window via size heuristic:", windowId);
          return true;
        }
      }
    }
  } catch (e) {
    logWarn("Failed to check window type for recovery:", e.message);
  }

  return false;
}

async function openMiniWindow(url) {
  const displays = await chrome.system.display.getInfo();
  const display = displays.find(d => d.isPrimary) || displays[0];

  const screenW = display.workArea.width;
  const screenH = display.workArea.height;

  const width = Math.round(screenW * 0.8);
  const height = Math.round(screenH * 0.8);

  const left = Math.round(display.workArea.left + (screenW - width) / 2);
  const top = Math.round(display.workArea.top + (screenH - height) / 2);

  const window = await chrome.windows.create({
    url,
    type: "popup",
    focused: true,
    width,
    height,
    left,
    top
  });

  if (window?.id) {
    const ids = await getMiniWindowIds();
    await setMiniWindowIds([...new Set([...ids, window.id])]);
    const sessionIds = await getSessionWindowIds();
    await setSessionWindowIds([...new Set([...sessionIds, window.id])]);
    logInfo("Opened mini window:", window.id, "url:", url);
  }
}

async function promoteMiniWindow(windowId, tabId) {
  const ids = await getMiniWindowIds();
  if (!ids.includes(windowId)) {
    logWarn("Promote called for non-mini window:", windowId);
    return;
  }

  try {
    const normalWindows = await chrome.windows.getAll({ windowTypes: ["normal"] });
    let targetWindow = null;

    if (normalWindows.length > 0) {
      try {
        targetWindow = await chrome.windows.getLastFocused({ windowTypes: ["normal"] });
      } catch (e) {
        logWarn("getLastFocused failed, using first normal window:", e.message);
        targetWindow = normalWindows[0];
      }
    }

    if (targetWindow && targetWindow.id) {
      await chrome.tabs.move(tabId, { windowId: targetWindow.id, index: -1 });
      await chrome.tabs.update(tabId, { active: true });
      await chrome.windows.update(targetWindow.id, { focused: true });
    } else {
      await chrome.windows.create({ tabId: tabId, type: "normal", focused: true });
    }

    logInfo("Promoted tab", tabId, "from mini window", windowId);

    await removeFromMiniWindowIds(windowId);

    try {
      await chrome.windows.remove(windowId);
    } catch (e) {
      logWarn("Mini window already closed during promote:", e.message);
    }
  } catch (e) {
    logError("Promote failed:", e.message, { windowId, tabId });
  }
}

async function closeMiniWindow(windowId) {
  const ids = await getMiniWindowIds();
  if (ids.includes(windowId)) {
    try {
      await chrome.windows.remove(windowId);
      logInfo("Closed mini window:", windowId);
    } catch (e) {
      logWarn("Failed to close mini window:", e.message, { windowId });
    }
  }
}

async function removeFromMiniWindowIds(windowId) {
  const ids = await getMiniWindowIds();
  await setMiniWindowIds(ids.filter((id) => id !== windowId));
  const sessionIds = await getSessionWindowIds();
  await setSessionWindowIds(sessionIds.filter((id) => id !== windowId));
}

async function getMiniWindowIds() {
  const data = await chrome.storage.local.get(MINI_WINDOW_IDS_KEY);
  return data[MINI_WINDOW_IDS_KEY] ?? [];
}

async function setMiniWindowIds(ids) {
  await chrome.storage.local.set({
    [MINI_WINDOW_IDS_KEY]: ids
  });
}

async function getSessionWindowIds() {
  const data = await chrome.storage.session.get(MINI_WINDOW_SESSION_KEY);
  return data[MINI_WINDOW_SESSION_KEY] ?? [];
}

async function setSessionWindowIds(ids) {
  await chrome.storage.session.set({
    [MINI_WINDOW_SESSION_KEY]: ids
  });
}
