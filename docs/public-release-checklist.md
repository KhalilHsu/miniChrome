# Public Release Checklist

This checklist is for the point where PeekLink is ready to be published on GitHub
as a public project, even if it is not yet ready for the Chrome Web Store.

## Must Fix Before Public Push

- Remove generated build artifacts from the working tree.
- Keep `.build/`, `.app`, `.dSYM`, and `.DS_Store` files out of Git history.
- Verify that no secret values, API keys, or private paths are stored in docs or source.
- Confirm the extension permissions are intentional and documented.
- Confirm the macOS app only stores the minimum settings needed for the bridge.

## Privacy And Security Review

- Review whether each Chrome permission is still needed for the MVP.
- Document why the extension uses any broad page-access or navigation permissions.
- Avoid reading Chrome profile databases directly.
- Avoid remote debugging against real Chrome profiles.
- Keep the bridge local-only and do not expose it to the network.
- Make it clear in README that the extension runs locally and is meant to manage
  Mini windows, not collect browsing data.

## Repository Hygiene

- Add `.gitignore` rules for build outputs and macOS metadata.
- Keep generated app bundles out of the repository.
- Keep local install scripts reproducible and side-effect free where possible.
- Avoid committing machine-specific files from a single developer machine.

## Release Readiness

- Verify `build.sh` still succeeds from a clean checkout.
- Verify the extension still opens, promotes, and closes Mini windows.
- Verify the macOS app still receives external links and forwards them to Chrome.
- Verify the default browser setup instructions are still accurate.
- Review README and docs for any wording that overpromises the MVP.

## Nice To Have

- Add a short privacy note in README.
- Add a short install guide for local development.
- Add a short troubleshooting section for Chrome extension IDs and app name/path.
