# Competitive Research

## Summary

There are several Chrome extensions that recreate parts of Arc Peek by opening
links in overlays or popup windows. There are also macOS apps that register as
the default browser and route links to different browsers. The research did not
find a mature product that combines both halves into a Little Arc-style flow for
Chrome external links.

PeekLink's potential gap:

```text
External app link
  -> macOS default browser proxy
  -> real Chrome profile popup window
  -> close, copy, or promote into a normal Chrome tab
```

## Chrome Popup And Peek Extensions

### Open in Popup Window

- URL: https://chromewebstore.google.com/detail/open-in-popup-window/gmnkpkmmkhbgnljljcchnakehlkihhie
- Positioning: link preview in a clean Chrome popup window.
- Notable features:
  - Context menu action for links and images.
  - Shift-click and drag-to-open options.
  - Configurable popup size and position.
  - Can close popup windows when the regular Chrome window regains focus.
  - Can remember popup window size after manual resize.
  - Describes itself as similar to Safari Link Preview, Arc Peek, and Zen
    Glance.
- Relevance: closest reference for PeekLink's Chrome extension window behavior.
- Limitation: operates inside Chrome browsing sessions; it does not receive
  links from external macOS apps as a default-browser proxy.

### Peek Preview - Arc Like Link Preview

- URL: https://chromewebstore.google.com/detail/peek-preview-arc-like-lin/jlllnhfjmihoiagiaallhmlcgdohdocb
- Source: https://github.com/tomowang/peek-preview
- Positioning: Arc-like link preview for Chrome and Firefox.
- Notable features:
  - Preview links in the current tab or a popup window.
  - Shift-click and drag-to-preview.
  - Esc or blur closes the preview.
  - Open source.
- Relevance: useful source reference for link preview behavior and edge cases.
- Limitation: closer to Arc Peek than Little Arc. It does not cover external app
  links or macOS default browser handling.

### Arc Peek: Link Preview

- URL: https://chromewebstore.google.com/detail/arc-peek-link-preview/cemmifilbjnnfldldefdakgljjloajhb
- Positioning: Arc Peek-style link preview for Chrome.
- Notable features:
  - Shift-click and drag-to-preview.
  - Click outside to close.
  - Expand preview into a new tab.
- Relevance: validates demand for Arc-like preview behavior in Chrome.
- Limitation: in-page preview workflow only, not external link triage.

### TabToPopup

- URL: https://chromewebstore.google.com/detail/tabtopopup/bpnnnahgjgehfimcicpjmjidcoghhfpf
- Source: https://github.com/chabon/TabToPopup
- Positioning: convert the current tab or a link into a popup window.
- Notable features:
  - Opens current tab as a popup window.
  - Remembers popup window position and size.
  - Adds right-click "open in popup window" behavior.
  - Includes options such as closing the original window and injecting CSS.
- Relevance: reference for tab-to-popup and popup sizing behavior.
- Limitation: window utility, not a link-buffer product.

## macOS Browser Router Apps

### Default Tamer

- URL: https://www.defaulttamer.app/
- Source: linked from product site as open source.
- Positioning: macOS default-browser proxy that routes links to the right
  browser based on source app, domain, and rules.
- Notable features:
  - Sets itself as the default browser.
  - Routes links by source app and domain.
  - Menu bar app.
  - Route history and fallback browser.
  - Privacy-first local routing.
- Relevance: strong reference for PeekLink's macOS app half.
- Limitation: routes links to browsers, but does not create temporary Chrome
  popup windows or manage a close/promote workflow.

### Velja

- URL: https://sindresorhus.com/velja
- Positioning: macOS browser picker and link router.
- Relevance: validates the macOS default-browser proxy pattern.
- Limitation: browser/app routing rather than Chrome Mini window triage.

### Open Link Pro

- URL: https://apps.apple.com/us/app/open-link-pro-browser-picker/id1530712347
- Positioning: macOS browser picker for opening links in selected browsers.
- Relevance: another commercial example of the default-browser routing pattern.
- Limitation: does not provide Chrome popup window management.

## Takeaways For PeekLink

- Chrome popup behavior is already proven by multiple extensions.
- macOS default-browser proxy behavior is already proven by browser router apps.
- The product opportunity is the combined workflow, not either component alone.
- The extension should learn from existing popup tools:
  - configurable size and position
  - remember manual resize
  - close-on-blur or close-on-focus-return
  - keyboard shortcuts
  - promote/expand action
- The macOS app should learn from router tools:
  - default browser setup flow
  - fallback browser behavior
  - source app and domain rules
  - local-only routing and clear privacy posture

## Open Questions

- Can the first version avoid an injected toolbar and rely on extension actions,
  keyboard shortcuts, and a small companion UI?
- Should the prototype start with a localhost bridge for speed, then move to
  Native Messaging before public release?
- Should PeekLink support routing rules in MVP, or only after the external link
  to Mini Chrome popup path feels reliable?
