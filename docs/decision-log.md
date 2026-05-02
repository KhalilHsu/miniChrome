# Decision Log

## 2026-04-28: Use Real Chrome For Mini Windows

Decision: Mini windows should be real Chrome popup windows, not WKWebView.

Reason: The product depends on the user's existing Chrome Profile, cookies,
extensions, and login state. WKWebView would create a cleaner native shell, but
would break authenticated browsing for many work apps.

## 2026-04-28: Use macOS App Plus Chrome Extension

Decision: Build PeekLink as a macOS app with a Chrome companion extension.

Reason: The macOS app owns the operating-system link entry point. The Chrome
extension owns Chrome window and tab control. This split preserves both native
OS integration and Chrome identity.

## 2026-04-28: Avoid Direct Chrome Cookie/Profile Access

Decision: Do not read or decrypt Chrome profile databases.

Reason: It is fragile, invasive, and unnecessary. Opening pages inside real
Chrome gives us the desired login behavior without touching sensitive profile
storage.

## 2026-05-01: Use Native Messaging For The Bridge

Decision: Use a Chrome native messaging host instead of a visible bridge tab to
hand URLs from the macOS app to the Chrome extension.

Reason: The visible bridge tab can activate Chrome and trigger Space switching.
Native messaging keeps the URL transfer out of the UI path while preserving the
real Chrome profile workflow.
