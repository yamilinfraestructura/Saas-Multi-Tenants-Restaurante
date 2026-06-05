# SDD UX - Experiencia de Gestión de Mesas (POS / Operativo)
**Directorio:** `sdd/PLAN/UX/MESAS_UX/`  
**Versión:** 1.0.0  
**Autor:** SaasSystemGuri  

---

## 1. Propósito
Este documento describe la experiencia de usuario (UX) específica para el módulo operativo de Mesas (`feature_pos` y operativa en vivo), utilizado por Mozos y Cajeros para gestionar el flujo de un servicio.

## 2. Mapa Visual del Comedor (Grid View)

En el proyecto original en React, se usaba `ComedorView.jsx` que representaba las mesas visualmente. En Flutter, la UX será similar pero optimizada:
- **Layout:** Un `GridView` dinámico que represente las mesas físicas, agrupadas por `Salas` (Tabs en la parte superior).
- **Indicadores de Estado:** Las tarjetas o círculos de las mesas deben comunicar el estado al instante, sin necesidad de leer texto:
  - 🟢 **Verde:** Libre / Activa.
  - 🟡 **Amarillo/Naranja:** En curso (Pedido activo).
  - 🔴 **Rojo:** Cuenta solicitada (Urgente).
  - 🔵 **Azul:** Reservada.

## 3. Interacciones Clave (Touch First)

La operativa del salón es rápida y ocurre en dispositivos móviles o tablets. Las interacciones deben diseñarse pensando en *Touch First*:

### 3.1 Abrir Mesa
- Un toque simple (`onTap`) sobre una mesa libre abre instantáneamente la pantalla para "Agregar Productos". No debe requerir modales de confirmación innecesarios.

### 3.2 Acciones sobre Mesa Ocupada
- Un toque simple sobre una mesa ocupada abre la vista del "Resumen de Pedido" de esa mesa, mostrando el total, tiempo transcurrido y opciones rápidas: "Añadir más", "Cobrar", "Liberar".

### 3.3 Visualización del Tiempo
- Una métrica crucial de UX para el mozo es saber cuánto tiempo lleva una mesa esperando o comiendo. Cada mesa ocupada debe mostrar un pequeño temporizador (`12 min`) que se actualiza usando un `StreamBuilder` nativo de Flutter o un hook de tiempo en Riverpod.

## 4. Animaciones de Transición
- Cuando una mesa cambia de "Libre" a "En curso" debido a que un cliente escanea el QR y hace un pedido, la mesa en la pantalla del cajero debe palpitar (efecto Pulse) o realizar una animación de escala suave (usando `AnimatedContainer` o `TweenAnimationBuilder` en Flutter) para atraer la atención del staff sin ser un popup molesto.
