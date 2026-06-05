import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_providers.dart';

class UsuariosManagerScreen extends ConsumerWidget {
  const UsuariosManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Personal del restaurante',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: usuariosAsync.when(
              loading: () => const Center(child: LoadingSpinner()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (usuarios) {
                if (usuarios.isEmpty) {
                  return const Center(child: Text('No hay usuarios registrados'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 48,
                    dataRowMinHeight: 48,
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Estado')),
                    ],
                    rows: [
                      for (final u in usuarios)
                        DataRow(
                          cells: [
                            DataCell(Text(u.userName)),
                            DataCell(Text(u.email)),
                            DataCell(
                              Chip(
                                label: Text(u.activo ? 'Activo' : 'Inactivo'),
                                backgroundColor: u.activo
                                    ? const Color(0xFFC8E6C9)
                                    : const Color(0xFFFFCDD2),
                              ),
                            ),
                          ],
                        ),
                    ],
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
