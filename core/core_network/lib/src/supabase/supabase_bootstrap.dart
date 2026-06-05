import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../di/service_locator.dart';

class SupabaseBootstrap {
  SupabaseBootstrap._();

  static Future<void> initialize({String envFileName = '.env'}) async {
    await dotenv.load(fileName: envFileName);

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL y SUPABASE_ANON_KEY deben estar definidos en $envFileName.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    if (!locator.isRegistered<SupabaseClient>()) {
      locator.registerSingleton<SupabaseClient>(Supabase.instance.client);
    }
  }
}
