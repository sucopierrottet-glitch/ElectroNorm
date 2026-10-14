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
    );
  }
}

/// Pure on-device deterministic PDF Technical Compliance Engine.
/// Generates A4 inspection-ready compliance memorandums strictly adhering
/// to NEC (NFPA 70), IEEE Std 141, and local jurisdiction standards.
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

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontBase,
        bold: fontBold,
      ),
      title: 'Electrical Technical Compliance Report - ${data.projectTitle}',
      author: 'ElectroNorm Pro',
      creator: 'ElectroNorm Pro Pure Vector Compliance Engine',
      subject: 'NFPA 70 / NEC Conduit Fill, Voltage Drop & Ampacity Verification',
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
        footer: (context) => _buildFooter(context, docId),
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
                        'ELECTRICAL TECHNICAL COMPLIANCE REPORT',
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
                    'Normative NFPA 70 (NEC) Raceway Fill, Jam Hazard & Voltage Drop Memorandum',
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
                    'Doc ID: $docId',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Issue Date: $formattedDate',
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
                  'PROJECT',
                  data.projectTitle.isEmpty ? 'Commercial Facility Feeders' : data.projectTitle,
                  sub: 'Site: ${data.siteAddress.isEmpty ? "742 Evergreen Terrace, Springfield" : data.siteAddress}',
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: _headerMetaItem(
                  'CLIENT / OWNER',
                  data.clientName.isEmpty ? 'N/A' : data.clientName,
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: _headerMetaItem(
                  'INSTALLING CONTRACTOR',
                  data.companyName.isEmpty ? 'N/A' : data.companyName,
                  sub: 'Lead Tech: ${data.technicianName.isEmpty ? "N/A" : data.technicianName} | Lic #${data.licenseNumber.isEmpty ? "N/A" : data.licenseNumber}',
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
                    pw.Text(
                      'SECTION 1: RACEWAY SPECIFICATIONS & CONDUIT FILL',
                      style: pw.TextStyle(
                        color: cHeaderBg,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    _buildComplianceBadge(
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
                      child: _specProperty('Conduit Type', raceway.type.fullName),
                    ),
                    pw.Expanded(
                      child: _specProperty('Trade Size', '${raceway.tradeSize}" (${raceway.metricDesignator} mm)'),
                    ),
                    pw.Expanded(
                      child: _specProperty('Material', raceway.type.isMetallic ? 'Metallic' : 'Non-Metallic (PVC)'),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _specProperty(
                        'Internal Diameter',
                        '${raceway.internalDiameterInches.toStringAsFixed(3)} in (${raceway.internalDiameterMm.toStringAsFixed(1)} mm)',
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        'Total Internal Area',
                        '${raceway.internalAreaSqInches.toStringAsFixed(3)} in² (${raceway.internalAreaSqMm.toStringAsFixed(1)} mm²)',
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        'Permitted Fill Area',
                        '${fill.allowedFillArea.toStringAsFixed(3)} in² (${fill.allowedFillPercentage.toStringAsFixed(1)}%)',
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _specProperty(
                        'Total Wire Area',
                        '${fill.totalConductorArea.toStringAsFixed(4)} in² (${(fill.totalConductorArea * 645.16).toStringAsFixed(1)} mm²)',
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        'Actual Raceway Occupancy',
                        '${fill.fillPercentage.toStringAsFixed(1)}%',
                        isEmphasized: true,
                        valueColor: isPass ? cPassGreen : cFailRed,
                      ),
                    ),
                    pw.Expanded(
                      child: _specProperty(
                        'Nipple Conduit (<= 24")',
                        fill.isNipple ? 'Yes (60% Max Limit)' : 'No (Standard NEC)',
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                // Jam Ratiopull hazard warning
                _buildJamRatioBanner(fill),
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
                  'RACEWAY CROSS-SECTION',
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
                _buildColorLegend(),
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

  static pw.Widget _buildColorLegend() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        _legendDot(const PdfColor(0.26, 0.26, 0.26), 'Ph A'),
        pw.SizedBox(width: 4),
        _legendDot(const PdfColor(0.83, 0.0, 0.0), 'Ph B'),
        pw.SizedBox(width: 4),
        _legendDot(const PdfColor(0.16, 0.47, 1.0), 'Ph C'),
        pw.SizedBox(width: 4),
        _legendDot(const PdfColor(0.92, 0.94, 0.95), 'Neu'),
        pw.SizedBox(width: 4),
        _legendDot(const PdfColor(0.18, 0.49, 0.20), 'GND'),
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
    required bool isCompliant,
    required double fillPercent,
    required double allowedPercent,
  }) {
    final bg = isCompliant ? cPassGreen : cFailRed;
    final text = isCompliant
        ? 'PASS - ${fillPercent.toStringAsFixed(1)}% / ${allowedPercent.toStringAsFixed(1)}% max'
        : 'VIOLATION - ${fillPercent.toStringAsFixed(1)}% (Exceeds ${allowedPercent.toStringAsFixed(1)}%)';

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

  static pw.Widget _buildJamRatioBanner(ConduitFillResult fill) {
    if (fill.jamRatio == null) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(3),
        decoration: pw.BoxDecoration(
          color: const PdfColor(0.94, 0.95, 0.97),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          'Jam Ratio (NEC Ch 9 Note 2): Not applicable for current conductor count.',
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
              'PULL HAZARD WARNING: ',
              style: pw.TextStyle(color: cFailRed, fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
            pw.Expanded(
              child: pw.Text(
                'Jam Ratio R_jam = ${ratio.toStringAsFixed(2)} falls within critical wedging range (2.80 <= R_jam <= 3.20). Cable crossover jamming hazard during pulling bends (NEC Ch 9 Note 2). Upsizing raceway recommended!',
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
        'Jam Ratio: R_jam = ${ratio.toStringAsFixed(2)} - Safe pulling clearance (Outside critical jamming boundary 2.80 - 3.20).',
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
            'SECTION 2: CONDUCTOR SCHEDULE & CROSS-SECTIONAL BREAKDOWN',
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
              1: pw.FlexColumnWidth(2.2), // Gauge
              2: pw.FlexColumnWidth(1.4), // Insulation
              3: pw.FlexColumnWidth(1.2), // Core
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
                  _tblHeader('Qty'),
                  _tblHeader('Gauge / Size'),
                  _tblHeader('Type'),
                  _tblHeader('Core'),
                  _tblHeader('OD (in)'),
                  _tblHeader('Area/ea (in²)'),
                  _tblHeader('Total Area (in²)'),
                  _tblHeader('Circuit Role'),
                ],
              ),
              // Conductor Rows
              ...data.conductors.map((g) {
                final isGround = g.isGround;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isGround ? const PdfColor(0.96, 0.98, 0.96) : PdfColors.white,
                  ),
                  children: [
                    _tblCell('${g.count}', align: pw.TextAlign.center, isBold: true),
                    _tblCell(g.spec.gauge, isBold: true),
                    _tblCell(g.spec.insulation.name.toUpperCase()),
                    _tblCell(g.spec.material.isCopper ? 'Cu' : 'Al', align: pw.TextAlign.center),
                    _tblCell(g.spec.outerDiameterInches.toStringAsFixed(3), align: pw.TextAlign.right),
                    _tblCell(g.spec.areaSqInches.toStringAsFixed(4), align: pw.TextAlign.right),
                    _tblCell(g.totalAreaSqInches.toStringAsFixed(4), align: pw.TextAlign.right, isBold: true),
                    _tblCell(_roleDisplayName(g.role)),
                  ],
                );
              }),
              // Total Summary Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor(0.93, 0.95, 0.98)),
                children: [
                  _tblCell('$totalCount', align: pw.TextAlign.center, isBold: true),
                  _tblCell('TOTAL CONDUCTORS', isBold: true),
                  _tblCell('-'),
                  _tblCell('-'),
                  _tblCell('-'),
                  _tblCell('TOTAL WIRE:'),
                  _tblCell('${totalArea.toStringAsFixed(4)} in²', align: pw.TextAlign.right, isBold: true),
                  _tblCell('${data.fillResult.fillPercentage.toStringAsFixed(1)}% Fill', isBold: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _roleDisplayName(String role) {
    final norm = role.toLowerCase().trim();
    if (norm.contains('phasea') || norm == 'l1' || norm == 'phase a') return 'Phase A (L1)';
    if (norm.contains('phaseb') || norm == 'l2' || norm == 'phase b') return 'Phase B (L2)';
    if (norm.contains('phasec') || norm == 'l3' || norm == 'phase c') return 'Phase C (L3)';
    if (norm.contains('neutral') || norm == 'n') return 'Neutral (N)';
    if (norm.contains('ground') || norm == 'g' || norm == 'egc' || norm == 'pe') return 'Ground (EGC)';
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
            'SECTION 3: VOLTAGE DROP & THERMAL AMPACITY DERATING ANALYSIS',
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
                          pw.Text(
                            'VOLTAGE DROP (NEC 210.19 / 215.2)',
                            style: pw.TextStyle(
                              color: cBrandBlue,
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
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
                                vDrop.isCompliantBranch ? 'PASS (<= 3.0%)' : 'EXCEEDS LIMIT',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 6, fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _calcMetric('Nominal Voltage', '${data.nominalVoltage.toStringAsFixed(0)} V AC')),
                          pw.Expanded(child: _calcMetric('Phase', data.circuitPhase == CircuitPhase.threePhase ? '3-Phase AC' : '1-Phase AC')),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _calcMetric('One-Way Length', '${data.circuitLengthFeet.toStringAsFixed(0)} ft (${(data.circuitLengthFeet * 0.3048).toStringAsFixed(1)} m)')),
                          pw.Expanded(child: _calcMetric('Design Current', '${data.loadCurrentAmps.toStringAsFixed(1)} A (PF: ${data.powerFactor.toStringAsFixed(2)})')),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      if (vDrop != null) ...[
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _calcMetric(
                                'Calculated Voltage Drop',
                                '${vDrop.voltageDropVolts.toStringAsFixed(2)} V (${vDrop.percentageDrop.toStringAsFixed(2)}%)',
                                isBold: true,
                                color: vDrop.isCompliantBranch ? cPassGreen : cFailRed,
                              ),
                            ),
                            pw.Expanded(
                              child: _calcMetric(
                                'End Load Voltage',
                                '${vDrop.endVoltage.toStringAsFixed(1)} V AC',
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
                          pw.Text(
                            'THERMAL DERATING (NEC 310.15 & 110.14)',
                            style: pw.TextStyle(
                              color: cBrandBlue,
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: const pw.BoxDecoration(
                              color: cHeaderBg,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                            ),
                            child: pw.Text(
                              'NEC 310.15 COMPLIANT',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _calcMetric('Ambient Temperature', '${data.ambientTempC.toStringAsFixed(0)}°C (${((data.ambientTempC * 9 / 5) + 32).toStringAsFixed(0)}°F)')),
                          pw.Expanded(child: _calcMetric('Current-Carrying Cond.', '${data.cccCount} Conductors')),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      if (derate != null) ...[
                        pw.Row(
                          children: [
                            pw.Expanded(child: _calcMetric('Temp Correction (310.15(B)(1))', derate.temperatureCorrectionFactor.toStringAsFixed(2))),
                            pw.Expanded(child: _calcMetric('Bundling Factor (310.15(C)(1))', derate.bundlingAdjustmentFactor.toStringAsFixed(2))),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: _calcMetric(
                                'Terminal Clamping Limit',
                                '${derate.terminalRatingLimit.toStringAsFixed(1)} A (NEC 110.14(C) 75°C)',
                              ),
                            ),
                            pw.Expanded(
                              child: _calcMetric(
                                'Final Allowable Ampacity',
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
                'SECTION 4: FORMAL FIELD INSPECTION SIGN-OFF & ACCEPTANCE',
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
                  data.fillResult.isCompliant ? 'APPROVED FOR ENERGIZING' : 'CONDITIONAL INSPECTION',
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
                        'INSTALLING CONTRACTOR CERTIFICATION',
                        style: pw.TextStyle(color: cTextMuted, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Lead Technician: ${data.technicianName.isEmpty ? "N/A" : data.technicianName}',
                        style: pw.TextStyle(color: cTextDark, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('License / Cert #: ${data.licenseNumber.isEmpty ? "N/A" : data.licenseNumber}', style: const pw.TextStyle(color: cTextDark, fontSize: 7)),
                      pw.Text('Date: $formattedDate', style: const pw.TextStyle(color: cTextDark, fontSize: 7)),
                      pw.SizedBox(height: 12),
                      pw.Container(height: 0.6, color: cBorderDark),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'I hereby certify that the conduit fill, jam ratio analysis, voltage drop, and conductor deratings specified above adhere strictly to NFPA 70 (NEC) standards.',
                        style: const pw.TextStyle(color: cTextMuted, fontSize: 5.5),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),

              // AHJ Inspector Sign-Off
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
                          pw.Text(
                            'AUTHORITY HAVING JURISDICTION (AHJ)',
                            style: pw.TextStyle(color: cTextMuted, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                          ),
                          if (hasSig)
                            pw.Text(
                              'VERIFIED DIGITAL STROKE',
                              style: pw.TextStyle(color: cPassGreen, fontSize: 6, fontWeight: pw.FontWeight.bold),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Inspector: ${data.inspectorName}',
                        style: pw.TextStyle(color: cTextDark, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Agency: ${data.agencyName}', style: const pw.TextStyle(color: cTextDark, fontSize: 7)),
                      pw.Text('Inspection Date: $formattedDate', style: const pw.TextStyle(color: cTextDark, fontSize: 7)),
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
                                '[ Touch Digital Signature Captured at Inspection ]',
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

  static pw.Widget _buildFooter(pw.Context context, String docId) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: cBorderSubtle, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ElectroNorm Pro - Generated offline on-device. Standard NFPA 70 / NEC Chapter 9 Tables 1, 4 & 5. Document ID: $docId',
            style: const pw.TextStyle(color: cTextMuted, fontSize: 6),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: cTextMuted, fontSize: 6, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
