import 'package:core_auth/core_auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/app_drawer.dart';

class AdminShellLayout extends ConsumerWidget {
  const AdminShellLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveLayout(
      mobile: Scaffold(
        appBar: AppBar(
          title: const Text('Administración'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(loginControllerProvider.notifier).logout(),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: child,
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 260,
              child: Material(
                elevation: 1,
                child: const AppDrawer(isPermanent: true),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
