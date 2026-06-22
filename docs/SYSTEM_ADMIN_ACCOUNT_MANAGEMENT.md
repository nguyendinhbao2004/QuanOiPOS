# Đặc tả quản lý Account cho SystemAdmin

## 1. Mục tiêu và phạm vi

Tài liệu này mô tả màn hình **Quản lý account** cho SystemAdmin và hợp đồng API cần có để triển khai. Mục tiêu là cho phép SystemAdmin đi từ các thẻ thống kê account đến danh sách phù hợp, tra cứu chi tiết và khóa/mở khóa account một cách an toàn.

V1 chỉ bao gồm:

- Danh sách, tìm kiếm, lọc, sắp xếp, phân trang account.
- Xem chi tiết account và các cửa hàng/vai trò liên quan.
- Khóa (`Suspended`) và mở khóa (`Active`) account.
- Danh sách đăng ký đang chờ xác minh email.

Không thuộc phạm vi V1: tạo, sửa, xóa account; thay đổi role/cửa hàng; reset mật khẩu; gửi lại OTP; thao tác hàng loạt.

## 2. Quy ước dữ liệu hiện có

| Khái niệm | Giá trị/nguồn dữ liệu | Cách hiển thị |
| --- | --- | --- |
| Loại account | `AccountType.SystemAdmin`, `AccountType.StoreUser` | SystemAdmin, StoreUser |
| Trạng thái hoạt động | `AccountStatus.Active` | Đang hoạt động |
| Trạng thái không hoạt động | `AccountStatus.Inactive` | Không hoạt động |
| Trạng thái bị khóa | `AccountStatus.Suspended` | Đã khóa |
| Account hợp lệ | `Accounts.IsDeleted = false` | Được tính và hiển thị |
| Đăng ký chờ xác minh | `OtpVerification.Purpose = Register`, chưa `ConsumedAt`, chưa hết `ExpiresAt`, chưa vượt `MaxAttempts` | Chờ xác minh |

`Inactive` được giữ nguyên để lọc và xem theo domain hiện tại, nhưng V1 không tạo trạng thái này bằng thao tác quản trị. Nút **Khóa** luôn chuyển account sang `Suspended`; nút **Mở khóa** luôn chuyển sang `Active`.

Đăng ký chờ xác minh không phải là account: account chỉ được tạo sau khi OTP đăng ký được xác nhận. Vì vậy danh sách chờ xác minh phải tách khỏi `GET /accounts` và không được đưa vào tổng account.

## 3. Hành vi màn hình

### 3.1. Điều hướng từ màn hình Quản lý account

Mỗi thẻ là một điểm điều hướng. FE chuyển sang route danh sách và đặt query tương ứng; khi tải trang, FE gọi API bằng đúng query đó.

| Thẻ được bấm | Route/query đích | Nguồn số liệu |
| --- | --- | --- |
| Tổng account | `/system-admin/accounts` | Tất cả account chưa xóa |
| SystemAdmin | `/system-admin/accounts?accountType=SystemAdmin` | Account loại SystemAdmin |
| StoreUser | `/system-admin/accounts?accountType=StoreUser` | Account loại StoreUser |
| Đang hoạt động | `/system-admin/accounts?status=Active` | Account trạng thái Active |
| Đã khóa | `/system-admin/accounts?status=Suspended` | Account trạng thái Suspended |
| Chờ xác minh | `/system-admin/pending-registrations` | OTP Register còn có thể xác minh |

Sau khi khóa/mở khóa thành công, FE tải lại dòng chi tiết/danh sách hiện tại và các số liệu thẻ khi người dùng quay lại màn hình tổng quan. Nếu account không còn thỏa filter hiện tại (ví dụ khóa khi đang lọc `Active`), bỏ dòng đó khỏi danh sách và cập nhật tổng số kết quả.

### 3.2. Danh sách account

Màn danh sách có ô tìm kiếm, bộ lọc, bảng dữ liệu và phân trang phía server.

- Tìm kiếm không phân biệt hoa thường theo `id` (khi keyword là số), `fullName`, `email`, `phone`.
- Bộ lọc gồm loại account, trạng thái, khoảng ngày tạo và khoảng lần đăng nhập cuối.
- Cột bảng: ID, họ tên, email, số điện thoại, loại account, trạng thái, ngày tạo, lần đăng nhập cuối, thao tác.
- Mặc định sắp xếp `createdAt desc`; cho phép sắp xếp `id`, `fullName`, `email`, `createdAt`, `lastLogin`, `accountType`, `status`.
- Mặc định `pageIndex=1`, `pageSize=20`; `pageSize` nhận 10, 20, 50 hoặc 100.
- Trạng thái trống, không có kết quả và lỗi tải dữ liệu phải được hiển thị riêng. Không hiển thị password hash, refresh token hoặc OTP.

### 3.3. Chi tiết và thao tác trạng thái

Chọn một dòng mở `/system-admin/accounts/{id}`. Trang/side sheet chi tiết gồm thông tin account, trạng thái, ngày tạo, lần đăng nhập cuối và các liên kết cửa hàng.

Mỗi liên kết cửa hàng hiển thị: `storeId`, tên cửa hàng, trạng thái cửa hàng, địa chỉ, số điện thoại, `isOwner`, vai trò (nếu có), `StoreUser.IsActive`, ngày tham gia. Một account có thể có nhiều liên kết.

- Account `Active` hoặc `Inactive`: hiển thị nút **Khóa account**.
- Account `Suspended`: hiển thị nút **Mở khóa account**.
- Khóa yêu cầu modal xác nhận và lý do tùy chọn (tối đa 500 ký tự). Cảnh báo rõ: account bị đăng xuất ở lần refresh token tiếp theo và không thể đăng nhập lại.
- Không hiển thị nút đổi trạng thái với account của SystemAdmin đang đăng nhập. Backend vẫn phải kiểm tra lại điều kiện này, không chỉ dựa UI.

## 4. Hợp đồng API

Tất cả endpoint nằm dưới `/api/system-admin`, yêu cầu `Authorization: Bearer <access-token>` và chỉ cho claim `AccountType = SystemAdmin`. Không có token hợp lệ trả `401`; account không phải SystemAdmin trả `403`. Tất cả thời điểm là UTC ISO-8601. Mọi response, bao gồm detail và đổi trạng thái, luôn theo wrapper:

```json
{
  "succeeded": true,
  "message": "",
  "errors": [],
  "data": {}
}
```

Các API danh sách đặt dữ liệu phân trang hoàn toàn trong `data`, để tương thích trực tiếp với `ApiResponse` của Flutter. Không dùng `meta` ngoài `data`.

### 4.1. Summary account

`GET /api/system-admin/accounts/summary`

API này trả toàn bộ số liệu trong cùng một lần gọi để FE render màn tổng quan; không cần gọi nhiều list API để lấy `totalItems`. `pendingRegistrationCount` dùng đúng điều kiện của endpoint pending-registration và không nằm trong `totalAccounts`.

```json
{
  "succeeded": true,
  "message": "",
  "errors": [],
  "data": {
    "totalAccounts": 1248,
    "systemAdminAccounts": 8,
    "storeUserAccounts": 1240,
    "activeAccounts": 1186,
    "suspendedAccounts": 18,
    "pendingRegistrationCount": 44
  }
}
```

### 4.2. Danh sách account

`GET /api/system-admin/accounts`

| Query | Kiểu/giá trị | Mặc định | Quy tắc |
| --- | --- | --- | --- |
| `keyword` | string | rỗng | Tối đa 100 ký tự; tìm theo ID/tên/email/số điện thoại. |
| `accountType` | `SystemAdmin` \| `StoreUser` | tất cả | Enum không phân biệt hoa thường. |
| `status` | `Active` \| `Inactive` \| `Suspended` | tất cả | Enum không phân biệt hoa thường. |
| `createdFrom`, `createdTo` | `YYYY-MM-DD` | rỗng | Lọc `CreatedAt`; `to` gồm hết ngày UTC. `from <= to`. |
| `lastLoginFrom`, `lastLoginTo` | `YYYY-MM-DD` | rỗng | Lọc `LastLogin`; account `LastLogin = null` không thuộc khoảng này. `from <= to`. |
| `sortBy` | `id`, `fullName`, `email`, `createdAt`, `lastLogin`, `accountType`, `status` | `createdAt` | Chỉ chấp nhận các giá trị này. |
| `sortDirection` | `asc` \| `desc` | `desc` | Không phân biệt hoa thường. |
| `pageIndex` | integer | 1 | Phải >= 1. |
| `pageSize` | 10 \| 20 \| 50 \| 100 | 20 | Giá trị khác trả `400`. |

`IsDeleted = true` luôn bị loại trừ, bất kể query.

Ví dụ:

```http
GET /api/system-admin/accounts?keyword=nguyen&accountType=StoreUser&status=Active&sortBy=lastLogin&sortDirection=desc&pageIndex=1&pageSize=20
```

```json
{
  "succeeded": true,
  "message": "",
  "errors": [],
  "data": {
    "items": [
      {
      "id": 123,
      "fullName": "Nguyễn Văn A",
      "email": "a@example.com",
      "phone": "0901234567",
      "accountType": "StoreUser",
      "status": "Active",
      "createdAt": "2026-06-01T08:30:00Z",
      "lastLogin": "2026-06-21T04:10:00Z"
      }
    ],
    "pagination": {
      "pageIndex": 1,
      "pageSize": 20,
      "totalPages": 4,
      "totalItems": 64
    }
  }
}
```

### 4.3. Chi tiết account

`GET /api/system-admin/accounts/{id}`

Account soft-delete hoặc không tồn tại trả `404`. Response:

```json
{
  "succeeded": true,
  "message": "",
  "errors": [],
  "data": {
  "id": 123,
  "fullName": "Nguyễn Văn A",
  "email": "a@example.com",
  "phone": "0901234567",
  "accountType": "StoreUser",
  "status": "Active",
  "createdAt": "2026-06-01T08:30:00Z",
  "updatedAt": "2026-06-10T03:15:00Z",
  "lastLogin": "2026-06-21T04:10:00Z",
  "storeMemberships": [
    {
      "storeId": 15,
      "storeName": "Quán Ơi - Quận 1",
      "storeStatus": "Active",
      "address": "123 Đường Lê Lợi, Q.1, TP.HCM",
      "phone": "0912345678",
      "isOwner": true,
      "roleId": 1,
      "roleName": "Owner",
      "isActive": true,
      "joinedAt": "2026-06-01T08:30:00Z"
    }
  ]
  }
}
```

### 4.4. Khóa/mở khóa account

`PATCH /api/system-admin/accounts/{id}/status`

```json
{ "status": "Suspended", "reason": "Vi phạm điều khoản sử dụng" }
```

| Field | Quy tắc |
| --- | --- |
| `status` | Bắt buộc, chỉ `Active` hoặc `Suspended`. `Inactive` trả `400`. |
| `reason` | Tùy chọn, trim, tối đa 500 ký tự. |

Xử lý nghiệp vụ trong cùng transaction:

1. Xác thực người gọi là SystemAdmin và lấy `currentAccountId` từ JWT.
2. Tìm account chưa soft-delete; không có trả `404`.
3. Nếu `id == currentAccountId`, trả `400`; không cho tự khóa/mở khóa.
4. Nếu trạng thái đích đã là trạng thái hiện tại, trả `400` để FE không hiểu nhầm thao tác đã thực hiện.
5. `Suspended` gọi `Account.Suspend()` và thu hồi toàn bộ refresh token chưa thu hồi của account. `Active` gọi `Account.Activate()`; không khôi phục refresh token cũ.
6. Ghi audit trạng thái cũ/mới, lý do, người thực hiện, IP, user-agent; commit transaction.

Response thành công:

```json
{
  "succeeded": true,
  "message": "",
  "errors": [],
  "data": {
    "id": 123,
    "status": "Suspended",
    "updatedAt": "2026-06-22T03:00:00Z"
  }
}
```

Mã lỗi: `400` (body/query/trạng thái không hợp lệ, tự thao tác hoặc trạng thái không đổi), `401`, `403`, `404` và `500` cho lỗi không dự kiến.

### 4.5. Đăng ký chờ xác minh

`GET /api/system-admin/pending-registrations`

| Query | Mặc định | Quy tắc |
| --- | --- | --- |
| `keyword` | rỗng | Tìm email; tối đa 100 ký tự. |
| `sortBy` | `createdAt` | Chỉ `email`, `createdAt`, `expiresAt`. |
| `sortDirection` | `desc` | `asc` hoặc `desc`. |
| `pageIndex` | 1 | >= 1. |
| `pageSize` | 20 | 10, 20, 50 hoặc 100. |

Điều kiện nguồn: `Purpose = Register`, `ConsumedAt = null`, `ExpiresAt > now UTC`, `AttemptCount < MaxAttempts`. Không trả `otpCodeHash`, `payloadJson`, mật khẩu hash hoặc mã OTP. Nếu có nhiều OTP hợp lệ cho cùng email, chỉ trả bản ghi mới nhất theo `CreatedAt` để không đếm và hiển thị trùng người đăng ký.

Mỗi dòng trả: `email`, `fullName` (đọc an toàn từ payload đăng ký), `createdAt`, `expiresAt`, `attemptCount`, `maxAttempts`. Response dùng cùng format list account: `data.items` và `data.pagination` với `pageIndex`, `pageSize`, `totalItems`, `totalPages`.

## 5. Phân quyền, audit và khoảng trống hiện tại

- Controller phải dùng `[Authorize]` cùng policy/filter kiểm tra `AccountType.SystemAdmin`; không chỉ tin route prefix.
- Không đưa các trường bí mật vào DTO hay log HTTP: `PasswordHash`, `RefreshToken.Token`, `OtpCodeHash`, `OtpVerification.PayloadJson`.
- `AuditLog` hiện bắt buộc `StoreId > 0`, trong khi thao tác này là cấp nền tảng, không gắn cửa hàng. Trước khi triển khai API đổi trạng thái cần mở rộng audit để cho phép system-level event (ví dụ `StoreId` nullable), hoặc tạo bảng audit dành cho SystemAdmin. Audit phải giữ actor account, entity `Account`, target account ID, old/new status, reason, IP, user-agent và UTC timestamp.
- `OtpVerificationRepository` hiện lưu OTP trong bộ nhớ tĩnh; endpoint pending-registration chỉ có dữ liệu ổn định khi OTP được lưu/persist theo cơ chế repository dùng chung. Tài liệu này yêu cầu endpoint truy vấn cùng nguồn OTP đang phục vụ flow đăng ký; nếu vẫn in-memory thì dữ liệu sẽ mất khi restart và không phù hợp để làm số liệu quản trị.

## 6. Tiêu chí nghiệm thu và kiểm thử

| Nhóm | Kịch bản bắt buộc |
| --- | --- |
| Điều hướng | Mỗi thẻ mở đúng route/query; số dòng tổng của list khớp số liệu thẻ cùng điều kiện. |
| List | Keyword tìm theo ID/tên/email/số điện thoại; kết hợp filter, sort, phân trang; account soft-delete không xuất hiện. |
| Validation | Enum, ngày, thứ tự ngày, sort, page index/page size sai trả `400`. |
| Detail | Account không có store, có một store và có nhiều store/role đều trả đúng; không lộ dữ liệu bí mật. |
| Status | Khóa account Active/Inactive thành Suspended, thu hồi refresh token; account không thể đăng nhập hoặc refresh token. Mở khóa thành Active nhưng refresh token cũ vẫn không dùng được. |
| Bảo mật | Từ chối `401`, `403`, self-action, ID không tồn tại/soft-delete và trạng thái đích không đổi. |
| Summary | Một request trả đúng total/SystemAdmin/StoreUser/Active/Suspended/pending; pending không cộng vào total account. |
| Response format | Cả hai list trả `data.items` + `data.pagination`; detail và đổi trạng thái trả payload trong `data`. |
| Audit | Có bản ghi audit đúng actor, target, cũ/mới, lý do, IP/user-agent; thay đổi status và revoke token atomic. |
| Pending | Chỉ hiển thị Register OTP còn hiệu lực/chưa dùng/chưa vượt lần thử; không trùng email; biến mất khi xác minh hoặc hết hạn. |

## 7. Ghi chú triển khai

Không dùng danh sách account để suy luận đăng ký chờ xác minh. Màn hình và API pending-registration phải được triển khai sau khi quyết định cơ chế lưu OTP bền vững. Mọi thời gian lọc theo ngày được chuẩn hóa UTC: `from` tính từ `00:00:00.0000000Z`, `to` tính đến `23:59:59.9999999Z`.
