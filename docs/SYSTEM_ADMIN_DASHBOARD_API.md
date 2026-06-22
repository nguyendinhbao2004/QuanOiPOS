# System Admin Dashboard API

Tài liệu này là hợp đồng để FE đối soát với backend cho màn hình **System Admin Dashboard**. Dashboard chỉ lấy dữ liệu subscription và tài khoản chủ cửa hàng; không bao gồm doanh thu order/món tại cửa hàng hoặc hardware order.

## Quy ước chung

- Base path: `/api/system-admin`.
- Tất cả endpoint yêu cầu JWT: `Authorization: Bearer <access-token>`.
- Chỉ `AccountType = SystemAdmin` được truy cập. Token chưa đăng nhập nhận `401`; tài khoản không phải SystemAdmin nhận `403`.
- Toàn bộ entity có `isDeleted = true` bị loại khỏi số liệu và danh sách.
- API xử lý thời gian theo UTC. `from` và `to` là ngày theo UTC; `to` được tính **bao gồm cả ngày đó**. FE tự đổi múi giờ khi hiển thị.
- Tiền là `decimal`, mặc định đơn vị `VND`; không có quy đổi tiền tệ.
- Thành công trả `200` với wrapper của backend: `{ succeeded, message, errors, data }`. Payload mô tả ở các phần dưới là nội dung trong `data`.

Ví dụ query chung:

```http
GET /api/system-admin/dashboard/overview?from=2026-05-01&to=2026-05-31&groupBy=day&planId=2&paymentStatus=Completed
```

| Query | Bắt buộc | Giá trị | Ghi chú |
| --- | --- | --- | --- |
| `from` | Có | `YYYY-MM-DD` | Ngày bắt đầu UTC. |
| `to` | Có | `YYYY-MM-DD` | Ngày kết thúc UTC, inclusive. |
| `groupBy` | Có | `day` \| `week` \| `month` | Không phân biệt hoa thường. Tuần bắt đầu vào Thứ Hai. |
| `planId` | Không | `int` | Áp dụng cho dữ liệu subscription/payment. KPI tài khoản không bị lọc theo plan. |
| `paymentStatus` | Không | `Pending` \| `Completed` \| `Failed` \| `Refunded` | Áp dụng cho payment. Doanh thu luôn chỉ cộng `Completed`; do đó nếu truyền giá trị khác `Completed`, doanh thu/số thanh toán thành công là `0`. |

`from`, `to` thiếu hoặc không hợp lệ; `groupBy` khác ba giá trị trên sẽ nhận `400`.

## 1. Tổng quan

`GET /api/system-admin/dashboard/overview`

Tính toán:

| KPI | Backend tính |
| --- | --- |
| `subscriptionRevenue` | Tổng `SubscriptionPayment.amount` Completed trong kỳ, theo `paidAt`. |
| `successfulPayments` | Số `SubscriptionPayment` Completed trong kỳ, theo `paidAt`. |
| `newSubscriptions` | Subscription tạo trong kỳ (`createdAt`). |
| `activeSubscriptions` | `status = Active` và `endDate > DateTime.UtcNow`. |
| `newStoreAccounts` | Account `StoreUser` tạo trong kỳ. |
| `totalStoreAccounts` | Tất cả Account `StoreUser` chưa xóa tại thời điểm gọi API. |
| `accountGrowthRate` | % thay đổi `newStoreAccounts` so với kỳ ngay trước. |
| `paidAccountRate` | Số StoreUser từng có payment Completed / tổng StoreUser. |

`comparison` là % thay đổi với kỳ liền trước có cùng độ dài. Khi kỳ trước bằng 0 và kỳ hiện tại lớn hơn 0, backend trả `100`; nếu cả hai bằng 0, trả `0`.

```json
{
  "period": {
    "from": "2026-05-01T00:00:00Z",
    "to": "2026-05-31T23:59:59.9999999Z",
    "groupBy": "day"
  },
  "metrics": {
    "subscriptionRevenue": 245000000,
    "successfulPayments": 1260,
    "newSubscriptions": 950,
    "activeSubscriptions": 820,
    "newStoreAccounts": 3420,
    "totalStoreAccounts": 28650,
    "accountGrowthRate": 13.56,
    "paidAccountRate": 4.82
  },
  "comparison": {
    "subscriptionRevenue": 18.4,
    "successfulPayments": 12.7,
    "newStoreAccounts": -3.2
  }
}
```

## 2. Chuỗi doanh thu subscription

`GET /api/system-admin/dashboard/subscription-revenue`

Dùng cho line/area chart. Mỗi bucket có doanh thu Completed, số payment Completed và số subscription mới.

```json
{
  "series": [
    {
      "period": "2026-05-01T00:00:00Z",
      "revenue": 8200000,
      "successfulPayments": 41,
      "newSubscriptions": 35
    }
  ]
}
```

## 3. Doanh thu theo gói

`GET /api/system-admin/dashboard/revenue-by-plan`

Dùng cho horizontal bar chart. `successfulPayments` là số giao dịch thành công, không phải số gói đã bán. `revenuePercentage` là tỷ trọng doanh thu trên toàn bộ các gói trong kết quả.

```json
{
  "items": [
    {
      "planId": 2,
      "planName": "Pro",
      "revenue": 132000000,
      "successfulPayments": 600,
      "revenuePercentage": 53.88
    }
  ]
}
```

## 4. Tăng trưởng tài khoản chủ cửa hàng

`GET /api/system-admin/dashboard/account-growth`

Dùng cho combo chart: cột `newStoreAccounts`, đường `totalStoreAccounts`. Giá trị đường là tổng StoreUser tích lũy tính tới cuối bucket, không phải active user.

```json
{
  "series": [
    {
      "period": "2026-05-01T00:00:00Z",
      "newStoreAccounts": 105,
      "totalStoreAccounts": 25335
    }
  ]
}
```

## 5. Phân bổ subscription

`GET /api/system-admin/dashboard/subscription-distribution`

Đây là ảnh chụp trạng thái subscription hiện tại, không giới hạn theo khoảng `from`/`to`; hai query này vẫn bắt buộc để giữ hợp đồng query chung. `planId` được áp dụng nếu có.

`isTrial` là thuộc tính riêng nên không nằm trong `segments`. Backend luôn trả bốn segment, kể cả segment có `count = 0`.

```json
{
  "segments": [
    { "status": "ACTIVE", "label": "Đang hoạt động", "count": 3950, "percentage": 65.2 },
    { "status": "PENDING", "label": "Chờ thanh toán", "count": 320, "percentage": 5.28 },
    { "status": "EXPIRED", "label": "Đã hết hạn", "count": 1420, "percentage": 23.43 },
    { "status": "CANCELLED", "label": "Đã hủy", "count": 369, "percentage": 6.09 }
  ],
  "trialSubscriptions": 125
}
```

## 6. Bảng thanh toán subscription

`GET /api/system-admin/subscription-payments`

Query bổ sung:

| Query | Mặc định | Ràng buộc |
| --- | --- | --- |
| `pageIndex` | `1` | >= 1 |
| `pageSize` | `10` | 1 đến 100 |

Danh sách được sắp xếp `createdAt` giảm dần. Bộ lọc ngày dùng `paidAt` nếu payment đã thanh toán; payment chưa thanh toán dùng `createdAt`.

```json
{
  "items": [
    {
      "paymentId": 1024,
      "subscriptionId": 512,
      "account": {
        "id": 123,
        "fullName": "Nguyễn Văn A",
        "email": "user@example.com"
      },
      "plan": { "id": 2, "name": "Pro" },
      "amount": 299000,
      "currency": "VND",
      "paymentMethod": "PayOS",
      "status": "Completed",
      "paidAt": "2026-06-11T02:30:00Z",
      "createdAt": "2026-06-11T02:25:00Z"
    }
  ],
  "pagination": {
    "pageIndex": 1,
    "pageSize": 10,
    "totalItems": 1260,
    "totalPages": 126
  }
}
```

## Response thực tế trên HTTP

Ví dụ HTTP response của endpoint overview (đã rút gọn):

```json
{
  "succeeded": true,
  "message": "",
  "errors": [],
  "data": {
    "period": { "from": "2026-05-01T00:00:00Z", "to": "2026-05-31T23:59:59.9999999Z", "groupBy": "day" },
    "metrics": { "subscriptionRevenue": 245000000 },
    "comparison": { "subscriptionRevenue": 18.4 }
  }
}
```

FE cần đọc payload tại `response.data.data` nếu HTTP client của FE đặt body response ở `response.data`.
