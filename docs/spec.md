# QuanOi POS Product Specification (Draft)

## 1. Document Purpose
This document defines the product/domain specification for QuanOi POS, a restaurant-management SaaS product.

The goal is to provide a shared source of truth for:
- Product understanding
- Frontend implementation scope
- Backend API consumption alignment
- Role and permission behavior across stores

## 2. Product Context
QuanOi POS is a Flutter application focused on frontend implementation and API consumption from an existing backend.

The platform supports two major actor categories:
- Super Admin actors for platform-wide management
- Store User actors for store-level restaurant operations

## 3. Scope
### 3.1 In Scope
- Account type model (SuperAdmin vs StoreUser)
- Multi-store membership model for StoreUser
- Store-level role model and role-based capabilities
- Post-login workspace resolution for StoreUser
- Store switching behavior for users belonging to multiple stores
- Core business flows for administration and operations

### 3.2 Out of Scope
- UI visual design details
- Backend architecture redesign
- API schema redesign
- Endpoint-level capability matrix
- Operational infrastructure details

## 4. Core Actors
### 4.1 Super Admin
Super Admin is responsible for platform governance and business administration across all stores.

Primary responsibilities:
- Manage stores
- Manage user accounts
- Manage service/subscription packages
- View and manage platform/system revenue

### 4.2 Store User
Store User is an account type used for store operation workflows.

A Store User:
- Can belong to one or multiple stores
- Can have different roles in different stores
- Must resolve active workspace context before entering store modules

## 5. Account and Access Model
### 5.1 Account Types
Every account has exactly one account type:
- SuperAdmin
- StoreUser

Account type determines high-level access boundaries:
- SuperAdmin can access platform-level modules
- StoreUser can access store-level modules only

### 5.2 Store Membership
Store membership links a StoreUser to a store.

Rules:
- A StoreUser may have many memberships (multi-store)
- Each membership has exactly one active role per store context
- A StoreUser role can differ from store to store

### 5.3 Store-Level Roles (Official Set)
Each store uses the following official role set:
- Owner
- Manager
- Staff
- Kitchen

Notes:
- Roles apply only inside the selected store context.
- `Cashier` may appear in business conversation examples but is out of the official role set in the current scope.

### 5.4 Workspace Context
For StoreUser, app behavior is driven by `WorkspaceContext`.

`WorkspaceContext` (conceptual contract):
- accountType
- activeStoreId
- activeRole

Behavioral requirement:
- StoreUser cannot enter store-operation modules when `activeStoreId` is not resolved.

## 6. Role Capability Model (Abstract)
This section defines expected capability boundaries at a business level.
Final API-level permissions are governed by backend contracts.

### 6.1 Owner
Expected capability scope:
- Full management authority within assigned store
- User assignment/management inside store scope
- Store configuration and operational oversight

### 6.2 Manager
Expected capability scope:
- Daily operation management
- Team/task coordination
- Access to management tools below Owner-level authority

### 6.3 Staff
Expected capability scope:
- Frontline operational workflows
- Limited, task-specific actions needed for service execution

### 6.4 Kitchen
Expected capability scope:
- Kitchen-production related workflows
- Preparation and fulfillment actions relevant to kitchen operations

## 7. Functional Requirements
### FR-01 Account Type Resolution
When a user signs in, the app must resolve and persist account type (SuperAdmin or StoreUser) from backend response data.

### FR-02 Module Boundary by Account Type
The app must expose only modules permitted by account type:
- SuperAdmin: platform-wide administration modules
- StoreUser: store-operation modules

### FR-03 Membership Loading
For StoreUser accounts, the app must load all store memberships associated with the account.

### FR-04 Role Resolution per Store
When a StoreUser selects a store, the app must resolve the role assigned for that selected store.

### FR-05 Dynamic Store Switching
StoreUser must be able to switch active store context without signing out, when multiple memberships exist.

### FR-06 Context-Aware Permissions
Permissions must be evaluated based on:
- Account type
- Active store (for StoreUser)
- Role in active store

### FR-07 Super Admin Store Management
Super Admin can create/manage store records via available backend APIs.

### FR-08 Super Admin User Management
Super Admin can manage user accounts and assign users to store scopes through supported backend operations.

### FR-09 Service Package Management
Super Admin can manage service/package offerings used by stores.

### FR-10 Revenue Visibility
Super Admin can access platform-level revenue information exposed by backend services.

### FR-11 StoreUser Workspace Selection
After StoreUser login success, app must resolve workspace entry:
- If membership count = 0 -> show no-store state.
- If membership count = 1 -> auto-select that store by default rule.
- If membership count > 1 -> show store-selection UI.

### FR-12 Active Store Requirement
StoreUser must have a resolved `activeStoreId` before entering store-operation module routes.

### FR-13 Role-based Landing
After `activeStoreId` is selected, app must route StoreUser into role-appropriate module shell based on resolved role for that store.

### FR-14 Context Refresh on Store Switch
When StoreUser switches store, app must refresh:
- activeStoreId
- activeRole
- route/module visibility and scoped data context

## 8. User Flows
### 8.1 Login and Routing Flow
1. User authenticates.
2. App receives account profile and account type.
3. If account type is SuperAdmin, route to platform admin workspace.
4. If account type is StoreUser, continue to workspace resolution flow.

### 8.2 StoreUser Workspace Resolution Flow
1. StoreUser login success.
2. App fetches memberships and available stores.
3. Branch by membership count:
   - 0 store: show no-store guidance state.
   - 1 store: auto-select and continue.
   - >1 store: user selects store from store picker.
4. App resolves role for selected store.
5. App enters role-appropriate module shell.

### 8.3 Store Switching Flow
1. StoreUser triggers switch-store action.
2. App presents allowed store list from memberships.
3. User selects another store.
4. App updates active store context and role context.
5. App refreshes permissions and scoped data.

### 8.4 Super Admin Management Flow (High-Level)
1. Super Admin enters administration area.
2. User performs store/user/package management actions.
3. App executes backend APIs and updates views.
4. Revenue dashboards/reports are displayed from backend-provided data.

## 9. Domain Entities (Conceptual)
### 9.1 Account
- accountId
- accountType (SuperAdmin | StoreUser)
- profile data
- status

### 9.2 Store
- storeId
- storeName
- subscription/service package info
- operational status

### 9.3 StoreMembership
- membershipId
- accountId (StoreUser)
- storeId
- role (Owner | Manager | Staff | Kitchen)
- membership status

### 9.4 WorkspaceContext
- accountType
- activeStoreId (nullable before selection)
- activeRole (nullable before selection)

### 9.5 ServicePackage
- packageId
- packageName
- pricing/terms metadata
- package status

### 9.6 RevenueRecord (Platform-Level)
- period
- total revenue
- store/package attribution metadata

## 10. Business Rules
- BR-01: Only SuperAdmin can access platform governance features.
- BR-02: Store-level actions are always scoped to active store context.
- BR-03: A StoreUser may have different roles across different stores.
- BR-04: Role changes in one store must not implicitly change role in another store.
- BR-05: Store switching must not require re-authentication in normal conditions.
- BR-06: StoreUser route guard must block store modules when `activeStoreId` is unresolved.
- BR-07: Role-home visibility is derived from resolved role in current active store.

## 11. Non-Functional Expectations (Frontend)
- Clear context visibility: active store and current role should always be known in app state and UI shell.
- Consistent authorization handling: blocked actions should fail gracefully with clear messaging.
- API-first behavior: frontend logic must align with backend permission responses.
- Predictable navigation: account-type guard and workspace-role guard should be explicit and testable.

## 12. Assumptions
- Backend already provides account type, memberships, and role data.
- Backend enforces authoritative permission checks.
- Revenue and package data are available via existing admin APIs.
- Frontend currently uses role-level module visibility; endpoint-level matrices may be added later.

## 13. Open Questions
- OQ-01: What is the complete endpoint-level capability matrix for each store role?
- OQ-02: Is multi-role per user per single store supported in future scope, or always exactly one role per membership?
- OQ-03: Should auto-select (single-store case) be configurable by product flag?
- OQ-04: Which revenue dimensions are mandatory (daily/monthly/store/package/channel)?
- OQ-05: Are additional store roles planned beyond Owner, Manager, Staff, Kitchen?

## 14. Acceptance Criteria (Spec Quality)
- AC-01: Distinguishes clearly between account type and store role.
- AC-02: Documents multi-store behavior and switching flow for StoreUser.
- AC-03: Covers Super Admin responsibilities: store, user, package, revenue.
- AC-04: Defines post-login workspace resolution for StoreUser (0/1/multi-store).
- AC-05: Defines `WorkspaceContext` and active-store requirement for route entry.

## 15. Change Log
- 2026-05-19: Initial detailed draft generated from source description in `docs/descrtipt.md`.
- 2026-05-19: Added StoreUser post-login workspace resolution, `WorkspaceContext`, and official role-set clarification.
