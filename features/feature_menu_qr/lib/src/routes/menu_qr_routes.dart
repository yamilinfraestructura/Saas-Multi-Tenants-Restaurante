import 'package:go_router/go_router.dart';

import '../screens/menu_qr_screen.dart';
import '../screens/service_unavailable_screen.dart';

class MenuQrRoutes {
  MenuQrRoutes._();

  static const menuBase = '/menu/:tenantSlug';
  static const menuWithMesa = '/menu/:tenantSlug/:salaId/:mesaId';

  static List<RouteBase> get routes => [
        GoRoute(
          path: '/menu/:tenantSlug/:salaId/:mesaId',
          builder: (context, state) {
            return MenuQrScreen(
              tenantSlug: state.pathParameters['tenantSlug']!,
              salaId: state.pathParameters['salaId'],
              mesaId: state.pathParameters['mesaId'],
            );
          },
        ),
        GoRoute(
          path: '/menu/:tenantSlug',
          builder: (context, state) {
            return MenuQrScreen(
              tenantSlug: state.pathParameters['tenantSlug']!,
            );
          },
        ),
        GoRoute(
          path: '/servicio-no-disponible',
          builder: (context, state) => const ServiceUnavailableScreen(),
        ),
      ];
}
