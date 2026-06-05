import 'package:core_auth/core_auth.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/pos_models.dart';
import '../providers/pos_providers.dart';

class ComedorScreen extends ConsumerStatefulWidget {
  const ComedorScreen({super.key});

  @override
  ConsumerState<ComedorScreen> createState() => _ComedorScreenState();
}

class _ComedorScreenState extends ConsumerState<ComedorScreen> {
  String? _selectedSalaId;

  @override
  Widget build(BuildContext context) {
    final salasAsync = ref.watch(posSalasProvider);
    final mesasAsync = ref.watch(posMesasProvider(_selectedSalaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista comedor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(loginControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: salasAsync.when(
        loading: () => const Center(child: LoadingSpinner()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (salas) {
          final selectedId =
              _selectedSalaId ?? (salas.isNotEmpty ? salas.first.id : null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (salas.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: salas.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final sala = salas[index];
                      return ChoiceChip(
                        label: Text(sala.nombre),
                        selected: sala.id == selectedId,
                        onSelected: (_) =>
                            setState(() => _selectedSalaId = sala.id),
                      );
                    },
                  ),
                ),
              Expanded(
                child: mesasAsync.when(
                  loading: () => const Center(child: LoadingSpinner()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (mesas) => _MesasGrid(mesas: mesas),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MesasGrid extends StatelessWidget {
  const _MesasGrid({required this.mesas});

  final List<PosMesa> mesas;

  @override
  Widget build(BuildContext context) {
    if (mesas.isEmpty) {
      return const Center(child: Text('No hay mesas en esta sala'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: mesas.length,
      itemBuilder: (context, index) {
        final mesa = mesas[index];
        return _MesaCard(mesa: mesa);
      },
    );
  }
}

class _MesaCard extends StatelessWidget {
  const _MesaCard({required this.mesa});

  final PosMesa mesa;

  Color get _color {
    switch (mesa.estado) {
      case 'activa':
        return const Color(0xFF4CAF50);
      case 'en_curso':
        return const Color(0xFFFFB300);
      case 'espera1':
      case 'espera2':
        return const Color(0xFFFF5722);
      case 'reservada':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/pos/mesa/${mesa.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mesa.valor,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                mesa.estado.replaceAll('_', ' '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (mesa.ultimoPedido != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatElapsed(mesa.ultimoPedido!),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatElapsed(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    return '${diff.inMinutes} min';
  }
}
