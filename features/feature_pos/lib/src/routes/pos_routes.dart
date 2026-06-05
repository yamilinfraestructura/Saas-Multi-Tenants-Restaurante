import 'package:go_router/go_router.dart';

import '../screens/comedor_screen.dart';
import '../screens/mesa_checkout_screen.dart';

class PosRoutes {
  PosRoutes._();

  static const comedor = '/pos/comedor';
  static const mesaCheckout = '/pos/mesa/:mesaId';

  static List<RouteBase> get routes => [
        GoRoute(
          path: comedor,
          builder: (context, state) => const ComedorScreen(),
        ),
        GoRoute(
          path: mesaCheckout,
          builder: (context, state) => MesaCheckoutScreen(
            mesaId: state.pathParameters['mesaId']!,
          ),
        ),
      ];
}
