# Plan: Frontend Navigation and Theme Latency - 2026-05-12

## Muc tieu
- Dieu tra sau do tre frontend tren Hub khi chuyen trang va khi doi light/dark.
- Giu nguyen thiet ke hien tai: layout, visual style, card/banner, theme tone khong doi ve mat y tuong.
- Giam do tre cam nhan toi da bang cache, render scheduling, paint containment va giam repaint khi theme switch.
- Co test va build xac nhan khong gay regression.

## Skill can dung
- `plan-skill`: tao plan va di theo tung phase.
- `frontend-skill`: toi uu component, state, CSS va UX.
- `documentation-skill`/`logging-skill`: ghi lai ket qua neu can commit task lon.
- `push-code-skill`: test, commit va push sau khi pass.

## Phase 1 - Audit va baseline (15-30 phut)
- Doc luong `/hub`, `/hub/[projectId]`, `AppShell`, cache API client va CSS theme.
- Xac dinh cac diem gay lag:
  - cache Hub chi doc trong `useEffect`, nen card/banner hien sau first paint;
  - theme toggle doi `data-theme` tren root lam repaint toan trang;
  - cards/hero dung nhieu shadow/filter/background co the gay paint cost;
  - dev mode cua Next tao overhead rieng.
- Chay frontend typecheck/test/build de co baseline.

## Phase 2 - Hub first-paint optimization (30-60 phut)
- Doi HubExplorer doc session cache trong state initializer, khong doi den `useEffect`.
- Tach helper cache de dung lai va test duoc.
- Giu stale-while-revalidate hien co: cache render ngay, API update sau.
- Them test cho cache-first render neu hop ly.

## Phase 3 - Theme switch optimization (30-60 phut)
- Dieu tra CSS transition/theme switch hien tai.
- Giam repaint khi toggle theme:
  - disable transition/animation trong thoi gian switch ngan;
  - tranh transition background/filter/box-shadow tren nhieu surface khi doi theme;
  - neu can, schedule theme state bang `requestAnimationFrame`.
- Giu giao dien light/dark nhu cu.

## Phase 4 - Render/paint containment (20-45 phut)
- Ap dung containment/content-visibility cho cac vung lap lai neu chua du.
- Dam bao card/banner khong bi layout shift.
- Kiem tra mobile/desktop CSS khong vo layout.

## Phase 5 - Verification va push (20-40 phut)
- Chay:
  - `npm run typecheck --prefix frontend`
  - `npm run test --prefix frontend`
  - `npm run build --prefix frontend`
  - secret scan neu co thay doi lien quan env/API.
- Don artifact `.next`, `next-env.d.ts` neu build cham vao.
- Commit/push source.

## Tieu chi pass
- Hub co the hien card/banner ngay tu cache khi quay lai/chuyen trang.
- Theme switch giam lag cam nhan, khong doi visual design.
- Tests/build pass.
- Working tree sach sau commit/push.

## Ket qua thuc hien
- Audit xac nhan Hub bi cham vi cache providers/featured chi duoc doc trong `useEffect`, tuc sau first paint.
- Da doi HubExplorer doc session cache trong state initializer, giup card/banner co the render ngay khi component mount.
- Audit xac nhan theme switch dang doi `data-theme` cung luc voi React state update, trong khi trang co nhieu background/filter/shadow can repaint.
- Da doi ThemeToggle bat `data-theme-switching` truoc mot animation frame roi moi apply theme; CSS trong luc switch tat transition/animation va bo filter nang tam thoi.
- Da giu nguyen thiet ke, layout va visual style.
- Verification pass:
  - `npm run typecheck --prefix frontend`
  - `npm run test --prefix frontend`
  - `npm run build --prefix frontend`
