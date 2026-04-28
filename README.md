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

## Project Docs

- [Product Brief](docs/product-brief.md)
- [Architecture](docs/architecture.md)
- [MVP Plan](docs/mvp-plan.md)
- [Decision Log](docs/decision-log.md)

## Repository Layout

```text
apps/macos/          macOS app design notes and future Swift implementation
extension/chrome/    Chrome companion extension scaffold
docs/                product, architecture, and execution notes
```
