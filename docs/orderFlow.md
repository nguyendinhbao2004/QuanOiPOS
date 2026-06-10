Tổng quan flow Order
Flow frontend nên triển khai:
Chọn bàn
→ Mở TableSession
→ Tải menu sản phẩm
→ Tạo một hoặc nhiều Order
→ Bếp cập nhật trạng thái từng món
→ Tạo Invoice theo Order hoặc toàn bộ TableSession
→ Xác nhận Payment
→ Đóng TableSession
Quy ước chung
Các API quản lý yêu cầu:
Authorization: Bearer <accessToken>
Content-Type: application/json
Riêng POST /api/orders cho phép gọi không có token.
Response chung:
{
  "succeeded": true,
  "message": "Thao tác thành công",
  "data": {},
  "errors": []
}
Enum
Enum	Giá trị
OrderType.DineIn	"DineIn"
OrderType.QR	"QR"
OrderType.TakeAway	"TakeAway"
OrderStatus.Pending	1
OrderStatus.Completed	2
OrderStatus.Cancelled	3
OrderItemStatus.Pending	1
OrderItemStatus.Preparing	2
OrderItemStatus.Ready	3
OrderItemStatus.Cancelled	4
PaymentMethod.Cash	1
PaymentMethod.QR	2
PaymentMethod.Card	3
PaymentStatus.Pending	1
PaymentStatus.Completed	2
PaymentStatus.Failed	3
PaymentStatus.Refunded	4

1. Lấy danh sách bàn
GET /api/tables/store/{storeId}/areas
Có thể lọc khu vực:
GET /api/tables/store/5/areas?areaId=2
Response:
{
  "succeeded": true,
  "data": [
    {
      "id": 2,
      "storeId": 5,
      "name": "Tầng 1",
      "description": null,
      "displayOrder": 1,
      "isActive": true,
      "tables": [
        {
          "id": 10,
          "storeId": 5,
          "areaId": 2,
          "name": "Bàn 01",
          "capacity": 4,
          "status": "Available",
          "createdAt": "2026-06-10T10:00:00Z",
          "createdBy": "1",
          "updatedAt": null,
          "updatedBy": null,
          "isDeleted": false
        }
      ]
    }
  ],
  "errors": []
}
API liên quan:
GET /api/tables/store/{storeId}
GET /api/tables/{tableId}
Quyền xem bàn: permission 8.
2. Mở phiên phục vụ bàn
POST /api/table-sessions
Request:
{
  "tableId": 10
}
Response 201:
{
  "succeeded": true,
  "message": "Tạo phiên bàn thành công!",
  "data": {
    "id": 501,
    "tableId": 10,
    "openTime": "2026-06-10T10:00:00Z",
    "closeTime": null,
    "status": 1,
    "createdAt": "2026-06-10T10:00:00Z",
    "createdBy": "1",
    "updatedAt": null,
    "updatedBy": null,
    "isDeleted": false
  },
  "errors": []
}
Một bàn không thể có hai phiên đang mở.
API truy vấn:
Method	Endpoint
GET	/api/table-sessions/{id}
GET	/api/table-sessions/table/{tableId}
GET	/api/table-sessions/store/{storeId}
GET	/api/table-sessions/store/{storeId}/open

Lấy các phiên đang mở:
{
  "succeeded": true,
  "data": {
    "totalCount": 1,
    "items": [
      {
        "id": 501,
        "tableId": 10,
        "openTime": "2026-06-10T10:00:00Z",
        "closeTime": null,
        "status": 1,
        "createdAt": "2026-06-10T10:00:00Z",
        "createdBy": "1",
        "updatedAt": null,
        "updatedBy": null,
        "isDeleted": false
      }
    ]
  },
  "errors": []
}
Quyền:
Thao tác	Permission
Xem phiên bàn	8
Mở phiên bàn	12
Đóng phiên bàn	13
Hủy phiên bàn	10

3. Lấy menu để order
Frontend nên gọi:
GET /api/products/store/{storeId}
GET /api/categories/store/{storeId}
ProductResponse đã có:
Giá sản phẩm.
Danh sách variant.
Danh sách topping.
Tên và ảnh sản phẩm.
Có thể lấy chi tiết topping đã gắn:
GET /api/product-toppings/product/{productId}
Response:
{
  "succeeded": true,
  "data": [
    {
      "id": 301,
      "productId": 101,
      "toppingId": 3,
      "name": "Trân châu",
      "price": 5000
    }
  ],
  "errors": []
}
4. Tạo Order
POST /api/orders
API này không bắt buộc token. Nếu có JWT hợp lệ, backend lưu createdByAccountId.
Request:
{
  "storeId": 5,
  "tableSessionId": 501,
  "orderType": "DineIn",
  "customerId": null,
  "items": [
    {
      "productId": 101,
      "variantId": 201,
      "note": "Ít đá, 50% đường",
      "toppings": [
        {
          "toppingId": 3,
          "quantity": 1
        },
        {
          "toppingId": 4,
          "quantity": 2
        }
      ]
    },
    {
      "productId": 102,
      "variantId": null,
      "note": null,
      "toppings": []
    }
  ]
}
Quy tắc:
items bắt buộc có ít nhất một phần tử.
tableSessionId phải thuộc đúng storeId.
Product, topping và customer phải thuộc đúng store.
Variant phải thuộc đúng product.
Variant, product và topping phải active.
Không được trùng topping trong cùng một item.
Số lượng topping phải lớn hơn 0.
orderType nhận chuỗi không phân biệt hoa thường.
Nếu store có ShiftSession đang mở, backend tự gắn shiftSessionId.
Response 201:
{
  "succeeded": true,
  "message": "Tạo đơn hàng thành công!",
  "data": {
    "id": 7001,
    "storeId": 5,
    "tableSessionId": 501,
    "shiftSessionId": 51,
    "orderType": 1,
    "status": 1,
    "customerId": null,
    "totalAmount": 75000,
    "finalAmount": null,
    "discountAmount": null,
    "paidAmount": null,
    "createdByAccountId": 1,
    "createdAt": "2026-06-10T10:10:00Z",
    "items": [
      {
        "id": 8001,
        "orderId": 7001,
        "productId": 101,
        "variantId": 201,
        "note": "Ít đá, 50% đường",
        "status": 1,
        "unitPrice": 35000,
        "productNameSnapshot": "Trà sữa",
        "variantNameSnapshot": "Size L",
        "discountId": null,
        "discountAmount": null,
        "finalPrice": null,
        "costPrice": 16000,
        "grossProfit": 19000,
        "toppings": [
          {
            "id": 9001,
            "orderItemId": 8001,
            "toppingId": 3,
            "toppingNameSnapshot": "Trân châu",
            "quantity": 1,
            "unitPrice": 5000,
            "totalPrice": 5000,
            "costPrice": 2000,
            "totalCostPrice": 2000,
            "grossProfit": 3000
          }
        ]
      }
    ]
  },
  "errors": []
}
Cách tính:
TotalAmount =
    tổng UnitPrice của tất cả OrderItem
    + tổng TotalPrice của topping
Giá và tên được snapshot tại thời điểm order, nên việc sửa giá sản phẩm sau đó không ảnh hưởng order cũ.
5. Lấy Order
Method	Endpoint	Chức năng
GET	/api/orders/{orderId}	Chi tiết đơn
GET	/api/orders/table-session/{tableSessionId}	Tất cả đơn của phiên bàn
GET	/api/orders/system	Toàn hệ thống, System Admin

Ví dụ:
GET /api/orders/table-session/501
Response data là mảng OrderResponse, sắp xếp từ mới đến cũ.
Quyền xem order: permission 27.
Một TableSession có thể có nhiều Order. Khi khách gọi thêm món, frontend tạo một order mới với cùng tableSessionId.
6. Quản lý trạng thái món
Lấy danh sách món
GET /api/order-items/order/{orderId}
GET /api/order-items/{orderItemId}
Quyền xem: permission 27.
Cập nhật trạng thái
PUT /api/order-items/{orderItemId}/status
Request:
{
  "status": 2
}
Flow đề xuất:
Pending (1) → Preparing (2) → Ready (3)
Response:
{
  "succeeded": true,
  "message": "Cập nhật trạng thái món thành công!",
  "data": {
    "id": 8001,
    "orderId": 7001,
    "productId": 101,
    "variantId": 201,
    "note": "Ít đá",
    "status": 2,
    "unitPrice": 35000,
    "productNameSnapshot": "Trà sữa",
    "variantNameSnapshot": "Size L",
    "discountId": null,
    "discountAmount": null,
    "finalPrice": null,
    "costPrice": 16000,
    "grossProfit": 19000,
    "toppings": []
  },
  "errors": []
}
Khi tất cả món của order có trạng thái Ready hoặc Cancelled, backend tự chuyển order sang Completed.
Quyền cập nhật trạng thái món: permission 32.
Hủy một món
PUT /api/order-items/{orderItemId}/cancel
Không có body.
Quyền hủy món: permission 33.
Lưu ý: hủy món hiện không tính lại totalAmount của order.
7. Hủy toàn bộ Order
PUT /api/orders/{orderId}/cancel
Không có body.
Chỉ hủy được khi:
Order chưa Completed.
Order chưa bị hủy.
Tất cả món vẫn đang Pending.
Quyền hủy order: permission 30.
8. Tạo hóa đơn
Có hai cách:
Thanh toán riêng một order.
Thanh toán toàn bộ order trong một TableSession.
POST /api/invoices
Thanh toán toàn bàn
{
  "orderId": null,
  "tableSessionId": 501,
  "method": 1,
  "discountAmount": 10000,
  "taxAmount": 5000,
  "serviceCharge": 0
}
Thanh toán riêng một order
{
  "orderId": 7001,
  "tableSessionId": null,
  "method": 2,
  "discountAmount": 0,
  "taxAmount": 0,
  "serviceCharge": 0
}
Chỉ được truyền một trong hai field orderId hoặc tableSessionId.
Công thức:
FinalAmount =
    SubTotal
    - DiscountAmount
    + TaxAmount
    + ServiceCharge
Khi tạo invoice, backend đồng thời tạo một payment trạng thái Pending.
Response 201:
{
  "succeeded": true,
  "message": "Tao invoice thanh cong!",
  "data": {
    "invoiceId": 1001,
    "orderId": null,
    "tableSessionId": 501,
    "invoiceCode": "INV-TS-501-20260610120000123",
    "subTotal": 150000,
    "discountAmount": 10000,
    "taxAmount": 5000,
    "serviceCharge": 0,
    "finalAmount": 145000,
    "issuedAt": "2026-06-10T12:00:00Z",
    "createdByAccountId": 1,
    "createdAt": "2026-06-10T12:00:00Z",
    "updatedAt": null,
    "isDeleted": false,
    "payments": [
      {
        "id": 1101,
        "invoiceId": 1001,
        "amount": 145000,
        "paymentMethod": 1,
        "status": 1,
        "createdAt": "2026-06-10T12:00:00Z",
        "updatedAt": null,
        "paidAt": null,
        "isDeleted": false
      }
    ]
  },
  "errors": []
}
Một nguồn thanh toán chỉ được có một invoice.
API liên quan:
GET /api/invoices
GET /api/invoices/{invoiceId}
PUT /api/invoices/{invoiceId}
DELETE /api/invoices/{invoiceId}
Cập nhật phí:
{
  "discountAmount": 15000,
  "taxAmount": 5000,
  "serviceCharge": 10000
}
Backend cập nhật cả số tiền của payment đang Pending.
9. Xác nhận thanh toán
Lấy paymentId từ:
invoice.data.payments[0].id
Sau đó gọi:
POST /api/payments/{paymentId}/confirm
Không có body.
Response:
{
  "succeeded": true,
  "message": "Xac nhan thanh toan thanh cong!",
  "errors": []
}
Khi xác nhận:
Payment chuyển thành Completed.
paidAt được cập nhật.
Các order thuộc invoice được chuyển thành Completed.
paidAmount của order được cập nhật.
Không thể confirm lại payment đã xử lý.
API liên quan:
GET /api/payments
GET /api/payments/{paymentId}
Đổi phương thức hoặc số tiền payment
PUT /api/payments/{paymentId}
{
  "method": 3,
  "amount": 145000
}
Thông thường frontend nên cập nhật invoice hoặc phương thức trước khi confirm, không nên tự sửa amount lệch với invoice.
10. Đóng phiên bàn
Sau khi payment thành công:
PUT /api/table-sessions/{tableSessionId}/close
Không có body.
Response:
{
  "succeeded": true,
  "data": {
    "id": 501,
    "tableId": 10,
    "openTime": "2026-06-10T10:00:00Z",
    "closeTime": "2026-06-10T12:05:00Z",
    "status": 2,
    "createdAt": "2026-06-10T10:00:00Z",
    "createdBy": "1",
    "updatedAt": "2026-06-10T12:05:00Z",
    "updatedBy": "1",
    "isDeleted": false
  },
  "errors": []
}
Hủy phiên bàn:
PUT /api/table-sessions/{tableSessionId}/cancel
Flow frontend đề xuất
Màn POS nhân viên
GET /api/tables/store/{storeId}/areas
Chọn bàn.
Tìm session đang mở bằng GET /api/table-sessions/table/{tableId}.
Nếu chưa có, gọi POST /api/table-sessions.
GET /api/products/store/{storeId}.
Tạo giỏ hàng phía frontend.
POST /api/orders.
Refresh GET /api/orders/table-session/{tableSessionId}.
Màn bếp
Lấy các order theo những phiên bàn đang mở.
Hiển thị từng OrderItem.
Chuyển Pending → Preparing → Ready.
Dùng PUT /api/order-items/{id}/status.
Hiện backend chưa có API lấy order trực tiếp theo storeId hoặc lọc trạng thái. Frontend phải đi qua danh sách session bàn hoặc cần bổ sung endpoint.
Màn thanh toán
GET /api/orders/table-session/{tableSessionId}.
Tính tổng hiển thị.
POST /api/invoices với tableSessionId.
Lấy paymentId từ invoice.
POST /api/payments/{paymentId}/confirm.
PUT /api/table-sessions/{tableSessionId}/close.
Các hạn chế frontend cần lưu ý
CreateOrderItemRequest không có quantity. Muốn gọi 3 sản phẩm giống nhau phải gửi 3 item riêng biệt.
Hủy một OrderItem không tính lại tổng tiền order/invoice.
Tạo order chưa kiểm tra TableSession có đang Open hay không.
Topping chỉ được kiểm tra cùng store, chưa kiểm tra topping có được gắn với product hay không.
Product có IsSell, nhưng response sản phẩm hiện không trả field này.
Invoice/payment hiện chỉ yêu cầu đăng nhập, chưa kiểm tra quyền store rõ ràng.
GET /api/invoices và GET /api/payments đang trả dữ liệu toàn hệ thống, chưa lọc theo store.
Thanh toán thành công không tự đóng TableSession; frontend phải gọi API close riêng.