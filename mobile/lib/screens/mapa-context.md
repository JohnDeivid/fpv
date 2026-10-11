# 🗺️ Mapa de Contexto: Arquitectura FPV & Visor 3D en BuanaVPad

> **Documento de Contexto para Desarrolladores y Modelos de IA:**
> Este archivo detalla **DÓNDE, CUÁNDO y CÓMO** está implementada cada parte del Modo FPV y el Visor 3D interactivo en BuanaVPad, tanto en la app móvil (Flutter) como en la aplicación de escritorio (Python).

---

## 🚁 1. Resumen General del Sistema FPV

BuanaVPad transforma el teléfono móvil en un mando de simulador de vuelo FPV (Drones de carreras/freestyle) comunicándose con una app desktop por WebSockets en tiempo real.

```
+-----------------------------------+             +----------------------------------+
|          MOBILE (Flutter)         |  WebSocket  |         DESKTOP (Python)         |
| • FpvLayoutFactory (Mode 2)       | ----------> | • FastAPI Server (/ws/fpv/{id})  |
| • ConnectToPcPage (FPV Toggle)    |             | • FpvControllerManager           |
| • FpvDrone3dViewer (Sketchfab 3D) |             | • vX360 Virtual Gamepad (vGen)   |
| • ControllerListPage (Plantillas) |             | • FpvTab (Ajustes Expo/Deadzone) |
+-----------------------------------+             +----------------------------------+
```

---

## 📦 2. Visor 3D Interactivo (Dron Flywoo + RadioMaster TX12)

### ¿DÓNDE está implementado?
1. **Widget Principal 3D:**
   - 📄 Archivo: [`mobile/lib/widgets/fpv_drone_3d_viewer.dart`](file:///home/johndeivid/buana-vpad/mobile/lib/widgets/fpv_drone_3d_viewer.dart)
   - Componentes clave:
     - `FpvDrone3dViewer`: Widget `StatefulWidget` que renderiza el modelo 3D en WebGL.
     - `showFpvDrone3dFullScreen(BuildContext context)`: Función helper que abre el visor a pantalla completa en un diálogo oscuro sin bordes.
2. **Pantalla de Conexión a PC:**
   - 📄 Archivo: [`mobile/lib/screens/connect_to_pc_page.dart`](file:///home/johndeivid/buana-vpad/mobile/lib/screens/connect_to_pc_page.dart)
   - Líneas clave:
     - Estado: `bool _showFpv3dPreview = false;`
     - Ubicación visual: Justo debajo de la tarjeta `FPV Drone Mode` (líneas ~595-660).
     - Muestra un botón desplegable para abrir el visor inline o a pantalla completa.
3. **Lista de Mandos / Plantillas:**
   - 📄 Archivo: [`mobile/lib/screens/controller_list_page.dart`](file:///home/johndeivid/buana-vpad/mobile/lib/screens/controller_list_page.dart)
   - Ubicación: En `_showNewLayoutSheet()` (botón flotante `+`), añade la opción *"Ver Kit 3D (Dron & Mando) 🥽"* que llama a `showFpvDrone3dFullScreen(context)`.
4. **Configuración de Dependencias:**
   - 📄 Archivo: [`mobile/pubspec.yaml`](file:///home/johndeivid/buana-vpad/mobile/pubspec.yaml)
   - Dependencia añadida: `webview_flutter: ^4.10.0`
5. **Permisos y Aceleración de Hardware en Android:**
   - 📄 Archivo: [`mobile/android/app/src/main/AndroidManifest.xml`](file:///home/johndeivid/buana-vpad/mobile/android/app/src/main/AndroidManifest.xml)
   - Atributos requeridos: `android:hardwareAccelerated="true"` y permisos `<uses-permission android:name="android.permission.INTERNET"/>`.

---

### ¿CÓMO funciona por dentro?
- **Renderizado 3D de alta fidelidad:** Usa WebGL acelerado por hardware a través de un WebView que carga el reproductor embebido de Sketchfab configurado para máxima calidad visual (PBR con texturas 4K).
- **Parámetros del Embed de Sketchfab:**
  ```dart
  static const String _sketchfabUrl =
      'https://sketchfab.com/models/6544a01c9b4042e8b12eb7f1a9f22b2d/embed?'
      'autostart=1&internal=1&ui_theme=dark&ui_infos=0&ui_watermark=0&'
      'ui_help=0&ui_settings=0&ui_inspector=0&ui_annotations=0&ui_stop=0&'
      'transparent=0&dnt=1';
  ```
- **Captura de Gestos (`gestureRecognizers`):**
  Para evitar que los gestos de rotación 3D choquen con el scroll de la página de Flutter, el widget utiliza:
  ```dart
  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(
      () => EagerGestureRecognizer(),
    ),
  }
  ```
- **Manejo de Estados:**
  - `_isLoading` & `_loadingProgress`: Muestra un spinner circular futurista temático en naranja mientras carga.
  - `_hasError`: Botón para reintentar si se pierde la conexión de red.

---

### ¿CÓMO modificar el Visor 3D en el futuro?
* **Cambiar el modelo 3D:** Solo edita la constante `_sketchfabUrl` en [`mobile/lib/widgets/fpv_drone_3d_viewer.dart`](file:///home/johndeivid/buana-vpad/mobile/lib/widgets/fpv_drone_3d_viewer.dart) con el ID de otro modelo de Sketchfab.
* **Ajustar el alto del widget embebido:** Modifica la propiedad `height` al instanciar `FpvDrone3dViewer(height: 290)`.
* **Insertarlo en otra pantalla:** Simplemente importa:
  ```dart
  import 'package:buana_vpad/widgets/fpv_drone_3d_viewer.dart';
  ```
  Y colócalo en el árbol de widgets: `const FpvDrone3dViewer(height: 300)`.

---

## 🎮 3. Lógica de Control FPV (Mode 2) & WebSocket

### Archivos Clave del Mando FPV

| Componente | Archivo | Responsabilidad |
|---|---|---|
| **Plantilla FPV** | [`mobile/lib/utils/fpv_layout_factory.dart`](file:///home/johndeivid/buana-vpad/mobile/lib/utils/fpv_layout_factory.dart) | Genera la distribución de botones y sticks Mode 2 preconfigurados |
| **Detección FPV** | [`mobile/lib/screens/connect_to_pc_page.dart`](file:///home/johndeivid/buana-vpad/mobile/lib/screens/connect_to_pc_page.dart) | Detecta si el layout seleccionado es FPV y conmuta a `/ws/fpv/{id}` |
| **Manager Desktop** | [`desktop/src/core/fpv_controller_manager.py`](file:///home/johndeivid/buana-vpad/desktop/src/core/fpv_controller_manager.py) | Procesa curvas Expo, Deadzone y Throttle sticky (sin retorno al centro) |
| **GUI Desktop** | [`desktop/src/gui/components/fpv_tab.py`](file:///home/johndeivid/buana-vpad/desktop/src/gui/components/fpv_tab.py) | Sliders visuales de Expo y Deadzone para simuladores (Liftoff, Uncrashed, etc.) |
| **Rutas API** | [`desktop/src/api/app.py`](file:///home/johndeivid/buana-vpad/desktop/src/api/app.py) | Endpoints `/ws/fpv/{id}` y `/fpv/settings` |

### Mapeo de Ejes Mode 2
- **Stick Izquierdo (X):** `Yaw` (Rotación horizontal).
- **Stick Izquierdo (Y):** `Throttle` (Acelerador) ➡️ **Sticky** (no retorna al centro).
- **Stick Derecho (X):** `Roll` (Inclinación lateral).
- **Stick Derecho (Y):** `Pitch` (Cabeceo adelante/atrás).
- **Botones de acción:**
  - `A`: ARM / DISARM
  - `B`: Modo Angle (Estabilizado)
  - `X`: Modo Acro (Manual)
  - `Y`: Beeper (Zumbador de rescate)

---

## 🚀 4. Compilación del APK Móvil

- **Entorno:** Flutter 3.5.4+ / Java 17 / Android SDK.
- **Compilación manual en GitHub Actions:**
  En `.github/workflows/` se pueden disparar compilaciones en la nube sin requerir Android Studio localmente.
- **Compilación local:**
  ```bash
  cd mobile
  flutter pub get
  flutter build apk --debug
  ```