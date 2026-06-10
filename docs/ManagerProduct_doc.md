Tất cả API bên dưới yêu cầu JWT:
Authorization: Bearer <accessToken>
Content-Type: application/json
Response chung:
{
  "succeeded": true,
  "message": "Thao tác thành công",
  "data": {},
  "errors": []
}
Response lỗi:
{
  "succeeded": false,
  "message": null,
  "data": null,
  "errors": ["Nội dung lỗi"]
}
HTTP status thường gặp: 200, 201, 400, 401, 403, 404, 500.
Enum gửi dưới dạng số:
Enum	Giá trị
ProductType.Food	1
ProductType.Drink	2
ProductType.Combo	3
IngredientItemType.Ingredient	1
IngredientItemType.ResellProduct	2

Flow tạo sản phẩm
1. Lấy dữ liệu phụ trợ
Frontend nên gọi song song:
GET /api/categories/store/{storeId}
GET /api/toppings/store/{storeId}
GET /api/ingredients/store/{storeId}
Ba API trả danh sách danh mục, topping và nguyên liệu thuộc đúng cửa hàng.
2. Tạo sản phẩm hoàn chỉnh
POST /api/products
Request:
{
  "storeId": 5,
  "categoryId": 12,
  "name": "Trà sữa truyền thống",
  "imageUrl": "https://example.com/tra-sua.jpg",
  "description": "Trà sữa vị truyền thống",
  "preparationTime": 5,
  "price": 30000,
  "costPrice": 14000,
  "type": 2,
  "variants": [
    {
      "name": "Size M",
      "price": 30000,
      "costPrice": 14000,
      "isDefault": true
    },
    {
      "name": "Size L",
      "price": 35000,
      "costPrice": 16500,
      "isDefault": false
    }
  ],
  "toppingIds": [3, 4],
  "recipes": [
    {
      "ingredientId": 21,
      "quantity": 20,
      "capacity": 50
    },
    {
      "ingredientId": 22,
      "quantity": 10,
      "capacity": 30
    }
  ]
}
variants, toppingIds, recipes có thể là null hoặc [].
Nếu không truyền variant, backend tự tạo variant mặc định dựa trên price và costPrice.
Response 201:
{
  "succeeded": true,
  "message": "Thêm sản phẩm thành công!",
  "data": {
    "id": 101,
    "storeId": 5,
    "categoryId": 12,
    "name": "Trà sữa truyền thống",
    "imageUrl": "https://example.com/tra-sua.jpg",
    "description": "Trà sữa vị truyền thống",
    "preparationTime": 5,
    "price": 30000,
    "costPrice": 14000,
    "type": 2,
    "isActive": true,
    "variants": [
      {
        "id": 201,
        "name": "Size M",
        "price": 30000,
        "costPrice": 14000,
        "isDefault": true
      }
    ],
    "toppings": [
      {
        "id": 3,
        "name": "Trân châu",
        "price": 5000
      }
    ],
    "createdAt": "2026-06-10T10:00:00Z",
    "createdBy": "1",
    "updatedAt": null,
    "updatedBy": null,
    "isDeleted": false
  },
  "errors": []
}
Điều kiện:
Category, topping và ingredient phải thuộc cùng storeId.
Giá, giá vốn, thời gian chuẩn bị và capacity không được âm.
Không trùng tên sản phẩm trong store.
Không trùng tên variant.
Không trùng ingredient trong recipes.
Quyền tạo sản phẩm: permission 20.
Product API
Method	Endpoint	Chức năng
GET	/api/products/store/{storeId}	Danh sách sản phẩm của store
GET	/api/products/{id}	Chi tiết sản phẩm
POST	/api/products	Tạo sản phẩm
PUT	/api/products/{id}	Cập nhật sản phẩm
PATCH	/api/products/{id}/is-sell	Bật/tắt bán
DELETE	/api/products/{id}	Ngừng hoạt động sản phẩm
GET	/api/products	Toàn hệ thống, chỉ System Admin

Cập nhật sản phẩm:
PUT /api/products/101
{
  "categoryId": 12,
  "name": "Trà sữa truyền thống mới",
  "imageUrl": "https://example.com/new.jpg",
  "description": "Mô tả mới",
  "preparationTime": 7,
  "price": 32000,
  "costPrice": 15000,
  "type": 2
}
Bật/tắt bán:
PATCH /api/products/101/is-sell
{
  "isSell": false
}
Lưu ý: ProductResponse hiện chưa trả field isSell, dù entity có field này. Frontend sẽ không đọc lại được trạng thái vừa cập nhật từ API get product.
Variant API
Method	Endpoint	Chức năng
GET	/api/product-variants/product/{productId}	Variant của sản phẩm
POST	/api/product-variants	Thêm nhiều variant
PUT	/api/product-variants/{id}	Sửa variant
GET	/api/product-variants	Toàn hệ thống

Thêm variant:
{
  "productId": 101,
  "variants": [
    {
      "name": "Size XL",
      "price": 40000,
      "costPrice": 19000,
      "isDefault": false
    }
  ]
}
Sửa variant:
{
  "name": "Size lớn",
  "price": 38000,
  "costPrice": 18000,
  "isDefault": true
}
Hiện chưa có API xóa variant.
Topping CRUD
Method	Endpoint
GET	/api/toppings/store/{storeId}
GET	/api/toppings/{id}
POST	/api/toppings
PUT	/api/toppings/{id}
DELETE	/api/toppings/{id}

Tạo topping:
{
  "storeId": 5,
  "name": "Trân châu đen",
  "price": 5000,
  "costPrice": 2000,
  "imageUrl": "https://example.com/topping.jpg"
}
Sửa topping:
{
  "name": "Trân châu đen",
  "price": 6000,
  "costPrice": 2500,
  "imageUrl": "https://example.com/topping-new.jpg"
}
Response data:
{
  "id": 3,
  "storeId": 5,
  "name": "Trân châu đen",
  "price": 5000,
  "costPrice": 2000,
  "imageUrl": "https://example.com/topping.jpg",
  "isActive": true,
  "createdAt": "2026-06-10T10:00:00Z",
  "createdBy": "1",
  "updatedAt": null,
  "updatedBy": null,
  "isDeleted": false
}
Gắn topping vào sản phẩm
Method	Endpoint
GET	/api/product-toppings/product/{productId}
POST	/api/product-toppings
DELETE	/api/product-toppings/{productToppingId}

Gắn topping:
{
  "productId": 101,
  "toppingIds": [3, 4, 5]
}
Response:
{
  "id": 301,
  "productId": 101,
  "toppingId": 3
}
Khi xóa phải dùng productToppingId, không phải toppingId.
Nguyên liệu CRUD
Method	Endpoint
GET	/api/ingredients/store/{storeId}
GET	/api/ingredients/{id}
POST	/api/ingredients
PUT	/api/ingredients/{id}
PUT	/api/ingredients/{id}/quantity
PUT	/api/ingredients/{id}/refill
DELETE	/api/ingredients/{id}

Tạo nguyên liệu:
{
  "storeId": 5,
  "name": "Sữa tươi",
  "itemType": 1,
  "unit": "chai",
  "capacity": 1000
}
Sửa thông tin:
{
  "name": "Sữa tươi không đường",
  "itemType": 1,
  "unit": "chai",
  "capacity": 1000
}
Cập nhật số lượng tồn:
PUT /api/ingredients/21/quantity
{
  "quantity": 20
}
Refill một đơn vị:
PUT /api/ingredients/21/refill
Không có request body. Backend giảm quantity đi 1 và đặt:
currentCapacity = capacity
Response nguyên liệu:
{
  "id": 21,
  "storeId": 5,
  "name": "Sữa tươi",
  "itemType": 1,
  "unit": "chai",
  "quantity": 20,
  "capacity": 1000,
  "currentCapacity": 1000,
  "isActive": true,
  "createdAt": "2026-06-10T10:00:00Z",
  "createdBy": "1",
  "updatedAt": null,
  "updatedBy": null,
  "isDeleted": false
}
Công thức sản phẩm
Method	Endpoint
GET	/api/recipes/product/{productId}
GET	/api/recipes/{id}
POST	/api/recipes
PUT	/api/recipes/{id}
DELETE	/api/recipes/{id}

Thêm nguyên liệu vào công thức:
{
  "productId": 101,
  "ingredientId": 21,
  "quantity": 20,
  "capacity": 50
}
Sửa định mức:
{
  "quantity": 25,
  "capacity": 60
}
Response:
{
  "id": 401,
  "productId": 101,
  "ingredientId": 21,
  "quantity": 20,
  "capacity": 50,
  "isActive": true,
  "createdAt": "2026-06-10T10:00:00Z",
  "createdBy": "1",
  "updatedAt": null,
  "updatedBy": null,
  "isDeleted": false
}
Category CRUD
Method	Endpoint
GET	/api/categories/store/{storeId}
GET	/api/categories/{id}
POST	/api/categories
PUT	/api/categories/{id}
DELETE	/api/categories/{id}

Tạo:
{
  "storeId": 5,
  "name": "Trà sữa"
}
Sửa:
{
  "name": "Đồ uống"
}