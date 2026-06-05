import 'package:core_network/core_network.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories/public_menu_repository.dart';
import 'repositories/supabase_public_menu_repository.dart';

void setupMenuQrDependencies() {
  if (locator.isRegistered<PublicMenuRepository>()) {
    return;
  }

  locator.registerLazySingleton<PublicMenuRepository>(
    () => SupabasePublicMenuRepository(locator<SupabaseClient>()),
  );
}
