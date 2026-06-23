# Kitchen API Guide

Tài liệu này mô tả luồng API cho màn hình bếp. FE dùng các API này để xem món đang được order trong một quán, lọc theo món/bàn/thời gian/trạng thái, cập nhật trạng thái từng món hoặc nhiều món, hủy món, và nhận realtime khi có món mới hoặc món đổi trạng thái.

## 1. Tổng quan luồng FE

1. User đăng nhập và có JWT.
2. FE mở màn hình bếp theo `storeId`.
3. FE gọi:

```http
GET /api/kitchen/stores/{storeId}/items
```

4. FE render danh sách theo từng món.
5. FE kết nối SignalR hub:

```text
/hubs/notifications
```

Sau khi connect, gọi:

```text
JoinStore(storeId)
```

6. FE nghe method:

```text
ReceiveNotification
```

7. Khi bếp thao tác:
   - Một món: gọi update/cancel theo `orderItemId`.
   - Nhiều món: gọi bulk update/bulk cancel.
8. Khi nhận realtime event, FE có thể update item trong state hoặc gọi lại API list để đồng bộ.

## 2. Auth và quyền

Tất cả Kitchen API yêu cầu:

```http
Authorization: Bearer {accessToken}
```

Điều kiện quyền:

- Account phải là `StoreUser` active của `storeId`.
- API xem danh sách dùng quyền `MANAGE_ORDERS`.
- API cập nhật trạng thái dùng permission id `32`.
- API hủy món dùng permission id `33`.

Nếu không có token: `401`.

Nếu không thuộc store hoặc thiếu quyền: `403`.

## 3. Enum trạng thái món

`OrderItemStatus`:

| Value | Name | Ý nghĩa |
|---:|---|---|
| 1 | `Pending` | Món mới/chờ xử lý |
| 2 | `Preparing` | Đang làm |
| 3 | `Ready` | Đã xong |
| 4 | `Cancelled` | Đã hủy |

Với API bếp, update status nên dùng `2`, `3`, hoặc `4`. Không dùng `1` để cập nhật ngược về `Pending`.

## 4. Response wrapper chung

Các API trả về dạng `Result<T>`:

```json
{
  "succeeded": true,
  "message": "string",
  "errors": [],
  "data": {}
}
```

Khi lỗi:

```json
{
  "succeeded": false,
  "message": "",
  "errors": ["Lý do lỗi"],
  "data": null
}
```

## 5. DTO chính

### KitchenOrderItemResponse

```json
{
  "orderItemId": 101,
  "orderId": 55,
  "storeId": 1,
  "tableSessionId": 12,
  "tableId": 8,
  "tableName": "Bàn 8",
  "productId": 20,
  "productName": "Phở bò",
  "variantId": 3,
  "variantName": "Tô lớn",
  "note": "Không hành",
  "status": 1,
  "orderedAt": "2026-06-22T15:30:00Z",
  "updatedAt": null,
  "toppings": [
    {
      "id": 1,
      "orderItemId": 101,
      "toppingId": 5,
      "toppingName": "Thêm bò",
      "quantity": 1,
      "unitPrice": 15000,
      "totalPrice": 15000
    }
  ]
}
```

### KitchenBulkUpdateResponse

```json
{
  "updatedItems": [
    {
      "orderItemId": 101,
      "orderId": 55,
      "storeId": 1,
      "tableSessionId": 12,
      "tableId": 8,
      "tableName": "Bàn 8",
      "productId": 20,
      "productName": "Phở bò",
      "variantId": 3,
      "variantName": "Tô lớn",
      "note": "Không hành",
      "status": 2,
      "orderedAt": "2026-06-22T15:30:00Z",
      "updatedAt": "2026-06-22T15:35:00Z",
      "toppings": []
    }
  ],
  "failedItems": [
    {
      "orderItemId": 999,
      "message": "Món trong đơn hàng không tồn tại!"
    }
  ]
}
```

Bulk API dùng cơ chế partial success: item hợp lệ vẫn được cập nhật, item lỗi nằm trong `failedItems`.

## 6. API lấy danh sách món cho bếp

```http
GET /api/kitchen/stores/{storeId}/items
```

### Query params

| Param | Type | Required | Mô tả |
|---|---|---:|---|
| `productId` | int | No | Lọc theo món |
| `tableId` | int | No | Lọc theo bàn |
| `tableSessionId` | int | No | Lọc theo phiên bàn |
| `status` | int | No | Lọc theo `OrderItemStatus` |
| `orderedFrom` | datetime | No | Lọc order từ thời điểm này |
| `orderedTo` | datetime | No | Lọc order đến thời điểm này |

Danh sách được sort theo `orderedAt` mới nhất trước.

### Ví dụ

Lấy tất cả món của quán:

```http
GET /api/kitchen/stores/1/items
```

Lọc món đang chờ:

```http
GET /api/kitchen/stores/1/items?status=1
```

Lọc theo bàn và khoảng thời gian:

```http
GET /api/kitchen/stores/1/items?tableId=8&orderedFrom=2026-06-22T00:00:00Z&orderedTo=2026-06-22T23:59:59Z
```

### Response 200

```json
{
  "succeeded": true,
  "message": "Lấy danh sách món cho màn hình bếp thành công!",
  "errors": [],
  "data": [
    {
      "orderItemId": 101,
      "orderId": 55,
      "storeId": 1,
      "tableSessionId": 12,
      "tableId": 8,
      "tableName": "Bàn 8",
      "productId": 20,
      "productName": "Phở bò",
      "variantId": 3,
      "variantName": "Tô lớn",
      "note": "Không hành",
      "status": 1,
      "orderedAt": "2026-06-22T15:30:00Z",
      "updatedAt": null,
      "toppings": []
    }
  ]
}
```

## 7. API cập nhật trạng thái một món

```http
PUT /api/kitchen/items/{id}/status
```

`id` là `orderItemId`.

### Body

```json
{
  "status": 2
}
```

Giá trị thường dùng:

- `2`: bắt đầu làm món.
- `3`: món đã xong.
- `4`: hủy món.

### Response 200

```json
{
  "succeeded": true,
  "message": "Cập nhật trạng thái món bếp thành công!",
  "errors": [],
  "data": {
    "orderItemId": 101,
    "orderId": 55,
    "storeId": 1,
    "tableSessionId": 12,
    "tableId": 8,
    "tableName": "Bàn 8",
    "productId": 20,
    "productName": "Phở bò",
    "variantId": 3,
    "variantName": "Tô lớn",
    "note": "Không hành",
    "status": 2,
    "orderedAt": "2026-06-22T15:30:00Z",
    "updatedAt": "2026-06-22T15:35:00Z",
    "toppings": []
  }
}
```

### Lưu ý nghiệp vụ

Khi một món được update thành `Ready`, backend kiểm tra tất cả item trong cùng order. Nếu tất cả item đều `Ready` hoặc `Cancelled`, order sẽ tự chuyển sang `Completed`.

## 8. API hủy một món

```http
PUT /api/kitchen/items/{id}/cancel
```

`id` là `orderItemId`.

Không cần body.

### Response 200

```json
{
  "succeeded": true,
  "message": "Hủy món bếp thành công!",
  "errors": [],
  "data": {
    "orderItemId": 101,
    "orderId": 55,
    "storeId": 1,
    "tableSessionId": 12,
    "tableId": 8,
    "tableName": "Bàn 8",
    "productId": 20,
    "productName": "Phở bò",
    "variantId": 3,
    "variantName": "Tô lớn",
    "note": "Không hành",
    "status": 4,
    "orderedAt": "2026-06-22T15:30:00Z",
    "updatedAt": "2026-06-22T15:40:00Z",
    "toppings": []
  }
}
```

Nếu món đã hủy trước đó, API trả `400`.

## 9. API cập nhật trạng thái nhiều món

```http
PUT /api/kitchen/items/bulk-status
```

### Body

```json
{
  "itemIds": [101, 102, 103],
  "status": 2
}
```

### Response 200

```json
{
  "succeeded": true,
  "message": "Cập nhật trạng thái nhiều món bếp hoàn tất!",
  "errors": [],
  "data": {
    "updatedItems": [
      {
        "orderItemId": 101,
        "orderId": 55,
        "storeId": 1,
        "tableSessionId": 12,
        "tableId": 8,
        "tableName": "Bàn 8",
        "productId": 20,
        "productName": "Phở bò",
        "variantId": null,
        "variantName": null,
        "note": null,
        "status": 2,
        "orderedAt": "2026-06-22T15:30:00Z",
        "updatedAt": "2026-06-22T15:35:00Z",
        "toppings": []
      }
    ],
    "failedItems": [
      {
        "orderItemId": 999,
        "message": "Món trong đơn hàng không tồn tại!"
      }
    ]
  }
}
```

FE nên hiển thị toast/tổng kết:

- `updatedItems.length` món thành công.
- `failedItems.length` món thất bại.
- Nếu có `failedItems`, hiển thị danh sách lỗi hoặc cảnh báo ngắn.

## 10. API hủy nhiều món

```http
PUT /api/kitchen/items/bulk-cancel
```

### Body

```json
{
  "itemIds": [101, 102, 103]
}
```

### Response 200

```json
{
  "succeeded": true,
  "message": "Hủy nhiều món bếp hoàn tất!",
  "errors": [],
  "data": {
    "updatedItems": [
      {
        "orderItemId": 101,
        "orderId": 55,
        "storeId": 1,
        "tableSessionId": 12,
        "tableId": 8,
        "tableName": "Bàn 8",
        "productId": 20,
        "productName": "Phở bò",
        "variantId": null,
        "variantName": null,
        "note": null,
        "status": 4,
        "orderedAt": "2026-06-22T15:30:00Z",
        "updatedAt": "2026-06-22T15:40:00Z",
        "toppings": []
      }
    ],
    "failedItems": []
  }
}
```

## 11. Realtime SignalR

### Connect

FE connect tới:

```text
{BASE_URL}/hubs/notifications
```

Kèm JWT. Nếu dùng SignalR JS client, thường truyền token qua `accessTokenFactory`.

Ví dụ:

```ts
const connection = new signalR.HubConnectionBuilder()
  .withUrl(`${BASE_URL}/hubs/notifications`, {
    accessTokenFactory: () => accessToken
  })
  .withAutomaticReconnect()
  .build();

connection.on("ReceiveNotification", (message) => {
  console.log(message);
});

await connection.start();
await connection.invoke("JoinStore", storeId);
```

### Message format

```json
{
  "eventName": "KITCHEN_ITEM_STATUS_CHANGED",
  "title": "Cập nhật trạng thái món",
  "content": "Màn hình bếp có thay đổi món.",
  "audience": "Store",
  "payload": {},
  "occurredAt": "2026-06-22T15:35:00Z"
}
```

### Event: KITCHEN_ORDER_CREATED

Phát khi order mới được tạo.

Payload:

```json
{
  "storeId": 1,
  "orderId": 55,
  "items": [
    {
      "orderItemId": 101,
      "orderId": 55,
      "storeId": 1,
      "tableSessionId": 12,
      "tableId": 8,
      "tableName": "Bàn 8",
      "productId": 20,
      "productName": "Phở bò",
      "variantId": null,
      "variantName": null,
      "note": "Không hành",
      "status": 1,
      "orderedAt": "2026-06-22T15:30:00Z",
      "updatedAt": null,
      "toppings": []
    }
  ]
}
```

FE nên prepend các item mới vào danh sách nếu đang xem cùng `storeId` và item match filter hiện tại.

### Event: KITCHEN_ITEM_STATUS_CHANGED

Phát khi một món đổi trạng thái qua API status.

Payload:

```json
{
  "storeId": 1,
  "orderId": 55,
  "orderItemId": 101,
  "item": {
    "orderItemId": 101,
    "orderId": 55,
    "storeId": 1,
    "tableSessionId": 12,
    "tableId": 8,
    "tableName": "Bàn 8",
    "productId": 20,
    "productName": "Phở bò",
    "variantId": null,
    "variantName": null,
    "note": null,
    "status": 2,
    "orderedAt": "2026-06-22T15:30:00Z",
    "updatedAt": "2026-06-22T15:35:00Z",
    "toppings": []
  }
}
```

FE nên replace item trong state theo `orderItemId`.

### Event: KITCHEN_ITEM_CANCELLED

Phát khi một món bị hủy.

Payload giống `KITCHEN_ITEM_STATUS_CHANGED`, nhưng `item.status = 4`.

## 12. Flow UI đề xuất cho FE

### Load màn hình

1. Lấy `storeId` từ route hoặc store đang chọn.
2. Gọi `GET /api/kitchen/stores/{storeId}/items`.
3. Render theo cột/trạng thái:
   - `Pending`
   - `Preparing`
   - `Ready`
   - `Cancelled` nếu muốn hiển thị lịch sử.
4. Connect SignalR và `JoinStore(storeId)`.

### Lọc

FE có thể giữ filter local state:

```ts
{
  productId?: number;
  tableId?: number;
  tableSessionId?: number;
  status?: 1 | 2 | 3 | 4;
  orderedFrom?: string;
  orderedTo?: string;
}
```

Khi filter đổi, gọi lại API list với query params tương ứng.

### Cập nhật một món

- Bấm "Đang làm": `PUT /api/kitchen/items/{orderItemId}/status`, body `{ "status": 2 }`.
- Bấm "Xong": `PUT /api/kitchen/items/{orderItemId}/status`, body `{ "status": 3 }`.
- Bấm "Hủy": `PUT /api/kitchen/items/{orderItemId}/cancel`.

Sau response thành công, update item trong state ngay. Realtime có thể đến sau, FE nên xử lý idempotent bằng cách replace theo `orderItemId`.

### Bulk action

1. FE cho chọn nhiều item.
2. Gọi bulk API.
3. Với `updatedItems`, replace item trong state.
4. Với `failedItems`, hiển thị cảnh báo.
5. Clear selection các item thành công.

## 13. Ghi chú quan trọng

- `orderedAt` là thời điểm tạo order, dùng để lọc theo thời gian order.
- `updatedAt` là thời điểm item đổi trạng thái gần nhất.
- Bulk API không rollback toàn bộ. Một vài item lỗi không chặn các item hợp lệ.
- Mỗi update/cancel thành công sẽ tạo `KitchenLog` ở backend.
- Mỗi update/cancel thành công sẽ phát realtime tới group store.
- Nếu FE thấy mất đồng bộ, cách đơn giản nhất là gọi lại `GET /api/kitchen/stores/{storeId}/items` với filter hiện tại.
