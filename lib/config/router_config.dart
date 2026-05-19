import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/entities/account_type.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/super_admin/presentation/pages/super_admin_home_page.dart';
import '../features/store_operations/presentation/pages/store_home_page.dart';

/// Route names as constants
abstract final class RouteNames {
  static const String auth = 'auth';
  static const String superAdminHome = 'super-admin-home';
  static const String storeHome = 'store-home';
  static const String splash = 'splash';
}

/// Centralized router configuration with auth guard
final routerProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;

  router = GoRouter(
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) {
          // Temporary splash while bootstrapping
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/auth',
        name: RouteNames.auth,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/super-admin-home',
        name: RouteNames.superAdminHome,
        builder: (context, state) => const SuperAdminHomePage(),
      ),
      GoRoute(
        path: '/store-home',
        name: RouteNames.storeHome,
        builder: (context, state) => const StoreHomePage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);

      // While bootstrapping, show splash
      if (authState.isBootstrapping) {
        return state.matchedLocation == '/' ? null : '/';
      }

      // Once bootstrap finishes, root should resolve to a real route
      if (state.matchedLocation == '/') {
        if (!authState.isAuthenticated) {
          return '/auth';
        }

        return authState.accountType == AccountType.superAdmin
            ? '/super-admin-home'
            : '/store-home';
      }

      // If unauthenticated, force to auth unless already there
      if (!authState.isAuthenticated) {
        return state.matchedLocation == '/auth' ? null : '/auth';
      }

      // If authenticated, prevent going back to /auth
      if (state.matchedLocation == '/auth') {
        return authState.accountType == AccountType.superAdmin
            ? '/super-admin-home'
            : '/store-home';
      }

      // Cross-account type route check
      if (authState.accountType == AccountType.superAdmin) {
        if (state.matchedLocation == '/store-home') {
          return '/super-admin-home';
        }
      } else if (authState.accountType == AccountType.storeUser) {
        if (state.matchedLocation == '/super-admin-home') {
          return '/store-home';
        }
      }

      // Allow the route
      return null;
    },
  );

  ref.listen(authNotifierProvider, (previous, next) {
    router.refresh();
  });

  ref.onDispose(router.dispose);
  return router;
});
