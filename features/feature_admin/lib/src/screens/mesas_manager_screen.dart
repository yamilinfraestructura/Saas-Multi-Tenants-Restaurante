import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_models.dart';
import '../providers/admin_providers.dart';

class MesasManagerScreen extends ConsumerStatefulWidget {
  const MesasManagerScreen({super.key});

  @override
  ConsumerState<MesasManagerScreen> createState() => _MesasManagerScreenState();
}

class _MesasManagerScreenState extends ConsumerState<MesasManagerScreen> {
  String? _selectedSalaId;

  @override
  Widget build(BuildContext context) {
    final salasAsync = ref.watch(salasListProvider);
    final mesasAsync = ref.watch(mesasListProvider(_selectedSalaId));

    return salasAsync.when(
      loading: () => const Center(child: LoadingSpinner()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (salas) {
        final selectedId =
            _selectedSalaId ?? (salas.isNotEmpty ? salas.first.id : null);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Mesas y salas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Nueva sala',
                    onPressed: () => _createSala(context),
                  ),
                ],
              ),
            ),
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
                    final selected = sala.id == selectedId;
                    return ChoiceChip(
                      label: Text(sala.nombre),
                      selected: selected,
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
                data: (mesas) => _MesasGrid(
                  mesas: mesas,
                  salaId: selectedId,
                  onRefresh: () {
                    ref.invalidate(mesasListProvider);
                    ref.invalidate(salasListProvider);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createSala(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva sala'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre de la sala'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await ref.read(adminRepositoryProvider).createSala(controller.text.trim());
      ref.invalidate(salasListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _MesasGrid extends ConsumerWidget {
  const _MesasGrid({
    required this.mesas,
    required this.salaId,
    required this.onRefresh,
  });

  final List<AdminMesa> mesas;
  final String? salaId;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: 'Nueva mesa',
              onPressed: salaId != null
                  ? () => _createMesa(context, ref)
                  : null,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 120,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: mesas.length,
            itemBuilder: (context, index) {
              final mesa = mesas[index];
              return Card(
                color: _colorForEstado(mesa.estado),
                child: Center(
                  child: Text(
                    mesa.valor,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _colorForEstado(String estado) {
    switch (estado) {
      case 'activa':
        return const Color(0xFFC8E6C9);
      case 'en_curso':
        return const Color(0xFFFFF9C4);
      case 'espera1':
      case 'espera2':
        return const Color(0xFFFFCCBC);
      case 'reservada':
        return const Color(0xFFBBDEFB);
      default:
        return const Color(0xFFECEFF1);
    }
  }

  Future<void> _createMesa(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva mesa'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Número o nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(adminRepositoryProvider).createMesa(
            salaId: salaId!,
            valor: controller.text.trim(),
          );
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
