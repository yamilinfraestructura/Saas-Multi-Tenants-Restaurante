# SDD UX - Experiencia de Autenticación (Login)
**Directorio:** `sdd/PLAN/UX/LOGIN_UX/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Define la experiencia de inicio de sesión de los empleados, administradores del restaurante, y superadmins del sistema.

## 2. Flujo de Autenticación SaaS (Sin Passwordless por defecto)

Para el personal, el flujo basado en **Email + Contraseña** es el más seguro y rápido en terminales compartidas (ej. la Tablet de la caja).

### 2.1 La Pantalla de Login (feature_auth)
- **Layout:** Pantalla dividida (Split Screen) en resoluciones amplias.
  - Mitad izquierda (o fondo): Imagen decorativa o branding del ecosistema SaaS.
  - Mitad derecha: Formulario centrado.
- **Inputs:**
  - `TextFormField` para Email (con validación regex instantánea tipo `onUserInteraction`).
  - `TextFormField` para Password (con botón toggle `suffixIcon` para mostrar/ocultar contraseña).
- **Botón de Ingreso:** Debe reaccionar a la tecla `Enter` del teclado físico mediante la propiedad `onSubmitted` en los inputs.

### 2.2 Transición Asíncrona (UX)
Cuando el usuario presiona "Ingresar":
1. El botón cambia a estado de carga (Spinner).
2. Los campos de texto se deshabilitan (`enabled: false`) para evitar doble submit.
3. Llamada a `Supabase.auth.signInWithPassword()`.
4. Si falla: Animación de "shake" en el formulario y mensaje rojo debajo del campo de error.
5. Si éxito: Animación hero o transición "Fade" suave a la pantalla principal correspondiente (`Admin`, `Mesas`, o `Cocina`).

### 2.3 Mantener la Sesión
- Supabase Auth en Flutter persiste la sesión automáticamente mediante almacenamiento seguro nativo (Secure Storage de iOS/Android).
- La UX al abrir la app de nuevo debe ser instantánea: un Splash screen nativo (`flutter_native_splash`) que verifica si hay token válido y salta directamente al dashboard en menos de un segundo, sin mostrar la pantalla de login siquiera un parpadeo.
