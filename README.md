# ElectroNorm Pro

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Android SDK](https://img.shields.io/badge/Android%20SDK-34-3DDC84?logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](LICENSE)
[![Google Play](https://img.shields.io/badge/Google%20Play-Ready-414141?logo=google-play)](https://play.google.com)

**ElectroNorm Pro** is a high-precision, offline-first cross-platform mobile application in Flutter designed specifically for electrical contractors, inspectors, and industrial engineers. The application delivers deterministic normative conduit fill calculations (NEC Chapter 9 Table 1, Table 4, Table 5; REBT; IEC), thermal ampacity derating, voltage drop simulations, real-time vector cross-section raceway visualization, and on-device technical compliance PDF reports with digital signature sign-offs.

---

## Key Features

### 1. Deterministic Electrical Calculation Engine
- **Conduit Fill Limits (NEC Chapter 9 Table 1)**:
  - 1 conductor: 53% max fill
  - 2 conductors: 31% max fill
  - 3+ conductors: 40% max fill
  - Short nipples ($\le 24\text{ inches}$): 60% max fill
- **Raceway Catalog**: 60 physical profiles across 1/2" to 4" trade sizes:
  - EMT (Electrical Metallic Tubing)
  - PVC Schedule 40 & PVC Schedule 80
  - IMC (Intermediate Metal Conduit)
  - RMC (Rigid Metal Conduit)
  - FMC (Flexible Metallic Conduit)
- **Conductor Database**:
  - Insulation types: THHN, THWN, XHHW, USE-2
  - Gauge sizes: 14 AWG to 500 kcmil, plus metric equivalents (1.5 mm² to 240 mm²)
  - Copper and aluminum conductors with calibrated nominal areas and outer diameters
- **Jam Ratio Hazard Detection**: Automatically flags critical pulling jam danger ($2.80 \le R_{jam} \le 3.20$) when pulling three equal conductors.
- **Voltage Drop Engine**: Single-phase (120V, 240V) and three-phase (208V, 480V) AC drop calculations with configurable power factor, conductor temperature, and length, evaluated against 3% branch / 5% total NEC limits.
- **Ampacity Derating (NEC Table 310.15)**: Multi-wire bundling adjustment factors (Table 310.15(C)(1)), ambient temperature correction (Table 310.15(B)(1)), and terminal rating temperature clamping (NEC 110.14(C)).

### 2. High-Contrast Field UI & Real-Time Vector Visualizer
- **Material 3 Dark-First Field Theme**: High-contrast slate and emerald palette optimized for low-light mechanical rooms, electrical vaults, and sunny construction jobsites.
- **Vector Cross-Section Canvas (`CustomPainter`)**: Real-time 2D circle packing visualization of conductors within the raceway using a Golden-Spiral seeded relaxation algorithm.
- **Visual Threshold Meter**: Dynamic occupancy badge indicating Compliant (Green $\le 40\%$), Caution (Amber $\le 50\%$), or Overfilled (Red $> 50\%$) with automated one-tap trade size upsize recommendations.
- **Color-Coded Phasing**: Automatic color tagging for Phase A (Black/Silver), Phase B (Red), Phase C (Blue), Neutral (Slate/White), and Ground (Green/Bare Copper).

### 3. Inspection-Ready PDF Technical Reports & Digital Signatures
- **On-Device PDF Generation**: Client-ready Electrical Technical Compliance Reports rendered via vector PDF engine (`pdf` and `printing` packages).
- **Embedded Digital Signatures**: Field technician and AHJ (Authority Having Jurisdiction) inspector digital signatures captured directly on an interactive touchscreen pad.
- **Direct System Sharing**: Native print, PDF export, and share functionality without third-party servers.

### 4. 100% Offline-First Architecture & Store Readiness
- **Zero Cloud Dependence**: Full functionality in remote basements, substations, and mines. Local persistence powered by sandboxed `SharedPreferences`.
- **Pro Subscription Model**: Annual pass ($69.00/yr with 14-day free trial) and Monthly pass ($8.99/mo).
- **Google Play Compliance**: Configured for package `com.simpleappspg.electronorm`, targetSdk 34, strict `INTERNET` permission only, and release keystore fallback.

---

## Architectural Layout

```
c:\repos\ElectroNorm\
├── android\
│   ├── app\
│   │   ├── build.gradle.kts          # com.simpleappspg.electronorm, targetSdk 34
│   │   └── src\main\AndroidManifest.xml # android.permission.INTERNET only
│   └── build.gradle.kts
├── lib\
│   ├── main.dart                     # App bootstrap and theme setup
│   ├── calculators\                  # Pure Dart deterministic math engines
│   │   ├── conduit_fill_calculator.dart
│   │   ├── derating_calculator.dart
│   │   └── voltage_drop_calculator.dart
│   ├── catalogs\                     # Physical raceway and conductor specs
│   │   ├── conductor_catalog.dart
│   │   └── raceway_catalog.dart
│   ├── models\                       # Strongly-typed domain models
│   ├── screens\                      # Screen widgets
│   │   ├── calculator_screen.dart
│   │   ├── paywall_screen.dart
│   │   ├── report_preview_screen.dart
│   │   └── saved_projects_screen.dart
│   ├── services\                     # PDF rendering and offline storage
│   │   ├── pdf_report_service.dart
│   │   └── storage_service.dart
│   ├── theme\                        # Material 3 high-contrast theme
│   └── widgets\                      # CustomPainter and UI components
├── test\                             # Benchmark unit & E2E integration test suites
├── privacy_policy.html               # Legal disclosures for Google Play Console
├── pubspec.yaml                      # Dependencies and Flutter metadata
└── README.md                         # Project documentation
```

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.13.5 or higher)
- [Dart SDK](https://dart.dev) (v3.0.0 or higher)
- [Android Studio](https://developer.android.com/studio) / Android SDK API 34

### Installation
```bash
# Clone the repository
git clone https://github.com/sucopierrottet-glitch/ElectroNorm.git
cd ElectroNorm

# Install dependencies
flutter pub get
```

### Static Analysis & Verification
```bash
# Run static analysis (enforces 0 errors, 0 warnings, 0 lints)
flutter analyze

# Run unit and integration tests
flutter test
```

### Building for Android
```bash
# Build release APK
flutter build apk --release

# Build Google Play App Bundle (AAB)
flutter build appbundle --release
```

---

## Google Play Store Configuration

- **Application ID / Namespace**: `com.simpleappspg.electronorm`
- **Target SDK**: API 34 (Android 14)
- **Minimum SDK**: API 21 (Android 5.0)
- **Permissions**: Strictly `android.permission.INTERNET` only (Least Privilege Principle; zero sensitive or dangerous permissions).
- **Privacy Policy**: Hosted at `privacy_policy.html` and available via [Privacy Policy](privacy_policy.html).

---

## Developer & Copyright

Developed by **SimpleApps PG** (`simpleappspg`).  
Official repository: [https://github.com/sucopierrottet-glitch/ElectroNorm](https://github.com/sucopierrottet-glitch/ElectroNorm)  
All Rights Reserved &copy; 2026 SimpleApps PG.
