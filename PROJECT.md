# Project: ElectroNorm Pro

## Architecture
ElectroNorm Pro is an offline-first, high-precision cross-platform mobile application in Flutter designed for electrical contractors, inspectors, and engineers. It performs normative raceway fill, jam ratio, voltage drop, and ampacity derating calculations adhering strictly to NEC (NFPA 70), REBT, and IEC standards.

### Architectural Layers
1. **Domain & Calculation Engine (`lib/models/`, `lib/catalogs/`, `lib/calculators/`)**:
   - Pure Dart deterministic calculation engine with zero external dependencies.
   - Comprehensive raceway catalog (60 profiles across EMT, PVC 40, PVC 80, IMC, RMC, FMC in 1/2" to 4").
   - Conductor catalog (THHN, THWN, XHHW, USE-2 from 14 AWG to 500 kcmil and metric 1.5 to 240 mm²).
   - Conduit fill limits: 1 conductor (53%), 2 conductors (31%), 3+ conductors (40%), nipples <=24" (60%).
   - Jam ratio safety detection ($2.80 \le R_{jam} \le 3.20$).
   - Dual AC voltage drop engine (NEC Table 9 effective impedance & circular mil) for single-phase (120/240V) and three-phase (208/480V) in copper and aluminum.
   - Temperature correction (Table 310.15(B)(1)) and bundling adjustment (Table 310.15(C)(1)) with terminal rating clamping (NEC 110.14(C)).

2. **Presentation & Field UI (`lib/screens/`, `lib/widgets/`, `lib/theme/`)**:
   - Material 3 high-contrast dark-mode-first theme designed for field conditions.
   - Real-time raceway cross-section vector rendering via `CustomPainter`.
   - Golden-Spiral seeded relaxation circle packing algorithm (< 0.3ms collision-free).
   - Color-coded conductor groups (Phase A black/silver, Phase B red, Phase C blue, Neutral slate/white, Ground green/copper).
   - Dynamic occupancy badge (Green <= 40%, Amber <= 50%, Red > 50%) and upsizing pills.
   - Rapid-input conductor wizard.

3. **PDF Technical Compliance Engine (`lib/services/pdf_report_service.dart`, `lib/widgets/signature_dialog.dart`)**:
   - On-device pure vector PDF generation using `pdf: ^3.13.1` and `printing: ^5.15.1`.
   - Comprehensive electrical compliance report: company branding, project details, raceway schedule table, vector conduit fill diagram, voltage drop & derating section, dual digital signature block.
   - Touch signature pad integration using `signature: ^6.4.0`.
   - Direct export, print, and WhatsApp/email sharing via `share_plus: ^13.3.1`.

4. **Persistence & Store Monetization (`lib/services/storage_service.dart`, `lib/screens/paywall_screen.dart`, `android/`)**:
   - 100% offline JSON persistence using `shared_preferences: ^2.5.5` for project runs, presets, and electrician profile.
   - Subscription paywall screen: $8.99/mo, $69.00/yr, 14-day trial, exit-intent rescue dialog, and 5-tap Demo Mode toggle.
   - Google Play store packaging: Kotlin DSL `android/app/build.gradle.kts`, namespace `com.simpleappspg.electronorm`, `INTERNET` permission only, release keystore fallback, and store `privacy_policy.html`.

5. **Testing & QA Suite (`test/`)**:
   - Complete unit test suite verifying all 21 normative benchmark vectors.
   - Opaque-box E2E integration test suite across Tiers 1-4.
   - Zero-warning `flutter analyze` enforcement.

---

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Scaffolding & Dependencies | Flutter project initialization with validated production packages | M1 | Survey |
| 2 | Raceway Catalog | 60 raceway profiles (1/2" to 4" across EMT, PVC 40, PVC 80, IMC, RMC, FMC) | M1 | R1 |
| 3 | Conductor Catalog | THHN, THWN, XHHW, USE-2 (14 AWG-500 kcmil, 1.5-240 mm²), areas & ampacities | M1 | R1 |
| 4 | Conduit Fill Engine | NEC Table 1 fill limits (53%, 31%, 40%, 60%) and multi-wire fill calculation | M1 | R1 |
| 5 | Jam Ratio Detector | Detection of critical pulling jam risk ($2.80 \le R_{jam} \le 3.20$) | M1 | R1 |
| 6 | Voltage Drop Engine | 1-phase (120/240V) & 3-phase (208/480V) AC drop for Cu/Al with PF and limits | M1 | R1 |
| 7 | Derating Calculator | Ambient temp (Table 310.15(B)(1)) & bundling (Table 310.15(C)(1)) with clamping | M1 | R1 |
| 8 | Calculation Unit Tests | 21 deterministic benchmark test vectors covering all R1 formulas | M1 | R1/AC |
| 9 | High-Contrast Field Theme | Ergonomic Material 3 dark-mode-first styling for mechanical rooms | M2 | R2 |
| 10 | Conductor Packing Algorithm | Golden-Spiral seeded relaxation algorithm for real-time 2D circle packing | M2 | R2 |
| 11 | Raceway CustomPainter | Vector circular profile rendering with color-coded conductors & occupancy meter | M2 | R2 |
| 12 | Rapid Conductor Wizard | Fast mixed-wire input wizard with live recalculation and upsizing pills | M2 | R2 |
| 13 | PDF Compliance Report Engine | On-device vector PDF generator with project metadata, tables, diagrams | M3 | R3 |
| 14 | Digital Signature Pad | Interactive touch signature capture embedded into inspection sign-off block | M3 | R3 |
| 15 | PDF Sharing & Printing | Direct system print and file share integration via share_plus | M3 | R3 |
| 16 | Offline Persistence Repository | Local JSON storage via shared_preferences for runs, presets, profiles | M4 | R4 |
| 17 | Saved Projects UI | Management screen for saved calculations, search, reload, and delete | M4 | R4 |
| 18 | Subscription Paywall Screen | Pro tiers ($8.99/mo, $69.00/yr), 14-day trial, rescue dialog, demo toggle | M4 | R4 |
| 19 | Android Packaging Setup | Kotlin Gradle DSL, namespace `com.simpleappspg.electronorm`, targetSdk 34 | M4 | R4 |
| 20 | Google Play Permission Audit | Strict `android.permission.INTERNET` only in AndroidManifest.xml | M4 | R4 |
| 21 | Privacy Policy Page | Google Play Console compliant `privacy_policy.html` | M4 | R4 |
| 22 | Opaque-Box E2E Test Suite | Automated end-to-end integration tests verifying Tiers 1-4 | M5 | R5/AC |
| 23 | Static Code Analysis | Clean `flutter analyze` with 0 fatal errors, lints, or broken imports | M5 | R5/AC |
| 24 | Git Remote Synchronization | Clean commit to branch `main` and push to GitHub remote | M5 | R5 |

---

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Core Electrical Engine & Scaffolding | Features 1-8: Flutter scaffold, raceway & conductor catalogs, fill, jam, voltage drop, derating calculators & unit tests | None | DONE |
| M2 | Field UI & Real-Time Raceway Canvas | Features 9-12: High-contrast theme, circle packing painter, color-coded conductors, rapid wizard | M1 | DONE |
| M3 | PDF Compliance Engine & Signature Pad | Features 13-15: PDF document generator, signature dialog, preview & sharing | M1, M2 | DONE |
| M4 | Offline Persistence, Paywall & Store Packaging | Features 16-21: Local storage service, saved projects screen, paywall, Android Gradle, Manifest, privacy policy | M1, M2 | DONE |
| M5 | E2E Verification, QA & Git Remote Sync | Features 22-24: E2E tests, flutter analyze, full regression pass, commit & git push | M1, M2, M3, M4 | DONE |

---

## Interface Contracts

### 1. Engine Models & Calculators (`lib/models/`, `lib/calculators/`)
```dart
enum RacewayType { emt, pvcSch40, pvcSch80, imc, rmc, fmc }
enum ConductorInsulation { thhn, thwn, xhhw, use2 }
enum ConductorMaterial { copper, aluminum }
enum CircuitPhase { singlePhase, threePhase }

class RacewayProfile {
  final RacewayType type;
  final String tradeSize; // e.g. "3/4"
  final double internalDiameterInches;
  final double internalAreaSqInches;
  final double internalDiameterMm;
  final double internalAreaSqMm;
  const RacewayProfile(...);
}

class ConductorSpec {
  final String gauge; // e.g. "12 AWG", "4 mm²"
  final ConductorInsulation insulation;
  final ConductorMaterial material;
  final double outerDiameterInches;
  final double areaSqInches;
  final double ampacity60C;
  final double ampacity75C;
  final double ampacity90C;
  final int? maxOcpdAmps;
  const ConductorSpec(...);
}

class ConductorGroup {
  final String id;
  final ConductorSpec spec;
  final int count;
  final String role; // "phaseA", "phaseB", "phaseC", "neutral", "ground"
  const ConductorGroup(...);
}

class ConduitFillResult {
  final double totalConductorArea;
  final double racewayInternalArea;
  final double fillPercentage;
  final double allowedFillPercentage;
  final bool isCompliant;
  final double? jamRatio;
  final bool hasJamRisk;
  final String? recommendedUpsizeTradeSize;
  const ConduitFillResult(...);
}

class VoltageDropResult {
  final double voltageDropVolts;
  final double percentageDrop;
  final double endVoltage;
  final bool isCompliantBranch; // <= 3.0%
  final bool isCompliantTotal;  // <= 5.0%
  const VoltageDropResult(...);
}

class DeratingResult {
  final double baseAmpacity;
  final double temperatureCorrectionFactor;
  final double bundlingAdjustmentFactor;
  final double deratedAmpacity;
  final double terminalRatingLimit;
  final double allowableAmpacity;
  const DeratingResult(...);
}
```

### 2. CustomPainter Visualizer Contract (`lib/widgets/`)
```dart
class PackedConductorPosition {
  final double normalizedX; // -1.0 to 1.0 relative to raceway radius
  final double normalizedY;
  final double normalizedRadius;
  final Color color;
  final String label;
  const PackedConductorPosition(...);
}

abstract class ConductorPackingAlgorithm {
  List<PackedConductorPosition> pack({
    required double conduitRadius,
    required List<ConductorGroup> groups,
  });
}
```

### 3. PDF Compliance Engine Contract (`lib/services/`)
```dart
class ComplianceReportData {
  final String projectTitle;
  final String clientName;
  final String siteAddress;
  final String technicianName;
  final String companyName;
  final DateTime date;
  final RacewayProfile raceway;
  final List<ConductorGroup> conductors;
  final ConduitFillResult fillResult;
  final VoltageDropResult? voltageDropResult;
  final DeratingResult? deratingResult;
  final Uint8List? signaturePngBytes;
  const ComplianceReportData(...);
}

abstract class PdfReportService {
  Future<Uint8List> generateReport(ComplianceReportData data);
  Future<void> printOrShareReport(ComplianceReportData data);
}
```

### 4. Storage Contract (`lib/services/`)
```dart
abstract class StorageService {
  Future<List<SavedCalculation>> getSavedCalculations();
  Future<void> saveCalculation(SavedCalculation item);
  Future<void> deleteCalculation(String id);
  Future<bool> isProSubscriber();
  Future<void> setProSubscriber(bool value);
  Future<TechnicianProfile> getProfile();
  Future<void> saveProfile(TechnicianProfile profile);
}
```

---

## Code Layout
```
c:\repos\ElectroNorm\
├── android\
│   ├── app\
│   │   ├── build.gradle.kts      # com.simpleappspg.electronorm, targetSdk 34
│   │   └── src\main\AndroidManifest.xml # strictly INTERNET permission
│   └── build.gradle.kts
├── lib\
│   ├── main.dart                 # Application entry point & theme initialization
│   ├── models\                   # RacewayProfile, ConductorSpec, Results
│   ├── catalogs\                 # raceway_catalog.dart, conductor_catalog.dart
│   ├── calculators\              # conduit_fill, voltage_drop, derating
│   ├── theme\                    # High-contrast Material 3 dark-first theme
│   ├── widgets\                  # raceway_painter.dart, packing_algorithm.dart, signature_dialog.dart
│   ├── screens\                  # calculator_screen.dart, report_preview_screen.dart, paywall_screen.dart, saved_projects_screen.dart
│   └── services\                 # storage_service.dart, pdf_report_service.dart
├── test\
│   ├── calculations_test.dart    # 21 normative benchmark unit tests
│   ├── packing_test.dart         # CustomPainter packing algorithm tests
│   └── e2e_integration_test.dart # Opaque-box E2E test suite (Tiers 1-4)
├── privacy_policy.html           # Google Play Console compliance document
├── pubspec.yaml                  # Flutter configuration & locked dependencies
└── README.md                     # Comprehensive project documentation
```
