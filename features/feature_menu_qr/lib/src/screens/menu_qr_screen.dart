import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_utils/core_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_models.dart';
import '../providers/menu_providers.dart';
import 'service_unavailable_screen.dart';

class MenuQrScreen extends ConsumerStatefulWidget {
  const MenuQrScreen({
    required this.tenantSlug,
    this.salaId,
    this.mesaId,
    super.key,
  });

  final String tenantSlug;
  final String? salaId;
  final String? mesaId;

  @override
  ConsumerState<MenuQrScreen> createState() => _MenuQrScreenState();
}

class _MenuQrScreenState extends ConsumerState<MenuQrScreen> {
  String? _selectedCategoriaId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(publicMenuProvider(widget.tenantSlug));

    return menuAsync.when(
      loading: () => const Scaffold(
        body: Center(child: LoadingSpinner()),
      ),
      error: (_, __) => const ServiceUnavailableScreen(),
      data: (menu) {
        if (!menu.tenant.isAvailable) {
          return const ServiceUnavailableScreen();
        }

        final categorias = [...menu.categorias]
          ..sort((a, b) => a.posicion.compareTo(b.posicion));
        final selectedId = _selectedCategoriaId ??
            (categorias.isNotEmpty ? categorias.first.id : null);
        final productos = menu.productos
            .where((p) => p.categoriaId == selectedId)
            .toList();

        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  if (menu.tenant.logoUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: menu.tenant.logoUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(menu.tenant.nombre),
                  ),
                ],
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (categorias.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categorias.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categorias[index];
                        final selected = cat.id == selectedId;
                        return ChoiceChip(
                          label: Text(
                            cat.emoji != null
                                ? '${cat.emoji} ${cat.nombre}'
                                : cat.nombre,
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedCategoriaId = cat.id),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: productos.isEmpty
                      ? const Center(child: Text('No hay productos disponibles'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: productos.length,
                          itemBuilder: (context, index) {
                            return _ProductCard(producto: productos[index]);
                          },
                        ),
                ),
              ],
            ),
            floatingActionButton: _CartFab(
              mesaId: widget.mesaId,
              tenantId: menu.tenant.id,
              isSubmitting: _isSubmitting,
              onSubmit: () => _submitPedido(menu.tenant.id),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          ),
        );
      },
    );
  }

  Future<void> _submitPedido(String tenantId) async {
    final items = ref.read(cartProvider);
    if (items.isEmpty || widget.mesaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.mesaId == null
                ? 'Escaneá el QR de tu mesa para pedir'
                : 'Agregá productos al carrito',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(publicMenuRepositoryProvider).createPedido(
            tenantId: tenantId,
            mesaId: widget.mesaId!,
            nombreCliente: 'Cliente QR',
            items: items,
          );
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pedido enviado a cocina!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar pedido: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.producto});

  final Producto producto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(cartProvider.notifier).addProduct(producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: producto.img != null
                  ? CachedNetworkImage(
                      imageUrl: producto.img!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ColoredBox(
                        color: Color(0xFFECEFF1),
                        child: Center(child: LoadingSpinner()),
                      ),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFECEFF1),
                        child: Icon(Icons.restaurant),
                      ),
                    )
                  : const ColoredBox(
                      color: Color(0xFFECEFF1),
                      child: Center(child: Icon(Icons.restaurant)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(producto.precio),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartFab extends ConsumerWidget {
  const _CartFab({
    required this.mesaId,
    required this.tenantId,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final String? mesaId;
  final String tenantId;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartItemCountProvider);
    final total = ref.watch(cartTotalProvider);

    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(32),
        color: Theme.of(context).colorScheme.primary,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: isSubmitting ? null : () => _showCartSheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(label: Text('$count'), child: const Icon(Icons.shopping_cart)),
                const SizedBox(width: 12),
                Text(
                  'Ver carrito · ${CurrencyFormatter.format(total)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final items = ref.watch(cartProvider);
            final total = ref.watch(cartTotalProvider);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tu pedido',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...items.map(
                    (item) => ListTile(
                      title: Text(item.producto.nombre),
                      subtitle: Text(CurrencyFormatter.format(item.producto.precio)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  item.producto.id,
                                  item.cantidad - 1,
                                ),
                          ),
                          Text('${item.cantidad}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .updateQuantity(
                                  item.producto.id,
                                  item.cantidad + 1,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        CurrencyFormatter.format(total),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: mesaId != null ? 'Pedir' : 'Necesitás escanear mesa',
                      isLoading: isSubmitting,
                      onPressed: mesaId != null ? onSubmit : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
