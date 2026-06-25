1. Xem danh sách tồn nguyên liệu
GET /api/inventory/ingredients?storeId={storeId}&status={all|low|out} ở [InventoryController.cs (line 51)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:51)
Mục đích:
Lấy danh sách tồn của toàn bộ nguyên liệu trong một cửa hàng.
Đây là API chính để render màn “tồn kho nguyên liệu”.
Query params:
storeId: bắt buộc.
status: tùy chọn.
all: trả tất cả.
low: chỉ trả nguyên liệu còn hàng nhưng quantity <= minimumStock.
out: chỉ trả nguyên liệu quantity <= 0.
Kiểu dữ liệu trả về là Result<IReadOnlyCollection<InventoryIngredientResponse>>, DTO ở [InventoryDtos.cs (line 6)](/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Dto/Inventory/InventoryDtos.cs:6)
Mỗi item có:
id
storeId
name
unit
quantity
minimumStock
averageUnitCost
lastImportUnitCost
isTrackInventory
isLowStock
isOutOfStock
Ý nghĩa thực tế:
quantity: số lượng tồn hiện tại.
minimumStock: ngưỡng cảnh báo.
isTrackInventory: có theo dõi tồn hay không.
isLowStock, isOutOfStock: cờ để FE tô màu/cảnh báo.
Ví dụ:
GET /api/inventory/ingredients?storeId=1&status=low
2. Xem lịch sử biến động của một nguyên liệu
GET /api/inventory/ingredients/{ingredientId}/movements?from={ISO-8601}&to={ISO-8601} ở [InventoryController.cs (line 55)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:55)
Mục đích:
Xem lịch sử nhập, xuất, hao hụt, điều chỉnh, bán hàng của một nguyên liệu cụ thể.
Dùng để audit hoặc đối soát vì sao tồn thay đổi.
Query params:
from: tùy chọn
to: tùy chọn
Kiểu dữ liệu trả về là Result<IReadOnlyCollection<InventoryMovementResponse>>, DTO ở [InventoryDtos.cs (line 10)](/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Dto/Inventory/InventoryDtos.cs:10)
Mỗi movement có:
id
ingredientId
productId
type
reason
quantity
requestedQuantity
shortageQuantity
unitCost
totalCost
orderId
orderItemId
note
destinationName
occurredAt
Ý nghĩa quan trọng:
type: Import hoặc Export
reason: như Purchase, Sale, Waste, StocktakeIncrease, StocktakeDecrease...
quantity: lượng thực tế đã cộng/trừ
requestedQuantity: lượng hệ thống muốn trừ
shortageQuantity: phần thiếu nếu có cơ chế warning-first
orderId, orderItemId: dùng để lần về giao dịch bán
Ví dụ:
GET /api/inventory/ingredients/10/movements?from=2026-06-01T00:00:00Z&to=2026-06-30T23:59:59Z
3. Xem danh sách tồn thành phẩm / product
GET /api/inventory/products?storeId={storeId}&status={all|low|out} ở [InventoryController.cs (line 59)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:59)
Mục đích:
Lấy danh sách tồn của product/thành phẩm.
Phù hợp cho hàng đóng gói, chai/lon/snack, hoặc món được quản lý tồn product.
Query params:
storeId: bắt buộc
status: tùy chọn, giống API nguyên liệu
Kiểu dữ liệu trả về là Result<IReadOnlyCollection<InventoryProductResponse>>, DTO ở [InventoryDtos.cs (line 22)](/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Dto/Inventory/InventoryDtos.cs:22)
Mỗi item có:
id
storeId
name
quantity
minimumStock
averageUnitCost
lastImportUnitCost
isTrackInventory
inventoryDeductionMode
isLowStock
isOutOfStock
Ý nghĩa thêm:
inventoryDeductionMode cho biết khi bán sẽ trừ kiểu gì:
RecipeOnly
ProductOnly
Both
VariantOnly
Ví dụ:
GET /api/inventory/products?storeId=1&status=all
4. Xem lịch sử biến động của một product
GET /api/inventory/products/{productId}/movements?from={ISO-8601}&to={ISO-8601} ở [InventoryController.cs (line 63)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:63)
Mục đích:
Xem lịch sử nhập/xuất/trừ bán của một product.
Dùng khi muốn biết vì sao tồn Coca, nước suối, snack... thay đổi.
Query params:
from: tùy chọn
to: tùy chọn
Kiểu dữ liệu:
Cũng là Result<IReadOnlyCollection<InventoryMovementResponse>>
Khác với movement nguyên liệu:
productId có giá trị
ingredientId sẽ là null
Ví dụ:
GET /api/inventory/products/20/movements?from=2026-06-01T00:00:00Z&to=2026-06-30T23:59:59Z
5. Xem dashboard tồn kho
GET /api/inventory/dashboard?storeId={storeId} ở [InventoryController.cs (line 136)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:136)
Mục đích:
Lấy dữ liệu tổng quan để hiển thị card/dashboard cảnh báo tồn kho.
Dùng cho trang tổng quan chứ không thay thế list chi tiết.
Kiểu dữ liệu trả về là Result<InventoryDashboardResponse>, DTO ở [InventoryDtos.cs (line 40)](/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Dto/Inventory/InventoryDtos.cs:40)
Field trả về:
lowStockCount
outOfStockCount
missingRecipeProductCount
reorderItems
Ý nghĩa:
lowStockCount: số nguyên liệu sắp hết
outOfStockCount: số nguyên liệu đã hết
missingRecipeProductCount: số product active cần recipe nhưng chưa có recipe active
reorderItems: danh sách nguyên liệu nên nhập thêm, kiểu InventoryIngredientResponse
Lưu ý:
Theo implementation hiện tại, dashboard này chủ yếu đếm cảnh báo ở ingredient; cảnh báo product nên lấy thêm từ API product list với status=low/out. Logic đó nằm trong service ở [InventoryService.cs (line 336)](/D:/Repo/EXE/QuanOiBE/QuanOi.Infrastructure/Services/InventoryService.cs:336)
Ví dụ:
GET /api/inventory/dashboard?storeId=1
6. Các API báo cáo có liên quan đến việc xem tiêu hao tồn
Đây không phải “xem số tồn hiện tại”, nhưng rất liên quan để phân tích kho.
GET /api/inventory/reports/ingredient-consumption?storeId={storeId}&from={ISO-8601}&to={ISO-8601} ở [InventoryController.cs (line 144)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:144)
Trả về IngredientConsumptionResponse ở [InventoryDtos.cs (line 39)](/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Dto/Inventory/InventoryDtos.cs:39) gồm:
ingredientId
ingredientName
unit
consumedQuantity
shortageQuantity
totalCost
Mục đích:
Xem tổng tiêu hao nguyên liệu trong kỳ.
Rất hợp để đối chiếu với luồng nấu/bán.
GET /api/inventory/reports/product-profitability?storeId={storeId}&from={ISO-8601}&to={ISO-8601} ở [InventoryController.cs (line 140)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:140)
Trả về ProductProfitabilityResponse ở [InventoryDtos.cs (line 38)](/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Dto/Inventory/InventoryDtos.cs:38) gồm:
productId
productName
quantitySold
revenue
cost
grossProfit
Mục đích:
Xem góc độ lợi nhuận sản phẩm, có dùng cost từ inventory.
7. Phiếu kho cũng là API xem tồn gián tiếp
Nếu cần xem chứng từ nhập/xuất để giải thích biến động tồn, có:
GET /api/inventory/documents ở [InventoryController.cs (line 20)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:20)
GET /api/inventory/documents/{id} ở [InventoryController.cs (line 24)](/D:/Repo/EXE/QuanOiBE/QuanOi/Controllers/InventoryController.cs:24)
Mục đích:
Xem danh sách và chi tiết phiếu nhập/xuất kho.
Phù hợp khi màn hình cần cả “sổ chứng từ” ngoài “sổ biến động”.
8. Những gì hiện chưa có
Hiện tại mình chưa thấy endpoint GET riêng để:
xem danh sách tồn của variant
xem movement theo variantId