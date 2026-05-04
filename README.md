# PeekLink

PeekLink is a macOS-first "Little Arc for Chrome" concept.

The app acts as a default browser proxy for external links. Links from Slack,
Messages, Mail, Notion, Linear, and other apps open in a lightweight Mini Chrome
window first. From there, the user can close the link, copy it, or promote it
into a normal Chrome tab.

The key product bet is simple: external links should not pollute the user's main
browser workspace until the user decides they are worth keeping.

## Product Shape

PeekLink is designed as two cooperating pieces:

- A macOS menu bar app that registers as a browser and receives external links.
- A Chrome companion extension that opens and manages real Chrome popup windows.

This preserves the user's Chrome Profile, cookies, login state, and extensions
while still giving PeekLink control over the external-link workflow.

## MVP

- Register the macOS app as a browser for `http` and `https` links.
- Forward incoming URLs to the Chrome companion extension.
- Open each URL in a Mini Chrome popup window using the active Chrome profile.
- Provide controls for Close, Open in Chrome Tab, and Copy Link.
- Remember window size and position.
- Add a small menu bar control for settings and recent links.

## Why Not WKWebView First?

WKWebView gives the app more native window control, but it does not naturally
share Chrome cookies, profiles, extensions, or login state. For authenticated
work apps, that breaks the most important part of the experience.

PeekLink should feel like Chrome, not a separate browser that makes the user log
in again.

## Privacy Note

PeekLink runs locally on your Mac. The browser extension is used to open and
manage Mini Chrome windows in your own Chrome profile. It does not send page
content to a remote service, and it does not read Chrome profile databases
directly. Some extension permissions look broad because the MVP needs to manage
links across the sites you open from other apps.

## Project Docs

- [Product Brief](docs/product-brief.md)
- [Architecture](docs/architecture.md)
- [MVP Plan](docs/mvp-plan.md)
- [Decision Log](docs/decision-log.md)
- [Competitive Research](docs/competitive-research.md)

## Repository Layout

```text
apps/macos/          macOS app built with Swift Package Manager
extension/chrome/    Chrome companion extension
docs/                product, architecture, and execution notes
```

## Security & Extension Permissions

Because PeekLink relies on a Chrome Extension to provide a native-feeling "Little Arc" experience, it requests several permissions that may look broad at first glance. These are the current MVP tradeoffs:

- **`<all_urls>` (Content Scripts)**: The extension injects a tiny UI overlay ("Promote to Chrome") and a click-interceptor into the Mini windows. Because PeekLink acts as your default browser proxy, it needs to be able to render this UI and intercept `target="_blank"` links on *any* URL you might click from an external app. The content script **only** executes UI injection and click-interception; it does not read, store, or transmit any page content.
- **`webNavigation`**: Used exclusively to catch JavaScript-based popups (e.g., `window.open`) that originate from a Mini window. It forces them to navigate inside the current Mini window instead of mistakenly spawning a new tab in your main Chrome window.
- **`system.display`**: Used to intelligently calculate 80% of your current active monitor's dimensions and center the Mini window perfectly upon creation. This prevents websites from rendering in cramped "mobile" layouts.
- **`tabs` & `windows`**: Required to create the Mini window, move tabs from the Mini window to your main Chrome window during a "Promote" action, and instantly close leftover tabs.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

