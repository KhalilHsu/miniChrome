// Only run logic if we are actually in a Mini window
chrome.runtime.sendMessage({ action: "checkMiniWindow" }, (response) => {
  if (response && response.isMiniWindow) {
    injectOverlay();
  }
});

function injectOverlay() {
  if (document.getElementById('peeklink-overlay-container')) return;

  const container = document.createElement('div');
  container.id = 'peeklink-overlay-container';

  const promoteBtn = document.createElement('button');
  promoteBtn.className = 'peeklink-btn';
  const promoteLabel = chrome.i18n.getMessage('promoteToChromeButton') || 'Promote to Chrome (⌘Enter)';
  promoteBtn.innerHTML = `
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>
      <polyline points="15 3 21 3 21 9"></polyline>
      <line x1="10" y1="14" x2="21" y2="3"></line>
    </svg>
    ${promoteLabel}
  `;
  
  promoteBtn.onclick = () => {
    chrome.runtime.sendMessage({ action: "promoteCurrentWindow" });
  };

  container.appendChild(promoteBtn);
  document.body.appendChild(container);

  // Listen for Command+Enter on the page itself
  document.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      chrome.runtime.sendMessage({ action: "promoteCurrentWindow" });
    }
  });

  // Intercept all clicks on links to prevent opening in a new tab/window
  // This forces standard links to open inside the Mini window
  document.addEventListener('click', (e) => {
    const link = e.target.closest('a');
    if (link && link.target === '_blank') {
      link.target = '_self';
    }
  }, true); // use capture phase to catch it before other frameworks
}
