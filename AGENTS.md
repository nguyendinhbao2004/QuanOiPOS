# QuanOi POS Agent Rules

## Mục tiêu
Khi làm việc trong QuanOi POS, luôn ưu tiên cấu trúc có sẵn của dự án, tái sử dụng code và giữ thay đổi gọn theo đúng source of truth.

## Source of Truth
Luôn ưu tiên các file config, theme, network, storage, constants và DI đã có sẵn trong `lib/core` trước khi tạo logic mới.

### Bắt buộc
- Tìm xem code hiện có đã giải quyết được bài toán chưa trước khi tạo mới.
- Ưu tiên sửa và tái sử dụng service, helper, interceptor, mapper, repository thay vì copy logic.
- Giữ naming và cấu trúc theo convention đang có trong dự án.
- Nếu thêm file mới, đặt đúng layer và mục đích, tránh tạo file “tiện tay” không có nơi dùng rõ ràng.

### Không được
- Không tạo logic trùng lặp ở nhiều layer khi có thể gom về một abstraction.
- Không thay đổi kiến trúc chỉ để làm nhanh nếu không có lợi ích rõ ràng.
- Không trộn business logic vào widget/UI nếu nó thuộc layer khác.

## Khi nào cần đọc rule UI riêng
Chỉ khi agent được giao dựng hoặc chỉnh UI Flutter thì mới đọc thêm file [docs/ui-build-rules.md](docs/ui-build-rules.md).

## Khi nào cần đọc rule kiến trúc Clean + Riverpod
Khi agent được giao tạo mới hoặc chỉnh sửa feature, state management, repository, use case hoặc DI thì bắt buộc đọc thêm file [docs/clean-architecture-riverpod.md](docs/clean-architecture-riverpod.md).

## What to do before implementing a feature
1. Đọc [docs/specd.md](docs/specd.md) để bám đúng scope nghiệp vụ và role/access model.
2. Đọc [docs/clean-architecture-riverpod.md](docs/clean-architecture-riverpod.md) để đặt đúng layer theo Clean Architecture và Riverpod convention.
3. Xác định feature thuộc layer nào: UI, domain, data, network, storage hay DI.
4. Tìm implementation sẵn có trước khi thêm mới.
5. Chỉ tách abstraction khi pattern lặp hoặc có khả năng tái sử dụng thật.
6. Giữ thay đổi nhỏ, đúng scope, và dễ review.
