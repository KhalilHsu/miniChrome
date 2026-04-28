const MINI_WINDOW_IDS_KEY = "miniWindowIds";

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "peeklink-open-link-in-mini",
    title: "Open Link in Mini",
    contexts: ["link"]
  });
});

chrome.contextMenus.onClicked.addListener(async (info) => {
  if (info.menuItemId !== "peeklink-open-link-in-mini" || !info.linkUrl) {
    return;
  }

  await openMiniWindow(info.linkUrl);
});

chrome.commands.onCommand.addListener(async (command) => {
  if (command !== "open-current-tab-in-mini") {
    return;
  }

  const [tab] = await chrome.tabs.query({
    active: true,
    currentWindow: true
  });

  if (!tab?.url || !tab.id) {
    return;
  }

  await openMiniWindow(tab.url);
});

chrome.windows.onRemoved.addListener(async (windowId) => {
  const ids = await getMiniWindowIds();
  if (!ids.includes(windowId)) {
    return;
  }

  await setMiniWindowIds(ids.filter((id) => id !== windowId));
});

async function openMiniWindow(url) {
  const window = await chrome.windows.create({
    url,
    type: "popup",
    focused: true,
    width: 980,
    height: 720
  });

  if (window?.id) {
    const ids = await getMiniWindowIds();
    await setMiniWindowIds([...new Set([...ids, window.id])]);
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
