import 'package:core_auth/core_auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cocina_models.dart';
import '../providers/cocina_providers.dart';

class CocinaKanbanScreen extends ConsumerWidget {
  const CocinaKanbanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(pedidosActivosStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cocina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(loginControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: pedidosAsync.when(
        loading: () => const Center(child: LoadingSpinner()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (pedidos) {
          final pendientes =
              pedidos.where((p) => p.estado == 'pendiente').toList();
          final preparacion = pedidos
              .where((p) => p.estado == 'en_preparacion')
              .toList();
          final listos = pedidos.where((p) => p.estado == 'listo').toList();

        return ResponsiveLayout(
          mobile: _MobileKanban(
            pendientes: pendientes,
            preparacion: preparacion,
            listos: listos,
          ),
          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _KanbanColumn(
                  title: 'Pendiente',
                  color: const Color(0xFFFFECB3),
                  pedidos: pendientes,
                  nextEstado: 'en_preparacion',
                  actionLabel: 'Preparar',
                ),
              ),
              Expanded(
                child: _KanbanColumn(
                  title: 'En preparación',
                  color: const Color(0xFFBBDEFB),
                  pedidos: preparacion,
                  nextEstado: 'listo',
                  actionLabel: 'Listo',
                ),
              ),
              Expanded(
                child: _KanbanColumn(
                  title: 'Listo',
                  color: const Color(0xFFC8E6C9),
                  pedidos: listos,
                  nextEstado: 'entregado',
                  actionLabel: 'Entregar',
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }
}

class _MobileKanban extends StatelessWidget {
  const _MobileKanban({
    required this.pendientes,
    required this.preparacion,
    required this.listos,
  });

  final List<CocinaPedido> pendientes;
  final List<CocinaPedido> preparacion;
  final List<CocinaPedido> listos;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Pendiente'),
              Tab(text: 'Preparación'),
              Tab(text: 'Listo'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _KanbanColumn(
                  title: 'Pendiente',
                  color: const Color(0xFFFFECB3),
                  pedidos: pendientes,
                  nextEstado: 'en_preparacion',
                  actionLabel: 'Preparar',
                ),
                _KanbanColumn(
                  title: 'En preparación',
                  color: const Color(0xFFBBDEFB),
                  pedidos: preparacion,
                  nextEstado: 'listo',
                  actionLabel: 'Listo',
                ),
                _KanbanColumn(
                  title: 'Listo',
                  color: const Color(0xFFC8E6C9),
                  pedidos: listos,
                  nextEstado: 'entregado',
                  actionLabel: 'Entregar',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.pedidos,
    required this.nextEstado,
    required this.actionLabel,
  });

  final String title;
  final Color color;
  final List<CocinaPedido> pedidos;
  final String nextEstado;
  final String actionLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '$title (${pedidos.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          pedido.nombreCliente,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Mesa: ${pedido.mesaId.substring(0, 8)}…',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: actionLabel,
                          onPressed: () async {
                            await ref
                                .read(cocinaRepositoryProvider)
                                .updateEstado(pedido.id, nextEstado);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
