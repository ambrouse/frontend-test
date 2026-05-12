# Frontend Navigation and Theme Latency Report

## Timestamp
- Date: 2026-05-12 (Asia/Saigon)

## Scope
- Investigate Hub page latency when card/banner appear after route transition.
- Investigate light/dark theme switch lag.
- Keep the current visual design unchanged.

## Findings
- Hub provider data was cached in `sessionStorage`, but the cache was only read inside `useEffect`. That means the page could paint once with empty providers before card/banner state was restored.
- Theme switching changed the root `data-theme` while many surfaces were eligible for transition, animation, filter, shadow and complex background repaint.
- The backend provider list had already been optimized, so this pass focused on frontend first paint and repaint cost.

## Changes
- Hub now reads cached providers and featured projects in the initial state path, so a warm Hub visit can render card/banner immediately.
- Theme toggle now marks the document as switching first, waits one animation frame, then applies the theme. This lets CSS disable expensive transitions before the repaint.
- During theme switching, CSS temporarily disables animations/transitions, uses scroll background attachment, hides the body grid overlay, and removes heavy filters from large image layers.

## Verification
- `npm run typecheck --prefix frontend`
- `npm run test --prefix frontend`
- `npm run build --prefix frontend`

## Notes
- Production mode should feel smoother than `next dev`; dev mode still has Turbopack/HMR overhead.
- If lag remains after this, the next investigation target is image decode/paint cost for large provider media.
