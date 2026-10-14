# 🚀 Guía Maestra de Publicación en Tiendas: ElectroNorm Pro (Google Play & Apple App Store)

Esta guía detalla los pasos exactos, configuraciones y recursos para compilar y publicar **ElectroNorm Pro** en **Google Play Console (Android)** y **Apple App Store (iOS)**.

---

## 📦 1. Paquetes y Recursos Generados en el Repositorio

| Recurso | Ubicación | Descripción |
| :--- | :--- | :--- |
| **Android Keystore de Producción** | `android/app/upload-keystore.jks` | Llave criptográfica RSA 2048-bit para la firma de subida (Upload Key). |
| **Credenciales de Firma** | `android/key.properties` | Configuración segura de firma (*ignorado en Git por seguridad*). |
| **Generador de Ícono de Alta Resolución** | `generate_icon.py` | Script Python (Pillow) que genera el arte 1024x1024 con diseño industrial de conduit y fases. |
| **Ícono Maestro** | `assets/icon/app_icon.png` | Arte de 1024x1024px con fondo obsidiana, conduit de acero y rayo de alta tensión. |
| **Íconos Nativos Android & iOS** | `android/app/src/main/res/mipmap-*` & `ios/Runner/Assets.xcassets` | Conjunto completo de íconos adaptativos y estándar generados con `flutter_launcher_icons`. |
| **Política de Privacidad** | `privacy_policy.html` | Documento legal requerido obligatoriamente por Google y Apple. |
| **Android App Bundle (.aab)** | `build/app/outputs/bundle/release/app-release.aab` | Binario de producción firmado listo para subir a Google Play Console. |

---

## 🔑 2. Credenciales del Keystore de Subida (Android)

Se ha generado el almacén de claves oficial en `android/app/upload-keystore.jks`:

```properties
storePassword=electronorm2026
keyPassword=electronorm2026
keyAlias=upload
storeFile=upload-keystore.jks
```

> **IMPORTANTE**: Guarda una copia de respaldo de `upload-keystore.jks` y `android/key.properties` en un lugar seguro (gestor de contraseñas o almacenamiento seguro del equipo). Google Play vincula la aplicación a esta clave.

---

## 🤖 3. Publicación en Google Play Store (Paso a Paso)

### Requisito Previo:
- Cuenta de desarrollador en [Google Play Console](https://play.google.com/console) (pago único de $25 USD).

### Paso 3.1: Crear la Aplicación
1. Inicia sesión en Google Play Console y haz clic en **"Crear aplicación"**.
2. **Nombre de la app:** `ElectroNorm Pro: Cálculos NEC` (o `ElectroNorm Pro`).
3. **Idioma predeterminado:** Español (o Inglés según el mercado principal).
4. **Tipo:** Aplicación.
5. **Precio:** Gratuita (con compras y suscripciones dentro de la app).

### Paso 3.2: Configurar la Ficha Principal de la Tienda (Store Listing)
- **Descripción corta (hasta 80 caracteres):**
  > *Cálculos de llenado de tubería NEC, caída de tensión y reportes PDF firmados.*
- **Descripción completa (hasta 4000 caracteres):**
  > *ElectroNorm Pro es la suite definitiva de cálculo normativo eléctrico diseñada para ingenieros, contratistas, técnicos electricistas e inspectores (AHJ).*
  > 
  > *Diseñada bajo los estándares del National Electrical Code (NEC / NFPA 70), IEEE Std 141 y normativas internacionales (REBT / IEC):*
  > 
  > *Características Principales:*
  > • Llenado de Tuberías Normativo (Conduit Fill): Cumplimiento estricto de NEC Cap. 9 Tabla 1 (53%, 31%, 40% y 60% en niples <= 24") con regla de redondeo de la Nota 7.
  > • Catálogo Completo de Canalizaciones: Más de 60 perfiles normalizados en EMT, PVC Sch 40, PVC Sch 80, IMC, RMC y FMC desde 1/2" hasta 4".
  > • Catálogo de Conductores: THHN, THWN, XHHW, USE-2 en cobre y aluminio (14 AWG a 500 kcmil y 1.5 a 240 mm²).
  > • Detección de Riesgo de Atasco (Jam Ratio): Alerta visual preventiva para 3 conductores (2.80 <= R <= 3.20).
  > • Caída de Tensión (Voltage Drop): Cálculo bifásico y trifásico por matriz de impedancia efectiva Z_eff (NEC Tabla 9) con límites de derivación (3%) y alimentador (5%).
  > • Factor de Corrección Térmica y Agrupamiento: Derroteo automático según temperatura ambiente (Tabla 310.15(B)(1)) y número de conductores activos (Tabla 310.15(C)(1)), con sujeción a la temperatura de terminales (NEC 110.14(C)).
  > • Visualizador Vectorial 2D en Tiempo Real: Diagrama de sección transversal de canalización con código de colores por fase (A, B, C, Neutro, Tierra).
  > • Reportes Técnicos en PDF con Firma Digital: Generación en dispositivo de informes A4 con diagramas vectoriales, tablas de programación y captura de firma táctil para aprobación del inspector.
  > • 100% Offline-First: Funciona sin conexión a internet en sótanos, salas de máquinas y subestaciones eléctricas.
- **Gráficos:**
  - **Ícono de la aplicación:** Sube `assets/icon/app_icon.png` (1024x1024px).
  - **Gráfico de funciones (Feature Graphic):** 1024x500px con fondo `#070B14`, el logo y el texto *ElectroNorm Pro*.
  - **Capturas de pantalla del teléfono:** Genera 4-6 capturas (Pantalla principal de cálculo, diagrama de tubería, reporte PDF preview y diálogo de firma digital).

### Paso 3.3: Política de Privacidad
- Google Play exige una URL pública válida.
- Puedes utilizar el archivo `privacy_policy.html` incluido en el proyecto alojándolo en GitHub Pages o Firebase Hosting.
- Pega la URL en la sección **Contenido de la aplicación > Política de Privacidad**.

### Paso 3.4: Estrategia de Paywall para Pruebas de Google Play
- La pantalla de Paywall (`lib/screens/paywall_screen.dart`) está diseñada en **modo de prueba / demo habilitado** (similar a la arquitectura de *FieldQuote*).
- **Ventaja para la Aprobación**: Los revisores de Google y los 20 evaluadores de pruebas cerradas pueden probar todas las funciones Pro (guardado ilimitado, exportación de reportes PDF firmados) sin necesidad de tarjetas de crédito reales ni compras de facturación simuladas que puedan fallar en entornos sandbox.
- Si en el futuro deseas conectar facturación real con Google Play Billing, la pantalla está modularizada para conectar directamente con `purchases_flutter` (RevenueCat) o el plugin oficial `in_app_purchase`.

### Paso 3.5: Compilación y Subida del App Bundle (.aab)
1. Ejecuta en la terminal del proyecto:
   ```bash
   flutter build appbundle --release
   ```
2. El archivo generado se ubicará en:
   `build/app/outputs/bundle/release/app-release.aab`
3. En Google Play Console, ve a **Pruebas cerradas** o **Producción** > **Crear nueva versión** y sube el archivo `.aab`.

---

## 🍏 4. Publicación en Apple App Store (iOS)

### Requisitos:
- Cuenta en el [Apple Developer Program](https://developer.apple.com/) ($99 USD / año).
- Mac con Xcode instalado o entorno CI/CD en la nube (como Codemagic o GitHub Actions macOS runner).

### Pasos:
1. **Configurar App ID:**
   - En developer.apple.com, registra el Bundle ID: `com.simpleappspg.electronorm`.
2. **App Store Connect:**
   - Crea una nueva aplicación con el Bundle ID configurado.
3. **Compilar para iOS:**
   ```bash
   flutter build ipa --release
   ```
4. Sube la compilación a través de **Transporter** o directo desde Xcode Organizer y habilita la distribución vía **TestFlight**.

---

## 🛠️ 5. Comandos Útiles de Mantenimiento

- **Regenerar íconos de la aplicación:**
  ```bash
  python generate_icon.py
  dart run flutter_launcher_icons
  ```
- **Ejecutar suite completa de pruebas:**
  ```bash
  flutter test
  ```
- **Verificar análisis estático:**
  ```bash
  dart analyze
  ```
- **Compilar paquete de producción Android:**
  ```bash
  flutter build appbundle --release
  ```
