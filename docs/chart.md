UI Dashboard System Admin
Dashboard chỉ thống kê doanh thu bán subscription và tăng trưởng tài khoản chủ cửa hàng, không lấy doanh thu bán món tại cửa hàng.
1. Bộ lọc chung
from, to: khoảng thời gian
groupBy: day | week | month
planId: lọc theo gói
paymentStatus: Pending | Completed | Failed | Refunded
So sánh với kỳ liền trước
2. KPI tổng quan
KPI	Cách tính
Doanh thu gói	Tổng SubscriptionPayment.Amount có trạng thái Completed
Số thanh toán thành công	Số payment Completed
Subscription mới	Số subscription tạo trong kỳ
Subscription đang hoạt động	Status = Active và EndDate > hiện tại
Tài khoản chủ cửa hàng mới	AccountType = StoreUser, tạo trong kỳ
Tổng tài khoản chủ cửa hàng	Tổng account StoreUser chưa bị xóa
Tăng trưởng tài khoản	So sánh số tài khoản mới với kỳ trước
Tỷ lệ tài khoản trả phí	Tài khoản từng thanh toán thành công / tổng tài khoản

Không dùng packagesSold, vì một subscription có thể thanh toán nhiều lần khi gia hạn.
{
  "period": {
    "from": "2026-05-01",
    "to": "2026-05-31",
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
3. Biểu đồ doanh thu subscription
Loại: Line chart hoặc Area chart.
Trục X: ngày, tuần hoặc tháng
Trục Y: doanh thu
Chỉ cộng payment Completed
Tooltip thêm số giao dịch và subscription mới
{
  "series": [
    {
      "period": "2026-05-01",
      "revenue": 8200000,
      "successfulPayments": 41,
      "newSubscriptions": 35
    }
  ]
}
4. Doanh thu theo gói
Loại: Horizontal bar chart.
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
Đếm successfulPayments, không gọi là số gói đã bán.
5. Tăng trưởng tài khoản
Loại: Combo chart.
Cột: tài khoản StoreUser mới
Đường: tổng tài khoản StoreUser tích lũy
Không hiển thị active user vì hiện chưa có lịch sử hoạt động theo ngày
{
  "series": [
    {
      "period": "2026-05-01",
      "newStoreAccounts": 105,
      "totalStoreAccounts": 25335
    }
  ]
}
6. Phân bổ subscription
Loại: Donut chart.
{
  "segments": [
    {
      "status": "ACTIVE",
      "label": "Đang hoạt động",
      "count": 3950,
      "percentage": 65.2
    },
    {
      "status": "PENDING",
      "label": "Chờ thanh toán",
      "count": 320,
      "percentage": 5.28
    },
    {
      "status": "EXPIRED",
      "label": "Đã hết hạn",
      "count": 1420,
      "percentage": 23.43
    },
    {
      "status": "CANCELLED",
      "label": "Đã hủy",
      "count": 369,
      "percentage": 6.09
    }
  ],
  "trialSubscriptions": 125
}
IsTrial là thuộc tính riêng, không phải một SubscriptionStatus.
7. Bảng thanh toán subscription
Các cột:
Payment ID
Chủ cửa hàng
Gói
Số tiền
Phương thức thanh toán
Trạng thái
Ngày thanh toán
Ngày tạo giao dịch
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
      "plan": {
        "id": 2,
        "name": "Pro"
      },
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
API chốt
GET /api/system-admin/dashboard/overview
GET /api/system-admin/dashboard/subscription-revenue
GET /api/system-admin/dashboard/revenue-by-plan
GET /api/system-admin/dashboard/account-growth
GET /api/system-admin/dashboard/subscription-distribution
GET /api/system-admin/subscription-payments
Query dùng chung:
?from=2026-05-01&to=2026-05-31&groupBy=day&planId=2
Các API này phải:
Yêu cầu đăng nhập.
Chỉ cho AccountType.SystemAdmin.
Bỏ qua bản ghi IsDeleted = true.
Dùng UTC trong API, frontend đổi sang múi giờ hiển thị.
Trả tiền bằng decimal, mặc định đơn vị VND.