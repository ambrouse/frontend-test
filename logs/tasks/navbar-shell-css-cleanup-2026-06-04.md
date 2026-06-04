# Navbar Shell CSS Cleanup Log - 2026-06-04

## Scope

- User reported that navbar animation was broken in dark mode and asked to avoid stacking more CSS overrides.
- Goal was to make the four dock buttons and the light theme button follow the dark theme button animation while cleaning the codebase.

## Changes

- Added `frontend/src/styles/shell.css` as the single stylesheet for side dock, dock buttons, command bar, live status, and theme toggle.
- Imported `shell.css` after `globals.css` from `frontend/src/app/layout.tsx`.
- Removed historical nav/theme override blocks from `frontend/src/styles/globals.css`, including old `navThin`, `navClose`, `navCrescent`, `finalNavFlash`, and related stacked rules.
- Reduced hover border intensity so the visible motion reads as the crescent pseudo-element instead of a thick full ring.
- Fixed shell layout after CSS extraction: the side dock is fixed at `left: 0`, content uses `margin-left: var(--dock-width)` and `width: calc(100vw - var(--dock-width))`, and root padding is reset to avoid double offset.
- Updated navbar spin timing to `0.38s` with a slight ease-out near the end per user feedback.

## Evidence

- Evidence folder: `tests/navbar-shell-clean-2026-06-04/`.
- Build passed with `npm run build`.
- Typecheck passed with `npm run typecheck` after build regenerated `.next/types`.
- Visual checks were captured for dark theme button, dark dock buttons, light theme button, light dock buttons, and settings panel in both modes.
- Layout regression evidence shows document scroll width equals viewport width, navbar remains fixed after scroll, and content starts at exactly the dock width.

## Notes

- One parallel typecheck/build attempt failed because `next build` was recreating `.next/types` while `tsc` was reading them. Running typecheck again after build passed.
