# SDD UI - Screens y Views
**Directorio:** `sdd/PLAN/UI/SCREENS_VIEWS/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Establecer las directrices estructurales para los archivos que representan una pantalla completa (Screen) o una vista sustancial dentro de un Layout (View). En Flutter, esta distinción ayuda a organizar el árbol de widgets.

## 2. Diferencia entre Screen y View

- **Screen:** Es un Widget que ocupa toda la pantalla y está atado a una ruta directa de `GoRouter`. Ejemplos: `LoginScreen`, `MenuClienteScreen`, `AdminDashboardScreen`. Generalmente incluyen un `Scaffold`.
- **View:** Es un Widget principal que se muestra *dentro* de un Layout u otra Screen. No tiene `Scaffold` propio. Ejemplos: `ProductosManagerView` (renderizado dentro del cuerpo principal del `AdminDashboardScreen`).

## 3. Estructura de un Archivo Screen/View en Flutter

Toda Screen en este sistema debe usar Riverpod (`ConsumerWidget`) para enlazar el estado con la UI de forma reactiva.

**Ejemplo de patrón de código recomendado:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Las pantallas deben llevar el sufijo 'Screen'
class MesasDashboardScreen extends ConsumerWidget {
  const MesasDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchar el estado (AsyncValue) de Riverpod
    final mesasState = ref.watch(mesasControllerProvider);

    // 2. Retornar el Scaffold de la pantalla principal
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Mesas')),
      // 3. Manejar los 3 estados fundamentales (Loading, Error, Data)
      body: mesasState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: ErrorBanner(message: error.toString())),
        data: (mesas) {
          if (mesas.isEmpty) {
            return const Center(child: Text('No hay mesas configuradas.'));
          }
          // Delegar en un View o Widget compuesto
          return MesasGridView(mesas: mesas);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(routerProvider).go('/admin/mesas/nueva'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## 4. Regla de "No Lógica de Negocio"
Las Screens no deben contener métodos como `await supabase.from...` ni cálculos complejos. Si un botón desencadena una acción de la base de datos, la Screen debe invocar un método expuesto por el Provider/Controller de Riverpod correspondiente. Esto asegura que la Screen sea fácilmente testeable mediante Widget Testing (mockeando el provider).
