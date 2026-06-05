import 'package:go_router/go_router.dart';

import '../layouts/admin_shell_layout.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/menu_manager_screen.dart';
import '../screens/mesas_manager_screen.dart';
import '../screens/usuarios_manager_screen.dart';

class AdminRoutes {
  AdminRoutes._();

  static const dashboard = '/admin';
  static const menu = '/admin/menu';
  static const mesas = '/admin/mesas';
  static const usuarios = '/admin/usuarios';

  static List<RouteBase> get routes => [
        ShellRoute(
          builder: (context, state, child) => AdminShellLayout(child: child),
          routes: [
            GoRoute(
              path: dashboard,
              builder: (context, state) => const AdminDashboardScreen(),
            ),
            GoRoute(
              path: menu,
              builder: (context, state) => const MenuManagerScreen(),
            ),
            GoRoute(
              path: mesas,
              builder: (context, state) => const MesasManagerScreen(),
            ),
            GoRoute(
              path: usuarios,
              builder: (context, state) => const UsuariosManagerScreen(),
            ),
          ],
        ),
      ];
}
