# StoreUser Workspace Flow (Post-login)

## 1. Problem Statement
Sau khi `StoreUser` đăng nhập thành công, app chưa thể vào ngay module làm việc nếu chưa xác định:
- Người dùng đang làm ở store nào (`activeStore`).
- Role hiện hành trong store đó (`activeRole`).

Vì một `StoreUser` có thể thuộc nhiều store với role khác nhau, cần có bước chọn workspace/store và resolve role trước khi render app shell theo role.

## 2. Official Role Set
Role chuẩn trong scope hiện tại:
- `Owner`
- `Manager`
- `Staff`
- `Kitchen`

Lưu ý:
- `Cashier` chỉ là ví dụ nghiệp vụ phát sinh trong trao đổi, chưa thuộc role set chính thức của spec hiện tại.

## 3. User Journey Sau Login
### 3.1 High-level flow
1. User login thành công.
2. Resolve `accountType`.
3. Nếu `SystemAdmin` -> vào workspace SystemAdmin.
4. Nếu `StoreUser` -> load danh sách `StoreMembership`.
5. App xử lý rule chọn store:
   - Không có store: vào trạng thái empty + hướng dẫn liên hệ quản trị.
   - Có 1 store: auto-select store đó (theo default rule).
   - Có nhiều store: hiển thị `Store Picker` để user chọn.
6. Resolve role theo store đã chọn.
7. Load app shell/module theo role tương ứng.

### 3.2 Switching flow
1. Từ app shell, user bấm đổi store.
2. Hiển thị danh sách store được phép truy cập.
3. User chọn store mới.
4. App cập nhật `activeStore` + `activeRole`.
5. Guard và module được refresh theo context mới.

## 4. Workspace Selection Rules
- Rule-01: `StoreUser` bắt buộc có `activeStore` trước khi vào module vận hành.
- Rule-02: Mỗi `StoreMembership` có đúng 1 role active trong từng store.
- Rule-03: Role giữa các store độc lập, không đồng bộ chéo.
- Rule-04: Đổi store không yêu cầu đăng nhập lại trong điều kiện bình thường.
- Rule-05: Nếu chưa resolve xong role/context thì không render module role-home.

## 5. Role-based Landing Behavior
Sau khi có `activeStore` + `activeRole`, app route đến role-home tương ứng:
- `Owner` -> owner workspace shell
- `Manager` -> manager workspace shell
- `Staff` -> staff workspace shell
- `Kitchen` -> kitchen workspace shell

Ghi chú:
- Capability chi tiết theo endpoint/module sẽ do backend contract quyết định.
- Frontend chỉ enforce điều hướng và visibility theo context đã resolve.

## 6. Required Screens (MVP Documentation)
### 6.1 Account Hub (sau login của StoreUser)
- Hiển thị thông tin account + trạng thái gói + shortcut chức năng account.
- Có entry rõ ràng để vào chọn store/workspace.

### 6.2 Store Picker
- Danh sách store user có membership.
- Có search/filter cơ bản nếu danh sách dài.
- Hiển thị role tương ứng của user trong từng store.
- Có trạng thái `loading`, `empty`, `error`.

### 6.3 Role Home (theo active role)
- App shell/module theo role.
- Header luôn hiển thị `activeStore` và `activeRole`.
- Có hành động đổi store ở vị trí nhất quán.

## 7. UI Reference (Mock Summary)
Mock HTML trước đó được dùng làm tham chiếu hình dung bố cục:
- Màn account hub cho StoreUser.
- Màn dashboard sau khi vào store với role quản lý/chủ quán.

Giới hạn của mock:
- Không phải source of truth cho architecture, state, route guard.
- Không bắt buộc map 1-1 từng thành phần visual khi implement Flutter.

## 8. Out of Scope (Tài liệu này)
- Capability matrix chi tiết đến endpoint/action.
- Thiết kế API backend mới.
- Luồng phân quyền nâng cao ngoài role set hiện tại.
