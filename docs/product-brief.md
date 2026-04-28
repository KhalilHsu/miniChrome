# Product Brief

## Working Name

PeekLink

## One-Liner

A macOS link buffer that opens external links in Mini Chrome first, then lets the
user close them or promote them into the main browser.

## Problem

Chrome users who like Arc's Little Arc often want a temporary link window:

- External links should be quick to inspect.
- Throwaway links should not create permanent tab clutter.
- Important links should be easy to move into the main browser.
- Authenticated sites should use the user's real Chrome identity.

Chrome alone does not offer this workflow cleanly.

## Target User

Power users who live in Chrome but miss Arc's Little Arc:

- Founders and operators opening many links from chat and email.
- Engineers reviewing GitHub, Linear, docs, and dashboards from Slack.
- Researchers who triage lots of articles and references.
- Anyone who uses multiple work apps and wants less tab pollution.

## Core Workflow

```text
Click link in another app
  -> PeekLink receives it as the default browser
  -> PeekLink asks Chrome extension to open Mini Chrome
  -> User previews the page with real Chrome cookies
  -> User closes it or promotes it into a normal Chrome tab
```

## Product Principles

- Preserve Chrome identity. Login state matters more than native rendering purity.
- Keep the surface small. The Mini window should be temporary by default.
- Make promotion explicit. A link becomes a real tab only when the user chooses.
- Stay fast. The product fails if opening a link feels heavier than Chrome.
- Avoid AI in v1. The first product value is link triage, not automation.

## Non-Goals For MVP

- Rebuilding a full browser.
- Replacing Chrome's tab manager.
- Syncing browsing history across devices.
- Supporting every browser on day one.
- Automatically judging link importance with AI.
