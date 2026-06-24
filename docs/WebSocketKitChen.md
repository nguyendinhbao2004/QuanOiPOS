Luồng backend gửi websocket cho màn hình bếp
Frontend mở kết nối SignalR
Màn hình bếp kết nối tới:ws://localhost:5000/hubs/notifications

Token JWT được truyền qua access_token.
Backend đọc token này trong [Program.cs (line 121)](/abs/path/D:/Repo/EXE/QuanOiBE/QuanOi/Program.cs:121).

Hub xác thực user
Hub dùng [Authorize] nên chỉ connection có token hợp lệ mới vào được.
Khi connect thành công, backend tự thêm connection vào group theo account:account:{accountId}

Đoạn này nằm ở [NotificationHub.cs (line 19)](/abs/path/D:/Repo/EXE/QuanOiBE/QuanOi/Hub/NotificationHub.cs:19).

Frontend phải gọi JoinStore(storeId)
Đây là bước quan trọng để màn hình bếp nhận thông báo của cửa hàng.
Khi FE gọi:connection.invoke("JoinStore", storeId)

Backend kiểm tra account đó có quyền trong store hay không.
Nếu hợp lệ, backend add connection vào group:store:{storeId}

Code ở [NotificationHub.cs (line 32)](/abs/path/D:/Repo/EXE/QuanOiBE/QuanOi/Hub/NotificationHub.cs:32).

Khi có order mới
Sau khi tạo order thành công, backend gọi:KitchenFeatureHelper.PublishOrderCreatedAsync(...)

Code ở [CreateOrderHandler.cs (line 305)](/abs/path/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Feature/Order/Command/CreateOrder/CreateOrderHandler.cs:305).

Backend tạo payload thông báo
Trong [KitchenFeatureHelper.cs (line 131)](/abs/path/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Feature/Kitchen/Common/KitchenFeatureHelper.cs:131), backend tạo payload gồm:storeId
orderId
items

Đồng thời tạo event:eventName = "KITCHEN_ORDER_CREATED"


Backend publish realtime event
Backend gọi:RealtimeNotificationEvent.ToStore(..., order.StoreId, payload)

Nghĩa là event này nhắm tới một store cụ thể, không phải toàn bộ client.
Đoạn này ở [KitchenFeatureHelper.cs (line 146)](/abs/path/D:/Repo/EXE/QuanOiBE/QuanOi.Application/Feature/Kitchen/Common/KitchenFeatureHelper.cs:146).

RealtimeNotificationService chọn đúng kiểu gửi
Service nhận event rồi chuyển sang transport SignalR.
Nếu audience là Store, nó gọi:SendToStoreAsync(storeId, message)

Code ở [RealtimeNotificationService.cs (line 39)](/abs/path/D:/Repo/EXE/QuanOiBE/QuanOi.Infrastructure/Notification/RealtimeNotificationService.cs:39).

SignalR gửi vào group của store
Transport thực tế gửi qua:_hubContext.Clients.Group(RealtimeGroups.Store(storeId)).SendAsync("ReceiveNotification", message)

Tức là backend gửi tới tất cả connection đã join group:store:{storeId}

Code ở [SignalRRealtimeNotificationTransport.cs (line 35)](/abs/path/D:/Repo/EXE/QuanOiBE/QuanOi/Hub/SignalRRealtimeNotificationTransport.cs:35).

Frontend nhận message
FE phải lắng nghe method:ReceiveNotification

Khi nhận được, FE đọc:eventName
payload

Nếu eventName === "KITCHEN_ORDER_CREATED" thì thêm món mới vào danh sách bếp.

Tóm tắt một câu
Backend không gửi thẳng cho “màn hình bếp” theo từng tab, mà gửi vào group SignalR theo storeId; màn hình bếp nào đã JoinStore(storeId) thì mới nhận được event KITCHEN_ORDER_CREATED.
Sơ đồ ngắn
CreateOrder API
  -> CreateOrderHandler
  -> KitchenFeatureHelper.PublishOrderCreatedAsync
  -> RealtimeNotificationService.PublishAsync
  -> SignalRRealtimeNotificationTransport.SendToStoreAsync
  -> SignalR Group: store:{storeId}
  -> FE đang JoinStore(storeId)
  -> ReceiveNotification