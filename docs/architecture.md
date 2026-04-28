# Architecture

## Recommended Shape

```text
macOS App
  -> registers as handler for http/https
  -> receives external URL
  -> sends URL to Chrome companion extension
  -> manages settings, rules, recent links, global shortcuts

Chrome Companion Extension
  -> runs inside the user's Chrome profile
  -> opens URL in a popup window
  -> manages Close / Promote / Copy actions
  -> preserves cookies, extensions, and login state
```

## Why This Shape

The important requirement is that Mini windows use the user's Chrome Profile.
That means the page should be opened by real Chrome, not by a standalone
WKWebView. The Chrome extension is the cleanest component for creating and
managing Chrome popup windows.

The macOS app still matters because it can act at the operating-system link
entry point. It can become the default browser proxy and receive links from
Slack, Messages, Mail, Notion, Linear, and other apps before Chrome does.

## Component Responsibilities

### macOS App

- Registers as an `http` and `https` handler.
- Receives incoming URLs from external apps.
- Stores user settings:
  - default Chrome profile preference
  - window size and screen placement
  - domain rules
  - recent links
- Shows a menu bar control.
- Provides global shortcut support.
- Talks to the Chrome extension through a local bridge.

### Chrome Extension

- Opens Mini windows with `chrome.windows.create({ type: "popup", url })`.
- Tracks Mini window IDs and tab IDs.
- Promotes a Mini tab to the user's main Chrome window.
- Closes Mini windows.
- Copies the current link.
- Optionally injects a minimal overlay toolbar into Mini windows.

## Bridge Options

### Option 1: Native Messaging

The macOS app installs a Chrome Native Messaging host. The extension connects to
that host and receives incoming URLs.

Pros:

- Official Chrome extension mechanism.
- Stronger structure than AppleScript.
- Good long-term architecture.

Cons:

- More setup work.
- Requires installing a native host manifest.

### Option 2: Localhost Bridge

The macOS app runs a small local HTTP server. The extension connects to it or
polls it for incoming URLs.

Pros:

- Easy to prototype.
- Simple debugging.

Cons:

- Local port management.
- More security review work.

### Option 3: AppleScript / CLI Only

The macOS app controls Chrome directly.

Pros:

- Fastest proof of concept.

Cons:

- Brittle.
- Permission prompts.
- Harder to manage tabs and windows cleanly.

## Initial Recommendation

Prototype with a local bridge if speed matters. Move to Native Messaging before
public release.

## Security Notes

- Never read Chrome cookie databases directly.
- Never decrypt user cookies.
- Do not expose a local bridge to the network.
- Only accept URLs from the local macOS app.
- Avoid remote debugging against real Chrome profiles.
