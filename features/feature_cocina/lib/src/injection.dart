import 'package:core_network/core_network.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories/cocina_repository.dart';
import 'repositories/supabase_cocina_repository.dart';

void setupCocinaDependencies() {
  if (locator.isRegistered<CocinaRepository>()) {
    return;
  }

  locator.registerLazySingleton<CocinaRepository>(
    () => SupabaseCocinaRepository(locator<SupabaseClient>()),
  );
}
