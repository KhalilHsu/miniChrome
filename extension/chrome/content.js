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

  // Navigation Group (Back/Forward)
  const navGroup = document.createElement('div');
  navGroup.className = 'peeklink-nav-group';

  const backBtn = document.createElement('button');
  backBtn.className = 'peeklink-btn';
  backBtn.title = 'Back';
  backBtn.innerHTML = `
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
      <polyline points="15 18 9 12 15 6"></polyline>
    </svg>
  `;
  backBtn.onclick = () => window.history.back();

  const forwardBtn = document.createElement('button');
  forwardBtn.className = 'peeklink-btn';
  forwardBtn.title = 'Forward';
  forwardBtn.innerHTML = `
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
      <polyline points="9 18 15 12 9 6"></polyline>
    </svg>
  `;
  forwardBtn.onclick = () => window.history.forward();

  navGroup.appendChild(backBtn);
  navGroup.appendChild(forwardBtn);

  // Address Bar
  const addressBar = document.createElement('input');
  addressBar.className = 'peeklink-address-bar';
  addressBar.type = 'text';
  addressBar.value = window.location.href;
  addressBar.spellcheck = false;

  addressBar.onkeydown = (e) => {
    if (e.key === 'Enter') {
      let url = addressBar.value.trim();
      if (url && !url.match(/^[a-zA-Z]+:\/\//)) {
        url = 'https://' + url;
      }
      if (url) {
        window.location.href = url;
      }
      addressBar.blur();
    } else if (e.key === 'Escape') {
      addressBar.value = window.location.href;
      addressBar.blur();
    }
  };

  // Update address bar value when navigation happens
  const updateAddressBar = () => {
    addressBar.value = window.location.href;
  };
  window.addEventListener('popstate', updateAddressBar);
  // Also check periodically as SPA navigation might not trigger popstate in some cases
  setInterval(updateAddressBar, 1000);

  // Divider
  const divider = document.createElement('div');
  divider.className = 'peeklink-divider';

  // Promote Button
  const promoteBtn = document.createElement('button');
  promoteBtn.className = 'peeklink-btn promote-btn';
  const promoteLabel = chrome.i18n.getMessage('promoteToChromeButton') || 'Promote';
  promoteBtn.innerHTML = `
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"></path>
      <polyline points="15 3 21 3 21 9"></polyline>
      <line x1="10" y1="14" x2="21" y2="3"></line>
    </svg>
    <span>${promoteLabel}</span>
  `;
  
  promoteBtn.onclick = () => {
    chrome.runtime.sendMessage({ action: "promoteCurrentWindow" });
  };

  container.appendChild(navGroup);
  container.appendChild(addressBar);
  container.appendChild(divider);
  container.appendChild(promoteBtn);
  document.body.appendChild(container);

  // Listen for Command+Enter on the page itself
  document.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter' && document.activeElement !== addressBar) {
      chrome.runtime.sendMessage({ action: "promoteCurrentWindow" });
    }
  });

  // Intercept all clicks on links to prevent opening in a new tab/window
  document.addEventListener('click', (e) => {
    const link = e.target.closest('a');
    if (link && link.target === '_blank') {
      link.target = '_self';
    }
  }, true);
}
