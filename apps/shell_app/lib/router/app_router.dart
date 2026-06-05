import 'package:core_auth/core_auth.dart';
import 'package:feature_admin/feature_admin.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_billing/feature_billing.dart';
import 'package:feature_cocina/feature_cocina.dart';
import 'package:feature_menu_qr/feature_menu_qr.dart';
import 'package:feature_pos/feature_pos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(tenantInfoProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

String homeRouteForNivel(String? nivel) {
  switch (nivel) {
    case 'superadmin':
    case 'admin':
    case 'supervisor':
      return AdminRoutes.dashboard;
    case 'cocina':
    case 'bar':
      return CocinaRoutes.root;
    case 'mozo':
      return PosRoutes.comedor;
    default:
      return AdminRoutes.dashboard;
  }
}

bool isPublicRoute(String location) {
  return location.startsWith('/menu') ||
      location == '/servicio-no-disponible';
}

bool isBillingRoute(String location) {
  return location == BillingRoutes.root || location.startsWith('${BillingRoutes.root}/');
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AuthRoutes.login,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (isPublicRoute(location)) {
        return null;
      }

      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isLoginRoute = location == AuthRoutes.login;

      if (!isAuthenticated && !isLoginRoute) {
        final fullPath = state.uri.toString();
        return '${AuthRoutes.login}?redirect=${Uri.encodeComponent(fullPath)}';
      }

      if (isAuthenticated) {
        final tenant = ref.read(tenantInfoProvider).valueOrNull;

        if (tenant?.isInactivo == true && !isLoginRoute) {
          ref.read(loginControllerProvider.notifier).logout();
          return AuthRoutes.login;
        }

        if (tenant?.isSuspendido == true &&
            !isBillingRoute(location) &&
            !isLoginRoute) {
          return BillingRoutes.root;
        }

        if (isLoginRoute) {
          final redirect = state.uri.queryParameters['redirect'];
          if (redirect != null && redirect.isNotEmpty) {
            return redirect;
          }
          final nivel = ref.read(currentUserNivelProvider);
          return homeRouteForNivel(nivel);
        }
      }

      return null;
    },
    routes: [
      ...AuthRoutes.routes,
      ...MenuQrRoutes.routes,
      ...BillingRoutes.routes,
      ...AdminRoutes.routes,
      ...PosRoutes.routes,
      ...CocinaRoutes.routes,
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.uri}'),
      ),
    ),
  );
});
