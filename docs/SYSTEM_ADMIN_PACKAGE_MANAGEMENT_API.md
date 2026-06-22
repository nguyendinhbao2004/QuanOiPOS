# Frontend integration — Quản lý gói dịch vụ (System Admin)

Tài liệu này mô tả **API đã triển khai** cho màn hình Quản lý gói của System Admin. Frontend chỉ dùng các endpoint dưới `/api/system-admin/subscription-plans`; không dùng các API cũ `/api/subscription-plans` cho màn hình admin.

## 1. Xác thực và format response

Base URL:

```text
/api/system-admin/subscription-plans
```

Mọi request phải gửi access token:

```http
Authorization: Bearer <access-token>
```

Chỉ tài khoản `SystemAdmin` được gọi API. Frontend xử lý lỗi chung như sau:

| HTTP status | Ý nghĩa | Xử lý FE gợi ý |
| --- | --- | --- |
| `200` | Đọc/thay đổi trạng thái/xóa thành công | Cập nhật UI hoặc tải lại dữ liệu liên quan. |
| `201` | Tạo gói thành công | Đóng form, thông báo thành công, tải lại summary và danh sách. |
| `400` | Query/body không hợp lệ, tên trùng, hoặc gói đã có subscription nên không thể xóa | Hiển thị `errors[0]`. |
| `401` | Thiếu, hết hạn hoặc token không hợp lệ | Chuyển về luồng đăng nhập. |
| `403` | Tài khoản không phải SystemAdmin | Chặn truy cập màn hình/quay về trang phù hợp. |
| `404` | Gói không tồn tại | Đóng trang chi tiết/form và tải lại danh sách. |

Tất cả response dùng wrapper dưới đây. Với Axios, payload nghiệp vụ là `response.data.data`.

```json
{
  "succeeded": true,
  "message": "",
  "data": {},
  "errors": []
}
```

Ví dụ lỗi:

```json
{
  "succeeded": false,
  "message": null,
  "data": null,
  "errors": [
    "Không thể xóa gói đã có subscription. Hãy ngừng bán gói này thay vì xóa."
  ]
}
```

## 2. Flow tích hợp màn hình

### 2.1. Trang tổng quan quản lý gói

Khi mở trang, gọi song song:

```http
GET /api/system-admin/subscription-plans/summary
GET /api/system-admin/dashboard/overview?from=2026-06-01&to=2026-06-30&groupBy=day
```

- `summary.data.totalPlans` hiển thị ở thẻ **Tổng số gói**.
- `summary.data.activePlans` hiển thị ở thẻ **Gói đang bán**.
- `summary.data.inactivePlans` dùng cho chú thích “x gói đang tạm ẩn”.
- `summary.data.planUsage` render panel **Tình trạng gói dịch vụ**: mỗi item là một gói đang bán và số cửa hàng đang dùng gói đó. Không hard-code Trial/Basic/Pro; hiển thị động theo `planName`.
- `overview.data.metrics.subscriptionRevenue` là **Doanh thu gói** tháng hiện tại. API overview thuộc dashboard; xem thêm `SYSTEM_ADMIN_DASHBOARD_API.md` nếu cần chi tiết filter/thời gian.

Ví dụ response `summary`:

```json
{
  "succeeded": true,
  "message": "",
  "data": {
    "totalPlans": 6,
    "activePlans": 4,
    "inactivePlans": 2,
    "planUsage": [
      {
        "planId": 1,
        "planName": "Trial",
        "activeStoreCount": 126
      },
      {
        "planId": 2,
        "planName": "Basic",
        "activeStoreCount": 214
      },
      {
        "planId": 3,
        "planName": "Pro",
        "activeStoreCount": 98
      }
    ]
  },
  "errors": []
}
```

### 2.2. Điều hướng từ thẻ sang danh sách

| Người dùng nhấn | Điều hướng FE | API cần gọi |
| --- | --- | --- |
| **Tổng số gói** | Mở màn danh sách với filter `all` | `GET /api/system-admin/subscription-plans?status=all&pageIndex=1&pageSize=10` |
| **Gói đang bán** | Mở màn danh sách với filter `active` | `GET /api/system-admin/subscription-plans?status=active&pageIndex=1&pageSize=10` |
| Tab/bộ lọc **Tạm ẩn** | Đổi filter sang `inactive`, reset trang về 1 | `GET /api/system-admin/subscription-plans?status=inactive&pageIndex=1&pageSize=10` |

Sau thao tác tạo/sửa/bật/tạm ẩn/xóa, hãy gọi lại cả `summary` và request danh sách hiện tại để số thẻ, row và phân trang luôn đồng bộ.

## 3. Danh sách gói

```http
GET /api/system-admin/subscription-plans?status=all&pageIndex=1&pageSize=10
```

### Query parameters

| Tên | Kiểu | Bắt buộc | Mặc định | Giá trị hợp lệ |
| --- | --- | --- | --- | --- |
| `status` | string | Không | `all` | `all`, `active`, `inactive`; không phân biệt hoa thường. |
| `pageIndex` | number | Không | `1` | Số nguyên >= 1. |
| `pageSize` | number | Không | `10` | Số nguyên từ 1 đến 100. |

Backend luôn loại gói đã xóa, sắp xếp theo `price` tăng dần rồi `id` tăng dần. Không có search/sort parameter ở phiên bản hiện tại.

Response mẫu:

```json
{
  "succeeded": true,
  "message": "",
  "data": {
    "items": [
      {
        "id": 2,
        "name": "Basic",
        "price": 199000,
        "durationDays": 30,
        "maxStores": 1,
        "maxUsers": 5,
        "features": "[\"Báo cáo cơ bản\"]",
        "isActive": true,
        "createdAt": "2026-06-01T00:00:00Z",
        "updatedAt": null
      }
    ],
    "pagination": {
      "pageIndex": 1,
      "pageSize": 10,
      "totalItems": 4,
      "totalPages": 1
    }
  },
  "errors": []
}
```

### Kiểu dữ liệu FE đề xuất

```ts
type PlanStatus = 'all' | 'active' | 'inactive';

interface SubscriptionPlan {
  id: number;
  name: string;
  price: number;
  durationDays: number;
  maxStores: number;
  maxUsers: number;
  features: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string | null;
}

interface Pagination {
  pageIndex: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
}

interface PlanUsage {
  planId: number;
  planName: string;
  activeStoreCount: number;
}

interface PlanSummary {
  totalPlans: number;
  activePlans: number;
  inactivePlans: number;
  planUsage: PlanUsage[];
}
```

`features` hiện là chuỗi JSON (ví dụ `"[\"Báo cáo cơ bản\"]"`), không phải mảng JSON trả trực tiếp. FE có thể `JSON.parse(features)` khi cần hiển thị từng tính năng; nếu parse thất bại thì hiển thị nguyên chuỗi hoặc fallback rỗng.

## 4. Xem chi tiết và form tạo/sửa

### Lấy chi tiết

```http
GET /api/system-admin/subscription-plans/{id}
```

Response `data` có cùng kiểu `SubscriptionPlan` ở danh sách. API này chỉ trả cấu hình gói; **không** trả subscription, payment hay dữ liệu người mua.

FE gọi API này khi mở màn hình/form sửa để lấy dữ liệu mới nhất. Nếu nhận `404`, hiển thị thông báo “Gói không còn tồn tại” và quay về danh sách.

### Tạo gói

```http
POST /api/system-admin/subscription-plans
Content-Type: application/json
```

### Cập nhật gói

```http
PUT /api/system-admin/subscription-plans/{id}
Content-Type: application/json
```

Hai API dùng cùng body; `isActive` phải được gửi từ giá trị switch trên form.

```json
{
  "name": "Pro",
  "price": 399000,
  "durationDays": 30,
  "maxStores": 3,
  "maxUsers": 15,
  "features": "[\"Báo cáo nâng cao\", \"Xuất dữ liệu\"]",
  "isActive": true
}
```

| Field | Kiểu | Ràng buộc backend |
| --- | --- | --- |
| `name` | string | Không rỗng; không được trùng tên gói chưa xóa. |
| `price` | number | >= 0; đơn vị VND. |
| `durationDays` | number | Số nguyên > 0. |
| `maxStores` | number | Số nguyên > 0. |
| `maxUsers` | number | Số nguyên > 0. |
| `features` | string/null | Tùy chọn; FE gửi chuỗi JSON nếu có danh sách tính năng. |
| `isActive` | boolean | `true` là bán ngay, `false` là tạo/cập nhật ở trạng thái tạm ẩn. |

Tạo thành công trả `201`; cập nhật thành công trả `200`. Cả hai đều trả `data` là `SubscriptionPlan` mới nhất.

## 5. Bật bán, tạm ẩn và xóa

### Bật bán

```http
PATCH /api/system-admin/subscription-plans/{id}/activate
```

### Tạm ẩn

```http
PATCH /api/system-admin/subscription-plans/{id}/deactivate
```

Hai request không có body. Thành công trả:

```json
{
  "succeeded": true,
  "message": "Kích hoạt gói subscription thành công.",
  "errors": []
}
```

Hoặc khi tạm ẩn:

```json
{
  "succeeded": true,
  "message": "Ngừng bán gói subscription thành công.",
  "errors": []
}
```

Sau khi tạm ẩn, gói vẫn xuất hiện trong danh sách admin với `status=inactive`, nhưng không còn xuất hiện trong API công khai `GET /api/subscription-plans/active`. Subscription hiện hữu không bị thay đổi.

### Xóa

```http
DELETE /api/system-admin/subscription-plans/{id}
```

Không có request body. Chỉ xóa được gói chưa từng có subscription. Nếu API trả `400`, FE không retry; hiển thị `errors[0]` và gợi ý admin dùng thao tác **Tạm ẩn**.

Sau khi xóa thành công, tải lại summary và trang danh sách hiện tại. Nếu xóa item cuối của một trang, FE nên chuyển về `pageIndex = max(1, totalPages mới)` rồi gọi lại danh sách.

## 6. API reference đầy đủ

### 6.1. Lấy số liệu thẻ gói

```http
GET /api/system-admin/subscription-plans/summary
Authorization: Bearer <access-token>
```

Không có query parameter và không có request body.

`200 OK`

```json
{
  "succeeded": true,
  "message": "",
  "data": {
    "totalPlans": 6,
    "activePlans": 4,
    "inactivePlans": 2,
    "planUsage": [
      {
        "planId": 1,
        "planName": "Trial",
        "activeStoreCount": 126
      },
      {
        "planId": 2,
        "planName": "Basic",
        "activeStoreCount": 214
      },
      {
        "planId": 3,
        "planName": "Pro",
        "activeStoreCount": 98
      }
    ]
  },
  "errors": []
}
```

| Field trong `data` | Kiểu | Mô tả |
| --- | --- | --- |
| `totalPlans` | number | Tổng gói chưa bị xóa. |
| `activePlans` | number | Gói đang bán (`isActive=true`). |
| `inactivePlans` | number | Gói tạm ẩn (`isActive=false`). |
| `planUsage` | array | Danh sách toàn bộ gói đang bán, sắp xếp theo giá rồi id. |

Mỗi item trong `planUsage`:

| Field | Kiểu | Mô tả |
| --- | --- | --- |
| `planId` | number | ID gói; dùng làm key khi render list. |
| `planName` | string | Tên gói hiển thị, ví dụ `Trial`, `Basic`, `Pro`. |
| `activeStoreCount` | number | Số **cửa hàng chưa xóa** của chủ tài khoản có subscription của gói này đang `Active` và `endDate` còn hiệu lực tại thời điểm gọi API. Một cửa hàng chỉ được đếm một lần cho một gói. |

Frontend render panel theo `planUsage`; hàng **Tạm ẩn** dùng `inactivePlans` và đơn vị hiển thị là `gói`, không phải `cửa hàng`.

### 6.2. Lấy danh sách gói có phân trang

```http
GET /api/system-admin/subscription-plans?status=active&pageIndex=1&pageSize=10
Authorization: Bearer <access-token>
```

Request chỉ dùng query parameter, không có request body.

`200 OK`

```json
{
  "succeeded": true,
  "message": "",
  "data": {
    "items": [
      {
        "id": 2,
        "name": "Basic",
        "price": 199000,
        "durationDays": 30,
        "maxStores": 1,
        "maxUsers": 5,
        "features": "[\"Báo cáo cơ bản\"]",
        "isActive": true,
        "createdAt": "2026-06-01T00:00:00Z",
        "updatedAt": null
      }
    ],
    "pagination": {
      "pageIndex": 1,
      "pageSize": 10,
      "totalItems": 4,
      "totalPages": 1
    }
  },
  "errors": []
}
```

`400 Bad Request` khi filter không hợp lệ:

```json
{
  "succeeded": false,
  "message": null,
  "data": null,
  "errors": ["status chỉ hỗ trợ all, active hoặc inactive."]
}
```

### 6.3. Lấy chi tiết một gói

```http
GET /api/system-admin/subscription-plans/2
Authorization: Bearer <access-token>
```

Không có query parameter và không có request body.

`200 OK`

```json
{
  "succeeded": true,
  "message": "",
  "data": {
    "id": 2,
    "name": "Basic",
    "price": 199000,
    "durationDays": 30,
    "maxStores": 1,
    "maxUsers": 5,
    "features": "[\"Báo cáo cơ bản\"]",
    "isActive": true,
    "createdAt": "2026-06-01T00:00:00Z",
    "updatedAt": "2026-06-05T04:30:00Z"
  },
  "errors": []
}
```

`404 Not Found`

```json
{
  "succeeded": false,
  "message": null,
  "data": null,
  "errors": ["Gói subscription không tồn tại."]
}
```

### 6.4. Tạo gói

```http
POST /api/system-admin/subscription-plans
Authorization: Bearer <access-token>
Content-Type: application/json
```

Request body:

```json
{
  "name": "Pro",
  "price": 399000,
  "durationDays": 30,
  "maxStores": 3,
  "maxUsers": 15,
  "features": "[\"Báo cáo nâng cao\", \"Xuất dữ liệu\"]",
  "isActive": true
}
```

`201 Created`

```json
{
  "succeeded": true,
  "message": "Tạo gói subscription thành công.",
  "data": {
    "id": 3,
    "name": "Pro",
    "price": 399000,
    "durationDays": 30,
    "maxStores": 3,
    "maxUsers": 15,
    "features": "[\"Báo cáo nâng cao\", \"Xuất dữ liệu\"]",
    "isActive": true,
    "createdAt": "2026-06-22T08:00:00Z",
    "updatedAt": null
  },
  "errors": []
}
```

`400 Bad Request` (ví dụ trùng tên):

```json
{
  "succeeded": false,
  "message": null,
  "data": null,
  "errors": ["Tên gói subscription đã tồn tại."]
}
```

### 6.5. Cập nhật gói

```http
PUT /api/system-admin/subscription-plans/3
Authorization: Bearer <access-token>
Content-Type: application/json
```

Request body giống hệt API tạo gói và là **full update**: FE phải gửi đầy đủ mọi field, không chỉ field đã thay đổi.

```json
{
  "name": "Pro",
  "price": 449000,
  "durationDays": 30,
  "maxStores": 4,
  "maxUsers": 20,
  "features": "[\"Báo cáo nâng cao\", \"Xuất dữ liệu\"]",
  "isActive": true
}
```

`200 OK` trả chính xác object gói sau cập nhật trong `data`:

```json
{
  "succeeded": true,
  "message": "Cập nhật gói subscription thành công.",
  "data": {
    "id": 3,
    "name": "Pro",
    "price": 449000,
    "durationDays": 30,
    "maxStores": 4,
    "maxUsers": 20,
    "features": "[\"Báo cáo nâng cao\", \"Xuất dữ liệu\"]",
    "isActive": true,
    "createdAt": "2026-06-22T08:00:00Z",
    "updatedAt": "2026-06-22T08:15:00Z"
  },
  "errors": []
}
```

`404 Not Found` nếu `id` không tồn tại; `400 Bad Request` nếu body không hợp lệ hoặc trùng tên.

### 6.6. Bật bán gói

```http
PATCH /api/system-admin/subscription-plans/3/activate
Authorization: Bearer <access-token>
```

Không có request body.

`200 OK`

```json
{
  "succeeded": true,
  "message": "Kích hoạt gói subscription thành công.",
  "errors": []
}
```

### 6.7. Tạm ẩn gói

```http
PATCH /api/system-admin/subscription-plans/3/deactivate
Authorization: Bearer <access-token>
```

Không có request body.

`200 OK`

```json
{
  "succeeded": true,
  "message": "Ngừng bán gói subscription thành công.",
  "errors": []
}
```

Hai API đổi trạng thái trả `404 Not Found` khi gói không tồn tại. Sau thành công, frontend phải tải lại `summary` và danh sách hiện tại.

### 6.8. Xóa gói

```http
DELETE /api/system-admin/subscription-plans/3
Authorization: Bearer <access-token>
```

Không có query parameter và không có request body.

`200 OK`

```json
{
  "succeeded": true,
  "message": "Xóa gói subscription thành công.",
  "errors": []
}
```

Nếu gói đã từng có subscription, backend trả `400 Bad Request`:

```json
{
  "succeeded": false,
  "message": null,
  "errors": [
    "Không thể xóa gói đã có subscription. Hãy ngừng bán gói này thay vì xóa."
  ]
}
```

### 6.9. Lấy doanh thu gói tháng hiện tại

API này không thuộc resource gói, nhưng dùng cho thẻ **Doanh thu gói** trong cùng màn hình.

```http
GET /api/system-admin/dashboard/overview?from=2026-06-01&to=2026-06-30&groupBy=day
Authorization: Bearer <access-token>
```

`200 OK` — frontend chỉ cần đọc `data.metrics.subscriptionRevenue`:

```json
{
  "succeeded": true,
  "message": "",
  "data": {
    "period": {
      "from": "2026-06-01T00:00:00Z",
      "to": "2026-06-30T23:59:59.9999999Z",
      "groupBy": "day"
    },
    "metrics": {
      "subscriptionRevenue": 86200000
    }
  },
  "errors": []
}
```

## 7. Luồng gọi API tham khảo

```text
Mở trang quản lý
  ├─ GET /summary
  └─ GET /dashboard/overview (tháng hiện tại)

Nhấn “Tổng số gói” hoặc “Gói đang bán”
  └─ GET /subscription-plans?status=all|active&pageIndex=1&pageSize=10

Mở form sửa
  └─ GET /subscription-plans/{id}

Lưu form
  ├─ POST /subscription-plans              (tạo)
  └─ PUT /subscription-plans/{id}          (sửa)
       └─ reload summary + danh sách hiện tại

Bật bán / tạm ẩn / xóa
  └─ PATCH activate | PATCH deactivate | DELETE
       └─ reload summary + danh sách hiện tại
```

## 8. Endpoint cũ không dùng cho màn hình này

Không tích hợp màn hình System Admin với các endpoint sau:

- `GET /api/subscription-plans/active`: dành cho khách hàng chọn gói, công khai và chỉ trả gói đang bán.
- `GET /api/subscription-plans` và `GET /api/subscription-plans/{id}`: endpoint tương thích cũ; không có phân trang/filter admin và endpoint chi tiết có payload rộng hơn cần thiết.
- Các thao tác cũ dưới `/api/subscription-plans`: đã bị giới hạn SystemAdmin, nhưng frontend mới cần dùng route `/api/system-admin/subscription-plans` để nhận đúng contract trong tài liệu này.
