# Navbar Light Ring Verification

Scope: verify the light-mode navbar ring animation on both vertical desktop dock and horizontal mobile dock after the contrast update.

Run target: `http://localhost:6901/` using the existing local Next.js dev server.

Checks:
- Light desktop dock hover/active ring is visible on the white shell.
- Light theme-toggle hover ring uses the same stronger ring treatment.
- Light mobile horizontal navbar keeps the ring visible without layout shift.
- Dark desktop dock remains on the original dark-mode ring treatment.

Evidence:
- [Light desktop dock hover](app/01-light-desktop-dock-hub-hover.png)
- [Light desktop theme hover](app/02-light-desktop-theme-hover.png)
- [Light mobile navbar hover](app/03-light-mobile-navbar-hub-hover.png)
- [Dark desktop dock hover](app/04-dark-desktop-dock-hub-hover.png)

Result: pass.
