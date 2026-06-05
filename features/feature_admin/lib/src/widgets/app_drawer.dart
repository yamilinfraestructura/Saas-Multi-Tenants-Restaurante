import 'package:core_auth/core_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../routes/admin_routes.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({this.isPermanent = false, super.key});

  final bool isPermanent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.storefront,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Panel Admin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    ref.watch(currentUserNivelProvider) ?? 'usuario',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          _DrawerTile(
            icon: Icons.dashboard_outlined,
            label: 'Inicio',
            route: AdminRoutes.dashboard,
            selected: currentPath == AdminRoutes.dashboard,
          ),
          _DrawerTile(
            icon: Icons.restaurant_menu,
            label: 'Menú y categorías',
            route: AdminRoutes.menu,
            selected: currentPath == AdminRoutes.menu,
          ),
          _DrawerTile(
            icon: Icons.table_restaurant,
            label: 'Mesas y salas',
            route: AdminRoutes.mesas,
            selected: currentPath == AdminRoutes.mesas,
          ),
          _DrawerTile(
            icon: Icons.people_outline,
            label: 'Usuarios',
            route: AdminRoutes.usuarios,
            selected: currentPath == AdminRoutes.usuarios,
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              if (!isPermanent) {
                Navigator.of(context).pop();
              }
              ref.read(loginControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: () {
        context.go(route);
        if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
