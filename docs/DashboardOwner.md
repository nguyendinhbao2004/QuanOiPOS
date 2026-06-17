POST /api/ai-insights/sales là API tạo thống kê + phân tích doanh thu bán hàng cho một quán trong một khoảng thời gian.
API này yêu cầu đăng nhập vì controller có [Authorize].
Endpoint
POST /api/ai-insights/sales
Authorization: Bearer <access_token>
Content-Type: application/json
Body
{
  "storeId": 1,
  "fromDate": "2026-06-01T00:00:00Z",
  "toDate": "2026-06-17T23:59:59Z",
  "type": 1
}
Các thuộc tính trong body
storeId
ID của quán cần xem thống kê. Bắt buộc, phải lớn hơn 0.
fromDate
Ngày bắt đầu thống kê. Không bắt buộc. Nếu không truyền, hệ thống mặc định lấy khoảng 30 ngày gần nhất.
toDate
Ngày kết thúc thống kê. Không bắt buộc. Nếu không truyền, hệ thống lấy thời điểm hiện tại.
type
Loại insight AI. Không bắt buộc.
Giá trị hiện có:
1 = Trend
2 = Suggestion
Trong đó:
Trend: phân tích xu hướng doanh thu
Suggestion: gợi ý cải thiện kinh doanh
Luồng xử lý
API sẽ:
Kiểm tra người dùng từ JWT.
Kiểm tra storeId có tồn tại không.
Kiểm tra tài khoản có quyền xem dữ liệu quán đó không.
Lấy các đơn hàng trong khoảng fromDate đến toDate.
Chỉ tính doanh thu từ các order có trạng thái Completed.
Đếm số order Cancelled.
Tính top 5 món bán chạy dựa trên OrderItem.
Gọi AI để sinh nội dung phân tích.
Lưu insight vào bảng AIInsight.
Trả về metric + nội dung phân tích.
Response thành công
{
  "succeeded": true,
  "message": "Tao insight doanh thu thanh cong.",
  "data": {
    "id": 12,
    "storeId": 1,
    "type": 1,
    "fromDate": "2026-06-01T00:00:00Z",
    "toDate": "2026-06-17T23:59:59Z",
    "content": "Doanh thu trong giai đoạn này có xu hướng...",
    "metrics": {
      "totalRevenue": 1500000,
      "paidRevenue": 1450000,
      "completedOrderCount": 35,
      "cancelledOrderCount": 3,
      "averageOrderValue": 42857.14,
      "topProducts": [
        {
          "productId": 5,
          "productName": "Trà sữa truyền thống",
          "orderItemCount": 20
        }
      ]
    },
    "createdAt": "2026-06-17T15:00:00Z"
  },
  "errors": []
}
Các thuộc tính trong response
succeeded
Cho biết API thành công hay thất bại.
message
Thông báo kết quả xử lý.
errors
Danh sách lỗi nếu thất bại.
data.id
ID của insight vừa được tạo trong database.
data.storeId
ID quán được phân tích.
data.type
Loại insight: 1 = Trend, 2 = Suggestion.
data.fromDate, data.toDate
Khoảng thời gian hệ thống dùng để thống kê.
data.content
Nội dung phân tích do AI tạo ra. Nếu không có đơn hoàn thành, hệ thống trả nội dung báo chưa có dữ liệu.
data.metrics.totalRevenue
Tổng doanh thu từ các order Completed, lấy theo FinalAmount.
data.metrics.paidRevenue
Tổng tiền đã thanh toán từ các order Completed, lấy theo PaidAmount.
data.metrics.completedOrderCount
Số đơn đã hoàn thành.
data.metrics.cancelledOrderCount
Số đơn đã hủy trong khoảng thời gian đó.
data.metrics.averageOrderValue
Giá trị trung bình mỗi đơn hoàn thành.
Công thức:
averageOrderValue = totalRevenue / completedOrderCount
data.metrics.topProducts
Danh sách tối đa 5 món bán chạy nhất.
productId là ID món.
productName là tên món.
orderItemCount là số dòng order item của món đó.
Các lỗi có thể gặp
400 Bad Request
{
  "succeeded": false,
  "message": "",
  "data": null,
  "errors": [
    "fromDate phai nho hon hoac bang toDate."
  ]
}
Hoặc khoảng ngày vượt quá 90 ngày:
{
  "succeeded": false,
  "errors": [
    "Khoang ngay phan tich khong duoc vuot qua 90 ngay."
  ]
}
401 Unauthorized
Chưa đăng nhập hoặc không xác định được user.
403 Forbidden
Tài khoản không có quyền phân tích dữ liệu của quán này.
404 Not Found
storeId không tồn tại.