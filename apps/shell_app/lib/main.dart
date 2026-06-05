import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/app_bootstrap.dart';
import 'bootstrap/url_strategy.dart';

Future<void> main() async {
  configureUrlStrategy();
  await bootstrapShellApp();
  runApp(
    const ProviderScope(
      child: ShellApp(),
    ),
  );
}
