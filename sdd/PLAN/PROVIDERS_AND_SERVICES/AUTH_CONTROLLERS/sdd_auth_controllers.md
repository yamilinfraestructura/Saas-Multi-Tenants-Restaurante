# SDD - Controladores de Autenticación
**Directorio:** `sdd/PLAN/PROVIDERS_AND_SERVICES/AUTH_CONTROLLERS/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Definir la arquitectura del manejo de estado para la autenticación y la resolución del Tenant (Restaurante) utilizando **Riverpod**.

## 2. Flujo de Estado (Auth State)

En Flutter, la autenticación no debe ser un estado estático que se consulta de forma imperativa. Debe ser un flujo reactivo.

### 2.1 Proveedor Central: `authProvider`
Se creará un `StreamProvider` en Riverpod que escuche los cambios de estado de Supabase Auth (`Supabase.instance.client.auth.onAuthStateChange`).

```dart
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
```

### 2.2 Proveedor del Usuario: `currentUserProvider`
Derivado del `authStateProvider`, este proveedor extraerá el usuario actual y su `tenant_id` del JWT.

```dart
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user;
});

final currentTenantIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  // El tenant_id viaja en los app_metadata del JWT gracias al webhook/trigger de registro
  return user?.appMetadata['tenant_id'] as String?;
});
```

## 3. Redirección Reactiva (GoRouter + Riverpod)

El mayor beneficio de este enfoque es que GoRouter puede escuchar a Riverpod. 
Si el token expira o el usuario hace logout, `currentUserProvider` emitirá `null`. GoRouter, configurado con un `refreshListenable`, detectará este cambio y expulsará al usuario automáticamente a la pantalla de `/login`, sin importar en qué pantalla oculta de la app se encuentre.

## 4. Controladores de Login (StateNotifier)
Para la pantalla de login, se usará un `AsyncNotifier` que maneje el estado de carga y posibles errores durante el submit del formulario.

```dart
class LoginController extends AsyncNotifier<void> {
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(email, password);
    });
  }
}
```
