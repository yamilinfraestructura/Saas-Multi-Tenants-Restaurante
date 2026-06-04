# SDD — Almacenamiento en Supabase Storage
**Directorio:** `sdd/PLAN/BASE_DE_DATOS/STORAGE/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  
**Fecha:** 2026-06-04

---

## 1. Propósito

Este documento especifica la estructura y políticas de seguridad para **Supabase Storage**. El storage se utilizará para almacenar todos los archivos multimedia del sistema, aislándolos por Tenant (restaurante).

Los principales casos de uso son:
- Logos e imágenes corporativas de los restaurantes (`tenant_logos`).
- Imágenes de los productos y categorías del menú (`productos`).
- Fotos de perfil de los empleados/usuarios (`avatars`).

---

## 2. Estructura de Buckets (Contenedores)

Se recomiendan **3 Buckets** principales. Separarlos por tipo de archivo facilita la configuración de cachés y políticas de seguridad.

### 2.1 Bucket: `tenant_logos`
- **Uso:** Logos de las empresas para mostrar en el Menú QR y la App.
- **Visibilidad:** Público (Cualquiera puede ver, el Menú QR lo necesita sin autenticación).
- **Estructura de rutas:** `<tenant_id>/logo.png`
  - *Ejemplo:* `550e8400-e29b-41d4-a716-446655440000/logo_principal.jpg`

### 2.2 Bucket: `productos`
- **Uso:** Fotos de los platillos y bebidas.
- **Visibilidad:** Público (Los clientes escanean el QR y ven los platos sin login).
- **Estructura de rutas:** `<tenant_id>/<categoria_id>/<producto_id>.jpg`
  - *Ejemplo:* `550e8400.../bebidas/coca_cola_600.jpg`

### 2.3 Bucket: `avatars`
- **Uso:** Fotos de perfil de mozos, cajeros y administradores.
- **Visibilidad:** Privado o Público (Depende si se quiere mostrar en el ticket "Atendido por X"). Se recomienda **Público** para facilitar la carga en la UI.
- **Estructura de rutas:** `<tenant_id>/<usuario_id>.jpg`

---

## 3. Políticas de Seguridad (Storage RLS)

Al igual que en la base de datos, Supabase Storage usa Postgres RLS bajo el capó (tabla `storage.objects`).

### Reglas Generales:
1. **Lectura (SELECT):** Permitida a todo el mundo (Public) para `tenant_logos` y `productos`.
2. **Escritura (INSERT/UPDATE/DELETE):** Solo permitida a usuarios autenticados que pertenezcan al `tenant_id` correspondiente a la carpeta.

### Ejemplo de Política de Storage (PostgreSQL)

Para aplicar estas reglas en Supabase SQL Editor:

```sql
-- Habilitar acceso público de lectura para el bucket 'productos'
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'productos' );

-- Solo el admin o personal del tenant puede subir imágenes a su propia carpeta
CREATE POLICY "Tenant Upload Access"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'productos' AND
  (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);

-- Solo el admin o personal del tenant puede borrar sus imágenes
CREATE POLICY "Tenant Delete Access"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'productos' AND
  (storage.foldername(name))[1] = (auth.jwt() ->> 'tenant_id')::text
);
```
*(El uso de `(storage.foldername(name))[1]` extrae la primera carpeta de la ruta, que por nuestra convención siempre será el `tenant_id`).*

---

## 4. Uso desde Flutter

En Flutter, utilizaremos el paquete `image_picker` para seleccionar la imagen y `supabase_flutter` para subirla.

### Flujo recomendado:
1. El usuario selecciona la imagen desde la galería.
2. Comprimir la imagen antes de subirla (Ej. con `flutter_image_compress` o nativamente) para ahorrar ancho de banda y storage (ideal Max 800x800px para productos, calidad 75%).
3. Subir a Supabase Storage:
```dart
final String path = '${tenantId}/${productoId}.jpg';
await supabase.storage
  .from('productos')
  .upload(path, fileToUpload, fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
```
4. Obtener la URL pública y guardarla en la tabla `productos` (columna `img`):
```dart
final String publicUrl = supabase.storage.from('productos').getPublicUrl(path);
// Luego: UPDATE productos SET img = publicUrl WHERE id = productoId;
```
5. En la UI, mostrar con `cached_network_image` para no consumir descargas de Supabase innecesarias.

---

## 5. Optimización y Límites

- **Caché CDN:** Las URLs públicas de Supabase pasan por CDN. Al actualizar un logo, usar la opción `upsert: true` pero tener en cuenta que el CDN puede tardar en refrescar. Un truco es añadir un timestamp a la URL en BD `?v=12345`.
- **Restricción de tamaño:** Se pueden configurar reglas RLS para rechazar archivos mayores a 2MB.
```sql
-- Agregar al WITH CHECK de la política de INSERT:
AND (file_size < 2097152) -- 2MB en bytes
```
