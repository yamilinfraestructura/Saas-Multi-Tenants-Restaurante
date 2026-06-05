import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import 'package:feature_admin/feature_admin.dart';
import 'package:feature_billing/feature_billing.dart';
import 'package:feature_cocina/feature_cocina.dart';
import 'package:feature_menu_qr/feature_menu_qr.dart';
import 'package:feature_pos/feature_pos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/app_router.dart';

class ShellApp extends ConsumerWidget {
  const ShellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(materialAppThemeProvider);

    return MaterialApp.router(
      title: 'SaaS System Guri',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return SuspensionGate(
          billingRoute: '/billing',
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

Future<void> bootstrapShellApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  locator.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(locator<SupabaseClient>()),
  );
  locator.registerLazySingleton<TenantRepository>(
    () => SupabaseTenantRepository(locator<SupabaseClient>()),
  );
  setupMenuQrDependencies();
  setupAdminDependencies();
  setupPosDependencies();
  setupCocinaDependencies();
  setupBillingDependencies();
}
