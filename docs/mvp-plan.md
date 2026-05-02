# MVP Plan

## Phase 0: Project Setup

- [x] Create project brief.
- [x] Define architecture.
- [x] Create Chrome extension scaffold.
- [ ] Choose final app name.
- [x] Choose prototype bridge: Native Messaging.

## Phase 1: Chrome Extension Prototype

- [ ] Add manifest permissions for `windows`, `tabs`, `storage`, and `commands`.
- [ ] Open a Mini popup window for a supplied URL.
- [ ] Track Mini window IDs.
- [ ] Add keyboard command to Mini-open the current tab.
- [ ] Add context menu item: Open Link in Mini.
- [ ] Add promote action: move Mini tab to the most recent normal Chrome window.
- [ ] Add close action.

## Phase 2: macOS Browser Proxy Prototype

- [ ] Create SwiftUI menu bar app.
- [ ] Register app as browser URL handler for `http` and `https`.
- [ ] Receive incoming URLs.
- [ ] Forward URL to Chrome extension bridge.
- [ ] Add settings UI for Chrome path and profile behavior.

## Phase 3: Product Polish

- [ ] Remember Mini window size and position.
- [ ] Add recent links list.
- [ ] Add auto-cleanup for old Mini windows.
- [ ] Add per-domain rules.
- [ ] Add onboarding that explains default browser setup.

## Phase 4: Release Readiness

- [ ] Replace prototype bridge with Native Messaging if needed.
- [ ] Harden local bridge security.
- [ ] Add app signing and notarization.
- [ ] Add Chrome Web Store package metadata.
- [ ] Prepare install instructions.
