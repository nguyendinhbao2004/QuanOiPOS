# Tich hop FE: AI bao cao kinh doanh

Tai lieu nay la contract de FE tich hop API AI bao cao kinh doanh moi. API nay tach rieng voi API cu `POST /api/ai-insights/sales`, nen FE dang dung sales insight hien tai khong bi anh huong.

Tat ca API yeu cau JWT va tra wrapper:

```json
{
  "succeeded": true,
  "message": "...",
  "errors": [],
  "data": {}
}
```

## 1. Endpoint

`POST /api/ai-insights/business-report`

Muc dich:

- Tong hop doanh thu, so don, gia tri don trung binh.
- Tinh gia von, loi nhuan gop, bien loi nhuan.
- Tinh chi phi nhap hang trong ky.
- Xep hang mon ban chay.
- Gom so order va doanh thu theo 24 khung gio.
- Chi ra mon ban manh theo tung gio.
- Tong hop ton kho thap, het hang, mon thieu cong thuc.
- De xuat item can nhap them hoac nen giam nhap.
- Luu noi dung AI vao bang `AIInsights`.

## 2. Request

```json
{
  "storeId": 1,
  "fromDate": "2026-06-01",
  "toDate": "2026-06-23",
  "timezoneOffsetMinutes": 420,
  "type": 3
}
```

| Field | Bat buoc | Ghi chu |
| --- | --- | --- |
| `storeId` | Co | Id cua cua hang can phan tich. |
| `fromDate` | Khong | ISO date/datetime. Neu khong gui, backend lay mac dinh 30 ngay truoc `toDate`. |
| `toDate` | Khong | ISO date/datetime. Neu khong gui, backend lay thoi diem hien tai. Neu gui ngay khong co gio, backend tinh het ngay do. |
| `timezoneOffsetMinutes` | Khong | Mac dinh `420` cho Viet Nam. Dung de gom khung gio hien thi cho FE. |
| `type` | Khong | Nen gui `3` = `BusinessReport`. Neu khong gui, backend tu dung `BusinessReport`. |

Range ngay toi da: 90 ngay.

Luu y enum `type` nen gui dang so de chac chan tuong thich voi config JSON hien tai:

- `1` = `Trend`
- `2` = `Suggestion`
- `3` = `BusinessReport`

## 3. Response tong quat

```json
{
  "succeeded": true,
  "message": "Tao bao cao kinh doanh bang AI thanh cong.",
  "errors": [],
  "data": {
    "id": 15,
    "storeId": 1,
    "type": 3,
    "fromDate": "2026-06-01T00:00:00Z",
    "toDate": "2026-06-23T23:59:59.9999999Z",
    "content": "Noi dung AI phan tich...",
    "metrics": {},
    "createdAt": "2026-06-24T03:30:00Z"
  }
}
```

FE nen render:

- `content`: noi dung AI da viet san bang tieng Viet.
- `metrics`: so lieu goc de ve cards, charts, tables. Khong nen parse nguoc tu `content`.

## 4. Metrics chi tiet

### 4.1 `revenueSummary`

```json
{
  "totalRevenue": 1250000,
  "paidRevenue": 1200000,
  "completedOrderCount": 42,
  "cancelledOrderCount": 3,
  "averageOrderValue": 29761.9
}
```

Y nghia:

- `totalRevenue`: tong doanh thu cua order `Completed`, uu tien `FinalAmount`, fallback `TotalAmount`.
- `paidRevenue`: tong tien da thu.
- `completedOrderCount`: so order hoan tat.
- `cancelledOrderCount`: so order bi huy trong cung khoang ngay.
- `averageOrderValue`: `totalRevenue / completedOrderCount`.

Goi y UI: card Doanh thu, Da thu, Don hoan tat, Don huy, Gia tri don TB.

### 4.2 `profitSummary`

```json
{
  "totalCost": 480000,
  "grossProfit": 770000,
  "grossProfitMargin": 61.6
}
```

Y nghia:

- `totalCost`: tong gia von cua order item khong bi huy, thuoc order `Completed`.
- `grossProfit`: tong loi nhuan gop.
- `grossProfitMargin`: phan tram loi nhuan gop tren doanh thu.

V1 chi la loi nhuan gop, chua tinh luong nhan vien, mat bang, dien nuoc, khuyen mai ngoai order.

### 4.3 `purchaseSummary`

```json
{
  "totalPurchaseCost": 900000,
  "purchaseMovementCount": 6
}
```

Y nghia:

- Chi cong giao dich kho `Import` voi ly do `Purchase`.
- Khong cong kiem ke tang, dieu chinh, xuat kho, hao hut.

Goi y UI: card Chi phi nhap hang trong ky va so lan nhap.

### 4.4 `topProducts`

```json
[
  {
    "productId": 10,
    "productName": "Tra sua truyen thong",
    "quantitySold": 25,
    "revenue": 750000,
    "cost": 260000,
    "grossProfit": 490000,
    "grossProfitMargin": 65.33
  }
]
```

Y nghia:

- Sap xep theo `quantitySold` giam dan, sau do theo `revenue`.
- Chi tinh order item khong bi huy, thuoc order `Completed`.
- `quantitySold` hien la so dong order item, moi dong tuong ung 1 mon da order.

Goi y UI: table Top mon ban chay, co cot So luong, Doanh thu, Gia von, Loi nhuan, Bien LN.

### 4.5 `hourlyOrders`

API tra du 24 bucket, gio `0` den `23` sau khi cong `timezoneOffsetMinutes`.

```json
[
  { "hour": 0, "orderCount": 0, "revenue": 0 },
  { "hour": 11, "orderCount": 8, "revenue": 240000 },
  { "hour": 18, "orderCount": 12, "revenue": 420000 }
]
```

Y nghia:

- `hour`: gio local theo offset FE gui, mac dinh gio Viet Nam.
- `orderCount`: so order `Completed` tao trong gio do.
- `revenue`: doanh thu order trong gio do.

Goi y UI: bar chart 24 cot. Tooltip hien `11:00 - 11:59`, so don, doanh thu.

### 4.6 `hourlyProductSales`

Moi gio co doanh so se tra mon ban manh nhat cua gio do.

```json
[
  {
    "hour": 18,
    "productId": 10,
    "productName": "Tra sua truyen thong",
    "quantitySold": 6,
    "revenue": 180000,
    "grossProfit": 117000
  }
]
```

Goi y UI: table “Mon ban manh theo khung gio”, hoac tooltip bo sung cho chart gio cao diem.

### 4.7 `inventorySummary`

```json
{
  "lowStockCount": 4,
  "outOfStockCount": 2,
  "missingRecipeProductCount": 1,
  "lowStockItems": [
    {
      "itemType": "Ingredient",
      "itemId": 3,
      "itemName": "Tran chau",
      "quantity": 800,
      "unit": "g",
      "minimumStock": 1000
    }
  ],
  "outOfStockItems": [
    {
      "itemType": "Product",
      "itemId": 20,
      "itemName": "Nuoc suoi",
      "quantity": 0,
      "unit": "cai",
      "minimumStock": 10
    }
  ]
}
```

Y nghia:

- `lowStockCount`: item co track kho, con hang nhung `quantity <= minimumStock`.
- `outOfStockCount`: item co track kho va `quantity <= 0`.
- `missingRecipeProductCount`: so mon active can cong thuc nhung chua co recipe active.
- `lowStockItems`, `outOfStockItems`: moi danh sach gioi han 10 item de FE render nhanh.

### 4.8 `inventoryRecommendations`

```json
[
  {
    "recommendationType": "Restock",
    "itemType": "Ingredient",
    "itemId": 3,
    "itemName": "Tran chau",
    "currentQuantity": 800,
    "unit": "g",
    "minimumStock": 1000,
    "consumedQuantity": 2500,
    "importedQuantity": 3000,
    "reason": "Ton kho dang bang hoac duoi nguong toi thieu."
  },
  {
    "recommendationType": "ReduceImport",
    "itemType": "Product",
    "itemId": 30,
    "itemName": "Sua hop",
    "currentQuantity": 120,
    "unit": "cai",
    "minimumStock": 20,
    "consumedQuantity": 0,
    "importedQuantity": 100,
    "reason": "Trong ky co nhap hang nhung chua ghi nhan tieu thu."
  }
]
```

Gia tri `recommendationType`:

- `Restock`: can nhap them.
- `ReduceImport`: nen giam nhap.

Gia tri `itemType`:

- `Ingredient`: nguyen lieu.
- `Product`: thanh pham/san pham co quan ly ton.

Goi y UI:

- Badge do/cam cho `Restock`.
- Badge xanh/ghi cho `ReduceImport`.
- Hien current/minimum/consumed/imported de quan ly hieu ly do.

## 5. Truong hop it du lieu

Neu khong co order `Completed` trong ky:

- API van tra `succeeded = true`.
- `content` se noi ro chua co don hoan tat de phan tich doanh thu.
- `metrics.inventorySummary` va `inventoryRecommendations` van co the co du lieu neu cua hang da cau hinh kho.
- FE nen render empty state cho cac chart doanh thu/top mon, nhung van hien phan ton kho.

## 6. Error cases

### 400 - Request khong hop le

Co the do:

- `storeId <= 0`
- `fromDate > toDate`
- Khoang ngay vuot qua 90 ngay
- `timezoneOffsetMinutes` ngoai khoang `-720` den `840`

### 401 - Chua dang nhap

JWT thieu hoac het han.

### 403 - Khong co quyen cua hang

User khong phai owner/store user cua `storeId`.

### 404 - Khong tim thay cua hang

`storeId` khong ton tai hoac da xoa.

### 502/500 - Loi AI provider hoac config

Thuong gap khi:

- Thieu `Gemini:ApiKey`.
- Gemini tra loi loi HTTP.
- Response Gemini sai format.

FE nen hien thong bao co the thu lai sau, khong nen xoa metric da co o UI neu dang cache.

## 7. Goi y man hinh FE

Man hinh nen chia thanh cac khu:

1. Bo loc: store, fromDate, toDate, nut Tao bao cao.
2. Cards KPI: doanh thu, da thu, loi nhuan gop, bien loi nhuan, chi phi nhap, so don.
3. Noi dung AI: render `content` trong panel doc nhanh.
4. Chart khung gio: dung `hourlyOrders`.
5. Bang top mon: dung `topProducts`.
6. Bang mon ban manh theo gio: dung `hourlyProductSales`.
7. Ton kho: low/out count, danh sach item can chu y.
8. Khuyen nghi kho: dung `inventoryRecommendations`.

FE khong can tu tinh lai cac chi so chinh. Neu can format tien, format cac field decimal theo VND.

## 8. Curl mau

```bash
curl -X POST "https://api.example.com/api/ai-insights/business-report" \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "storeId": 1,
    "fromDate": "2026-06-01",
    "toDate": "2026-06-23",
    "timezoneOffsetMinutes": 420,
    "type": 3
  }'
```
