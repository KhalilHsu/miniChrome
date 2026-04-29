const MINI_WINDOW_IDS_KEY = "miniWindowIds";

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
      chrome.tabs.remove(sender.tab.id).catch(() => {});
    }
    sendResponse({ success: true });
    return false;
  } else if (message.action === "checkMiniWindow") {
    if (!sender.tab || !sender.tab.windowId) {
      sendResponse({ isMiniWindow: false });
      return false;
    }
    getMiniWindowIds().then(ids => {
      sendResponse({ isMiniWindow: ids.includes(sender.tab.windowId) });
    });
    return true; // async response
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
  await setMiniWindowIds(ids.filter((id) => id !== windowId));
});

// Fallback: Catch any new tabs spawned by JS window.open from a Mini window
chrome.webNavigation.onCreatedNavigationTarget.addListener(async (details) => {
  const miniWindowIds = await getMiniWindowIds();
  try {
    const sourceTab = await chrome.tabs.get(details.sourceTabId);
    if (sourceTab && miniWindowIds.includes(sourceTab.windowId)) {
      // Force the mini window tab to navigate to the new URL
      await chrome.tabs.update(details.sourceTabId, { url: details.url });
      // Instantly kill the newly spawned tab
      await chrome.tabs.remove(details.tabId);
    }
  } catch (e) {
    // Tab might already be closed
  }
});

async function openMiniWindow(url) {
  // Get all displays
  const displays = await chrome.system.display.getInfo();
  // Try to find primary display, fallback to first
  const display = displays.find(d => d.isPrimary) || displays[0];
  
  const screenW = display.workArea.width;
  const screenH = display.workArea.height;
  
  // Calculate 80% width and height
  const width = Math.round(screenW * 0.8);
  const height = Math.round(screenH * 0.8);
  
  // Calculate center position
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
  }
}

async function promoteMiniWindow(windowId, tabId) {
  const ids = await getMiniWindowIds();
  if (!ids.includes(windowId)) {
    return; // Only promote tabs from mini windows
  }

  // Find the most recent normal window
  const normalWindows = await chrome.windows.getAll({ windowTypes: ['normal'] });
  let targetWindow = null;

  if (normalWindows.length > 0) {
    try {
      targetWindow = await chrome.windows.getLastFocused({ windowTypes: ['normal'] });
    } catch (e) {
      targetWindow = normalWindows[0];
    }
  }

  if (targetWindow && targetWindow.id) {
    await chrome.tabs.move(tabId, { windowId: targetWindow.id, index: -1 });
    await chrome.tabs.update(tabId, { active: true });
    await chrome.windows.update(targetWindow.id, { focused: true });
  } else {
    // No normal window exists, create a new one with this tab
    await chrome.windows.create({ tabId: tabId, type: "normal", focused: true });
  }

  // Close the mini window if there are no more tabs
  try {
    await chrome.windows.remove(windowId);
  } catch (e) {
    // Ignore error if window already closed
  }
}

async function closeMiniWindow(windowId) {
  const ids = await getMiniWindowIds();
  if (ids.includes(windowId)) {
    try {
      await chrome.windows.remove(windowId);
    } catch (e) {
      // Ignore
    }
  }
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
