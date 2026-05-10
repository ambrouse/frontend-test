# Plan: AI Hub Frontend

Ngày lập: 2026-05-10

## 1. Mục tiêu

Xây dựng frontend cho một AI Hub chạy local, dùng để quản lý nhanh các project/provider từ GitHub cá nhân. Ứng dụng cần cho phép xem tình trạng phần cứng máy, theo dõi tài nguyên đang dùng, duyệt các project đã setup sẵn, đánh giá khả năng chạy của từng project trên máy hiện tại, xem chi tiết logs/cấu hình/benchmark, và thao tác install/stop/delete.

Phong cách giao diện cần dark-first, nhẹ nhàng nhưng thời trang, hiện đại, có light/dark option, tránh cảm giác dashboard dạng block/card đơn điệu. Thiết kế phải có cá tính mới mẻ nhưng vẫn rõ ràng cho workflow kỹ thuật.

## 2. Phạm vi MVP

- Home: tổng quan phần cứng và runtime của máy.
- Hub: danh sách project/provider đã chuẩn bị sẵn.
- Hub Detail: chi tiết project, logs, yêu cầu cấu hình, benchmark lần chạy gần nhất, trạng thái cài đặt/chạy.
- Theme: dark/light switch, dark là ưu tiên thị giác chính.
- Mock data/API adapter trước, để backend có thể nối vào sau.
- Responsive desktop-first, vẫn dùng tốt trên tablet/mobile.

Ngoài phạm vi MVP:

- Auth/user management.
- Marketplace public nhiều người dùng.
- Tự clone/install thật từ GitHub nếu backend chưa có API.
- Realtime hardware telemetry thật nếu chưa có service nền.

## 3. Tham khảo thiết kế và nguyên tắc áp dụng

Nguồn đã đọc:

- Material Design dark theme: dark mode nên dùng nền xám tối có tầng surface/elevation, không chỉ đảo màu hoặc dùng đen tuyệt đối. Link: https://design.google/library/material-design-dark-theme
- Midrocket UI trends 2026: dark mode trưởng thành dùng grey variations, OLED-aware palette, 3D/data visualization có tính tiện ích, AI interfaces cần thích ứng theo ngữ cảnh. Link: https://midrocket.com/en/guides/ui-design-trends-2026/
- TheeDigital web design trends 2026: bento modular layout, variable typography, organic shapes, subtle 3D/depth, purposeful micro-animation. Link: https://www.theedigital.com/blog/web-design-trends
- Creative Bloq 2026 graphic/illustration trends: xu hướng phản ứng với vẻ quá bóng bẩy của AI bằng texture, chất thủ công, cảm giác có con người. Link: https://www.creativebloq.com/design/graphic-design/texture-warmth-and-tactile-rebellion-the-big-graphic-design-trends-for-2026

Áp dụng vào AI Hub:

- Dark-first: base không dùng pure black; dùng nhiều lớp surface tối như ink, graphite, smoked glass.
- Không lạm dụng neon: chỉ dùng accent cho status, CTA, metric nóng.
- Layout command-center: Home giống bảng điều khiển phần cứng có nhịp bất đối xứng, không xếp toàn bộ thành grid card đều nhau.
- Tactile + technical: thêm noise/texture rất nhẹ, đường line kỹ thuật mảnh, glow nhỏ có kiểm soát, surface blur vừa đủ.
- Data có hình dáng riêng: CPU/GPU/RAM/VRAM/Disk/temperature không chỉ là số trong ô; dùng gauge, strip chart, radial meter, compact sparkline.
- Micro-interaction có mục đích: hover project card hé quick actions, ping status có pulse nhẹ, install progress có step timeline.
- Light mode không phải bản phụ xấu: vẫn dùng surface mềm, accent giữ tương phản, tránh trắng tinh phẳng.

## 4. Information Architecture

### 4.1 App shell

- Left rail mảnh hoặc floating dock: Home, Hub, Tasks, Settings.
- Top command bar: search project, theme toggle, hardware health indicator, running task count.
- Background layer: dark textured canvas, radial light rất nhẹ theo vùng focus, không dùng gradient blob trang trí rời rạc.
- Content layer: các module không đóng trong quá nhiều card; dùng section band, rail, metric island, floating inspector.

### 4.2 Home

Mục tiêu: cho người dùng biết máy hiện tại đang đủ khỏe để chạy project nào và tài nguyên đang bị chiếm ở đâu.

Nội dung:

- Hardware identity: CPU, GPU, RAM, VRAM, disk, driver/runtime nếu có.
- Resource cockpit: CPU %, GPU %, RAM used/free, VRAM used/free, disk free, nhiệt độ.
- Running tasks: task name, provider/project, PID hoặc session id, runtime, CPU/GPU/RAM/VRAM đang dùng, status.
- Capacity hints: "Có thể chạy thêm 1 LLM 7B quantized", "VRAM đang căng", "GPU temp cao".
- Recent activity: install/run/stop/error events gần đây.

Thiết kế:

- Hero không phải marketing; là "machine cockpit" toàn màn hình đầu tiên.
- Main visual là hardware telemetry cluster: một vùng lớn dành cho GPU/VRAM + nhiệt độ, các metric nhỏ bám xung quanh.
- Task đang chạy dạng timeline/rail dọc, không dùng table khô ở màn đầu.

### 4.3 Hub

Mục tiêu: duyệt nhanh các project/provider, biết cái nào máy chạy nổi, chỉnh nhẹ cấu hình trước khi install/run.

Nội dung:

- Filter theo loại: LLM, Vision, Spark LLM, NVIDIA Blueprint, Embedding, Speech, Tooling, Custom.
- Search theo tên/tag/GitHub repo.
- Project cards: tên, loại, repo, mô tả ngắn, status setup, compatibility ping xanh/vàng/đỏ, yêu cầu tối thiểu nổi bật, last benchmark.
- Quick edit nhẹ: model path, quantization/profile, port, env preset, branch/version, install directory.
- Sort: recommended, lowest requirement, recently used, installed, failed.

Thiết kế:

- Project grid dạng masonry/bento có nhịp khác nhau theo loại project và trạng thái.
- Ping status:
  - Green: chạy tốt trên cấu hình hiện tại.
  - Yellow: chạy được nhưng có cảnh báo, ví dụ gần full VRAM hoặc RAM.
  - Red: thiếu tài nguyên hoặc dependency quan trọng.
- Card không chỉ là block: có stripe màu theo loại, mini requirement bar, hover inspector, repo/action icon.

### 4.4 Hub Detail

Mục tiêu: một màn hình đủ sâu để install, monitor, debug và quyết định giữ/xóa project.

Nội dung:

- Header: project name, type, repo link, install status, compatibility ping, primary actions Install/Run/Stop/Delete.
- Requirement panel:
  - Minimum: CPU, GPU, RAM, VRAM, disk, driver/runtime.
  - Recommended: cấu hình đề xuất.
  - Current machine fit: pass/warn/fail từng mục.
- Runtime benchmark gần nhất:
  - LLM: tokens/second, time to first token, context length, model size, quantization, VRAM peak.
  - Vision: FPS, latency p50/p95, resolution, batch size, VRAM peak.
  - Spark LLM: job latency, throughput, executor memory, GPU acceleration nếu có.
  - NVIDIA Blueprint: service health, container count, GPU utilization, API latency.
- Logs:
  - Install logs.
  - Runtime logs.
  - Error-only filter.
  - Search logs.
  - Copy/export log action.
- Config editor:
  - Basic tab cho chỉnh nhẹ.
  - Advanced tab có confirm khi sửa env/dependency/script.
- Actions:
  - Install.
  - Run/Start nếu đã install.
  - Stop.
  - Delete/remove local files, có confirm.

Thiết kế:

- Detail layout dạng split: bên trái là project identity + requirement fit, giữa là live status/benchmark, bên phải hoặc bottom là logs terminal.
- Logs dùng terminal panel thật sự có hierarchy màu, timestamp rõ, filter chips.
- Actions nguy hiểm như Delete dùng affordance rõ, không đặt ngang hàng quá nổi bật với Install/Stop.

## 5. Data Model đề xuất

### 5.1 HardwareSnapshot

- cpu: name, cores, usagePercent, temperatureC.
- gpu: name, vendor, usagePercent, temperatureC, vramTotalMb, vramUsedMb, driverVersion.
- ram: totalMb, usedMb.
- disk: totalGb, freeGb, installPathFreeGb.
- timestamp.

### 5.2 RunningTask

- id, projectId, projectName, type.
- status: installing | running | stopping | failed | completed.
- startedAt, durationSec.
- cpuPercent, gpuPercent, ramMb, vramMb.
- currentStep, progressPercent.

### 5.3 HubProject

- id, name, type, repoUrl, description.
- tags, icon, accentColor.
- installStatus: not_installed | installed | installing | failed.
- runStatus: stopped | running | error.
- compatibility: green | yellow | red.
- compatibilityReasons.
- requirements: minimum, recommended.
- defaultConfig, editableConfig.
- lastBenchmark.
- lastRunAt.

### 5.4 ProjectLog

- id, projectId, source: install | runtime | system.
- level: info | warn | error | debug.
- timestamp, message, metadata.

## 6. Component Plan

- AppShell: navigation, command bar, global status.
- ThemeProvider: semantic tokens, light/dark switching, persisted preference.
- HardwareCockpit: main hardware overview.
- MetricGauge: CPU/GPU/RAM/VRAM/Disk/temperature visual.
- ResourceSparkline: mini trend chart.
- RunningTaskRail: task list/timeline.
- ProjectBentoGrid: hub layout.
- ProjectCard: project summary with compatibility ping.
- CompatibilityPing: green/yellow/red state with reasons tooltip.
- ProjectQuickEditDrawer: lightweight config edit.
- ProjectDetailHeader.
- RequirementFitMatrix.
- BenchmarkPanel: type-specific metrics.
- LogsTerminal: logs viewer, search, filters, export/copy.
- ActionBar: install/run/stop/delete with state handling.
- EmptyState/ErrorState/Skeleton loaders.

## 7. Visual System

### 7.1 Dark palette direction

- Background base: near-black graphite, not pure black.
- Surface low: dark charcoal.
- Surface high: slightly lighter smoked grey.
- Text primary: soft white, not pure white.
- Text secondary: cool grey.
- Accent primary: cyan/teal for active/AI/system energy.
- Accent secondary: warm amber for warnings and fashion contrast.
- Success: mint/green.
- Danger: coral/red.
- Type accents can vary by project type but must remain controlled.

### 7.2 Light palette direction

- Background base: warm off-white or pale grey.
- Surface: translucent white/soft grey.
- Text: near-black graphite.
- Accent giữ cùng hue nhưng giảm saturation.

### 7.3 Typography

- Font chính: modern sans như Inter, Geist, hoặc system fallback.
- Numeric metrics: tabular figures.
- Logs: monospace như JetBrains Mono hoặc ui-monospace.
- Không dùng hero-scale type trong panel nhỏ; metric lớn vừa phải, dễ scan.

### 7.4 Motion

- 120-220ms cho hover/focus.
- 300-500ms cho install progress/detail transition.
- Pulse status rất nhẹ, tắt hoặc giảm với prefers-reduced-motion.

## 8. Kỹ thuật đề xuất

Nếu bắt đầu project mới:

- Next.js + React + TypeScript.
- App Router, ưu tiên server-rendered shell và client components cho phần tương tác.
- CSS Modules hoặc global semantic CSS variables; tránh phụ thuộc quá nhiều vào utility class khi cần visual system riêng.
- Zustand hoặc TanStack Query cho state/data fetching khi nối API thật.
- Recharts/Visx cho chart nhẹ, hoặc custom SVG cho gauge đơn giản.
- Lucide React cho icon.
- Vitest + Testing Library cho unit/component tests.
- Playwright cho visual smoke/responsive checks.

Nếu repo sau này đã có stack khác, ưu tiên bám stack hiện có.

## 9. API/Service Adapter đề xuất

Tạo service layer để frontend không phụ thuộc mock:

- getHardwareSnapshot()
- getResourceHistory(range)
- getRunningTasks()
- getHubProjects(filters)
- getHubProjectDetail(projectId)
- updateProjectConfig(projectId, patch)
- installProject(projectId)
- startProject(projectId)
- stopProject(projectId)
- deleteProject(projectId)
- streamProjectLogs(projectId, source)

MVP có thể dùng mock data + fake delay + EventSource/WebSocket mock cho logs.

## 10. Phase triển khai

### Phase 1: Product framing và design direction

Thời gian dự kiến: 0.5-1 ngày

Việc cần làm:

- Chốt user flow chính: Home -> Hub -> Detail -> Install/Run/Stop.
- Chốt taxonomy project type: LLM, Vision, Spark LLM, NVIDIA Blueprint, v.v.
- Chốt status model cho install/run/compatibility.
- Tạo moodboard nội bộ bằng token mô tả: dark graphite, smoked glass, subtle technical lines, tactile texture, amber/cyan contrast.
- Viết design constraints để tránh layout container/card đều đều.

Skill dùng:

- frontend-skill.
- documentation-skill.

Testing:

- Review checklist: đủ màn hình, đủ state, đủ action chính.

Documentation/Logging:

- Ghi quyết định IA và visual direction vào docs.
- Log lại các giả định đã chọn.

### Phase 2: Scaffold frontend project

Thời gian dự kiến: 0.5 ngày

Việc cần làm:

- Khởi tạo Next.js React TypeScript nếu chưa có frontend app.
- Cấu trúc thư mục theo frontend-skill và Next.js App Router: src/app, src/components, src/pages, src/services, src/utils, styles, tests, docs, logs.
- Cài Tailwind/CSS variables, lucide-react, test tools.
- Setup routing cho Home, Hub, Hub Detail.
- Setup lint/test scripts.

Skill dùng:

- frontend-skill.
- testing-skill.
- documentation-skill.
- logging-skill.

Testing:

- npm run build.
- npm run test nếu có test baseline.

Documentation/Logging:

- Ghi docs setup frontend.
- Log scaffold và dependency chính.

### Phase 3: Design tokens và theme system

Thời gian dự kiến: 0.5-1 ngày

Việc cần làm:

- Tạo semantic tokens: background, surface, surfaceElevated, text, textMuted, accent, success, warning, danger, border, focus.
- Dark-first palette, light palette tương ứng.
- Theme toggle, lưu localStorage, respect prefers-color-scheme.
- Motion tokens và reduced motion.
- Base typography, spacing, radius, shadow/elevation.

Skill dùng:

- frontend-skill.
- testing-skill.

Testing:

- Component test cho theme persistence.
- Contrast check thủ công/WCAG cho text chính và action.
- Visual smoke dark/light.

Documentation/Logging:

- Ghi bảng token vào docs/design-system.md.
- Log lý do chọn palette.

### Phase 4: Mock data và service layer

Thời gian dự kiến: 0.5-1 ngày

Việc cần làm:

- Tạo data model TypeScript cho HardwareSnapshot, RunningTask, HubProject, ProjectLog.
- Tạo mock projects đủ loại: LLM, Vision, Spark LLM, NVIDIA Blueprint.
- Tạo mock compatibility logic dựa trên RAM/VRAM/GPU/disk.
- Tạo fake logs và fake install/run state.
- Viết service adapter để sau này thay backend thật.

Skill dùng:

- frontend-skill.
- testing-skill.
- logging-skill.

Testing:

- Unit test compatibility calculation.
- Unit test service mock responses.

Documentation/Logging:

- Ghi API contract draft.
- Log các mock scenario.

### Phase 5: App shell và Home

Thời gian dự kiến: 1-1.5 ngày

Việc cần làm:

- Xây AppShell, navigation, command bar, theme toggle.
- Xây HardwareCockpit.
- Xây MetricGauge/ResourceSparkline.
- Xây RunningTaskRail.
- Xây RecentActivity.
- Responsive behavior cho desktop/tablet/mobile.

Skill dùng:

- frontend-skill.
- testing-skill.

Testing:

- Component tests cho render hardware/task states.
- Visual check desktop/mobile.
- Build check.

Documentation/Logging:

- Ghi docs Home components.
- Log trạng thái hoàn thành phase.

### Phase 6: Hub listing

Thời gian dự kiến: 1-1.5 ngày

Việc cần làm:

- Xây ProjectBentoGrid và ProjectCard.
- Xây filter/search/sort.
- Xây CompatibilityPing + tooltip reasons.
- Xây ProjectQuickEditDrawer cho chỉnh nhẹ.
- Xử lý empty/loading/error states.

Skill dùng:

- frontend-skill.
- testing-skill.

Testing:

- Test filter/search/sort.
- Test card state green/yellow/red.
- Visual responsive check.

Documentation/Logging:

- Ghi docs Hub UX.
- Log các edge case.

### Phase 7: Hub Detail

Thời gian dự kiến: 1.5-2 ngày

Việc cần làm:

- Xây ProjectDetailHeader.
- Xây RequirementFitMatrix.
- Xây BenchmarkPanel type-specific.
- Xây LogsTerminal với filter/search/copy/export.
- Xây ConfigEditor basic/advanced.
- Xây action flow Install/Run/Stop/Delete với loading/confirm/error.

Skill dùng:

- frontend-skill.
- testing-skill.
- documentation-skill.
- logging-skill.

Testing:

- Test action states.
- Test logs filter/search.
- Test benchmark render theo từng project type.
- Visual smoke detail page.

Documentation/Logging:

- Ghi docs detail page và action model.
- Log các scenario install/run/stop/delete.

### Phase 8: Polish, accessibility và modern feel

Thời gian dự kiến: 1 ngày

Việc cần làm:

- Thêm micro-interactions có kiểm soát.
- Tune spacing, rhythm, responsive typography.
- Kiểm tra text không overflow trong buttons/cards/panels.
- Kiểm tra contrast, focus states, keyboard navigation.
- Thêm reduced-motion handling.
- Tối ưu cảm giác "không container/block": section blending, inspector overlays, asymmetric rhythm.

Skill dùng:

- frontend-skill.
- testing-skill.

Testing:

- Keyboard-only pass.
- Reduced motion pass.
- Desktop/mobile screenshots.
- npm run build.

Documentation/Logging:

- Update design-system docs.
- Log các thay đổi polish.

### Phase 9: Final verification, docs, logs, push readiness

Thời gian dự kiến: 0.5-1 ngày

Việc cần làm:

- Chạy toàn bộ test/build/lint.
- Review code theo frontend-skill.
- Tổng kết docs.
- Tổng kết logs.
- Chuẩn bị push theo push-code-skill nếu người dùng yêu cầu push.

Skill dùng:

- testing-skill.
- documentation-skill.
- logging-skill.
- push-code-skill.

Testing:

- npm run build.
- npm run test.
- npm run lint nếu có.
- Visual smoke cuối cùng.

Documentation/Logging:

- docs/tasks/ai-hub-frontend.md.
- logs/tasks/ai-hub-frontend.md.

## 11. Ước lượng tổng

- MVP UI có mock data tốt: 6-9 ngày làm việc.
- Nếu cần backend API thật/realtime telemetry thật: cộng thêm 3-7 ngày tùy hệ thống.
- Nếu cần install/run/delete thật trên máy local qua agent/service: cộng thêm 5-10 ngày vì cần xử lý quyền, process, logs, rollback, bảo mật.

## 12. Rủi ro và cách giảm

- Telemetry phần cứng khác nhau theo Windows/Linux/NVIDIA/AMD: dùng adapter service, frontend không hardcode nguồn dữ liệu.
- Compatibility ping dễ sai nếu thiếu thông tin model/project: lưu reasons rõ ràng, cho user override profile.
- Logs realtime có thể rất dài: virtualize log list, filter theo level/source, giới hạn buffer.
- Delete project nguy hiểm: bắt buộc confirm, hiển thị path sẽ xóa, backend phải kiểm tra path an toàn.
- Dark UI dễ thiếu tương phản: dùng semantic tokens + contrast checklist.
- Thiết kế quá "trendy" có thể khó dùng: micro-interaction chỉ phục vụ feedback, data vẫn phải đọc nhanh.

## 13. Câu hỏi cần chốt trước khi code

- Frontend sẽ là app độc lập mới hay tích hợp vào repo/backend có sẵn?
- Stack mong muốn: React/Vite/TypeScript có ổn không?
- Danh sách GitHub project/provider ban đầu gồm những repo nào?
- Backend đã có API telemetry/install/logs chưa, hay cần mock trước?
- App chạy local-only hay có nhu cầu truy cập qua LAN/browser khác?
- Install/delete thật có cần xác nhận nhiều bước và giới hạn thư mục an toàn không?

## 14. Definition of Done

- Có Home, Hub, Hub Detail chạy được với mock data.
- Có dark/light theme, dark mode là trải nghiệm chính và đẹp.
- Project cards có compatibility ping xanh/vàng/đỏ kèm lý do.
- Detail có requirements, benchmark theo project type, logs, config, install/stop/delete states.
- Responsive không vỡ layout ở mobile/tablet/desktop.
- Build pass, tests chính pass.
- Docs và logs task được cập nhật theo skill.
