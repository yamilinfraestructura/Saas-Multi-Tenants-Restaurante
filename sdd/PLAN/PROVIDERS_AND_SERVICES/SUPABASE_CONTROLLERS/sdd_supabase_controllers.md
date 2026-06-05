# SDD - Controladores de Supabase (Data Layer)
**Directorio:** `sdd/PLAN/PROVIDERS_AND_SERVICES/SUPABASE_CONTROLLERS/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Separar claramente la **lógica de acceso a datos** (Supabase) del estado de la interfaz de usuario (Riverpod).

## 2. Arquitectura GetIt + Riverpod

Para mantener el código limpio y testeable, las llamadas a Supabase (`supabase.from('tabla')...`) **nunca** deben ir directamente en la UI ni dentro de los providers de Riverpod. Se debe usar el patrón Repositorio.

### 2.1 Repositorios (Inyectados con GetIt)
Los repositorios contienen las consultas SQL. Se registran en `GetIt` como Singletons o LazySingletons.

```dart
abstract class MesasRepository {
  Future<List<Mesa>> getMesas();
  Future<void> liberarMesa(String mesaId);
}

class SupabaseMesasRepository implements MesasRepository {
  final SupabaseClient _client;
  SupabaseMesasRepository(this._client);

  @override
  Future<List<Mesa>> getMesas() async {
    final res = await _client.from('mesas').select();
    return res.map((e) => Mesa.fromJson(e)).toList();
  }
}
```

### 2.2 Providers (Riverpod)
Riverpod consume los repositorios desde GetIt para exponer el estado a la UI.

```dart
// 1. Obtener el repositorio desde GetIt
final mesasRepositoryProvider = Provider<MesasRepository>((ref) {
  return GetIt.I<MesasRepository>();
});

// 2. Exponer los datos de forma asíncrona a la UI
final mesasListProvider = FutureProvider<List<Mesa>>((ref) async {
  final repository = ref.watch(mesasRepositoryProvider);
  return repository.getMesas();
});
```

## 3. Manejo de Streams (Realtime)
Para vistas como la de Cocina, donde los pedidos deben aparecer al instante, se usarán `StreamProviders` conectados a los canales Realtime de Supabase.

```dart
final pedidosActivosStreamProvider = StreamProvider<List<Pedido>>((ref) {
  final supabase = GetIt.I<SupabaseClient>();
  return supabase.from('pedidos')
      .stream(primaryKey: ['id'])
      .eq('estado', 'pendiente')
      .map((list) => list.map((e) => Pedido.fromJson(e)).toList());
});
```
