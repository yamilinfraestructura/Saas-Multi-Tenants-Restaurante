import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/tenant_providers.dart';

/// Soft wall cuando el tenant está suspendido: solo permite rutas de billing.
class SuspensionGate extends ConsumerWidget {
  const SuspensionGate({
    required this.child,
    this.billingRoute = '/billing',
    super.key,
  });

  final Widget child;
  final String billingRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuspended = ref.watch(isTenantSuspendedProvider);
    if (!isSuspended) {
      return child;
    }

    final router = GoRouter.maybeOf(context);
    final location = router?.state.matchedLocation ?? '';
    if (location.startsWith(billingRoute)) {
      return child;
    }

    return Stack(
      children: [
        child,
        ModalBarrier(
          dismissible: false,
          color: Colors.black.withValues(alpha: 0.72),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pause_circle_outline,
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Suscripción suspendida',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Renová tu plan para seguir operando el restaurante.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go(billingRoute),
                      child: const Text('Ir a pagos'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
