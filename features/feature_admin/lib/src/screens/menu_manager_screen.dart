import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_models.dart';
import '../providers/admin_providers.dart';

class MenuManagerScreen extends ConsumerStatefulWidget {
  const MenuManagerScreen({super.key});

  @override
  ConsumerState<MenuManagerScreen> createState() => _MenuManagerScreenState();
}

class _MenuManagerScreenState extends ConsumerState<MenuManagerScreen> {
  String? _selectedCategoriaId;

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasListProvider);
    final productosAsync = ref.watch(productosListProvider(_selectedCategoriaId));

    return categoriasAsync.when(
      loading: () => const Center(child: LoadingSpinner()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (categorias) {
        final selectedId = _selectedCategoriaId ??
            (categorias.isNotEmpty ? categorias.first.id : null);

        return ResponsiveLayout(
          mobile: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: categorias.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categorias[index];
                    return ChoiceChip(
                      label: Text(
                        cat.emoji != null
                            ? '${cat.emoji} ${cat.nombre}'
                            : cat.nombre,
                      ),
                      selected: cat.id == selectedId,
                      onSelected: (_) =>
                          setState(() => _selectedCategoriaId = cat.id),
                    );
                  },
                ),
              ),
              Expanded(
                child: productosAsync.when(
                  loading: () => const Center(child: LoadingSpinner()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (productos) => _ProductGrid(
                    productos: productos,
                    categoriaId: selectedId,
                    onRefresh: () {
                      ref.invalidate(productosListProvider);
                      ref.invalidate(categoriasListProvider);
                    },
                  ),
                ),
              ),
            ],
          ),
          desktop: Row(
            children: [
              SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Categorías',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: categorias.length,
                        itemBuilder: (context, index) {
                          final cat = categorias[index];
                          return ListTile(
                            selected: cat.id == selectedId,
                            title: Text(
                              cat.emoji != null
                                  ? '${cat.emoji} ${cat.nombre}'
                                  : cat.nombre,
                            ),
                            onTap: () =>
                                setState(() => _selectedCategoriaId = cat.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: productosAsync.when(
                  loading: () => const Center(child: LoadingSpinner()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (productos) => _ProductGrid(
                    productos: productos,
                    categoriaId: selectedId,
                    onRefresh: () {
                      ref.invalidate(productosListProvider);
                      ref.invalidate(categoriasListProvider);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductGrid extends ConsumerStatefulWidget {
  const _ProductGrid({
    required this.productos,
    required this.categoriaId,
    required this.onRefresh,
  });

  final List<AdminProducto> productos;
  final String? categoriaId;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends ConsumerState<_ProductGrid> {
  bool _isSaving = false;

  Future<void> _showCreateSheet() async {
    if (widget.categoriaId == null) return;

    final nombreController = TextEditingController();
    final precioController = TextEditingController(text: '0');

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nuevo producto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Guardar',
                isLoading: _isSaving,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(adminRepositoryProvider).createProducto(
            AdminProducto(
              id: '',
              nombre: nombreController.text.trim(),
              precio: double.tryParse(precioController.text) ?? 0,
              categoriaId: widget.categoriaId!,
              estado: 'activo',
              tipo: 'comida',
            ),
          );
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto creado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Productos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Agregar producto',
                onPressed: widget.categoriaId != null ? _showCreateSheet : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.productos.isEmpty
              ? const Center(child: Text('Sin productos en esta categoría'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.productos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = widget.productos[index];
                    return ListTile(
                      title: Text(p.nombre),
                      subtitle: Text(CurrencyFormatter.format(p.precio)),
                      trailing: Chip(label: Text(p.estado)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
