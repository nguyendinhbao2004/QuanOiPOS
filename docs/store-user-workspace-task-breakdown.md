# StoreUser Workspace Implementation Breakdown

## Summary
Tài liệu này chia nhỏ các task để triển khai luồng `StoreUser post-login workspace resolution` theo phase.

Đầu vào chuẩn:
- `docs/spec.md`
- `docs/storeUser.md`
- `docs/clean-architecture-riverpod.md`
- `docs/ui-build-rules.md`

Role set chính thức trong scope:
- `Owner`, `Manager`, `Staff`, `Kitchen`

---

## Phase 1: Domain Contracts & State Model

### Mục tiêu
Xác định contract domain và state chuẩn cho workspace context, độc lập UI/framework.

### Input/Output Artifact
- Input: spec + storeUser docs.
- Output:
  - Domain entities/contracts cho `StoreMembership`, `WorkspaceContext`.
  - Use case contracts:
    - `LoadStoreMembershipsUseCase`
    - `SelectActiveStoreUseCase`
    - `ResolveActiveRoleUseCase`
  - `WorkspaceContextState` với status:
    - `bootstrapping`
    - `selectingStore`
    - `ready`
    - `error`

### Dependency
- Không phụ thuộc implementation data/UI.

### Task Checklist
- [ ] Chốt model `WorkspaceContext { accountType, activeStoreId, activeRole }`.
- [ ] Chốt quy ước trạng thái 0-store / 1-store / multi-store.
- [ ] Viết acceptance criteria cho từng use case.

### Acceptance Criteria
- Contract mô tả được đầy đủ luồng chọn store và resolve role.
- Không có framework type trong domain contracts.

---

## Phase 2: Data Integration (Membership/Role)

### Mục tiêu
Nối datasource/repository để load memberships và resolve role theo store từ backend API có sẵn.

### Input/Output Artifact
- Input: domain contracts từ Phase 1.
- Output:
  - Datasource methods cho memberships/context.
  - Repository implementation map DTO -> entity.
  - Error mapping theo chuẩn network layer hiện có.

### Dependency
- Cần hoàn thành contract Phase 1 trước.

### Task Checklist
- [ ] Thêm method datasource lấy danh sách stores của StoreUser.
- [ ] Thêm mapper membership/role về domain entity.
- [ ] Implement repository cho 3 use case workspace.
- [ ] Chuẩn hoá handling lỗi `loading/empty/error`.

### Acceptance Criteria
- Có thể trả về đúng 3 nhánh dữ liệu:
  - 0 store
  - 1 store
  - N store
- Dữ liệu role theo từng store được map chính xác và ổn định.

---

## Phase 3: Routing + Guards

### Mục tiêu
Thêm điều hướng có kiểm soát context theo 2 lớp guard.

### Input/Output Artifact
- Input: auth state hiện có + workspace context state.
- Output:
  - Account-type guard (`SystemAdmin` vs `StoreUser`).
  - Workspace-role guard (chặn StoreUser vào module khi chưa có `activeStore`).
  - Route contract cho:
    - `store picker`
    - role-based home

### Dependency
- Cần có workspace provider/notifier và state ready từ Phase 1/2.

### Task Checklist
- [ ] Tách guard theo đúng 2 lớp.
- [ ] Route StoreUser chưa có `activeStore` về `store picker`.
- [ ] Route StoreUser có context đầy đủ về role-home tương ứng.
- [ ] Refresh route khi user đổi store.

### Acceptance Criteria
- Không thể vào module store-operation nếu chưa resolve context.
- Đổi store cập nhật route/module theo context mới, không cần logout/login.

---

## Phase 4: Workspace UI + Role Landing

### Mục tiêu
Triển khai UI cho account hub/store picker/role landing theo rules UI và state provider.

### Input/Output Artifact
- Input: routing + provider từ Phase 3.
- Output:
  - StoreUser account hub có entry vào chọn workspace/store.
  - Store picker screen.
  - Role-home shell theo role active.
  - UI switch-store nhất quán.

### Dependency
- Phase 3 phải ổn định guard và route.

### Task Checklist
- [ ] Khởi tạo `SystemShell` cho StoreUser với tab `Tài khoản` active mặc định sau login.
- [ ] Màn `Store Picker` có đủ state `loading/empty/error`.
- [ ] Hiển thị rõ `activeStore` + `activeRole` ở app shell.
- [ ] Nút/entry đổi store đặt nhất quán trên role-home.
- [ ] UI chỉ đọc context từ provider/notifier (không nhúng business logic).

### Acceptance Criteria
- Luồng UX đầy đủ từ login -> chọn store -> vào role-home.
- Không có hardcode role logic phân tán trong widget thuần.

---

## Phase 5: Testing + Regression Checklist

### Mục tiêu
Khóa chất lượng cho luồng workspace trước khi mở rộng module nghiệp vụ.

### Input/Output Artifact
- Input: implementation các phase trước.
- Output:
  - Unit tests cho use case workspace.
  - Provider/notifier state tests.
  - Router guard tests.
  - Manual regression checklist.

### Dependency
- Cần hoàn tất implementation phase 1-4.

### Task Checklist
- [ ] Test use case branch: 0-store / 1-store / multi-store.
- [ ] Test state transition: bootstrapping -> selectingStore -> ready -> error.
- [ ] Test route guard với StoreUser chưa có `activeStore`.
- [ ] Test đổi store khi đang đăng nhập.
- [ ] Manual regression: SystemAdmin flow không bị ảnh hưởng.

### Acceptance Criteria
- Toàn bộ nhánh chính của workspace flow được cover.
- Không hồi quy luồng auth/system-admin hiện có.

---

## Definition of Done (Workspace Scope)
- Có `WorkspaceContext` rõ ràng trong state và điều hướng.
- StoreUser chỉ vào module khi có `activeStore` + `activeRole`.
- Tài liệu + implementation + test dùng cùng một thuật ngữ/contract.
- Cross-check pass giữa:
  - `docs/spec.md`
  - `docs/storeUser.md`
  - `docs/clean-architecture-riverpod.md`
  - `docs/ui-build-rules.md`
