import 'package:core_auth/core_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SuspensionGate muestra modal cuando tenant suspendido', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isTenantSuspendedProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return SuspensionGate(
                child: Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Contenido bloqueado'),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Suscripción suspendida'), findsOneWidget);
    expect(find.text('Ir a pagos'), findsOneWidget);
  });
}
