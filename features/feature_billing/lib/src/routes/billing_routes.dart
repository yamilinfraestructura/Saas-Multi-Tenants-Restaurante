import 'package:go_router/go_router.dart';

import '../screens/billing_screen.dart';

class BillingRoutes {
  BillingRoutes._();

  static const root = '/billing';

  static List<RouteBase> get routes => [
        GoRoute(
          path: root,
          builder: (context, state) => const BillingScreen(),
        ),
      ];
}
