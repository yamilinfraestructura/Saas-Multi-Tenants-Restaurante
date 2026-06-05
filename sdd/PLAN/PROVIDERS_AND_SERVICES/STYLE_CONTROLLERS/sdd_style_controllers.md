# SDD - Controladores de Estilos y Temas
**Directorio:** `sdd/PLAN/PROVIDERS_AND_SERVICES/STYLE_CONTROLLERS/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Definir cómo se manejará el cambio dinámico de tema visual (colores, logotipos) dependiendo del restaurante (Tenant) activo.

## 2. Dynamic Theming con Riverpod

En un SaaS multi-tenant, si el cliente escanea el QR de "Burger King", la app debe ser roja y amarilla. Si escanea "Starbucks", debe ser verde. Esto se logra controlando el `ThemeData` de Flutter mediante un Provider.

### 2.1 El Tema Provider
El provider principal de la aplicación (`MaterialApp` o `MaterialApp.router`) escuchará un objeto de configuración del Tenant.

```dart
final tenantThemeProvider = Provider<ThemeData>((ref) {
  // Escuchar la configuración del negocio (obtenida previamente de Supabase)
  final config = ref.watch(configuracionNegocioProvider).value;
  
  // Extraer colores o usar fallbacks por defecto
  final primaryColorHex = config?.colorPrimario ?? '#2C687B';
  final primaryColor = HexColor(primaryColorHex);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
    fontFamily: 'Inter',
    // Personalización de componentes base
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
  );
});
```

### 2.2 Integración en la App
```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(tenantThemeProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: theme,
      // La app cambia de color automáticamente en toda su jerarquía
      // tan pronto como el tenantThemeProvider emite un nuevo ThemeData.
    );
  }
}
```
