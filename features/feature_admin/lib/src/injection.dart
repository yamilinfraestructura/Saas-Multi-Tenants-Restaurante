import 'package:core_network/core_network.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories/admin_repository.dart';
import 'repositories/supabase_admin_repository.dart';

void setupAdminDependencies() {
  if (locator.isRegistered<AdminRepository>()) {
    return;
  }

  locator.registerLazySingleton<AdminRepository>(
    () => SupabaseAdminRepository(locator<SupabaseClient>()),
  );
}
