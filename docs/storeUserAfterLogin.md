# StoreUser After-Login Account Hub (Pre-Store Selection)

## 1. Mục tiêu
Tài liệu này mô tả màn hình mặc định sau khi `StoreUser` đăng nhập thành công nhưng chưa chọn store làm việc.

Mục tiêu của phase:
- Hiển thị `system shell` với tab `Tài khoản` active mặc định.
- Cung cấp entrypoint sang các chức năng account (gói dịch vụ, cửa hàng, bảo mật, cài đặt).
- Chưa triển khai business flow chi tiết bên trong từng chức năng.

## 2. Route Contract (Doc-level)
Flow điều hướng ở mức tài liệu:
1. `StoreUser login success`
2. Route vào `SystemShell(AccountTab.account)`
3. User chọn menu trong Account Hub:
   - `Cửa hàng` -> đi vào flow `store picker/workspace resolution`
   - Mục còn lại -> placeholder/coming soon trong phase hiện tại

Nguyên tắc:
- Account Hub là điểm vào mặc định trước khi user chọn `activeStore`.
- Không điều hướng trực tiếp vào module vận hành store từ shell này.

## 3. Bottom Nav Contract (Phase hiện tại)
- Hiển thị đủ các tab trong shell.
- Tab `Tài khoản` active mặc định.
- Các tab khác ở trạng thái stub:
  - hiển thị UI bình thường
  - chưa mở feature thật
  - tap sẽ hiện coming-soon behavior

## 4. Thành phần UI chính
Account Hub gồm các khối:
- Top header: branding + greeting + notification icon.
- User profile card: avatar + tên + email + affordance điều hướng.
- Account menu section:
  - `Gói dịch vụ của tôi`
  - `Cửa hàng`
  - `Bảo mật`
  - `Cài đặt ứng dụng`
- Logout CTA.
- Bottom navigation thuộc `SystemShell`.

## 5. Data State tối thiểu
Ở phase này, Account Hub cần tối thiểu 3 trạng thái:
- `loading`: đang load profile/account summary.
- `ready`: hiển thị đầy đủ profile + menu.
- `error`: hiển thị lỗi có thể retry.

Ghi chú:
- Không yêu cầu state machine chi tiết theo từng menu feature ở phase này.

## 6. Widget Decomposition (Doc-level)
### 6.1 Shared shell/widget contracts
- `SystemShellScaffold(currentTab, onTabSelected, body)`
- `BottomNavStubItem(title, icon, isActive, onTap, isEnabled)`

### 6.2 Account Hub widgets
- `AccountHubHeader`
- `UserProfileCard`
- `AccountMenuSection`
- `AccountMenuItem(title, leadingIcon, trailingMeta?, onTap, enabled)`
- `LogoutActionButton`

Nguyên tắc tách:
- UI widget không chứa business logic phân quyền/store resolution.
- Tương tác điều hướng gọi qua callback/provider layer.

## 7. Ranh giới logic phase này
### Trong scope
- Render `StoreUser system shell` + Account tab mặc định.
- Điều hướng từ menu `Cửa hàng` sang flow workspace đã định nghĩa tại tài liệu workspace.
- Hiển thị placeholder cho menu/tabs chưa triển khai.

### Ngoài scope
- Xây dựng logic chi tiết cho quảng cáo/tin tức/gói/bảo mật/cài đặt.
- Triển khai module vận hành theo role.
- Thiết kế API mới.

## 8. Kiểm tra tính sẵn sàng tài liệu
- Thuật ngữ thống nhất với các tài liệu liên quan:
  - `system shell`
  - `account hub`
  - `store picker/workspace resolution`
- Không mâu thuẫn với:
  - `docs/spec.md`
  - `docs/storeUser.md`
  - `docs/clean-architecture-riverpod.md`
  - `docs/ui-build-rules.md`

## 9. UI Reference
Mock HTML trong bản nháp trước dùng làm visual reference cho:
- Layout tổng thể account hub.
- Tông trình bày header/profile/menu/logout/bottom nav.

Không dùng mock làm source of truth cho:
- Route guard
- State architecture
- Domain/Data contracts
