import 'package:go_router/go_router.dart';

import '../screens/login_screen.dart';

class AuthRoutes {
  AuthRoutes._();

  static const login = '/login';

  static List<RouteBase> get routes => [
        GoRoute(
          path: login,
          builder: (context, state) {
            final redirect = state.uri.queryParameters['redirect'];
            return LoginScreen(postLoginRedirect: redirect);
          },
        ),
      ];
}
