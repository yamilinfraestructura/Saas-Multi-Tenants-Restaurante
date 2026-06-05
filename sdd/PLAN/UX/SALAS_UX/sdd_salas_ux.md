# SDD UX - Gestión de Salas y Mesas (Generación de QR)
**Directorio:** `sdd/PLAN/UX/SALAS_UX/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Este documento define la experiencia de usuario (UX) para el **ABM (Alta, Baja y Modificación) de Salas y Mesas** dentro del Panel de Administración (`feature_admin`). Abarca la creación de los espacios físicos del restaurante y la **generación, previsualización y exportación de Códigos QR**.

## 2. Paradigma de Interacción (ABM Salas y Mesas)

En lugar de tener dos pantallas separadas que obliguen al usuario a saltar de un lado a otro, se propone una **Vista Maestra-Detalle (Master-Detail) con Tabs**:

### 2.1 Vista Principal (`MesasManagerView`)
- **Top Bar (Tabs):** Lista horizontal de `Salas` (Ej: "Terraza", "Salón Principal", "Barra"). Al final, un botón "+ Nueva Sala".
- **Cuerpo (Grid):** Grilla visual de las `Mesas` pertenecientes a la Sala seleccionada.
- **Acción Flotante (FAB):** Botón principal para "+ Nueva Mesa".

### 2.2 Creación/Edición (SlideOver / Modal)
Cuando el admin hace clic en "Editar" una mesa o crear una nueva:
- Se abre un panel lateral (`EndDrawer`) en Desktop/Tablet, o un `BottomSheet` en Móvil.
- **Campos:** Nombre de Mesa (Ej. "1", "A"), Estado (Activa/Inactiva), y Horarios de Operación si aplica.
- **Detección de Colisiones:** Al igual que en React, la lógica debe validar que no exista otra mesa con el mismo nombre en la misma sala antes de guardar.

## 3. Experiencia de Generación y Gestión de Códigos QR

El Código QR es la puerta de entrada de los clientes al sistema. Debe manejarse de manera intuitiva y masiva.

### 3.1 Anatomía de la URL del QR
El generador del QR debe construir dinámicamente el `Deep Link` utilizando el paquete `app_links`:
`https://app.guri.com/menu/<tenant_slug_o_id>/<sala_id>/<mesa_id>`

### 3.2 Visualización en la Tarjeta de la Mesa
En el Grid del ABM de Mesas, cada tarjeta de Mesa debe mostrar:
- El nombre y estado.
- Un mini-thumbnail del Código QR generado al vuelo (usando el paquete `qr_flutter`).
- Botón **"Descargar QR"**: Descarga un archivo PNG o PDF individual de esa mesa específica.
- Botón **"Copiar Link"**: Para enviarlo por WhatsApp.

### 3.3 Exportación Masiva (El "Killer Feature")
Los restaurantes odian descargar 50 QRs uno por uno.
- En el `TopAppBar` de la vista de Mesas, debe haber un botón global: **"📥 Exportar todos los QRs"**.
- **Acción (UX):** Se abre una previsualización PDF (usando el paquete `printing`). Este PDF generará automáticamente páginas A4, maquetadas con el Logo del Restaurante y tarjetas recortables de los Códigos QR de todas las mesas de la sala seleccionada.
- **Lógica (Riverpod):** Un `FutureProvider` recorrerá todas las mesas de la sala actual, generará los QRs en memoria y los incrustará en un documento usando el paquete `pdf`.

## 4. Manejo de Errores y Excepciones
- Si falla la creación de la mesa (Ej: Falta de conexión), la UI debe mantener los datos ingresados en el SlideOver y mostrar el `ErrorBanner` rojo estipulado en `sdd_excepciones.md`.
- Si se elimina una sala, se debe alertar al usuario (`AlertDialog` destructivo) que **todas las mesas y pedidos** asociados a esa sala se verán afectados (o bloquear la eliminación si la sala tiene mesas activas, delegando la cascada a Supabase o al backend).
