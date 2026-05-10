# AI Hub Frontend Work Log

## Update 2026-05-10 - Backend implementation phase 1-3

- Added `backend/` FastAPI app with cache-first hardware, provider, task, and health APIs.
- Added provider registry that serves in-memory warm snapshots and refreshes from `providers/*/aihub.provider.json`.
- Added `providers/` seed folders for 30 frontend providers with manifest/config/runtime/log/script layout.
- Added backend pytest contract and latency tests.
- Added frontend `apiClient` with 250 ms timeout and static fallback behavior for Hub/AppShell so render is not blocked by backend.
- Updated CI to run backend pytest on Linux and Windows.
- Warm-path local averages: health 1.851 ms, hardware 1.918 ms, providers 2.307 ms, featured 2.244 ms.
- Verified: backend pytest pass, frontend typecheck pass, frontend test pass, frontend build pass.

## Update 2026-05-10 - Backend provider runtime plan

- Read the requested `plan-skill` from `.codex/skills/project-workflow/references/github-skills/plan-skill/SKILL.md`.
- Added `plans/plan-backend-provider-runtime.md` with FastAPI backend, root `providers/` layout, frontend API needs, low-latency cache/watch/SSE pipeline, phases, testing, and CI/CD notes.
- Removed the side-dock Live/provider shortcut button from `AppShell`.
- Verified: frontend typecheck pass, frontend test pass.

## Update 2026-05-10 - Hub performance pass

- Removed heavy per-card theme bloom and the delayed theme toggle lock.
- Stopped Hub carousel from changing body ambient color on every slide.
- Memoized provider cards/grid so carousel slide changes do not re-render the full provider list.
- Replaced expensive route/card/filter animations with lighter opacity/transform transitions.
- Fixed light card arrow placement and increased light-card text contrast.
- Verified: typecheck pass, test pass, build pass.

## Update 2026-05-10 - Codex skill wrapper and responsive polish

- Added `.codex/skills/project-workflow` as a Codex-compatible wrapper.
- Preserved the original `.github/skills` content unchanged under `references/github-skills`.
- Tuned Home responsive density for smaller screens: reduced hero padding, readiness console height, metric card height, GPU panel sizing, and one-column home grid behavior.
- Tuned Hub responsive layout: provider cards switch to 2 columns earlier and filter/search stack earlier to avoid cramped cards.
- Verified: skill validation pass, typecheck pass, test pass, build pass.

Ngày: 2026-05-10

## Tóm tắt phiên làm việc

- Đã đọc `frontend-skill`, `documentation-skill`, `logging-skill`.
- Không tìm thấy `testing-skill`, đã ghi nhận và dùng Vitest cho testing.
- Người dùng yêu cầu đổi stack sang Next.js; đã cập nhật `plans/plan-ai-hub-frontend.md`.
- Đã scaffold Next.js App Router với TypeScript.
- Đã xây mock service, compatibility evaluator và tests.
- Đã dựng Home, Hub, Hub Detail theo visual direction dark-first.
- Đã thêm docs và log task.

## Kiểm tra đã chạy

- `npm.cmd run typecheck`: pass.
- `npm.cmd run test`: pass.
- `npm.cmd run build`: pass.

## Vấn đề gặp phải

- PowerShell chặn `npm.ps1`, đã dùng `npm.cmd`.
- Build đầu tiên báo `usePathname()` có thể null; đã thêm fallback `pathname ?? "/"`.
- `npm install` báo 7 moderate vulnerabilities; chưa force fix để tránh breaking changes.

## Cập nhật 2026-05-10

- Sửa Hub banner từ static title sang carousel project có background image asset và tint theo màu project.
- Sửa Detail banner, bỏ phần mô tả dài và repo line trong hero.
- Thêm theme ripple/stagger animation.
- Verify lại: typecheck pass, test pass, build pass.

## Cập nhật 2026-05-10 lần 2

- Tải 5 ảnh thật từ Pexels về `public/assets/projects/*.jpg`.
- Cập nhật mock data để dùng ảnh thật và ambient color riêng cho từng project.
- Cập nhật Hub/Detail để set body ambient theo project hiện tại.
- Bỏ ripple theme cũ, thay bằng `data-theme-next` và `data-theme-transition` với surface bloom.
- Verify lại: typecheck pass, test pass, build pass.

## Push preparation 2026-05-10

- Đọc lại `push-code-skill`.
- Thêm `.gitignore`, `.env.example`, `README.md`, và GitHub Actions CI.
- Chuẩn bị push lên `https://github.com/ambrouse/frontend-test.git`.

## Cập nhật UI polish 2026-05-10

- Đọc lại `frontend-skill`.
- Thêm animation xuất hiện khi vào trang và khi chuyển route.
- Tune light theme, body ambient, project card visual layer.
- Verify lại: typecheck pass, test pass, build pass.

## Cập nhật light theme 2026-05-10

- Tắt Next dev indicator bằng `devIndicators: false`.
- Tăng contrast cho navbar light mode.
- Giảm độ chói body/banner/card trong light mode.
- Thêm overlay sáng phía text cho hero/detail ở light mode để chữ không chìm vào ảnh.
- Verify lại: typecheck pass, test pass, build pass.
