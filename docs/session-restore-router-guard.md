# Session Restore + go_router Guard Implementation Plan

## Overview
Upgrade auth flow to restore session on app launch and enforce route-level authorization via go_router, compatible with mobile and web platforms.

## Scope
### In Scope
- Session restore from token + profile snapshot on app launch
- Centralized route guard using go_router
- Auth state machine with bootstrapping phase
- Cross-platform session persistence (mobile + web)

### Out of Scope
- Register API implementation
- Refresh token renewal redesign
- Role/store context loading after login
- Social login

## Architecture Approach

### 1. Auth State Machine (Enhanced)
```
┌─────────────────────────────────────────────────────┐
│ AuthState (expanded)                                │
├─────────────────────────────────────────────────────┤
│ status: bootstrapping → unauthenticated ↔ authenticated
│         └─→ authenticating → failure ↔ authenticated
│ accountType: SystemAdmin | StoreUser | null          │
│ fullName: string | null                             │
│ errorMessage: string | null                         │
│ sessionRestored: bool (flag for bootstrap detect)   │
└─────────────────────────────────────────────────────┘
```

### 2. Session Snapshot Storage
- Use `shared_preferences` for cross-platform compatibility
- Store: { accountId, email, fullName, accountType }
- Separate from TokenStorage to keep concerns isolated
- Key: `session_snapshot`

### 3. Flow: App Startup
1. main.dart runs setupDependencies() + ProviderScope wrap
2. app.dart consumes authNotifierProvider
3. AuthNotifier.build() triggers initializeSession() once
4. initializeSession() checks token existence + snapshot validity
5. If valid → emit authenticated state (restored from snapshot)
6. If invalid → emit unauthenticated state + clear stale data
7. go_router guard redirects based on final auth state

### 4. Flow: User Login
1. User enters credentials in LoginForm
2. AuthNotifier.login() calls LoginUseCase
3. On success:
   - Save tokens via TokenStorage
   - Save session snapshot
   - Emit authenticated state with accountType + fullName
4. go_router guard detects state change → redirect to role-appropriate home

### 5. Flow: Logout
1. User taps logout button
2. AuthNotifier.logout() calls LogoutUseCase
3. Clear tokens + session snapshot
4. Emit unauthenticated state
5. go_router guard → force redirect to /auth

### 6. go_router Guard Logic
```
redirect(BuildContext, GoRouterState) {
  if (bootstrapping) return null;  // let it continue, splash/loading shown
  if (unauthenticated) {
    return routeRequiresAuth ? '/auth' : null;
  }
  if (authenticated) {
    if (isSystemAdmin && routeIsSystemAdminOnly) return null;
    if (isSystemAdmin && routeIsStoreUserOnly) return '/system-admin-home';
    if (isStoreUser && routeIsStoreUserOnly) return null;
    if (isStoreUser && routeIsSystemAdminOnly) return '/store-home';
  }
  return null;  // allowed
}
```

## Implementation Checklist

### Phase 1: Core Models & Storage
- [ ] Create SessionSnapshot model (accountId, email, fullName, accountType)
- [ ] Create SessionSnapshotStorage interface + SharedPreferencesImpl
- [ ] Register in DI (injection.dart)

### Phase 2: Domain Layer (Use Cases)
- [ ] Add restoreSession() method to AuthRepository contract
- [ ] Create RestoreSessionUseCase

### Phase 3: Auth Notifier & State Enhancement
- [ ] Add bootstrapping status to AuthState
- [ ] Add sessionRestored flag to AuthState
- [ ] Implement initializeSession() in AuthNotifier
- [ ] Update login() to persist snapshot
- [ ] Update logout() to clear snapshot

### Phase 4: Data Layer (Repository)
- [ ] Implement restoreSession() in AuthRepositoryImpl
- [ ] Implement snapshot save/load in AuthRepositoryImpl

### Phase 5: go_router Setup
- [ ] Create routing config file (lib/config/router_config.dart or similar)
- [ ] Define routes (/auth, /system-admin-home, /store-home)
- [ ] Implement redirect guard logic
- [ ] Update app.dart to use MaterialApp.router

### Phase 6: Bootstrap Wiring
- [ ] Ensure initializeSession() is called once on app startup
- [ ] Update test/widget_test.dart for router startup

### Phase 7: Verification
- [ ] flutter analyze
- [ ] Run widget tests
- [ ] Manual flow tests:
  - Fresh app open → /auth
  - Login SystemAdmin → /system-admin-home
  - App kill + reopen → should restore session and land on home
  - Web hard refresh → same session persistence check
  - Logout → back to /auth
  - Deep link to protected route while unauth → redirect to /auth

## File Changes Summary

### New Files
- `lib/features/auth/data/models/session_snapshot_model.dart`
- `lib/core/storage/session_snapshot_storage.dart`
- `lib/core/storage/session_snapshot_storage_impl.dart`
- `lib/features/auth/domain/usecases/restore_session_use_case.dart`
- `lib/config/router_config.dart` (or similar routing module)

### Modified Files
- `lib/features/auth/domain/repositories/auth_repository.dart` → add restoreSession() + save/load snapshot
- `lib/features/auth/presentation/controllers/auth_state.dart` → add bootstrapping, sessionRestored
- `lib/features/auth/presentation/controllers/auth_notifier.dart` → add initializeSession()
- `lib/features/auth/data/repositories/auth_repository_impl.dart` → implement new contract methods
- `lib/core/di/injection.dart` → register new dependencies
- `lib/app.dart` → replace MaterialApp with MaterialApp.router
- `lib/main.dart` → (no change needed if initializeSession auto-triggers)
- `test/widget_test.dart` → adapt for router startup

## Success Criteria
1. App launches → shows loading/splash while bootstrapping
2. With valid token + snapshot → lands directly on role-appropriate home
3. Without token → shows auth page
4. Web refresh preserves session state
5. go_router guard prevents unauthorized route access
6. Logout clears session and redirects to /auth
7. No platform-specific code in UI layer; all differences handled in storage/DI

## Decisions Rationale
- **shared_preferences** for snapshot: Works seamlessly on iOS, Android, Web; simpler than encrypted alternatives for non-sensitive identity data
- **SessionSnapshot model**: Lightweight restore mechanism without re-calling /auth/me endpoint immediately
- **AuthState.bootstrapping**: Prevents flash of auth screen during restore check; can show splash/loading UI until restore complete
- **Separate storage interfaces**: TokenStorage handles auth tokens; SessionSnapshotStorage handles identity—clearer separation of concerns

## Risk Mitigation
- If token expires during bootstrap → restore fails → go to /auth (handled gracefully)
- If snapshot corrupted/invalid → clear and go to /auth (no crash)
- Web platform specifics → abstracted behind interface; platform-specific impl in SharedPreferencesImpl
- Deep linking while unauth → guard redirects to /auth → normal login flow

## Next Steps (After Implementation)
1. Phase 2: Add role/store loading after SystemAdmin login (FR-03 from spec)
2. Phase 3: Register register API and handle store selection for StoreUser
3. Phase 4: Implement workspace_context feature for multi-store switching
