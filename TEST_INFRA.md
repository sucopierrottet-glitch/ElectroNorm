# E2E Test Infra: ElectroNorm Pro

## Test Philosophy
- Opaque-box, requirement-driven testing derived from `ORIGINAL_REQUEST.md` (R1-R5).
- Methodology: Category-Partition + Boundary Value Analysis + Pairwise Combinatorial + Real-World Workload Testing.
- Pass/Fail Semantics: 100% of tests must pass via `flutter test`.

## Feature Inventory & Test Mapping
| # | Feature | Source | Tier 1 (Coverage) | Tier 2 (Boundary) | Tier 3 (Cross-Feature) | Tier 4 (Real-World) |
|---|---------|--------|:-----------------:|:-----------------:|:----------------------:|:-------------------:|
| 1 | Conduit Fill Math (NEC Table 1) | R1 | >= 5 tests | >= 5 tests | Pairwise with trade sizes | Realistic feeder run |
| 2 | Raceway Dimensions Catalog | R1 | >= 5 tests | >= 5 tests | EMT, PVC40, PVC80, IMC, RMC, FMC | 4" RMC heavy service |
| 3 | Conductor Sizing & Ampacity | R1 | >= 5 tests | >= 5 tests | 14 AWG to 500 kcmil & metric | Mixed wire schedules |
| 4 | Jam Ratio Pulling Risk | R1 | >= 5 tests | >= 5 tests | Ratio in [2.8, 3.2] threshold | 3x identical 500 kcmil |
| 5 | Voltage Drop (1-Phase & 3-Phase)| R1 | >= 5 tests | >= 5 tests | 120V, 208V, 240V, 480V; Cu & Al | Long industrial run |
| 6 | Derating (Temp & Bundling) | R1 | >= 5 tests | >= 5 tests | 30°C to 80°C, 4 to 30 conductors | High-ambient rooftop |
| 7 | Conductor Packing Visualizer | R2 | >= 5 tests | >= 5 tests | Non-overlapping geometry | 20 mixed conductors |
| 8 | Occupancy Badge & Thresholds | R2 | >= 5 tests | >= 5 tests | Green <=40%, Amber <=50%, Red >50%| Overfilled raceway |
| 9 | PDF Document Generation | R3 | >= 5 tests | >= 5 tests | Valid PDF bytes, table layout | Inspection report export |
| 10 | Signature Pad Data Integration | R3 | >= 5 tests | >= 5 tests | PNG bytes to PDF sign block | Inspector sign-off |
| 11 | Offline Persistence | R4 | >= 5 tests | >= 5 tests | Save, reload, clear runs | Restart persistence |
| 12 | Paywall & Demo Mode | R4 | >= 5 tests | >= 5 tests | Pro status toggle, pricing | FieldQuote architecture |
| 13 | Android & Google Play Packaging | R4 | >= 5 tests | >= 5 tests | com.simpleappspg.electronorm, INTERNET | Store audit |
| 14 | Git Version Control & Sync | R5 | >= 5 tests | >= 5 tests | branch main, origin tracking | Commit & push integrity |

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Commercial Rooftop 480V 3-Phase Feeder | 3x 250 kcmil Cu + 1x #4 Ground in 2" EMT @ 45°C ambient, 200A load, 250ft | High |
| 2 | Residential 200A Underground Service Lateral | 3x 4/0 Al XHHW in 2.5" PVC Sch 40, 240V 1-phase, 160A load, 180ft | High |
| 3 | Industrial Motor Control Center Branch | 3x #10 THHN Cu + 1x #12 Ground in 3/4" EMT, 208V 3-phase, 24A load, 85ft, check jam ratio | Medium |
| 4 | Data Center Multi-Circuit Bundling | 12x #12 THHN current-carrying conductors in 1" EMT @ 35°C, bundling derating | High |
| 5 | Full Inspection Compliance PDF with Digital Signature | Complete calculation run saved to offline storage, signed by AHJ, rendered to PDF | End-to-End |

## Coverage Thresholds
- Tier 1: >= 70 tests
- Tier 2: >= 70 tests
- Tier 3: >= 20 pairwise tests
- Tier 4: >= 5 application-level end-to-end tests
- **Total Minimum: >= 165 test cases**
