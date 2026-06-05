import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/pos_providers.dart';

class MesaCheckoutScreen extends ConsumerWidget {
  const MesaCheckoutScreen({required this.mesaId, super.key});

  final String mesaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(mesaPedidosProvider(mesaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de mesa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/pos/comedor'),
        ),
      ),
      body: pedidosAsync.when(
        loading: () => const Center(child: LoadingSpinner()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pedidos) {
          if (pedidos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Mesa libre — sin pedidos activos'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Liberar mesa',
                    onPressed: () async {
                      await ref.read(posRepositoryProvider).liberarMesa(mesaId);
                      ref.invalidate(mesaPedidosProvider(mesaId));
                      ref.invalidate(posMesasProvider);
                      if (context.mounted) context.go('/pos/comedor');
                    },
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final pedido in pedidos)
                Card(
                  child: ListTile(
                    title: Text(pedido.nombreCliente),
                    subtitle: Text(
                      'Estado: ${pedido.estado} · Cobro: ${pedido.cobroPago}',
                    ),
                    trailing: const Icon(Icons.receipt_long),
                  ),
                ),
              const SizedBox(height: 24),
              SecondaryButton(
                label: 'Imprimir ticket',
                onPressed: () async {
                  try {
                    await ref.read(thermalPrinterProvider).printTicket(
                          titulo: 'Cuenta mesa',
                          lineas: [
                            for (final p in pedidos)
                              '${p.nombreCliente} · ${p.estado}',
                          ],
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ticket enviado a impresora')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Impresión: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Cobrar y cerrar',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checkout completo — integración en Fase 4'),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
