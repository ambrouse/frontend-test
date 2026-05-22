# Frontend Testing Raw

## Unit và integration

- Test component qua hành vi người dùng, không test state nội bộ hoặc implementation detail.
- Hook/state manager test rule chuyển trạng thái, async lifecycle, cleanup và race condition quan trọng.
- API client test request shape, auth header, error mapping, retry/backoff nếu có.
- Không mock toàn bộ component tree nếu interaction giữa các component là phần cần kiểm chứng.

## State và async

- Kiểm tra trạng thái trước, trong và sau async action.
- Test hủy request/unmount nếu code có cleanup hoặc abort controller.
- Kiểm tra race: request cũ không ghi đè request mới khi có khả năng xảy ra.
- Fake timer chỉ dùng khi cần; luôn cleanup timer/mock sau test.

## Accessibility trong test frontend

- Query theo role/name để buộc component có semantics đúng.
- Form control phải có label hoặc accessible name.
- Dialog/menu/popover phải kiểm focus open/close nếu component có behavior đó.

## Anti-pattern

- Không assert CSS class trừ khi class là contract công khai hoặc utility quan trọng.
- Không snapshot markup lớn thay cho assertion hành vi.
- Không mock router/store/API tùy tiện nếu integration thật rẻ và đáng tin hơn.
