# SDD UX - Experiencia de Pantalla de Administración
**Directorio:** `sdd/PLAN/UX/ADMIN_SCREEN_UX/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Este documento define las reglas de experiencia de usuario para el panel de administración (`feature_admin`). A diferencia del cliente final, el administrador necesita eficiencia, densidad de datos y herramientas bulk (masivas) para gestionar el restaurante.

## 2. Paradigma de Interacción (Data-Dense vs Touch-Friendly)

Dado que el administrador podría usar una laptop (con mouse y teclado) o una Tablet:
- **Web/Desktop (Mouse):** Se favorecen los `DataTables` (Tablas de Flutter) para gestionar Productos y Usuarios, permitiendo ordenamiento de columnas, edición inline, y selección múltiple con checkboxes. Hover states son obligatorios.
- **Tablet (Touch):** Las celdas de las tablas deben tener un `minHeight` de `48px` (Hit target recomendado por Material 3 para pantallas táctiles) para asegurar que los botones de edición sean fáciles de presionar.

## 3. Flujo Crítico: Gestor del Menú (ABM de Productos)

En el proyecto React original (`MenuManager.jsx`), la gestión de categorías y productos ocurría con modales. En Flutter adaptaremos esto:
1. **Vista Principal:** Split View o Master-Detail (Solo Desktop/Tablet).
   - *Master (Izquierda):* Lista de Categorías seleccionables.
   - *Detail (Derecha):* Tarjetas o Grid de productos pertenecientes a esa categoría.
2. **Acción de Creación:**
   - En lugar de modales flotantes intrusivos, se recomienda un `SlideOver` o `EndDrawer` que emerge desde el borde derecho de la pantalla, manteniendo el contexto visual de la lista de productos de fondo.
3. **Optimización Flutter:** Al arrastrar (Drag & Drop) para reordenar categorías, se utilizará el widget `ReorderableListView` de Flutter, actualizando el orden localmente y aplicando un debounce antes de persistir la posición en Supabase para evitar excesivas escrituras en BD.

## 4. Feedback Visual (Estado Asíncrono)
Para operaciones de administración (Guardar, Eliminar):
- Los botones principales deben implementar un estado de `isLoading` (reemplazando el texto por un pequeño spinner interno).
- Mostrar notificaciones `SnackBar` (Toast) sutiles en la parte inferior izquierda de la pantalla al terminar con éxito, o un diálogo modal si la operación falla con un error explicativo (ver `sdd_excepciones.md`).
