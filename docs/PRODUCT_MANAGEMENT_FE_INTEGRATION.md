# Product management API cho FE

Tài liệu này mô tả màn quản lý một sản phẩm sau refactor: thông tin sản phẩm, variants, công thức nguyên liệu, định lượng riêng theo variant, topping và tồn kho. Mục tiêu là FE có thể mở form, chỉnh nhiều phần, rồi lưu một lần bằng aggregate API.

## 1. Quy ước chung

- Tất cả endpoint yêu cầu `Authorization: Bearer <accessToken>`.
- JSON dùng `camelCase`.
- Decimal gửi bằng JSON number, không gửi chuỗi tiền tệ.
- Response thành công luôn dùng wrapper:

```json
{
  "succeeded": true,
  "message": "Thông báo",
  "errors": [],
  "data": {}
}
```

- Response lỗi có `succeeded: false`, FE đọc `errors`.
- Mã lỗi thường gặp:
  - `400`: payload sai, dữ liệu không thuộc store, trùng tên variant, tồn không đủ.
  - `401`: token thiếu hoặc không hợp lệ.
  - `403`: tài khoản không có quyền trên store.
  - `404`: product/variant/topping/ingredient không tồn tại.

## 2. Mô hình nghiệp vụ

### 2.1 Product và variant

- `product` là món/hàng chính trên menu.
- `variant` là lựa chọn bán của product, ví dụ size M/L, chai 330ml/1.5L.
- Variant không lưu bằng JSON; backend lưu bảng riêng để order, kho, báo cáo và công thức query được ổn định.

### 2.2 Cách trừ kho

`inventoryDeductionMode` nhận/trả dạng string:

| Mode | Dùng khi | Khi bán sẽ trừ |
| --- | --- | --- |
| `RecipeOnly` | Món pha chế | Nguyên liệu theo công thức product + điều chỉnh variant + topping |
| `ProductOnly` | Hàng bán lại có tồn chung | 1 đơn vị tồn product |
| `VariantOnly` | Hàng bán lại có tồn riêng từng variant | 1 đơn vị tồn variant được chọn |
| `Both` | Trường hợp đặc biệt | 1 đơn vị tồn product và nguyên liệu |

Gợi ý FE:

- Món pha chế: chọn `RecipeOnly`, cấu hình `recipes`, có thể cấu hình `recipeAdjustments` cho từng variant.
- Hàng đóng gói chung tồn: chọn `ProductOnly`, nhập tồn product qua API inventory product.
- Hàng đóng gói tồn riêng size/loại: chọn `VariantOnly`, nhập tồn từng variant qua API inventory variant.

## 3. Mở màn quản lý sản phẩm

### GET `/api/products/{id}/management-detail`

Endpoint này là nguồn dữ liệu chính cho form chỉnh sửa sản phẩm.

Response `data`:

```json
{
  "product": {
    "id": 20,
    "storeId": 1,
    "categoryId": 2,
    "name": "Trà đào",
    "imageUrl": null,
    "description": "Trà đào cam sả",
    "preparationTime": 5,
    "price": 35000,
    "costPrice": 0,
    "type": 2,
    "isActive": true,
    "isSell": true,
    "variants": [
      {
        "id": 31,
        "name": "M",
        "price": 35000,
        "costPrice": 0,
        "isDefault": true,
        "quantity": 0,
        "minimumStock": 0,
        "averageUnitCost": 0,
        "lastImportUnitCost": 0,
        "isTrackInventory": false,
        "isLowStock": false,
        "isOutOfStock": false
      }
    ],
    "toppings": [
      { "id": 7, "name": "Trân châu", "price": 5000 }
    ],
    "quantity": 0,
    "minimumStock": 0,
    "averageUnitCost": 0,
    "lastImportUnitCost": 0,
    "isTrackInventory": true,
    "inventoryDeductionMode": "RecipeOnly",
    "isLowStock": false,
    "isOutOfStock": false
  },
  "variants": [
    {
      "id": 31,
      "name": "M",
      "price": 35000,
      "costPrice": 0,
      "isDefault": true,
      "isActive": true,
      "quantity": 0,
      "minimumStock": 0,
      "averageUnitCost": 0,
      "lastImportUnitCost": 0,
      "isTrackInventory": false,
      "isLowStock": false,
      "isOutOfStock": false
    }
  ],
  "recipes": [
    {
      "id": 51,
      "productId": 20,
      "ingredientId": 10,
      "ingredientName": "Trà ô long",
      "ingredientUnit": "g",
      "ingredientQuantity": 850,
      "quantity": 15,
      "capacity": 0,
      "isActive": true
    }
  ],
  "variantRecipeAdjustments": [
    {
      "id": 101,
      "variantId": 32,
      "ingredientId": 10,
      "ingredientName": "Trà ô long",
      "ingredientUnit": "g",
      "quantityDelta": 5,
      "isActive": true
    }
  ],
  "toppings": [
    {
      "id": 70,
      "toppingId": 7,
      "name": "Trân châu",
      "price": 5000,
      "isActive": true
    }
  ]
}
```

Lưu ý:

- `product.variants` là response public menu đã có từ trước.
- `variants` ở cấp ngoài là danh sách đầy đủ hơn cho form quản trị, có `isActive`.
- FE nên render mặc định các item `isActive: true`. Item inactive có thể dùng để hiển thị lịch sử nếu cần, nhưng không nên cho chọn bán mới.

## 4. Lưu toàn bộ form quản lý

### PUT `/api/products/{id}/management-detail`

Đây là endpoint chính để lưu màn quản lý một sản phẩm.

Behavior:

- Cập nhật thông tin product.
- Replace-all variants, recipes, toppings và recipe adjustments.
- Bản ghi bị bỏ khỏi payload sẽ `deactivate`, không hard delete.
- Variant mới gửi `id: null` hoặc bỏ `id`.
- Variant cũ gửi đúng `id`.
- Chỉ được có tối đa một variant `isDefault: true`.
- `ingredientId` và `toppingId` phải thuộc cùng store với product.

Request:

```json
{
  "categoryId": 2,
  "name": "Trà đào",
  "imageUrl": null,
  "description": "Trà đào cam sả",
  "preparationTime": 5,
  "price": 35000,
  "costPrice": 0,
  "type": 2,
  "variants": [
    {
      "id": 31,
      "name": "M",
      "price": 35000,
      "costPrice": 0,
      "isDefault": true,
      "minimumStock": 0,
      "isTrackInventory": false,
      "recipeAdjustments": []
    },
    {
      "id": null,
      "name": "L",
      "price": 40000,
      "costPrice": 0,
      "isDefault": false,
      "minimumStock": 0,
      "isTrackInventory": false,
      "recipeAdjustments": [
        { "id": null, "ingredientId": 10, "quantityDelta": 5 },
        { "id": null, "ingredientId": 11, "quantityDelta": 10 }
      ]
    }
  ],
  "recipes": [
    { "ingredientId": 10, "quantity": 15, "capacity": 0 },
    { "ingredientId": 11, "quantity": 40, "capacity": 0 }
  ],
  "toppingIds": [7, 8],
  "inventorySettings": {
    "minimumStock": 0,
    "isTrackInventory": true,
    "inventoryDeductionMode": "RecipeOnly"
  }
}
```

Response:

- `data` giống `GET /api/products/{id}/management-detail`.

FE nên làm:

- Sau khi save thành công, replace toàn bộ local state bằng `data`.
- Nếu người dùng xóa variant khỏi form, chỉ cần không gửi variant đó trong `variants`.
- Nếu người dùng xóa nguyên liệu khỏi công thức, không gửi dòng đó trong `recipes`.
- Nếu người dùng xóa topping khỏi sản phẩm, không gửi id đó trong `toppingIds`.

## 5. Endpoint thao tác từng phần

Các endpoint dưới đây phù hợp khi FE muốn auto-save từng tab hoặc từng phần nhỏ. Nếu đang có nút “Lưu toàn bộ”, ưu tiên dùng `PUT /api/products/{id}/management-detail`.

### 5.1 Cập nhật variants của product

`PUT /api/products/{id}/variants`

Request:

```json
{
  "variants": [
    {
      "id": 31,
      "name": "M",
      "price": 35000,
      "costPrice": 0,
      "isDefault": true,
      "minimumStock": 0,
      "isTrackInventory": false
    },
    {
      "id": null,
      "name": "L",
      "price": 40000,
      "costPrice": 0,
      "isDefault": false,
      "minimumStock": 0,
      "isTrackInventory": false
    }
  ]
}
```

Response `data` là mảng `ProductManagementVariantResponse`:

```json
[
  {
    "id": 31,
    "name": "M",
    "price": 35000,
    "costPrice": 0,
    "isDefault": true,
    "isActive": true,
    "quantity": 0,
    "minimumStock": 0,
    "averageUnitCost": 0,
    "lastImportUnitCost": 0,
    "isTrackInventory": false,
    "isLowStock": false,
    "isOutOfStock": false
  }
]
```

### 5.2 Cập nhật topping được phép chọn cho product

`PUT /api/products/{id}/toppings`

Request:

```json
{
  "toppingIds": [7, 8]
}
```

Response `data`:

```json
[
  {
    "id": 70,
    "toppingId": 7,
    "name": "Trân châu",
    "price": 5000,
    "isActive": true
  }
]
```

### 5.3 Cập nhật công thức nền của product

`PUT /api/products/{id}/recipe`

Request là mảng:

```json
[
  { "ingredientId": 10, "quantity": 15 },
  { "ingredientId": 11, "quantity": 40 }
]
```

Response:

```json
{
  "succeeded": true,
  "message": "Cập nhật công thức món thành công.",
  "errors": []
}
```

Alias cũ vẫn dùng được:

- `PUT /api/inventory/products/{productId}/recipe`

### 5.4 Cập nhật điều chỉnh nguyên liệu theo variant

`PUT /api/product-variants/{variantId}/recipe-adjustments`

Request là mảng:

```json
[
  { "ingredientId": 10, "quantityDelta": 5 },
  { "ingredientId": 11, "quantityDelta": 10 }
]
```

Ý nghĩa:

- `quantityDelta > 0`: variant dùng thêm nguyên liệu so với công thức nền.
- `quantityDelta < 0`: variant dùng ít hơn công thức nền.
- `quantityDelta = 0`: không nên gửi, FE nên bỏ dòng này.

Alias cũ vẫn dùng được:

- `PUT /api/inventory/product-variants/{variantId}/recipe-adjustments`

## 6. Quản lý tồn kho product và variant

### 6.1 Cấu hình tồn kho product

`PUT /api/inventory/products/{productId}/inventory-settings`

Request:

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
  "name": "Coca Cola",
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

### 6.2 Nhập tồn product

`POST /api/inventory/product-imports`

```json
{
  "storeId": 1,
  "productId": 20,
  "quantity": 24,
  "unitCost": 9000,
  "note": "Nhập đầu kỳ"
}
```

### 6.3 Điều chỉnh tồn product

`POST /api/inventory/product-adjustments`

```json
{
  "storeId": 1,
  "productId": 20,
  "actualQuantity": 22,
  "reason": "Kiểm kê",
  "note": "Lệch 2 lon"
}
```

### 6.4 Ghi nhận hao hụt product

`POST /api/inventory/product-wastage`

```json
{
  "storeId": 1,
  "productId": 20,
  "quantity": 1,
  "reason": "Móp lon",
  "note": "Không bán được"
}
```

### 6.5 Nhập tồn variant

Dùng khi product có `inventoryDeductionMode: "VariantOnly"`.

`POST /api/inventory/variant-imports`

Request:

```json
{
  "storeId": 1,
  "variantId": 31,
  "quantity": 12,
  "unitCost": 9000,
  "note": "Nhập Coca 330ml"
}
```

Response `data`:

```json
{
  "variant": {
    "id": 31,
    "productId": 20,
    "storeId": 1,
    "productName": "Coca Cola",
    "variantName": "330ml",
    "quantity": 12,
    "minimumStock": 3,
    "averageUnitCost": 9000,
    "lastImportUnitCost": 9000,
    "isTrackInventory": true,
    "isLowStock": false,
    "isOutOfStock": false
  },
  "movement": {
    "id": 1001,
    "ingredientId": null,
    "productId": 20,
    "type": "Import",
    "reason": "Purchase",
    "quantity": 12,
    "requestedQuantity": 12,
    "shortageQuantity": 0,
    "unitCost": 9000,
    "totalCost": 108000,
    "orderId": null,
    "orderItemId": null,
    "note": "Nhập Coca 330ml; VariantId=31",
    "destinationName": null,
    "occurredAt": "2026-06-24T03:30:00Z"
  }
}
```

### 6.6 Điều chỉnh tồn variant

`POST /api/inventory/variant-adjustments`

```json
{
  "storeId": 1,
  "variantId": 31,
  "actualQuantity": 10,
  "reason": "Kiểm kê",
  "note": "Lệch tồn"
}
```

### 6.7 Ghi nhận hao hụt variant

`POST /api/inventory/variant-wastage`

```json
{
  "storeId": 1,
  "variantId": 31,
  "quantity": 1,
  "reason": "Hư hỏng",
  "note": "Rách bao bì"
}
```

## 7. Flow FE đề xuất

### 7.1 Tạo món pha chế

1. FE lấy danh sách category, ingredient, topping theo store.
2. FE gọi `POST /api/products` hoặc tạo product cơ bản trước.
3. FE mở form bằng `GET /api/products/{id}/management-detail`.
4. Người dùng chỉnh variants, recipes, toppings.
5. FE gọi `PUT /api/products/{id}/management-detail`.
6. Khi bán và bếp chuyển món sang trạng thái chuẩn bị/ready theo flow hiện tại, backend tự trừ nguyên liệu.

### 7.2 Tạo hàng bán lại tồn chung

1. Set `inventoryDeductionMode: "ProductOnly"`.
2. Variant chỉ dùng để hiển thị lựa chọn bán, không bật `isTrackInventory` variant.
3. Nhập tồn qua `POST /api/inventory/product-imports`.
4. Khi bán, backend trừ `product.quantity`.

### 7.3 Tạo hàng bán lại tồn riêng từng variant

1. Set `inventoryDeductionMode: "VariantOnly"`.
2. Mỗi variant bật `isTrackInventory: true` nếu cần kiểm tồn.
3. Nhập tồn từng variant qua `POST /api/inventory/variant-imports`.
4. Khi bán, order item phải có `variantId`; backend trừ tồn của variant đó.

### 7.4 Gửi `variantId` khi tạo order

- `ProductOnly`: FE nên gửi `variantId: null` nếu sản phẩm không dùng variant để định giá. Nếu FE gửi một `variantId` cũ nhưng sản phẩm không còn active variant nào, backend sẽ bỏ qua và dùng giá product.
- `ProductOnly` có active variant: nếu FE gửi `variantId`, id đó phải active và thuộc product; backend dùng giá/cost của variant.
- `RecipeOnly` và `Both`: `variantId` là optional, nhưng nếu gửi thì phải active và thuộc product vì variant có thể ảnh hưởng giá và định lượng nguyên liệu.
- `VariantOnly`: FE bắt buộc gửi `variantId`; backend dùng variant đó để trừ tồn.

## 8. Validation FE nên làm trước khi gọi API

- `name` product không rỗng.
- `price`, `costPrice`, `minimumStock`, `quantity`, `unitCost` không âm.
- `preparationTime` không âm.
- Variant name không trùng nhau trong cùng form.
- Chỉ một variant default.
- Với `RecipeOnly`, nên có ít nhất một dòng `recipes`.
- Với `ProductOnly`, order item nên để `variantId: null` nếu không chọn variant bán cụ thể.
- Với `VariantOnly`, mỗi item bán nên bắt buộc chọn variant.
- Không gửi `quantityDelta: 0` nếu không có ý nghĩa nghiệp vụ.

## 9. Backward compatibility

Các endpoint cũ vẫn còn dùng được:

- `POST /api/products`
- `PUT /api/products/{id}`
- `GET /api/product-variants/product/{productId}`
- `POST /api/product-variants`
- `PUT /api/product-variants/{id}`
- `GET /api/product-toppings/product/{productId}`
- `POST /api/product-toppings`
- `DELETE /api/product-toppings/{id}`
- `PUT /api/inventory/products/{productId}/recipe`
- `PUT /api/inventory/product-variants/{variantId}/recipe-adjustments`
- `PUT /api/inventory/toppings/{toppingId}/recipe`

FE mới nên ưu tiên API aggregate trong tài liệu này để tránh lệch state giữa nhiều tab của form.
