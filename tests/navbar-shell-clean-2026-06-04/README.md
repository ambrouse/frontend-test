# Navbar Shell CSS Cleanup Evidence - 2026-06-04

## Scope

- Moved shell, dock navigation, and theme toggle styling into `frontend/src/styles/shell.css`.
- Removed stacked historical nav/theme override blocks from `frontend/src/styles/globals.css`.
- Kept the dock buttons and light theme toggle on the same crescent animation geometry as the dark theme toggle.

## Evidence

- `01-dark-theme-hover.png` through `04-dark-settings-hover.png`: dark-mode hover close-ups.
- `05-light-theme-hover.png` through `08-light-settings-hover.png`: light-mode hover close-ups.
- `09-light-settings-panel.png` and `10-dark-settings-panel.png`: settings panel sanity checks after CSS cleanup.
- `computed-style-audit.json`: computed styles for theme, Home, Hub, and Settings buttons.
- `layout-regression/07-hub-desktop-no-overflow-fixed-nav.png`: desktop Hub with fixed left navbar and no horizontal overflow.
- `layout-regression/08-hub-scroll-no-overflow-fixed-nav.png`: scrolled page proving the navbar stays fixed.
- `layout-regression/layout-metrics-no-overflow-fixed-nav.json`: viewport width, scroll width, dock/content rects, and animation timing.

## Verification

- `npm run build` passed.
- `npm run typecheck` passed after the build regenerated `.next/types`.
- Playwright screenshots were captured with the real `ai-hub-theme` localStorage key and waited for `document.documentElement.dataset.theme`.
- Final desktop metrics: dock `x=0`, content `x=78`, content width `calc(100vw - 78px)`, document scroll width equals viewport width, navbar animation is `0.38s` with a slight ease-out.
