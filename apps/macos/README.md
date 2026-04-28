# macOS App

This folder is reserved for the future SwiftUI menu bar app.

## Responsibilities

- Register as the default browser handler for `http` and `https`.
- Receive external links from other macOS apps.
- Forward URLs to the Chrome companion extension.
- Store settings and recent links.
- Provide global shortcuts and menu bar controls.

## Prototype Notes

The first prototype should prove:

```text
external URL -> macOS app -> Chrome extension -> Mini Chrome popup
```

Once that path works, the app can add settings, onboarding, and native polish.
