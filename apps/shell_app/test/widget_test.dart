import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shell_app/bootstrap/app_bootstrap.dart';

void main() {
  testWidgets('ShellApp muestra pantalla de login', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ShellApp(),
      ),
    );

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
