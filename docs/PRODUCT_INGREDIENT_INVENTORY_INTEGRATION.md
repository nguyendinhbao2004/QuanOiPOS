# Tích hợp Product, nguyên liệu và tồn kho

Tài liệu này là contract để FE triển khai màn hình tạo món, cấu hình công thức, tồn kho và quản lý nguyên liệu. Contract phản ánh API hiện tại, bao gồm thay đổi mới: mọi API `GET /api/products...` trả kèm trạng thái tồn kho của sản phẩm.

## 1. Quy ước chung

- Base URL: URL môi trường + đường dẫn bên dưới.
- Tất cả endpoint trong tài liệu cần `Authorization: Bearer <accessToken>`.
- JSON dùng `camelCase`; số lượng, giá và giá vốn gửi dưới dạng JSON number, không gửi chuỗi.
- Trong flow kho mới, `capacity`/`currentCapacity` là field legacy. FE gửi `0` nếu API còn yêu cầu field này và không dùng để tính tồn kho.
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
6. Khi mở/sửa món: GET products/{id}/management-detail
```

Không dùng `PUT /api/ingredients/{id}/quantity` cho UI kho mới: đây là endpoint cũ. Dùng `imports`, `adjustments`, `wastage`, `manual-issues` hoặc phiếu kho `documents` để có sổ biến động tồn kho.

Tồn kho khi bán được trừ khi bếp chuyển món sang trạng thái `Ready` qua API cập nhật trạng thái order item. Nếu kho không đủ, backend trả lỗi `400`, giữ nguyên trạng thái món hiện tại và không tạo movement kho. Payment hoàn tất không còn là trigger trừ kho.

## 3. Tạo và đọc sản phẩm

### 3.0 Xin URL upload ảnh sản phẩm

`POST /api/products/image-upload-url`

```json
{
  "storeId": 1,
  "contentType": "image/jpeg"
}
```

`contentType` chỉ nhận `image/jpeg`, `image/png` hoặc `image/webp`. Backend dùng giá trị này để validate loại ảnh và chọn extension cho object key. Presigned URL được tạo cho `PUT` thẳng lên S3, không gửi `Authorization`. FE nên gửi `Content-Type` tương ứng để S3 lưu metadata ảnh, nhưng header này không còn được ký chặt trong presigned URL để tránh lỗi `403 SignatureDoesNotMatch` khi client thêm/sửa nhẹ header.

Response `data`:

```json
{
  "key": "products/1/6b5c3d4e5f6a4b3c9d8e7f0011223344.jpg",
  "imageUrl": "https://cdn.example.com/products/1/6b5c3d4e5f6a4b3c9d8e7f0011223344.jpg",
  "uploadUrl": "https://bucket.s3.ap-southeast-1.amazonaws.com/...",
  "expiresAt": "2026-06-23T08:05:00Z"
}
```

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
  ],
  "inventorySettings": {
    "minimumStock": 6,
    "isTrackInventory": true,
    "inventoryDeductionMode": "RecipeOnly"
  }
}
```

| Field | Bắt buộc | Ghi chú |
| --- | --- | --- |
| `storeId`, `categoryId`, `name`, `preparationTime`, `price`, `costPrice`, `type` | Có | `type`: `1 = Food`, `2 = Drink`, `3 = Combo`. |
| `imageUrl`, `description` | Không | Có thể `null`. |
| `variants` | Không | Nếu `null` hoặc rỗng, backend tạo variant mặc định. |
| `toppingIds` | Không | Các id phải thuộc store và đang active. |
| `recipes` | Không | Mỗi `ingredientId` không được trùng, thuộc store, active; `quantity` không âm và là lượng tiêu hao cho 1 lần bán 1 món. `capacity` là legacy, gửi `0`. `quantity` dùng đúng đơn vị gốc của nguyên liệu. |
| `inventorySettings` | Không | Khi có mặt, lưu cấu hình tồn cùng lúc tạo product. Không bao gồm tồn đầu; dùng API nhập kho để ghi nhận tồn đầu. |

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
  "isSell": true,
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

`isActive` là vòng đời bản ghi; `isSell` mới là trạng thái có thể bán trên POS. Bật/tắt bán bằng `PATCH /api/products/{id}/is-sell` với payload `{ "isSell": true }`. Response trả `ProductResponse` mới nhất.

Khi order item của sản phẩm chuyển sang `Ready`, backend tự áp dụng `inventoryDeductionMode`:

- `RecipeOnly`: trừ nguyên liệu theo công thức active.
- `ProductOnly`: trừ 1 đơn vị tồn thành phẩm.
- `Both`: trừ cả 1 đơn vị tồn thành phẩm và nguyên liệu theo công thức.

Nếu có variant/topping, backend cộng thêm định mức điều chỉnh của variant và công thức topping trước khi kiểm tra tồn.

### 3.3 Detail dành cho form quản trị

`GET /api/products/{id}/management-detail` trả trong một lần gọi cả `product` (toàn bộ `ProductResponse`) và `recipes` (công thức active kèm nguyên liệu). Endpoint yêu cầu đồng thời quyền xem sản phẩm và quyền xem công thức; thiếu một quyền trả `403`.

```json
{
  "product": { "id": 20, "isActive": true, "isSell": true, "quantity": 23 },
  "recipes": [
    { "id": 51, "productId": 20, "ingredient": { "id": 10, "name": "Trà ô long", "unit": "g", "quantity": 850 }, "quantity": 15, "capacity": 0 }
  ]
}
```

### 3.4 Cấu hình cách trừ tồn của sản phẩm

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

### 3.5 Chọn và chỉnh công thức nguyên liệu

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

### 3.6 Cập nhật món và cấu hình tồn cùng lúc

`PUT /api/products/{id}` giữ nguyên các field product hiện có và nhận thêm `inventorySettings` optional:

```json
{
  "categoryId": 2,
  "name": "Coca Cola lon",
  "imageUrl": null,
  "description": null,
  "preparationTime": 0,
  "price": 15000,
  "costPrice": 12000,
  "type": 2,
  "variants": [],
  "inventorySettings": {
    "minimumStock": 8,
    "isTrackInventory": true,
    "inventoryDeductionMode": "ProductOnly"
  }
}
```

Nếu bỏ `inventorySettings`, backend giữ nguyên cấu hình tồn kho hiện tại. Nếu có mặt, phần product, variants và inventory settings được cập nhật trong một transaction; response là `ProductResponse` mới nhất.

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
| Xuất nhanh một dòng | `POST /api/inventory/manual-issues` | Xem payload bên dưới. |
| Nhập/xuất nhiều dòng | `POST /api/inventory/documents` | Xem mục 6. |

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
| Xuất nhanh một dòng | `POST /api/inventory/manual-issues` | `{ "storeId": 1, "itemType": "Product", "itemId": 20, "quantity": 2, "reason": "TransferOut", "destinationName": "Quán Ơi - Chi nhánh 2", "note": "Điều chuyển" }` |
| Nhập/xuất nhiều dòng | `POST /api/inventory/documents` | Xem mục 6. |

Response của các API này dùng `InventoryProductResponse` và `InventoryMovementResponse`; field tương ứng với phần tồn kho đã có trong `ProductResponse` ở mục 3.2.

## 6. Phiếu kho nhiều dòng

FE dùng nhóm `documents` khi cần màn phiếu nhập/xuất nhiều item, có trạng thái nháp, sửa phiếu, hủy phiếu và hoàn thành phiếu. Phiếu `Draft` chưa thay đổi tồn kho; chỉ khi gọi `POST /api/inventory/documents/{id}/complete`, backend mới cập nhật tồn và tạo movement ledger.

### 6.1 Endpoint phiếu kho

| Mục đích | Endpoint | Ghi chú |
| --- | --- | --- |
| Tạo phiếu nháp | `POST /api/inventory/documents` | Tạo phiếu nhập hoặc xuất, chưa đổi tồn. |
| Danh sách phiếu | `GET /api/inventory/documents?storeId={storeId}&type={Import|ManualIssue}&status={Draft|Completed|Cancelled}&from={ISO-8601}&to={ISO-8601}&pageIndex=1&pageSize=20` | `type`, `status`, `from`, `to` optional. |
| Chi tiết phiếu | `GET /api/inventory/documents/{id}` | Trả header và toàn bộ dòng phiếu. |
| Sửa phiếu nháp | `PUT /api/inventory/documents/{id}` | Payload giống tạo phiếu, replace-all items. |
| Hoàn thành phiếu | `POST /api/inventory/documents/{id}/complete` | Cập nhật tồn và tạo movements. |
| Hủy phiếu nháp | `POST /api/inventory/documents/{id}/cancel` | Chỉ hủy được phiếu `Draft`. |

Enum phiếu kho:

| Field | Giá trị |
| --- | --- |
| `type` | `Import`, `ManualIssue` |
| `status` | `Draft`, `Completed`, `Cancelled` |
| `itemType` | `Ingredient`, `Product` |
| `reason` cho phiếu xuất | `InternalUse`, `TransferOut`, `OtherIssue` |

### 6.2 Tạo phiếu nhập

`POST /api/inventory/documents`

```json
{
  "storeId": 1,
  "type": "Import",
  "vendorId": 3,
  "reason": null,
  "destinationName": null,
  "note": "Nhập hàng đầu tuần",
  "items": [
    { "itemType": "Ingredient", "itemId": 10, "quantity": 5000, "unitCost": 125 },
    { "itemType": "Product", "itemId": 20, "quantity": 24, "unitCost": 12000 }
  ]
}
```

Với phiếu nhập, `vendorId` có thể `null` hoặc là vendor active thuộc store. `reason` và `destinationName` gửi `null`. Khi complete, backend tạo movement `Import` với reason `Purchase`, cập nhật tồn và giá vốn bình quân cho từng dòng.

### 6.3 Tạo phiếu xuất

`POST /api/inventory/documents`

```json
{
  "storeId": 1,
  "type": "ManualIssue",
  "vendorId": null,
  "reason": "TransferOut",
  "destinationName": "Quán Ơi - Chi nhánh 2",
  "note": "Điều chuyển cuối ngày",
  "items": [
    { "itemType": "Ingredient", "itemId": 10, "quantity": 500, "unitCost": 0 },
    { "itemType": "Product", "itemId": 20, "quantity": 2, "unitCost": 0 }
  ]
}
```

Với phiếu xuất, `vendorId` phải là `null`; `reason` bắt buộc là `InternalUse`, `TransferOut` hoặc `OtherIssue`. Nếu `reason = TransferOut`, `destinationName` bắt buộc. `note` là ghi chú chung của cả phiếu. `unitCost` trong items chỉ để giữ schema đồng nhất; khi complete phiếu xuất, backend dùng `averageUnitCost` hiện tại của item để ghi giá vốn xuất.

### 6.4 Response chi tiết phiếu

Các API create/detail/update/complete trả `InventoryDocumentResponse` trong `data`:

```json
{
  "id": 101,
  "storeId": 1,
  "documentCode": "XK-000001",
  "type": "ManualIssue",
  "status": "Draft",
  "vendorId": null,
  "reason": "TransferOut",
  "destinationName": "Quán Ơi - Chi nhánh 2",
  "note": "Điều chuyển cuối ngày",
  "totalAmount": 0,
  "createdAt": "2026-06-23T08:00:00Z",
  "completedAt": null,
  "vendor": null,
  "items": [
    {
      "id": 1001,
      "itemType": "Ingredient",
      "ingredientId": 10,
      "productId": null,
      "itemName": "Trà ô long",
      "unit": "g",
      "currentQuantity": 850,
      "quantity": 500,
      "unitCost": 0,
      "lineTotal": 0
    },
    {
      "id": 1002,
      "itemType": "Product",
      "ingredientId": null,
      "productId": 20,
      "itemName": "Coca Cola lon",
      "unit": "cái",
      "currentQuantity": 23,
      "quantity": 2,
      "unitCost": 0,
      "lineTotal": 0
    }
  ]
}
```

`documentCode` có prefix `NH-` cho phiếu nhập và `XK-` cho phiếu xuất. `currentQuantity` là tồn hiện tại tại thời điểm đọc response, dùng để FE hiển thị tham khảo; không tự trừ/cộng trên FE.

### 6.5 Cập nhật và hoàn thành phiếu

`PUT /api/inventory/documents/{id}` chỉ áp dụng cho phiếu `Draft`. Payload giống `POST /api/inventory/documents` và là replace-all: FE phải gửi lại toàn bộ danh sách dòng muốn giữ; dòng không còn trong payload sẽ bị bỏ khỏi phiếu.

Không được đổi `storeId` hoặc `type` của phiếu khi update. Nếu cần đổi từ nhập sang xuất hoặc ngược lại, FE hủy phiếu nháp cũ và tạo phiếu mới.

`POST /api/inventory/documents/{id}/complete` khóa phiếu, cập nhật tồn, tạo movements có gắn `inventoryDocumentId` và `inventoryDocumentItemId`. Phiếu `Completed` không sửa hoặc hủy được; nếu sai số sau khi hoàn thành, tạo phiếu điều chỉnh/nhập/xuất mới.

### 6.6 Lỗi thiếu tồn khi hoàn thành phiếu xuất

Khi complete phiếu `ManualIssue`, backend kiểm tra toàn bộ dòng trước khi trừ tồn. Nếu có dòng thiếu tồn, backend trả `400`, không cập nhật tồn và không tạo movement.

Response lỗi:

```json
{
  "succeeded": false,
  "message": "Không đủ tồn kho để hoàn thành phiếu.",
  "errors": [],
  "data": {
    "shortages": [
      {
        "itemType": "Ingredient",
        "itemId": 10,
        "itemName": "Trà ô long",
        "unit": "g",
        "currentQuantity": 300,
        "requestedQuantity": 500,
        "shortageQuantity": 200
      }
    ]
  }
}
```

FE dùng cặp `itemType + itemId` để highlight đúng dòng thiếu tồn trong form.

### 6.7 Khi nào dùng API lẻ và khi nào dùng phiếu

| Nhu cầu UI | API nên dùng |
| --- | --- |
| Nhập nhanh một nguyên liệu | `POST /api/inventory/imports` |
| Nhập nhanh một thành phẩm | `POST /api/inventory/product-imports` |
| Xuất nhanh một nguyên liệu hoặc thành phẩm | `POST /api/inventory/manual-issues` |
| Hao hụt một item | `wastage` hoặc `product-wastage` |
| Kiểm kê đưa tồn về số thực tế | `adjustments` hoặc `product-adjustments` |
| Nhập/xuất nhiều item, cần phiếu nháp/duyệt/hoàn thành | `POST /api/inventory/documents` và `complete` |

## 7. Checklist FE

1. Sau khi tạo/sửa nguyên liệu, refresh danh sách ingredient của store.
2. Sau khi tạo product, cấu hình inventory settings rồi fetch recipe theo product id nếu cần xác thực dữ liệu đã lưu.
3. Sau mọi thao tác lẻ nhập/kiểm kê/hao hụt/xuất, dùng response trả về để cập nhật item ngay và refresh movements; không tự cộng/trừ lần nữa ở FE.
4. Với phiếu kho, tạo/update `Draft` không làm đổi tồn. Chỉ sau `complete` mới refresh tồn, danh sách movements và trạng thái phiếu.
5. Khi complete phiếu xuất bị lỗi thiếu tồn, dùng `data.shortages` để highlight row, không xóa dữ liệu đang nhập của người dùng.
6. Với `RecipeOnly`, không hiển thị tồn sản phẩm như tồn bán được; hiển thị tồn nguyên liệu và công thức. Với `ProductOnly`, hiển thị số lượng product. Với `Both`, hiển thị cả hai.
7. Không quy đổi đơn vị ở FE khi gửi recipe hoặc dòng phiếu; `quantity` phải cùng unit của ingredient/product đang hiển thị.

Tài liệu kho/phiếu nhiều dòng chi tiết hơn: [INVENTORY_API_CONTRACT.md](INVENTORY_API_CONTRACT.md).
