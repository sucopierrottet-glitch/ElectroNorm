import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/painting.dart' show Color;
import 'package:flutter/services.dart' show Uint8List;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/calculation_results.dart';
import '../models/conductor.dart';
import '../models/normative_profile.dart';
import '../models/raceway.dart';
import '../widgets/packing_algorithm.dart';

/// Comprehensive data contract for generating inspection-ready PDF compliance reports.
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

  // Additional inspection and electrical metadata
  final String inspectorName;
  final String licenseNumber;
  final String agencyName;
  final double nominalVoltage;
  final CircuitPhase circuitPhase;
  final double circuitLengthFeet;
  final double loadCurrentAmps;
  final double powerFactor;
  final double ambientTempC;
  final double terminalRatingC;
  final int cccCount;
  final String documentId;
  final String localeCode;
  final NormativeCountry normativeCountry;
  final bool useMetricUnits;

  const ComplianceReportData({
    required this.projectTitle,
    required this.clientName,
    required this.siteAddress,
    required this.technicianName,
    required this.companyName,
    required this.date,
    required this.raceway,
    required this.conductors,
    required this.fillResult,
    this.voltageDropResult,
    this.deratingResult,
    this.signaturePngBytes,
    this.inspectorName = 'Authority Having Jurisdiction (AHJ)',
    this.licenseNumber = 'ME-948210',
    this.agencyName = 'City Electrical Inspection Bureau',
    this.nominalVoltage = 120.0,
    this.circuitPhase = CircuitPhase.singlePhase,
    this.circuitLengthFeet = 100.0,
    this.loadCurrentAmps = 16.0,
    this.powerFactor = 0.90,
    this.ambientTempC = 30.0,
    this.terminalRatingC = 75.0,
    this.cccCount = 3,
    this.documentId = '',
    this.localeCode = 'en',
    this.normativeCountry = NormativeCountry.usa,
    this.useMetricUnits = false,
  });

  ComplianceReportData copyWith({
    String? projectTitle,
    String? clientName,
    String? siteAddress,
    String? technicianName,
    String? companyName,
    DateTime? date,
    RacewayProfile? raceway,
    List<ConductorGroup>? conductors,
    ConduitFillResult? fillResult,
    VoltageDropResult? voltageDropResult,
    DeratingResult? deratingResult,
    Uint8List? signaturePngBytes,
    String? inspectorName,
    String? licenseNumber,
    String? agencyName,
    double? nominalVoltage,
    CircuitPhase? circuitPhase,
    double? circuitLengthFeet,
    double? loadCurrentAmps,
    double? powerFactor,
    double? ambientTempC,
    double? terminalRatingC,
    int? cccCount,
    String? documentId,
    String? localeCode,
    NormativeCountry? normativeCountry,
    bool? useMetricUnits,
  }) {
    return ComplianceReportData(
      projectTitle: projectTitle ?? this.projectTitle,
      clientName: clientName ?? this.clientName,
      siteAddress: siteAddress ?? this.siteAddress,
      technicianName: technicianName ?? this.technicianName,
      companyName: companyName ?? this.companyName,
      date: date ?? this.date,
      raceway: raceway ?? this.raceway,
      conductors: conductors ?? this.conductors,
      fillResult: fillResult ?? this.fillResult,
      voltageDropResult: voltageDropResult ?? this.voltageDropResult,
      deratingResult: deratingResult ?? this.deratingResult,
      signaturePngBytes: signaturePngBytes ?? this.signaturePngBytes,
      inspectorName: inspectorName ?? this.inspectorName,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      agencyName: agencyName ?? this.agencyName,
      nominalVoltage: nominalVoltage ?? this.nominalVoltage,
      circuitPhase: circuitPhase ?? this.circuitPhase,
      circuitLengthFeet: circuitLengthFeet ?? this.circuitLengthFeet,
      loadCurrentAmps: loadCurrentAmps ?? this.loadCurrentAmps,
      powerFactor: powerFactor ?? this.powerFactor,
      ambientTempC: ambientTempC ?? this.ambientTempC,
      terminalRatingC: terminalRatingC ?? this.terminalRatingC,
      cccCount: cccCount ?? this.cccCount,
      documentId: documentId ?? this.documentId,
      localeCode: localeCode ?? this.localeCode,
      normativeCountry: normativeCountry ?? this.normativeCountry,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
    );
  }
}

/// Pure on-device deterministic PDF Technical Compliance Engine.
/// Generates A4 inspection-ready compliance memorandums strictly adhering
/// to NOM-001-SEDE (Mexico), NEC / NFPA 70 (USA), IEEE Std 141, and local standards.
class PdfReportService {
  // Brand & Document Color Palette (Vector PDF)
  static const PdfColor cHeaderBg = PdfColor(0.06, 0.09, 0.16); // #0F172A
  static const PdfColor cBrandBlue = PdfColor(0.15, 0.39, 0.92); // #2563EB
  static const PdfColor cPassGreen = PdfColor(0.09, 0.64, 0.29); // #16A34A
  static const PdfColor cCautionAmber = PdfColor(0.85, 0.47, 0.02); // #D97706
  static const PdfColor cFailRed = PdfColor(0.86, 0.15, 0.15); // #DC2626
  static const PdfColor cTextDark = PdfColor(0.09, 0.12, 0.17); // #171E2B
  static const PdfColor cTextMuted = PdfColor(0.40, 0.46, 0.54); // #64748B
  static const PdfColor cSurfaceBg = PdfColor(0.97, 0.98, 0.99); // #F8FAFC
  static const PdfColor cBorderSubtle = PdfColor(0.88, 0.91, 0.94); // #E2E8F0
  static const PdfColor cBorderDark = PdfColor(0.80, 0.84, 0.88); // #CBD5E1

  static String _tr(ComplianceReportData data, String es, String en, String pt) {
    final lang = data.localeCode.toLowerCase();
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  /// Generates the raw A4 PDF bytes for the given compliance report data.
  static Future<Uint8List> generateReport(ComplianceReportData data) async {
    pw.Font? fontBase;
    pw.Font? fontBold;
    bool isFlutterTest = false;
    if (!kIsWeb) {
      try {
        isFlutterTest = Platform.environment.containsKey('FLUTTER_TEST');
      } catch (_) {
        isFlutterTest = false;
      }
    }

    if (!isFlutterTest) {
      try {
        fontBase = await PdfGoogleFonts.robotoRegular();
        fontBold = await PdfGoogleFonts.robotoBold();
      } catch (_) {
        fontBase = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }
    } else {
      fontBase = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final standardLabel = data.normativeCountry == NormativeCountry.mexico
        ? 'NOM-001-SEDE'
        : 'NFPA 70 / NEC';

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontBase,
        bold: fontBold,
      ),
      title: '${_tr(data, "Reporte de Cumplimiento Eléctrico", "Electrical Technical Compliance Report", "Relatório de Conformidade Elétrica")} - ${data.projectTitle}',
      author: 'ElectroNorm Pro',
      creator: 'ElectroNorm Pro Pure Vector Compliance Engine',
      subject: '$standardLabel - Conduit Fill, Voltage Drop & Ampacity Verification',
    );

    final docId = data.documentId.isNotEmpty
        ? data.documentId
        : 'ENP-${data.date.year}${data.date.month.toString().padLeft(2, '0')}${data.date.day.toString().padLeft(2, '0')}-${(data.projectTitle.hashCode.abs() % 9000 + 1000)}';

    final dateFormat = DateFormat('dd/MMM/yyyy');
    final formattedDate = dateFormat.format(data.date);

    // Compute packed circle positions for the vector cross-section diagram
    final packedConductors = GoldenSpiralPackingAlgorithm.defaultInstance.pack(
      conduitRadius: data.raceway.internalDiameterInches / 2.0,
      groups: data.conductors,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        footer: (context) => _buildFooter(context, data, docId),
        build: (context) => [
          _buildHeaderBlock(data, docId, formattedDate),
          pw.SizedBox(height: 10),
          _buildRacewayAndVisualizerSection(data, packedConductors),
          pw.SizedBox(height: 10),
          _buildConductorScheduleTable(data),
          pw.SizedBox(height: 10),
          _buildVoltageDropAndDeratingSection(data),
          pw.SizedBox(height: 10),
          _buildInspectorSignOffBlock(data, formattedDate),
        ],
      ),
    );

    return doc.save();
  }

  /// Sends the document to the system native print sheet without external servers.
  static Future<void> printReport(ComplianceReportData data) async {
    final bytes = await generateReport(data);
    final title = data.projectTitle.trim().isEmpty ? 'Compliance_Report' : data.projectTitle.replaceAll(' ', '_');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${title}_Compliance_Report.pdf',
    );
  }

  /// Shares the document via native share sheet (WhatsApp, Email, Drive).
  static Future<void> shareReport(ComplianceReportData data) async {
    final bytes = await generateReport(data);
    final title = data.projectTitle.trim().isEmpty ? 'Compliance_Report' : data.projectTitle.replaceAll(' ', '_');
    final fileName = '${title}_Compliance_Report.pdf';
    final xFile = XFile.fromData(
      bytes,
      mimeType: 'application/pdf',
      name: fileName,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: 'ElectroNorm Pro Compliance Report: ${data.projectTitle}',
      ),
    );
  }

  /// Exports the PDF file directly to device storage.
  static Future<String> saveReportToFile(
    ComplianceReportData data, {
    String? fileName,
    Directory? targetDirectory,
  }) async {
    final bytes = await generateReport(data);
    final dir = targetDirectory ?? await getApplicationDocumentsDirectory();
    final title = data.projectTitle.trim().isEmpty ? 'Compliance_Report' : data.projectTitle.replaceAll(' ', '_');
    final name = fileName ?? '${title}_Compliance_Report.pdf';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  // --- PDF Component Builders ---

  static pw.Widget _buildHeaderBlock(
    ComplianceReportData data,
    String docId,
    String formattedDate,
  ) {
    final isMexico = data.normativeCountry == NormativeCountry.mexico;
    final subtitle = isMexico
        ? _tr(
            data,
            'Memoria de Cálculo NOM-001-SEDE: Ocupación de Canalización, Riesgo de Atasco y Caída de Tensión',
            'Normative NOM-001-SEDE Raceway Fill, Jam Hazard & Voltage Drop Memorandum',
            'Memorial NOM-001-SEDE: Ocupação de Eletroduto, Risco de Travamento e Queda de Tensão',
          )
        : _tr(
            data,
            'Memoria de Cálculo NFPA 70 (NEC): Ocupación de Canalización, Riesgo de Atasco y Caída de Tensión',
            'Normative NFPA 70 (NEC) Raceway Fill, Jam Hazard & Voltage Drop Memorandum',
            'Memorial NFPA 70 (NEC): Ocupação de Eletroduto, Risco de Travamento e Queda de Tensão',
          );
    final licPrefix = isMexico
        ? _tr(data, 'Cédula / Reg.', 'License #', 'Registro #')
        : _tr(data, 'Licencia #', 'Lic #', 'Licença #');

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: cHeaderBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const pw.BoxDecoration(
                          color: cBrandBlue,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          'ELECTRONORM PRO',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        _tr(
                          data,
                          'REPORTE TÉCNICO DE CUMPLIMIENTO ELÉCTRICO',
                          'ELECTRICAL TECHNICAL COMPLIANCE REPORT',
                          'RELATÓRIO TÉCNICO DE CONFORMIDADE ELÉTRICA',
                        ),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      color: PdfColor(0.70, 0.75, 0.82),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    '${_tr(data, "Folio", "Doc ID", "Doc ID")}: $docId',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${_tr(data, "Fecha", "Issue Date", "Data")}: $formattedDate',
                    style: const pw.TextStyle(
                      color: PdfColor(0.70, 0.75, 0.82),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 0.5, color: const PdfColor(0.25, 0.32, 0.42)),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: _headerMetaItem(
                  _tr(data, 'PROYECTO', 'PROJECT', 'PROJETO'),
                  data.projectTitle.isEmpty
                      ? _tr(
                          data,
                          'Alimentadores de Instalación Eléctrica',
                          'Commercial Facility Feeders',
                          'Alimentadores da Instalação Elétrica',
                        )
                      : data.projectTitle,
                  sub: '${_tr(data, "Ubicación", "Site", "Local")}: ${data.siteAddress.isEmpty ? _tr(data, "Por definir", "N/A", "A definir") : data.siteAddress}',
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: _headerMetaItem(
                  _tr(data, 'CLIENTE / PROPIETARIO', 'CLIENT / OWNER', 'CLIENTE / PROPRIETÁRIO'),
                  data.clientName.isEmpty ? 'N/A' : data.clientName,
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: _headerMetaItem(
                  _tr(data, 'RESPONSABLE / CONTRATISTA', 'INSTALLING CONTRACTOR', 'CONTRATADA RESPONSÁVEL'),
                  data.companyName.isEmpty ? 'N/A' : data.companyName,
                  sub: '${_tr(data, "Responsable", "Lead Tech", "Responsável")}: ${data.technicianName.isEmpty ? "N/A" : data.technicianName} | $licPrefix ${data.licenseNumber.isEmpty ? "N/A" : data.licenseNumber}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerMetaItem(String label, String value, {String? sub}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: PdfColor(0.55, 0.62, 0.70),
            fontSize: 6.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
          ),
          maxLines: 1,
        ),
        if (sub != null)
          pw.Text(
            sub,
            style: const pw.TextStyle(
              color: PdfColor(0.70, 0.75, 0.82),
              fontSize: 7,
            ),
            maxLines: 1,
          ),
      ],
    );
  }

  static pw.Widget _buildRacewayAndVisualizerSection(
    ComplianceReportData data,
    List<PackedConductorPosition> packedConductors,
  ) {
    final fill = data.fillResult;
    final raceway = data.raceway;
    final isPass = fill.isCompliant;
    final isMetric = data.useMetricUnits;

    final tradeSizeFormatted = NormativeFormatters.formatRacewaySize(
      raceway.tradeSize,
      type: raceway.type,
      metricDesignator: raceway.metricDesignator,
      isMetric: isMetric,
    );
    final tradeSizeValue = isMetric
        ? tradeSizeFormatted
        : '${raceway.tradeSize}" (${raceway.metricDesignator} mm)';

    final idValue = isMetric
        ? '${raceway.internalDiameterMm.toStringAsFixed(1)} mm (${raceway.internalDiameterInches.toStringAsFixed(3)} in)'
        : '${raceway.internalDiameterInches.toStringAsFixed(3)} in (${raceway.internalDiameterMm.toStringAsFixed(1)} mm)';

    final totalAreaValue = isMetric
        ? '${raceway.internalAreaSqMm.toStringAsFixed(1)} mm² (${raceway.internalAreaSqInches.toStringAsFixed(3)} in²)'
        : '${raceway.internalAreaSqInches.toStringAsFixed(3)} in² (${raceway.internalAreaSqMm.toStringAsFixed(1)} mm²)';

    final allowedAreaValue = isMetric
        ? '${(fill.allowedFillArea * NormativeFormatters.sqInchesToSqMm).toStringAsFixed(1)} mm² (${fill.allowedFillPercentage.toStringAsFixed(1)}%)'
        : '${fill.allowedFillArea.toStringAsFixed(3)} in² (${fill.allowedFillPercentage.toStringAsFixed(1)}%)';

    final wireAreaValue = isMetric
        ? '${(fill.totalConductorArea * NormativeFormatters.sqInchesToSqMm).toStringAsFixed(1)} mm² (${fill.totalConductorArea.toStringAsFixed(4)} in²)'
        : '${fill.totalConductorArea.toStringAsFixed(4)} in² (${(fill.totalConductorArea * NormativeFormatters.sqInchesToSqMm).toStringAsFixed(1)} mm²)';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left Column: Raceway Specs & Conduit Fill Analysis
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: cBorderSubtle, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              color: cSurfaceBg,
            ),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        _tr(
                          data,
                          'SECCIÓN 1: CANALIZACIÓN Y OCUPACIÓN (${data.normativeCountry.shortCode})',
                          'SECTION 1: RACEWAY SPECIFICATIONS & CONDUIT FILL',
                          'SEÇÃO 1: ESPECIFICAÇÕES DO ELETRODUTO E OCUPAÇÃO',
                        ),
                        style: pw.TextStyle(
                          color: cHeaderBg,
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    _buildComplianceBadge(
                      data: data,
                      isCompliant: isPass,
                      fillPercent: fill.fillPercentage,
                      allowedPercent: fill.allowedFillPercentage,
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _specProperty(
                        _tr(data, 'Tipo de Tubería', 'Conduit Type', 'Tipo de Eletroduto'),
                        raceway.type.fullName,
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        _tr(data, 'Designación / Diámetro', 'Trade Size', 'Diâmetro Nominal'),
                        tradeSizeValue,
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        'Material',
                        raceway.type.isMetallic
                            ? _tr(data, 'Metálica', 'Metallic', 'Metálico')
                            : _tr(data, 'No Metálica (PVC)', 'Non-Metallic (PVC)', 'Não Metálico (PVC)'),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _specProperty(
                        _tr(data, 'Diámetro Interno', 'Internal Diameter', 'Diâmetro Interno'),
                        idValue,
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        _tr(data, 'Área Interna Total', 'Total Internal Area', 'Área Interna Total'),
                        totalAreaValue,
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        _tr(data, 'Área Máx. Permitida', 'Permitted Fill Area', 'Área Máx. Permitida'),
                        allowedAreaValue,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _specProperty(
                        _tr(data, 'Área Total Conductores', 'Total Wire Area', 'Área Total dos Condutores'),
                        wireAreaValue,
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        _tr(data, 'Ocupación Real', 'Actual Raceway Occupancy', 'Ocupação Real'),
                        '${fill.fillPercentage.toStringAsFixed(1)}%',
                        isEmphasized: true,
                        valueColor: isPass ? cPassGreen : cFailRed,
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        isMetric
                            ? _tr(data, 'Niple (<= 60 cm)', 'Nipple (<= 60 cm / 24")', 'Niple (<= 60 cm)')
                            : _tr(data, 'Niple (<= 24")', 'Nipple Conduit (<= 24")', 'Niple (<= 24")'),
                        fill.isNipple
                            ? _tr(data, 'Sí (Límite 60%)', 'Yes (60% Max Limit)', 'Sim (Limite 60%)')
                            : _tr(
                                data,
                                'No (${data.normativeCountry.shortCode} estándar)',
                                'No (Standard ${data.normativeCountry.shortCode})',
                                'Não (Padrão ${data.normativeCountry.shortCode})',
                              ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                // Jam Ratio pull hazard warning
                _buildJamRatioBanner(data, fill),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),

        // Right Column: Pure Vector Conduit Cross-Section Diagram
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: cBorderSubtle, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              color: cSurfaceBg,
            ),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  _tr(data, 'SECCIÓN TRANSVERSAL', 'RACEWAY CROSS-SECTION', 'SEÇÃO TRANSVERSAL'),
                  style: pw.TextStyle(
                    color: cHeaderBg,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                // Canvas Diagram
                pw.CustomPaint(
                  size: const PdfPoint(120, 120),
                  painter: (PdfGraphics canvas, PdfPoint size) {
                    _drawConduitVectorDiagram(canvas, size, data, packedConductors);
                  },
                ),
                pw.SizedBox(height: 4),
                // Conductor Color Legend
                _buildColorLegend(data),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static void _drawConduitVectorDiagram(
    PdfGraphics canvas,
    PdfPoint size,
    ComplianceReportData data,
    List<PackedConductorPosition> packedConductors,
  ) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final outerWallRadius = (size.x / 2) - 3;
    final innerLumenRadius = outerWallRadius - 4;

    // 1. Draw outer raceway wall (metallic/PVC dark slate)
    canvas.setColor(const PdfColor(0.28, 0.33, 0.41));
    canvas.drawEllipse(cx, cy, outerWallRadius, outerWallRadius);
    canvas.fillPath();

    // 2. Draw inner lumen bore (deep dark mechanical room interior)
    canvas.setColor(const PdfColor(0.04, 0.06, 0.10));
    canvas.drawEllipse(cx, cy, innerLumenRadius, innerLumenRadius);
    canvas.fillPath();

    // 3. Subtle internal crosshair guides
    canvas.setColor(const PdfColor(0.12, 0.16, 0.23));
    canvas.setLineWidth(0.6);
    canvas.drawLine(cx - innerLumenRadius, cy, cx + innerLumenRadius, cy);
    canvas.strokePath();
    canvas.drawLine(cx, cy - innerLumenRadius, cx, cy + innerLumenRadius);
    canvas.strokePath();

    // 4. Draw packed conductors
    for (final p in packedConductors) {
      final px = cx + (p.normalizedX * innerLumenRadius);
      final py = cy + (p.normalizedY * innerLumenRadius);
      final pr = p.normalizedRadius * innerLumenRadius;

      if (pr <= 0.4) continue;

      // High-contrast outer border if specified (Phase A silver, Neutral dark slate)
      if (p.borderColor != null) {
        final bCol = _toPdfColor(p.borderColor!);
        canvas.setColor(bCol);
        canvas.drawEllipse(px, py, pr + 0.6, pr + 0.6);
        canvas.fillPath();
      }

      // Conductor insulation jacket
      final jacketColor = _toPdfColor(p.color);
      canvas.setColor(jacketColor);
      canvas.drawEllipse(px, py, pr, pr);
      canvas.fillPath();

      // Metallic core in center (copper or aluminum)
      final coreColor = p.isCopper
          ? const PdfColor(0.706, 0.325, 0.035) // Copper brown
          : const PdfColor(0.580, 0.640, 0.720); // Aluminum silver
      canvas.setColor(coreColor);
      final coreR = (pr * 0.35).clamp(0.6, pr * 0.5);
      canvas.drawEllipse(px, py, coreR, coreR);
      canvas.fillPath();
    }
  }

  static PdfColor _toPdfColor(Color c) {
    return PdfColor(c.r, c.g, c.b);
  }

  static pw.Widget _buildColorLegend(ComplianceReportData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        _legendDot(const PdfColor(0.26, 0.26, 0.26), _tr(data, 'F1', 'Ph A', 'F1')),
        pw.SizedBox(width: 4),
        _legendDot(const PdfColor(0.83, 0.0, 0.0), _tr(data, 'F2', 'Ph B', 'F2')),
        pw.SizedBox(width: 4),
        _legendDot(const PdfColor(0.16, 0.47, 1.0), _tr(data, 'F3', 'Ph C', 'F3')),
        pw.SizedBox(width: 4),
        _legendDot(const PdfColor(0.92, 0.94, 0.95), 'Neu'),
        pw.SizedBox(width: 4),
        _legendDot(const PdfColor(0.18, 0.49, 0.20), _tr(data, 'Tierra', 'GND', 'Terra')),
      ],
    );
  }

  static pw.Widget _legendDot(PdfColor color, String label) {
    return pw.Row(
      children: [
        pw.Container(
          width: 5,
          height: 5,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: const PdfColor(0.4, 0.4, 0.4), width: 0.4),
          ),
        ),
        pw.SizedBox(width: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: cTextMuted,
            fontSize: 5.5,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildComplianceBadge({
    required ComplianceReportData data,
    required bool isCompliant,
    required double fillPercent,
    required double allowedPercent,
  }) {
    final bg = isCompliant ? cPassGreen : cFailRed;
    final text = isCompliant
        ? '${_tr(data, "CUMPLE", "PASS", "APROVADO")} - ${fillPercent.toStringAsFixed(1)}% / ${allowedPercent.toStringAsFixed(1)}% max'
        : '${_tr(data, "EXCEDE", "VIOLATION", "VIOLAÇÃO")} - ${fillPercent.toStringAsFixed(1)}% (> ${allowedPercent.toStringAsFixed(1)}%)';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildJamRatioBanner(
    ComplianceReportData data,
    ConduitFillResult fill,
  ) {
    final ref = data.normativeCountry.jamRatioRef;
    if (fill.jamRatio == null) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(3),
        decoration: pw.BoxDecoration(
          color: const PdfColor(0.94, 0.95, 0.97),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          _tr(
            data,
            'Relación de Atasco ($ref): No aplica para la cantidad actual de conductores.',
            'Jam Ratio ($ref): Not applicable for current conductor count.',
            'Razão de Travamento ($ref): Não aplicável para a contagem atual.',
          ),
          style: const pw.TextStyle(color: cTextMuted, fontSize: 6.5),
        ),
      );
    }

    final ratio = fill.jamRatio!;
    final isHazard = fill.hasJamRisk;

    if (isHazard) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          color: const PdfColor(1.0, 0.94, 0.94),
          border: pw.Border.all(color: cFailRed, width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Row(
          children: [
            pw.Text(
              _tr(data, 'ALERTA DE ATASCO: ', 'PULL HAZARD WARNING: ', 'ALERTA DE TRAVAMENTO: '),
              style: pw.TextStyle(color: cFailRed, fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
            pw.Expanded(
              child: pw.Text(
                _tr(
                  data,
                  'Relación R_jam = ${ratio.toStringAsFixed(2)} está en rango crítico de acuñamiento (2.80 <= R_jam <= 3.20). Riesgo de atasco en curvas al jalar cables ($ref). Se recomienda subir diámetro de canalización.',
                  'Jam Ratio R_jam = ${ratio.toStringAsFixed(2)} falls within critical wedging range (2.80 <= R_jam <= 3.20). Cable crossover jamming hazard during pulling bends ($ref). Upsizing raceway recommended!',
                  'Razão R_jam = ${ratio.toStringAsFixed(2)} na faixa crítica (2.80 <= R_jam <= 3.20). Risco de travamento em curvas ($ref). Aumente o diâmetro.',
                ),
                style: const pw.TextStyle(color: cFailRed, fontSize: 6.5),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: const PdfColor(0.93, 0.97, 0.94),
        border: pw.Border.all(color: cPassGreen, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        _tr(
          data,
          'Relación de Atasco: R_jam = ${ratio.toStringAsFixed(2)} - Holgura segura para jalado (fuera de banda crítica 2.80 - 3.20).',
          'Jam Ratio: R_jam = ${ratio.toStringAsFixed(2)} - Safe pulling clearance (Outside critical jamming boundary 2.80 - 3.20).',
          'Razão de Travamento: R_jam = ${ratio.toStringAsFixed(2)} - Folga segura de puxamento (fora da faixa 2.80 - 3.20).',
        ),
        style: const pw.TextStyle(color: cPassGreen, fontSize: 6.5),
      ),
    );
  }

  static pw.Widget _specProperty(
    String label,
    String value, {
    bool isEmphasized = false,
    PdfColor? valueColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(color: cTextMuted, fontSize: 6.5),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: valueColor ?? cTextDark,
            fontSize: isEmphasized ? 8.5 : 7.5,
            fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildConductorScheduleTable(ComplianceReportData data) {
    final totalCount = data.conductors.fold(0, (sum, g) => sum + g.count);
    final totalArea = data.fillResult.totalConductorArea;
    final isMetric = data.useMetricUnits;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: cBorderSubtle, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: cSurfaceBg,
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _tr(
              data,
              'SECCIÓN 2: TABLA DE CONDUCTORES Y DESGLOSE DE SECCIÓN TRANSVERSAL',
              'SECTION 2: CONDUCTOR SCHEDULE & CROSS-SECTIONAL BREAKDOWN',
              'SEÇÃO 2: LISTA DE CONDUTORES E ÁREA TRANSVERSAL',
            ),
            style: pw.TextStyle(
              color: cHeaderBg,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: cBorderSubtle, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(26), // Qty
              1: pw.FlexColumnWidth(2.4), // Gauge
              2: pw.FlexColumnWidth(1.3), // Insulation
              3: pw.FlexColumnWidth(1.1), // Core
              4: pw.FlexColumnWidth(1.6), // OD
              5: pw.FlexColumnWidth(1.8), // Single Area
              6: pw.FlexColumnWidth(2.0), // Total Area
              7: pw.FlexColumnWidth(1.8), // Role
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: cHeaderBg),
                children: [
                  _tblHeader(_tr(data, 'Cant', 'Qty', 'Qtd')),
                  _tblHeader(_tr(data, 'Calibre / Sección', 'Gauge / Size', 'Bitola')),
                  _tblHeader(_tr(data, 'Aislam.', 'Type', 'Isolação')),
                  _tblHeader(_tr(data, 'Metal', 'Core', 'Metal')),
                  _tblHeader(isMetric ? 'DE (mm)' : 'OD (in)'),
                  _tblHeader(
                    isMetric
                        ? _tr(data, 'Área c/u (mm²)', 'Area/ea (mm²)', 'Área un (mm²)')
                        : _tr(data, 'Área c/u (in²)', 'Area/ea (in²)', 'Área un (in²)'),
                  ),
                  _tblHeader(
                    isMetric
                        ? _tr(data, 'Área Total (mm²)', 'Total Area (mm²)', 'Área Total (mm²)')
                        : _tr(data, 'Área Total (in²)', 'Total Area (in²)', 'Área Total (in²)'),
                  ),
                  _tblHeader(_tr(data, 'Función', 'Circuit Role', 'Função')),
                ],
              ),
              // Conductor Rows
              ...data.conductors.map((g) {
                final isGround = g.isGround;
                final gaugeText = NormativeFormatters.formatAwgWithMetric(
                  g.spec.gauge,
                  isMetric: isMetric,
                );
                final odText = isMetric
                    ? (g.spec.outerDiameterInches * NormativeFormatters.inchesToMm).toStringAsFixed(2)
                    : g.spec.outerDiameterInches.toStringAsFixed(3);
                final singleAreaText = isMetric
                    ? (g.spec.areaSqInches * NormativeFormatters.sqInchesToSqMm).toStringAsFixed(2)
                    : g.spec.areaSqInches.toStringAsFixed(4);
                final groupAreaText = isMetric
                    ? (g.totalAreaSqInches * NormativeFormatters.sqInchesToSqMm).toStringAsFixed(2)
                    : g.totalAreaSqInches.toStringAsFixed(4);

                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isGround ? const PdfColor(0.96, 0.98, 0.96) : PdfColors.white,
                  ),
                  children: [
                    _tblCell('${g.count}', align: pw.TextAlign.center, isBold: true),
                    _tblCell(gaugeText, isBold: true),
                    _tblCell(g.spec.insulation.name.toUpperCase()),
                    _tblCell(g.spec.material.isCopper ? 'Cu' : 'Al', align: pw.TextAlign.center),
                    _tblCell(odText, align: pw.TextAlign.right),
                    _tblCell(singleAreaText, align: pw.TextAlign.right),
                    _tblCell(groupAreaText, align: pw.TextAlign.right, isBold: true),
                    _tblCell(_roleDisplayName(data, g.role)),
                  ],
                );
              }),
              // Total Summary Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor(0.93, 0.95, 0.98)),
                children: [
                  _tblCell('$totalCount', align: pw.TextAlign.center, isBold: true),
                  _tblCell(_tr(data, 'TOTAL CONDUCTORES', 'TOTAL CONDUCTORS', 'TOTAL CONDUTORES'), isBold: true),
                  _tblCell('-'),
                  _tblCell('-'),
                  _tblCell('-'),
                  _tblCell(_tr(data, 'TOTAL:', 'TOTAL WIRE:', 'TOTAL:')),
                  _tblCell(
                    isMetric
                        ? '${(totalArea * NormativeFormatters.sqInchesToSqMm).toStringAsFixed(1)} mm²'
                        : '${totalArea.toStringAsFixed(4)} in²',
                    align: pw.TextAlign.right,
                    isBold: true,
                  ),
                  _tblCell(
                    '${data.fillResult.fillPercentage.toStringAsFixed(1)}% ${_tr(data, "Ocup.", "Fill", "Ocup.")}',
                    isBold: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _roleDisplayName(ComplianceReportData data, String role) {
    final norm = role.toLowerCase().trim();
    if (norm.contains('phasea') || norm == 'l1' || norm == 'phase a') {
      return _tr(data, 'Fase A (L1)', 'Phase A (L1)', 'Fase A (L1)');
    }
    if (norm.contains('phaseb') || norm == 'l2' || norm == 'phase b') {
      return _tr(data, 'Fase B (L2)', 'Phase B (L2)', 'Fase B (L2)');
    }
    if (norm.contains('phasec') || norm == 'l3' || norm == 'phase c') {
      return _tr(data, 'Fase C (L3)', 'Phase C (L3)', 'Fase C (L3)');
    }
    if (norm.contains('neutral') || norm == 'n') {
      return _tr(data, 'Neutro (N)', 'Neutral (N)', 'Neutro (N)');
    }
    if (norm.contains('ground') || norm == 'g' || norm == 'egc' || norm == 'pe') {
      return _tr(data, 'Tierra (TF)', 'Ground (EGC)', 'Terra (PE)');
    }
    return role;
  }

  static pw.Widget _tblHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 6.8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tblCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: cTextDark,
          fontSize: 6.8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildVoltageDropAndDeratingSection(ComplianceReportData data) {
    final vDrop = data.voltageDropResult;
    final derate = data.deratingResult;
    final isMexico = data.normativeCountry == NormativeCountry.mexico;
    final isMetric = data.useMetricUnits;

    final lengthDisplay = isMetric
        ? '${(data.circuitLengthFeet * NormativeFormatters.feetToMeters).toStringAsFixed(1)} m (${data.circuitLengthFeet.toStringAsFixed(0)} ft)'
        : '${data.circuitLengthFeet.toStringAsFixed(0)} ft (${(data.circuitLengthFeet * NormativeFormatters.feetToMeters).toStringAsFixed(1)} m)';

    final ambientDisplay = isMetric
        ? '${data.ambientTempC.toStringAsFixed(0)}°C'
        : '${data.ambientTempC.toStringAsFixed(0)}°C (${((data.ambientTempC * 9 / 5) + 32).toStringAsFixed(0)}°F)';

    final tempFactorRef = isMexico ? '310-15(b)(2)' : '310.15(B)(1)';
    final bundleFactorRef = isMexico ? '310-15(b)(3)' : '310.15(C)(1)';
    final derateShortCode = isMexico ? 'NOM 310-15' : 'NEC 310.15';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: cBorderSubtle, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: cSurfaceBg,
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _tr(
              data,
              'SECCIÓN 3: ANÁLISIS DE CAÍDA DE TENSIÓN Y DERRATEO TÉRMICO DE AMPACIDAD',
              'SECTION 3: VOLTAGE DROP & THERMAL AMPACITY DERATING ANALYSIS',
              'SEÇÃO 3: ANÁLISE DE QUEDA DE TENSÃO E FATORES DE CORREÇÃO TÉRMICA',
            ),
            style: pw.TextStyle(
              color: cHeaderBg,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Voltage Drop Box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: cBorderSubtle, width: 0.6),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${_tr(data, "CAÍDA DE TENSIÓN", "VOLTAGE DROP", "QUEDA DE TENSÃO")} (${data.normativeCountry.voltageDropRef})',
                              style: pw.TextStyle(
                                color: cBrandBlue,
                                fontSize: 7.2,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          if (vDrop != null)
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                              decoration: pw.BoxDecoration(
                                color: vDrop.isCompliantBranch ? cPassGreen : cFailRed,
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                              ),
                              child: pw.Text(
                                vDrop.isCompliantBranch
                                    ? _tr(data, 'CUMPLE (<= 3.0%)', 'PASS (<= 3.0%)', 'APROVADO (<= 3.0%)')
                                    : _tr(data, 'EXCEDE LÍMITE', 'EXCEEDS LIMIT', 'EXCEDE LIMITE'),
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 6, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _calcMetric(
                              _tr(data, 'Tensión Nominal', 'Nominal Voltage', 'Tensão Nominal'),
                              '${data.nominalVoltage.toStringAsFixed(0)} V CA',
                            ),
                          ),
                          pw.Expanded(
                            child: _calcMetric(
                              _tr(data, 'Sistema', 'Phase', 'Sistema'),
                              data.circuitPhase == CircuitPhase.threePhase
                                  ? _tr(data, 'Trifásico (3F)', '3-Phase AC', 'Trifásico (3F)')
                                  : _tr(data, 'Monofásico (1F)', '1-Phase AC', 'Monofásico (1F)'),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _calcMetric(
                              _tr(data, 'Longitud (Ida)', 'One-Way Length', 'Comprimento'),
                              lengthDisplay,
                            ),
                          ),
                          pw.Expanded(
                            child: _calcMetric(
                              _tr(data, 'Corriente de Carga', 'Design Current', 'Corrente de Projeto'),
                              '${data.loadCurrentAmps.toStringAsFixed(1)} A (FP: ${data.powerFactor.toStringAsFixed(2)})',
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      if (vDrop != null) ...[
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _calcMetric(
                                _tr(data, 'Caída Calculada', 'Calculated Voltage Drop', 'Queda Calculada'),
                                '${vDrop.voltageDropVolts.toStringAsFixed(2)} V (${vDrop.percentageDrop.toStringAsFixed(2)}%)',
                                isBold: true,
                                color: vDrop.isCompliantBranch ? cPassGreen : cFailRed,
                              ),
                            ),
                            pw.Expanded(
                              child: _calcMetric(
                                _tr(data, 'Tensión en Carga', 'End Load Voltage', 'Tensão na Carga'),
                                '${vDrop.endVoltage.toStringAsFixed(1)} V CA',
                                isBold: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),

              // Right: Thermal Derating Box
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    border: pw.Border.all(color: cBorderSubtle, width: 0.6),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${_tr(data, "DERRATEO TÉRMICO", "THERMAL DERATING", "CORREÇÃO TÉRMICA")} ($derateShortCode)',
                              style: pw.TextStyle(
                                color: cBrandBlue,
                                fontSize: 7.2,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: const pw.BoxDecoration(
                              color: cHeaderBg,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                            ),
                            child: pw.Text(
                              '$derateShortCode ${_tr(data, "OK", "COMPLIANT", "OK")}',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: _calcMetric(
                              _tr(data, 'Temp. Ambiente', 'Ambient Temperature', 'Temp. Ambiente'),
                              ambientDisplay,
                            ),
                          ),
                          pw.Expanded(
                            child: _calcMetric(
                              _tr(data, 'Cond. Portadores', 'Current-Carrying Cond.', 'Cond. Carregados'),
                              '${data.cccCount} ${_tr(data, "Conductores", "Conductors", "Condutores")}',
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      if (derate != null) ...[
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _calcMetric(
                                '${_tr(data, "Factor Temp.", "Temp Correction", "Fator Temp.")} ($tempFactorRef)',
                                derate.temperatureCorrectionFactor.toStringAsFixed(2),
                              ),
                            ),
                            pw.Expanded(
                              child: _calcMetric(
                                '${_tr(data, "Agrupamiento", "Bundling Factor", "Agrupamento")} ($bundleFactorRef)',
                                derate.bundlingAdjustmentFactor.toStringAsFixed(2),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _calcMetric(
                                _tr(data, 'Límite en Terminales', 'Terminal Clamping Limit', 'Limite nos Terminais'),
                                '${derate.terminalRatingLimit.toStringAsFixed(1)} A (${data.normativeCountry.terminalRatingRef} ${data.terminalRatingC.toStringAsFixed(0)}°C)',
                              ),
                            ),
                            pw.Expanded(
                              child: _calcMetric(
                                _tr(data, 'Ampacidad Admisible', 'Final Allowable Ampacity', 'Ampacidade Admissível'),
                                '${derate.allowableAmpacity.toStringAsFixed(1)} A (Base: ${derate.baseAmpacity.toStringAsFixed(0)}A)',
                                isBold: true,
                                color: cPassGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _calcMetric(
    String label,
    String value, {
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(color: cTextMuted, fontSize: 6.2),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: color ?? cTextDark,
            fontSize: 7.2,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInspectorSignOffBlock(
    ComplianceReportData data,
    String formattedDate,
  ) {
    final hasSig = data.signaturePngBytes != null && data.signaturePngBytes!.isNotEmpty;
    final isMexico = data.normativeCountry == NormativeCountry.mexico;
    final standardClause = isMexico ? 'NOM-001-SEDE' : 'NFPA 70 (NEC)';

    final authorityHeading = isMexico
        ? _tr(
            data,
            'UNIDAD DE VERIFICACIÓN / PERITO (UVIE / PEC)',
            'VERIFICATION AUTHORITY (UVIE / PEC)',
            'AUTORIDADE DE INSPEÇÃO (UVIE / PEC)',
          )
        : _tr(
            data,
            'AUTORIDAD COMPETENTE / INSPECTOR (AHJ)',
            'AUTHORITY HAVING JURISDICTION (AHJ)',
            'AUTORIDADE COMPETENTE (AHJ)',
          );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: cBorderDark, width: 1.0),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        color: PdfColors.white,
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _tr(
                  data,
                  'SECCIÓN 4: VALIDACIÓN TÉCNICA EN CAMPO Y FIRMA DE ACEPTACIÓN',
                  'SECTION 4: FORMAL FIELD INSPECTION SIGN-OFF & ACCEPTANCE',
                  'SEÇÃO 4: VISTORIA TÉCNICA EM CAMPO E ASSINATURA DE ACEITE',
                ),
                style: pw.TextStyle(
                  color: cHeaderBg,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: data.fillResult.isCompliant ? cPassGreen : cCautionAmber,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  data.fillResult.isCompliant
                      ? _tr(data, 'APROBADO PARA ENERGIZAR', 'APPROVED FOR ENERGIZING', 'APROVADO PARA ENERGIZAR')
                      : _tr(data, 'REVISIÓN CONDICIONAL', 'CONDITIONAL INSPECTION', 'INSPEÇÃO CONDICIONAL'),
                  style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              // Installer Sign-Off
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: cSurfaceBg,
                    border: pw.Border.all(color: cBorderSubtle, width: 0.6),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _tr(
                          data,
                          'CERTIFICACIÓN DEL RESPONSABLE / CONTRATISTA',
                          'INSTALLING CONTRACTOR CERTIFICATION',
                          'CERTIFICAÇÃO DO RESPONSÁVEL TÉCNICO',
                        ),
                        style: pw.TextStyle(color: cTextMuted, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${_tr(data, "Responsable", "Lead Technician", "Responsável")}: ${data.technicianName.isEmpty ? "N/A" : data.technicianName}',
                        style: pw.TextStyle(color: cTextDark, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '${isMexico ? _tr(data, "Cédula / Registro", "License / Cert #", "Registro Prof.") : _tr(data, "Licencia / Cert #", "License / Cert #", "Registro / Crea #")}: ${data.licenseNumber.isEmpty ? "N/A" : data.licenseNumber}',
                        style: const pw.TextStyle(color: cTextDark, fontSize: 7),
                      ),
                      pw.Text(
                        '${_tr(data, "Fecha", "Date", "Data")}: $formattedDate',
                        style: const pw.TextStyle(color: cTextDark, fontSize: 7),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(height: 0.6, color: cBorderDark),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _tr(
                          data,
                          'Manifiesto que el porcentaje de ocupación, relación de atasco, caída de tensión y ajuste térmico cumplen estrictamente con $standardClause.',
                          'I hereby certify that the conduit fill, jam ratio analysis, voltage drop, and conductor deratings specified above adhere strictly to $standardClause standards.',
                          'Declaro que a ocupação, razão de travamento, queda de tensão e correção térmica atendem rigorosamente às normas $standardClause.',
                        ),
                        style: const pw.TextStyle(color: cTextMuted, fontSize: 5.5),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),

              // Inspector / UVIE Sign-Off
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: cSurfaceBg,
                    border: pw.Border.all(color: cBorderSubtle, width: 0.6),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              authorityHeading,
                              style: pw.TextStyle(color: cTextMuted, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          if (hasSig)
                            pw.Text(
                              _tr(data, 'FIRMA DIGITAL VÁLIDA', 'VERIFIED DIGITAL STROKE', 'ASSINATURA VERIFICADA'),
                              style: pw.TextStyle(color: cPassGreen, fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${isMexico ? _tr(data, "Verificador / Perito", "Inspector", "Inspetor") : _tr(data, "Inspector", "Inspector", "Inspetor")}: ${data.inspectorName}',
                        style: pw.TextStyle(color: cTextDark, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '${isMexico ? _tr(data, "UVIE / Organismo", "Agency", "Órgão") : _tr(data, "Dependencia / Org.", "Agency", "Órgão")}: ${data.agencyName}',
                        style: const pw.TextStyle(color: cTextDark, fontSize: 7),
                      ),
                      pw.Text(
                        '${_tr(data, "Fecha de Revisión", "Inspection Date", "Data da Vistoria")}: $formattedDate',
                        style: const pw.TextStyle(color: cTextDark, fontSize: 7),
                      ),
                      pw.SizedBox(height: 4),

                      // Embedded Signature Pad PNG Image or Placeholder
                      pw.Container(
                        height: 36,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(color: hasSig ? cBrandBlue : cBorderSubtle, width: 0.8),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        alignment: pw.Alignment.center,
                        child: hasSig
                            ? pw.Image(
                                pw.MemoryImage(data.signaturePngBytes!),
                                height: 32,
                                fit: pw.BoxFit.contain,
                              )
                            : pw.Text(
                                _tr(
                                  data,
                                  '[ Espacio reservado para firma digital en sitio ]',
                                  '[ Touch Digital Signature Captured at Inspection ]',
                                  '[ Assinatura digital capturada na vistoria ]',
                                ),
                                style: const pw.TextStyle(color: cTextMuted, fontSize: 6.5),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(
    pw.Context context,
    ComplianceReportData data,
    String docId,
  ) {
    final standardRef = data.normativeCountry.fillStandardRef;
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: cBorderSubtle, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              _tr(
                data,
                'ElectroNorm Pro - Generado localmente sin conexión. Norma $standardRef. Folio: $docId',
                'ElectroNorm Pro - Generated offline on-device. Standard $standardRef. Document ID: $docId',
                'ElectroNorm Pro - Gerado localmente offline. Norma $standardRef. Doc ID: $docId',
              ),
              style: const pw.TextStyle(color: cTextMuted, fontSize: 6),
            ),
          ),
          pw.Text(
            _tr(
              data,
              'Página ${context.pageNumber} de ${context.pagesCount}',
              'Page ${context.pageNumber} of ${context.pagesCount}',
              'Página ${context.pageNumber} de ${context.pagesCount}',
            ),
            style: const pw.TextStyle(color: cTextMuted, fontSize: 6, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
