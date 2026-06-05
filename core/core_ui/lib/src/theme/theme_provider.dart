import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

final themeProvider = Provider<ThemeData>((ref) {
  return AppTheme.light();
});

final materialAppThemeProvider = Provider<ThemeData>((ref) {
  return ref.watch(themeProvider);
});
