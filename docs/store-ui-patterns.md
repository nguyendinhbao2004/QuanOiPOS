# Store UI Patterns

## Mục tiêu
Tài liệu này mô tả các UI pattern cần tái sử dụng khi xây store workspace/module cho QuanOi POS.

## Reusable Widgets
- `StoreWorkspaceHeader`: header trong workspace store, hiển thị active store và mở switch-store bottom sheet khi bấm vào vùng store.
- `StoreSwitcherBottomSheet`: bottom sheet chuyển cửa hàng, dùng danh sách store hiện có và không tự gọi network trực tiếp.
- `StoreBottomSheetPanel`: frame bottom sheet chuẩn gồm handle, title, close action và content slot.
- `StoreSwitchListTile`: item cửa hàng trong bottom sheet, có active/disabled state.
- `StoreBottomNavigationBar` và `StoreBottomNavItem`: bottom nav trong store workspace.

## Rules
- Không đặt nút back trong store workspace header; đổi store bằng cách bấm vùng active store.
- Khi user chọn store khác, route đổi sang `/stores/:storeId` để provider theo `storeId` fetch lại store detail và permissions.
- Không hiển thị role label nếu API/entity hiện tại chưa trả role rõ ràng.
- Widget chỉ nhận dữ liệu/callback từ page/provider; không gọi Dio trực tiếp trong UI widget.
- Ưu tiên dùng `AppColors`, `AppTextStyles`, `AppConstants`, `AppTheme` thay vì hardcode style.
