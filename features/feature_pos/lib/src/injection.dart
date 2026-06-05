import 'package:core_network/core_network.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories/pos_repository.dart';
import 'repositories/supabase_pos_repository.dart';
import 'services/thermal_printer.dart';
import 'services/thermal_printer_service.dart';

void setupPosDependencies() {
  if (locator.isRegistered<PosRepository>()) {
    return;
  }

  locator.registerLazySingleton<PosRepository>(
    () => SupabasePosRepository(locator<SupabaseClient>()),
  );

  if (!locator.isRegistered<ThermalPrinterService>()) {
    locator.registerLazySingleton<ThermalPrinterService>(
      createThermalPrinterService,
    );
  }
}
