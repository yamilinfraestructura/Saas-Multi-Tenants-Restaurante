# SDD — Webhooks del Sistema SaaS
**Directorio:** `sdd/PLAN/BASE_DE_DATOS/WEB_HOOKS/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  
**Fecha:** 2026-06-04

---

## 1. Propósito

Este documento especifica todos los **Database Webhooks** que deben configurarse en Supabase para el sistema SaaS. Los webhooks permiten disparar lógica del lado del servidor (Edge Functions o servicios externos) de forma reactiva ante cambios en la base de datos.

En este sistema los webhooks se utilizan para:
- Enviar **notificaciones push** (FCM vía Firebase Messaging) a dispositivos relevantes.
- Enviar **emails transaccionales** (vía Resend o SMTP) al cliente o al negocio.
- Disparar **acciones en RevenueCat** cuando cambia el plan de suscripción.
- Actualizar **estado de mesas en tiempo real** en todos los clientes conectados.
- Auditar **cambios de suscripción** para billing.

---

## 2. Tecnología

| Capa | Tecnología |
|------|-----------|
| Origen del evento | Supabase Database Webhook |
| Runtime del webhook | Supabase Edge Functions (Deno) |
| Notificaciones push | Firebase Cloud Messaging (FCM) — `firebase_messaging` |
| Email transaccional | Resend (recomendado) o SMTP propio |
| Subscriptions en tiempo real | Supabase Realtime (ya incluido — no requiere webhook) |
| Canal de auditoría | Tabla `audit_log` (ver Triggers) |

> **Nota:** Supabase Realtime cubre la sincronización de estado en tiempo real para la app Flutter (cambios en `pedidos`, `mesas`, etc.) **sin necesidad de webhook**. Los webhooks aquí especificados se usan exclusivamente para acciones asíncronas fuera del cliente.

---

## 3. Convención de nombres

```
wh_<tabla>_<evento>
```

Ejemplos: `wh_pedidos_insert`, `wh_reservas_estado_update`, `wh_tenant_suscripciones_insert`

---

## 4. Webhooks requeridos

---

### 4.1 `wh_pedidos_insert` — Nuevo pedido recibido

| Campo | Valor |
|-------|-------|
| **Tabla** | `pedidos` |
| **Evento** | `INSERT` |
| **Edge Function** | `notify-nuevo-pedido` |
| **Prioridad** | 🔴 Alta |

**Descripción:**  
Cuando se crea un nuevo pedido, se notifica al personal de cocina/bar y al supervisor de turno. Es el webhook más crítico del sistema: cualquier demora en este disparo afecta directamente la operación del restaurante.

**Payload esperado (NEW record):**
```json
{
  "id": "uuid",
  "tenant_id": "uuid",
  "mesa_id": "uuid",
  "nombre_cliente": "string",
  "estado": "pendiente",
  "total": 0.00,
  "fecha_creacion": "timestamp"
}
```

**Lógica de la Edge Function `notify-nuevo-pedido`:**
1. Recuperar los `usuario_id` del tenant que tengan el permiso `COCINA_VER` o `BAR_KANBAN` activo (`asignaciones`).
2. Obtener los FCM tokens de esos usuarios.
3. Enviar push notification con:
   - **Título:** `"Nuevo pedido — Mesa {valor_mesa}"`
   - **Body:** `"{nombre_cliente} — ${total}"`
   - **Data:** `{ tipo: "nuevo_pedido", pedido_id, mesa_id, tenant_id }`
4. Actualizar `mesas.ultimo_pedido = NOW()` y `mesas.estado = 'en_curso'`.

**Receptores de la notificación:**
- Usuarios con rol `cocina` y permiso `COCINA_VER`
- Usuarios con rol `bar` y permiso `BAR_KANBAN`
- Usuarios con rol `supervisor` o `admin` con `PEDIDOS_ACTIVOS`

---

### 4.2 `wh_pedidos_estado_update` — Cambio de estado de pedido

| Campo | Valor |
|-------|-------|
| **Tabla** | `pedidos` |
| **Evento** | `UPDATE` |
| **Columna monitoreada** | `estado` |
| **Edge Function** | `notify-estado-pedido` |
| **Prioridad** | 🔴 Alta |

**Descripción:**  
Notifica al mozo asignado o al supervisor cuando un pedido cambia de estado (ej: de `en_preparacion` a `listo`). La transición más importante es `listo` → alerta al mozo para retirar el pedido de cocina.

**Condición de filtro:**
```sql
NEW.estado IS DISTINCT FROM OLD.estado
```

**Matriz de notificaciones por transición:**

| Estado anterior | Estado nuevo | Notificar a |
|----------------|--------------|-------------|
| `pendiente` | `en_preparacion` | Mozo de la mesa, Supervisor |
| `en_preparacion` | `listo` | **Mozo de la mesa** (urgente) |
| `listo` | `entregado` | Supervisor |
| `entregado` | `completado` | Admin (cierre de cuenta) |

**Payload adicional necesario:**
- Join con `mesas` para obtener `personal_asignado_id` (mozo)
- Join con `usuarios` para obtener FCM token del mozo

---

### 4.3 `wh_pedidos_cuenta_solicitada` — Cliente solicita la cuenta

| Campo | Valor |
|-------|-------|
| **Tabla** | `pedidos` |
| **Evento** | `UPDATE` |
| **Columna monitoreada** | `cuenta_solicitada` |
| **Edge Function** | `notify-cuenta-solicitada` |
| **Prioridad** | 🔴 Alta |

**Descripción:**  
Cuando el cliente solicita la cuenta desde el menú QR (`cuenta_solicitada = TRUE`), se alerta al mozo asignado y al supervisor para que procesen el cobro.

**Condición de filtro:**
```sql
NEW.cuenta_solicitada = TRUE AND OLD.cuenta_solicitada = FALSE
```

**Notificación:**
- **Título:** `"⚡ Cuenta solicitada — Mesa {valor_mesa}"`
- **Body:** `"{nombre_cliente} está listo para pagar."`
- **Data:** `{ tipo: "cuenta_solicitada", pedido_id, mesa_id }`
- **Receptores:** Mozo de la mesa + Supervisor activo

---

### 4.4 `wh_reservas_insert` — Nueva reserva recibida

| Campo | Valor |
|-------|-------|
| **Tabla** | `reservas` |
| **Evento** | `INSERT` |
| **Edge Function** | `notify-nueva-reserva` |
| **Prioridad** | 🟡 Media |

**Descripción:**  
Cuando un cliente realiza una reserva (estado inicial `pendiente`), se envían dos acciones:
1. **Email de confirmación al cliente** (informando que está pendiente de aprobación).
2. **Push notification al Admin/Supervisor** para que confirme o rechace.

**Payload clave:**
```json
{
  "id": "uuid",
  "tenant_id": "uuid",
  "numero_reserva": "string",
  "nombre_cliente": "string",
  "email_cliente": "string",
  "fecha_reserva": "date",
  "cantidad_personas": 2,
  "estado": "pendiente"
}
```

**Edge Function `notify-nueva-reserva`:**
1. Enviar email al cliente (`email_cliente`) con resumen de la reserva y el mensaje:  
   _"Recibimos tu reserva #{numero_reserva}. Será confirmada a la brevedad."_
2. Push notification al Admin del tenant:  
   - **Título:** `"📅 Nueva reserva — {nombre_cliente}"`
   - **Body:** `"{fecha_reserva} — {cantidad_personas} personas"`

---

### 4.5 `wh_reservas_estado_update` — Estado de reserva cambia

| Campo | Valor |
|-------|-------|
| **Tabla** | `reservas` |
| **Evento** | `UPDATE` |
| **Columna monitoreada** | `estado` |
| **Edge Function** | `notify-estado-reserva` |
| **Prioridad** | 🟡 Media |

**Descripción:**  
Cuando el admin confirma o rechaza la reserva, se envía un email al cliente con el resultado.

**Condición de filtro:**
```sql
NEW.estado IS DISTINCT FROM OLD.estado
AND NEW.estado IN ('confirmada', 'cancelada')
```

**Lógica:**
- Si `confirmada` → Email: _"¡Tu reserva #{numero_reserva} fue confirmada! Te esperamos el {fecha_reserva}."_ + mensaje de `reservas_config.mensaje_confirmacion`
- Si `cancelada` → Email: _"Lamentamos informarte que tu reserva #{numero_reserva} fue cancelada."_

---

### 4.6 `wh_tenant_suscripciones_insert` — Nueva suscripción / pago

| Campo | Valor |
|-------|-------|
| **Tabla** | `tenant_suscripciones` |
| **Evento** | `INSERT` |
| **Edge Function** | `notify-nueva-suscripcion` |
| **Prioridad** | 🟡 Media |

**Descripción:**  
Cuando se registra un nuevo período de suscripción (pago exitoso), se:
1. Actualiza `tenants.plan_actual` al nuevo plan.
2. Envía email de bienvenida/renovación al Admin del tenant.
3. (Opcional) Llama al webhook de RevenueCat para sincronizar el entitlement.

**Lógica:**
```sql
-- Se puede delegar al trigger: set_tenant_plan_from_suscripcion
-- El webhook se usa solo para la notificación externa (email/RC)
```

---

### 4.7 `wh_tenant_estado_update` — Tenant suspendido o reactivado

| Campo | Valor |
|-------|-------|
| **Tabla** | `tenants` |
| **Evento** | `UPDATE` |
| **Columna monitoreada** | `estado` |
| **Edge Function** | `notify-tenant-estado` |
| **Prioridad** | 🟠 Alta (Billing) |

**Descripción:**  
Cuando un tenant pasa a `suspendido` (por vencimiento de suscripción) o vuelve a `activo` (por renovación):
1. Email al Admin del tenant informando el cambio.
2. Si `suspendido`: push notification urgente al Admin.
3. Log en tabla de auditoría.

**Condición de filtro:**
```sql
NEW.estado IS DISTINCT FROM OLD.estado
AND NEW.estado IN ('suspendido', 'activo')
```

---

### 4.8 `wh_stock_bajo_insert` — Producto con stock bajo

| Campo | Valor |
|-------|-------|
| **Tabla** | `productos` |
| **Evento** | `UPDATE` |
| **Columna monitoreada** | `stock` |
| **Edge Function** | `notify-stock-bajo` |
| **Prioridad** | 🟢 Baja |

**Descripción:**  
Cuando el `stock` de un producto cae por debajo de `stock_minimo`, se alerta al Admin.

**Condición de filtro:**
```sql
NEW.stock <= NEW.stock_minimo AND OLD.stock > OLD.stock_minimo
```

**Notificación:**
- **Título:** `"⚠️ Stock bajo — {nombre_producto}"`
- **Body:** `"Quedan {stock} unidades. Mínimo recomendado: {stock_minimo}."`
- **Receptores:** Admin del tenant

---

## 5. Arquitectura de Edge Functions

```
supabase/functions/
├── notify-nuevo-pedido/
│   └── index.ts
├── notify-estado-pedido/
│   └── index.ts
├── notify-cuenta-solicitada/
│   └── index.ts
├── notify-nueva-reserva/
│   └── index.ts
├── notify-estado-reserva/
│   └── index.ts
├── notify-nueva-suscripcion/
│   └── index.ts
├── notify-tenant-estado/
│   └── index.ts
└── notify-stock-bajo/
    └── index.ts
```

### Patrón base de una Edge Function

```typescript
// supabase/functions/notify-nuevo-pedido/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const payload = await req.json();
  const { record } = payload; // NEW record del webhook

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // 1. Obtener usuarios del tenant con permiso COCINA_VER
  // 2. Obtener FCM tokens
  // 3. Enviar push via FCM HTTP API v1

  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

---

## 6. Tabla de resumen

| # | Webhook | Tabla | Evento | Edge Function | Prioridad |
|---|---------|-------|--------|---------------|-----------|
| 1 | `wh_pedidos_insert` | `pedidos` | INSERT | `notify-nuevo-pedido` | 🔴 Alta |
| 2 | `wh_pedidos_estado_update` | `pedidos` | UPDATE(`estado`) | `notify-estado-pedido` | 🔴 Alta |
| 3 | `wh_pedidos_cuenta_solicitada` | `pedidos` | UPDATE(`cuenta_solicitada`) | `notify-cuenta-solicitada` | 🔴 Alta |
| 4 | `wh_reservas_insert` | `reservas` | INSERT | `notify-nueva-reserva` | 🟡 Media |
| 5 | `wh_reservas_estado_update` | `reservas` | UPDATE(`estado`) | `notify-estado-reserva` | 🟡 Media |
| 6 | `wh_tenant_suscripciones_insert` | `tenant_suscripciones` | INSERT | `notify-nueva-suscripcion` | 🟡 Media |
| 7 | `wh_tenant_estado_update` | `tenants` | UPDATE(`estado`) | `notify-tenant-estado` | 🟠 Alta |
| 8 | `wh_stock_bajo_insert` | `productos` | UPDATE(`stock`) | `notify-stock-bajo` | 🟢 Baja |

---

## 7. Variables de entorno requeridas en Edge Functions

```bash
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service_role_key>   # Solo Edge Functions, nunca en cliente
FCM_SERVER_KEY=<firebase_server_key>            # Para push notifications
RESEND_API_KEY=<resend_api_key>                 # Para emails transaccionales
```

> ⚠️ **Nunca exponer `SUPABASE_SERVICE_ROLE_KEY` ni `FCM_SERVER_KEY` en el cliente Flutter.**  
> Estas variables solo viven en las Edge Functions de Supabase.

---

## 8. Configuración en el Dashboard de Supabase

**Ruta:** `Database → Webhooks → Create a new Webhook`

| Campo | Configuración |
|-------|--------------|
| Name | Nombre del webhook (ej: `wh_pedidos_insert`) |
| Table | Tabla a escuchar |
| Events | INSERT / UPDATE / DELETE |
| HTTP Request | POST a la URL de la Edge Function |
| HTTP Headers | `Authorization: Bearer <service_role_key>` |

**URL de la Edge Function:**
```
https://<project-ref>.supabase.co/functions/v1/<function-name>
```

---

## 9. Coherencia con otros SDDs

| Referencia | Documento |
|-----------|-----------|
| Tablas `pedidos`, `mesas` | `SCHEMAS/03_operaciones_negocio_schema.sql` |
| Tablas `reservas` | `SCHEMAS/04_reservas_configuracion_schema.sql` |
| Tablas `tenants`, `tenant_suscripciones` | `SCHEMAS/01_saas_core_schema.sql` |
| Tabla `asignaciones`, `permisos_modulo` | `SCHEMAS/02_roles_modulos_permisos_schema.sql` |
| Triggers de auditoría (audit_log) | `TRIGGERS/sdd_triggers.md` |
| Excepciones del sistema | `UI/EXCEPCIONES/sdd_excepciones.md` |
| Paquetes Flutter usados | `PACKAGES_FLUTTER/paquetes_flutter.md` |
