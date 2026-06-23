# Tích hợp Product, nguyên liệu và tồn kho

Tài liệu này là contract để FE triển khai màn hình tạo món, cấu hình công thức, tồn kho và quản lý nguyên liệu. Contract phản ánh API hiện tại, bao gồm thay đổi mới: mọi API `GET /api/products...` trả kèm trạng thái tồn kho của sản phẩm.

## 1. Quy ước chung

- Base URL: URL môi trường + đường dẫn bên dưới.
- Tất cả endpoint trong tài liệu cần `Authorization: Bearer <accessToken>`.
- JSON dùng `camelCase`; số lượng, giá và giá vốn gửi dưới dạng JSON number, không gửi chuỗi.
- Mọi response thành công dùng wrapper:

```json
{
  "succeeded": true,
  "message": "...",
  "errors": [],
  "data": {}
}
```

- Khi lỗi, kiểm tra `succeeded: false` và hiển thị `errors`. Các mã thường gặp: `400` (payload/nghiệp vụ), `401` (token), `403` (quyền store), `404` (item không tồn tại).
- Enum được đánh dấu trong tài liệu này phải gửi dạng chuỗi đúng chính tả. `ProductType` và `IngredientItemType` của API cũ hiện gửi số.

## 2. Flow đề xuất

```text
1. GET ingredients theo store
2. POST products (có thể gửi recipes ngay)
3. PUT inventory/products/{id}/inventory-settings
4. Nếu không gửi recipes lúc tạo: PUT inventory/products/{id}/recipe
5. Nhập/điều chỉnh tồn qua inventory API
6. Khi mở chi tiết: GET products/{id} + GET recipes/product/{id}
```

Không dùng `PUT /api/ingredients/{id}/quantity` cho UI kho mới: đây là endpoint cũ. Dùng `imports`, `adjustments`, `wastage` hoặc `manual-issues` để có sổ biến động tồn kho.

## 3. Tạo và đọc sản phẩm

### 3.1 Tạo món và gắn nguyên liệu trong một lần gọi

`POST /api/products`

```json
{
  "storeId": 1,
  "categoryId": 2,
  "name": "Trà đào",
  "imageUrl": null,
  "description": "Trà đào cam sả",
  "preparationTime": 5,
  "price": 35000,
  "costPrice": 0,
  "type": 2,
  "variants": [
    { "name": "L", "price": 40000, "costPrice": 0, "isDefault": true }
  ],
  "toppingIds": [7],
  "recipes": [
    { "ingredientId": 10, "quantity": 15, "capacity": 0 },
    { "ingredientId": 11, "quantity": 40, "capacity": 0 }
  ]
}
```

| Field | Bắt buộc | Ghi chú |
| --- | --- | --- |
| `storeId`, `categoryId`, `name`, `preparationTime`, `price`, `costPrice`, `type` | Có | `type`: `1 = Food`, `2 = Drink`, `3 = Combo`. |
| `imageUrl`, `description` | Không | Có thể `null`. |
| `variants` | Không | Nếu `null` hoặc rỗng, backend tạo variant mặc định. |
| `toppingIds` | Không | Các id phải thuộc store và đang active. |
| `recipes` | Không | Mỗi `ingredientId` không được trùng, thuộc store, active; `quantity` và `capacity` không âm. `quantity` dùng đúng đơn vị gốc của nguyên liệu. |

Response `data` là `ProductResponse` (mục 3.2). Product được tạo, variants/toppings/recipes được lưu cùng flow; response không chứa mảng recipes, nên lấy lại qua `GET /api/recipes/product/{productId}` khi cần render form chỉnh công thức.

### 3.2 Một API sản phẩm có đủ tồn kho

Các endpoint sau cùng trả `ProductResponse` có dữ liệu menu **và** tồn kho:

- `GET /api/products/{id}`
- `GET /api/products/store/{storeId}`
- `GET /api/products` (SystemAdmin)

Ví dụ `data` một sản phẩm:

```json
{
  "id": 20,
  "storeId": 1,
  "categoryId": 2,
  "name": "Coca Cola lon",
  "imageUrl": null,
  "description": null,
  "preparationTime": 0,
  "price": 15000,
  "costPrice": 12000,
  "type": 2,
  "isActive": true,
  "variants": [{ "id": 31, "name": "Mặc định", "price": 15000, "costPrice": 12000, "isDefault": true }],
  "toppings": [],
  "createdAt": "2026-06-23T08:00:00Z",
  "createdBy": "5",
  "updatedAt": null,
  "updatedBy": null,
  "isDeleted": false,
  "quantity": 23,
  "minimumStock": 6,
  "averageUnitCost": 12000,
  "lastImportUnitCost": 12000,
  "isTrackInventory": true,
  "inventoryDeductionMode": "ProductOnly",
  "isLowStock": false,
  "isOutOfStock": false
}
```

`isLowStock` là `true` khi đang track, `0 < quantity <= minimumStock`. `isOutOfStock` là `true` khi đang track và `quantity <= 0`.

### 3.3 Cấu hình cách trừ tồn của sản phẩm

`PUT /api/inventory/products/{productId}/inventory-settings`

```json
{
  "minimumStock": 6,
  "isTrackInventory": true,
  "inventoryDeductionMode": "ProductOnly"
}
```

Response `data`:

```json
{
  "id": 20,
  "storeId": 1,
  "name": "Coca Cola lon",
  "quantity": 23,
  "minimumStock": 6,
  "averageUnitCost": 12000,
  "lastImportUnitCost": 12000,
  "isTrackInventory": true,
  "inventoryDeductionMode": "ProductOnly",
  "isLowStock": false,
  "isOutOfStock": false
}
```

| `inventoryDeductionMode` | Dùng khi |
| --- | --- |
| `RecipeOnly` | Món pha chế, chỉ trừ các nguyên liệu theo công thức. |
| `ProductOnly` | Thành phẩm đóng gói/chai/lon, trừ trực tiếp tồn sản phẩm. |
| `Both` | Cần trừ cả thành phẩm và nguyên liệu. |

### 3.4 Chọn và chỉnh công thức nguyên liệu

Sau khi có product id, thay toàn bộ công thức bằng:

`PUT /api/inventory/products/{productId}/recipe`

```json
[
  { "ingredientId": 10, "quantity": 15 },
  { "ingredientId": 11, "quantity": 40 }
]
```

Đây là **replace-all**: FE phải gửi toàn bộ danh sách đang lưu; nguyên liệu không nằm trong payload sẽ bị deactive khỏi công thức. Response chỉ là wrapper thành công, không có `data`.

Đọc công thức để render màn chi tiết/sửa:

`GET /api/recipes/product/{productId}`

```json
{
  "succeeded": true,
  "message": "Lấy danh sách định mức nguyên liệu của sản phẩm thành công!",
  "errors": [],
  "data": [
    {
      "id": 51,
      "productId": 20,
      "ingredient": {
        "id": 10,
        "storeId": 1,
        "name": "Trà ô long",
        "itemType": 1,
        "unit": "g",
        "quantity": 850,
        "capacity": 0,
        "currentCapacity": 0,
        "isActive": true
      },
      "quantity": 15,
      "capacity": 0,
      "isActive": true,
      "createdAt": "2026-06-23T08:00:00Z",
      "createdBy": "5",
      "updatedAt": null,
      "updatedBy": null,
      "isDeleted": false
    }
  ]
}
```

Nếu cần cập nhật từng recipe cũ, dùng `PUT /api/recipes/{recipeId}` với `{ "quantity": 20, "capacity": 0 }`. Tuy nhiên màn hình quản lý công thức mới nên dùng endpoint replace-all ở trên để tránh lệch dữ liệu.

## 4. Quản lý nguyên liệu

### 4.1 Danh sách và chi tiết

- `GET /api/ingredients/store/{storeId}`: danh sách nguyên liệu của cửa hàng.
- `GET /api/ingredients/{id}`: chi tiết một nguyên liệu.
- `GET /api/ingredients`: danh sách toàn hệ thống, chỉ dành cho SystemAdmin.

Tất cả trả `IngredientResponse`; ví dụ `data`:

```json
{
  "id": 10,
  "storeId": 1,
  "name": "Trà ô long",
  "itemType": 1,
  "unit": "g",
  "quantity": 850,
  "capacity": 0,
  "currentCapacity": 0,
  "isActive": true,
  "createdAt": "2026-06-23T08:00:00Z",
  "createdBy": "5",
  "updatedAt": null,
  "updatedBy": null,
  "isDeleted": false,
  "minimumStock": 1000,
  "averageUnitCost": 120,
  "lastImportUnitCost": 125,
  "isTrackInventory": true
}
```

`itemType`: `1 = Ingredient`, `2 = ResellProduct`. Tồn, cảnh báo và giá vốn đã có ngay trong API nguyên liệu này.

### 4.2 Tạo và sửa metadata

`POST /api/ingredients`

```json
{ "storeId": 1, "name": "Trà ô long", "itemType": 1, "unit": "g", "capacity": 0 }
```

`PUT /api/ingredients/{id}`

```json
{ "name": "Trà ô long rang", "itemType": 1, "unit": "g", "capacity": 0 }
```

Cả hai endpoint trả `IngredientResponse`. Khi tạo mới, tồn là `0`; cấu hình `minimumStock`/`isTrackInventory` gọi riêng endpoint settings ở mục 4.4. Xóa mềm bằng `DELETE /api/ingredients/{id}`, response không có `data`.

### 4.3 Danh sách kho, cảnh báo và lịch sử nguyên liệu

`GET /api/inventory/ingredients?storeId={storeId}&status={all|low|out}`

`status` optional; `low` là còn hàng nhưng dưới ngưỡng, `out` là hết hàng. Response `data` là mảng có cùng dữ liệu tồn kho và thêm `isLowStock`, `isOutOfStock`.

`GET /api/inventory/ingredients/{ingredientId}/movements?from={ISO-8601}&to={ISO-8601}` trả mảng movement. Một movement có các field: `id`, `ingredientId`, `productId`, `type` (`Import`/`Export`), `reason`, `quantity`, `requestedQuantity`, `shortageQuantity`, `unitCost`, `totalCost`, `orderId`, `orderItemId`, `note`, `destinationName`, `occurredAt`.

### 4.4 Cấu hình và thay đổi tồn nguyên liệu

| Mục đích | Endpoint | Request |
| --- | --- | --- |
| Bật/tắt tracking, đặt ngưỡng | `PUT /api/inventory/ingredients/{ingredientId}/settings` | `{ "minimumStock": 1000, "isTrackInventory": true }` |
| Nhập kho | `POST /api/inventory/imports` | `{ "storeId": 1, "ingredientId": 10, "quantity": 5000, "unitCost": 125, "vendorId": 3, "note": "Nhập sáng" }` |
| Kiểm kê | `POST /api/inventory/adjustments` | `{ "storeId": 1, "ingredientId": 10, "actualQuantity": 4700, "reason": "Kiểm kê", "note": "Cân lại" }` |
| Hao hụt | `POST /api/inventory/wastage` | `{ "storeId": 1, "ingredientId": 10, "quantity": 100, "reason": "Hết hạn", "note": null }` |
| Xuất nội bộ/chuyển kho | `POST /api/inventory/manual-issues` | Xem payload bên dưới. |

`adjustments.actualQuantity` là **tồn cuối cùng thực tế**, không phải lượng chênh lệch. Nhập kho tính lại giá vốn bình quân (`averageUnitCost`). Hao hụt phải lớn hơn 0 và không vượt tồn hiện tại.

Payload xuất thủ công:

```json
{
  "storeId": 1,
  "itemType": "Ingredient",
  "itemId": 10,
  "quantity": 100,
  "reason": "InternalUse",
  "destinationName": null,
  "note": "Pha trà thử món"
}
```

`itemType`: `Ingredient` hoặc `Product`. `reason` chỉ nhận `InternalUse`, `TransferOut`, `OtherIssue`; `note` bắt buộc. Với `TransferOut`, `destinationName` bắt buộc.

Các endpoint thay đổi tồn trả object có item sau thay đổi và movement, ví dụ `POST /imports` trả:

```json
{
  "ingredient": { "id": 10, "quantity": 5850, "minimumStock": 1000, "averageUnitCost": 124.27, "isTrackInventory": true, "isLowStock": false, "isOutOfStock": false },
  "movement": { "id": 501, "ingredientId": 10, "productId": null, "type": "Import", "reason": "Purchase", "quantity": 5000, "requestedQuantity": 5000, "shortageQuantity": 0, "unitCost": 125, "totalCost": 625000, "orderId": null, "orderItemId": null, "note": "Nhập sáng", "destinationName": null, "occurredAt": "2026-06-23T08:00:00Z" }
}
```

### 4.5 Endpoint cũ (không dùng cho UI kho mới)

- `PUT /api/ingredients/{id}/quantity` — request `{ "quantity": 4700 }`; backend vẫn tạo movement điều chỉnh nhưng không có lý do/người nhận rõ ràng.
- `PUT /api/ingredients/{id}/refill` — không có body; dành cho logic capacity/refill cũ.

## 5. Quản lý tồn thành phẩm

Khi dùng `ProductOnly` hoặc `Both`, FE có thể quản lý số lượng thành phẩm:

| Mục đích | Endpoint | Request |
| --- | --- | --- |
| Danh sách | `GET /api/inventory/products?storeId={storeId}&status={all|low|out}` | — |
| Lịch sử | `GET /api/inventory/products/{productId}/movements?from=&to=` | — |
| Nhập | `POST /api/inventory/product-imports` | `{ "storeId": 1, "productId": 20, "quantity": 24, "unitCost": 12000, "note": "Nhập một thùng" }` |
| Kiểm kê | `POST /api/inventory/product-adjustments` | `{ "storeId": 1, "productId": 20, "actualQuantity": 22, "reason": "Kiểm kê", "note": null }` |
| Hao hụt | `POST /api/inventory/product-wastage` | `{ "storeId": 1, "productId": 20, "quantity": 1, "reason": "Móp lon", "note": null }` |

Response của các API này dùng `InventoryProductResponse` và `InventoryMovementResponse`; field tương ứng với phần tồn kho đã có trong `ProductResponse` ở mục 3.2.

## 6. Checklist FE

1. Sau khi tạo/sửa nguyên liệu, refresh danh sách ingredient của store.
2. Sau khi tạo product, cấu hình inventory settings rồi fetch recipe theo product id nếu cần xác thực dữ liệu đã lưu.
3. Sau mọi nhập/kiểm kê/hao hụt/xuất, dùng response trả về để cập nhật item ngay và refresh movements; không tự cộng/trừ lần nữa ở FE.
4. Với `RecipeOnly`, không hiển thị tồn sản phẩm như tồn bán được; hiển thị tồn nguyên liệu và công thức. Với `ProductOnly`, hiển thị số lượng product. Với `Both`, hiển thị cả hai.
5. Không quy đổi đơn vị ở FE khi gửi recipe; `quantity` phải cùng unit của ingredient.

Tài liệu kho/phiếu nhiều dòng chi tiết hơn: [INVENTORY_API_CONTRACT.md](INVENTORY_API_CONTRACT.md).
