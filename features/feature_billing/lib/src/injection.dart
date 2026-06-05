import 'package:core_network/core_network.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories/billing_repository.dart';
import 'repositories/supabase_billing_repository.dart';

void setupBillingDependencies() {
  if (locator.isRegistered<BillingRepository>()) {
    return;
  }

  locator.registerLazySingleton<BillingRepository>(
    () => SupabaseBillingRepository(locator<SupabaseClient>()),
  );
}
