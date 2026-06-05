import 'package:core_auth/core_auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/billing_providers.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantInfoProvider);
    final suscripcionAsync = ref.watch(suscripcionActivaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripción y pagos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(loginControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: tenantAsync.when(
                loading: () => const LoadingSpinner(),
                error: (e, _) => Text('Error: $e'),
                data: (tenant) {
                  if (tenant == null) {
                    return const Text('No se encontró información del tenant');
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tenant.nombre,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text('Estado: ${tenant.estado}'),
                        backgroundColor: tenant.isSuspendido
                            ? const Color(0xFFFFCDD2)
                            : const Color(0xFFC8E6C9),
                      ),
                      const SizedBox(height: 24),
                      suscripcionAsync.when(
                        loading: () => const LoadingSpinner(),
                        error: (e, _) => Text('Error cargando plan: $e'),
                        data: (suscripcion) {
                          if (suscripcion == null) {
                            return const Text(
                              'No hay suscripción registrada. Contactá soporte.',
                            );
                          }

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plan ${suscripcion.planNombre}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Monto: ${CurrencyFormatter.format(suscripcion.monto, symbol: suscripcion.moneda == 'ARS' ? '\$' : suscripcion.moneda)}',
                                  ),
                                  Text('Vence: ${suscripcion.fechaFin}'),
                                  Text('Estado plan: ${suscripcion.estado}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      if (tenant.isSuspendido) ...[
                        const ErrorBanner(
                          message:
                              'Tu cuenta está suspendida. Renovala para recuperar el acceso completo.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      PrimaryButton(
                        label: 'Renovar suscripción',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Integración de pagos (MercadoPago/Stripe) — próximo release',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: 'Contactar soporte',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('soporte@saas-system-guri.com'),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
