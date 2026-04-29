const urlParams = new URLSearchParams(window.location.search);
const targetUrl = urlParams.get('url');

chrome.runtime.sendMessage({ action: "openMiniWindow", url: targetUrl });
