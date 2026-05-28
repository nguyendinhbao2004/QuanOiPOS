# Store Permission Access

## Mục tiêu
Tài liệu này mô tả contract frontend khi StoreUser truy cập một cửa hàng và app áp dụng permission-based access control theo store.

## API Contract
Khi user bấm `Truy cập` ở danh sách cửa hàng, app điều hướng theo `storeId` và load:
- `GET /stores/{id}` để lấy thông tin cửa hàng.
- `GET /permissions/store/{id}/me` để lấy permission của tài khoản hiện tại trong cửa hàng.

Nếu permission API trả `succeeded: false`, app xem đây là trạng thái không có quyền truy cập store và không render module vận hành.

## Permission Source of Truth
Permission code là application contract, không phải environment config.

Quy ước:
- Không đặt permission code trong `.env`.
- Tập trung permission code ở constants/mapping trong code để dễ sửa một nơi khi backend đổi code.
- UI đọc permission qua helper `can(code)` từ store access context, không tự parse response.

## UI Behavior
- User thiếu quyền vẫn có thể thấy một số menu/item ở trạng thái disabled để hiểu feature tồn tại.
- Hành động thiếu quyền không được trigger API.
- Backend vẫn là authority cuối cùng; frontend chỉ chặn sớm để UX rõ ràng hơn.

## Layering
- `workspace_context`: load store detail, permission list và expose store access context.
- `store_operations`: render store shell/overview theo context đã resolve.
- Widget không gọi Dio trực tiếp và không chứa business logic phân quyền.
