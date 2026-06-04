# SDD – Excepciones (UI)

## Propósito
Definir el catálogo de **excepciones** que pueden producirse en la capa UI del proyecto **SaaS System Guri**, así como los mensajes de usuario estándar que deben mostrarse. Esta guía sirve a los desarrolladores para lanzar errores consistentes y a los diseñadores para mantener la coherencia visual de los *alerts*.

## Principios
- **Coherencia**: todos los errores se presentan mediante el componente `SaasAlert` (ver `ALERTS/sdd_alerts.md`).
- **Accesibilidad**: el `title` del `Alert` actúa como *ARIA role* `alertdialog` y el mensaje tiene contraste ≥ 4.5:1.
- **Internacionalización**: los mensajes están preparados para ser externalizados a archivos `.arb` (Flutter intl) – se incluye la clave y la cadena en inglés.
- **Logging**: cada excepción se registra con `logger.e` (p. ej., `logger.e('NetworkError', error: e)`).

## Catálogo de excepciones
| Clase | Código HTTP / Código interno | Mensaje al usuario (clave i18n) | Tipo de `SaasAlert` | Comentario |
|-------|------------------------------|---------------------------------|---------------------|------------|
| `NetworkError` | N/A (sin respuesta) | `error_network` – "No se pudo conectar a los servidores. Revisa tu conexión e inténtalo de nuevo." | error | Falta de conectividad o timeout. |
| `AuthError` | 401 | `error_auth` – "Credenciales inválidas o sesión expirada. Por favor, inicia sesión nuevamente." | error | Token inválido, expirado o revocado. |
| `PermissionDenied` | 403 | `error_permission` – "No tienes permiso para realizar esta acción." | warning | Intento de acceder a recurso sin rol adecuado. |
| `NotFoundError` | 404 | `error_not_found` – "Recurso no encontrado. Puede que haya sido eliminado o la URL sea incorrecta." | warning | Recurso inexistente en Supabase. |
| `ValidationError` | 422 | `error_validation` – "Los datos ingresados son inválidos. Revisa los campos marcados." | error | Errores de formulario provistos por la API. |
| `ServerError` | 500‑599 | `error_server` – "Error interno del servidor. Por favor, intenta más tarde o contacta soporte." | error | Fallos inesperados del backend. |
| `TimeoutError` | N/A (timeout) | `error_timeout` – "La operación está tomando demasiado tiempo. Inténtalo de nuevo." | warning | Operación asincrónica excede el límite de tiempo. |
| `UnexpectedError` | N/A | `error_unexpected` – "Ha ocurrido un error inesperado. Por favor, reinicia la aplicación o contacta soporte." | error | Captura genérica para excepciones no mapeadas. |

## Uso recomendado en código UI
```dart
try {
  await repository.fetchData();
} on NetworkError catch (e) {
  logger.e('NetworkError', error: e);
  showDialog(
    context: context,
    builder: (_) => const SaasAlert(
      title: 'Error de red',
      message: 'error_network',
      type: SaasAlertType.error,
    ),
  );
}
```

## Integración con `SaasAlert`
- El **title** del `Alert` corresponde a la clave i18n (`error_network`, `error_auth`, …). 
- El **type** se asigna según la columna *Tipo de `SaasAlert`* (error ⚠️, warning ⚠️, info ℹ️, success ✅).
- En **web**, los alerts usan `AnimatedOpacity` para una aparición suave.

## Tests
- **Unit test** para cada excepción: lanzar la excepción y verificar que `SaasAlert` aparece con la clave correcta.
- **Golden test** para los distintos tipos de alert (error, warning, info, success).

---
*Este documento forma parte del conjunto SDD modular bajo `sdd/PLAN/UI/EXCEPCIONES`. Cada sub‑directorio sigue el mismo esquema de documentación.*
