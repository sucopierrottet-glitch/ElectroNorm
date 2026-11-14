import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/pdf_report_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/signature_dialog.dart';
import 'paywall_screen.dart';

/// Fullscreen inspection report preview, signature capture, and sharing screen.
class ReportPreviewScreen extends StatefulWidget {
  final ComplianceReportData reportData;

  const ReportPreviewScreen({
    super.key,
    required this.reportData,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  late ComplianceReportData _data;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _data = widget.reportData;
  }

  String _tr(String es, String en, String pt) {
    final lang = StorageService.instance.localeCode.toLowerCase();
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  Future<void> _captureSignature() async {
    final result = await SignatureDialog.show(
      context,
      inspectorName: _data.inspectorName,
      licenseNumber: _data.licenseNumber,
      agencyName: _data.agencyName,
      normativeCountry: _data.normativeCountry,
    );

    if (result != null && mounted) {
      setState(() {
        _data = _data.copyWith(
          signaturePngBytes: result.signatureBytes,
          inspectorName: result.inspectorName,
          licenseNumber: result.licenseNumber,
          agencyName: result.agencyName,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(Icons.verified, color: AppColors.compliant, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _tr(
                    'Firma de verificación incorporada para ${result.inspectorName}',
                    'Inspector signature embedded for ${result.inspectorName}',
                    'Assinatura incorporada para ${result.inspectorName}',
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _ensureProAccess() async {
    final isPro = await StorageService.instance.isProSubscriber();
    if (isPro) return true;
    if (!mounted) return false;
    final upgraded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (ctx) => const PaywallScreen()),
    );
    return upgraded == true;
  }

  Future<void> _shareReport() async {
    final hasAccess = await _ensureProAccess();
    if (!hasAccess) return;
    try {
      await PdfReportService.shareReport(_data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.overfilled,
            content: Text('${_tr("Error al compartir", "Failed to share report", "Erro ao compartilhar")}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _exportToStorage() async {
    final hasAccess = await _ensureProAccess();
    if (!hasAccess) return;
    setState(() => _isExporting = true);
    try {
      final path = await PdfReportService.saveReportToFile(_data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            duration: const Duration(seconds: 4),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.compliant, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _tr('PDF Exportado Correctamente', 'PDF Exported Successfully',
                            'PDF Exportado com Sucesso'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  path,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.overfilled,
            content: Text('${_tr("Error al exportar", "Error exporting file", "Erro ao exportar")}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSignature = _data.signaturePngBytes != null && _data.signaturePngBytes!.isNotEmpty;
    final country = _data.normativeCountry;
    final defaultSubtitle = country == NormativeCountry.mexico
        ? _tr('Verificación NOM-001-SEDE', 'NOM-001-SEDE Verification', 'Verificação NOM-001')
        : _tr('Verificación NFPA 70 / NEC', 'NFPA 70 Verification', 'Verificação NFPA 70');

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('Vista Previa de Dictamen PDF', 'Compliance Report Preview',
                  'Pré-visualização do Relatório'),
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              _data.projectTitle.isEmpty ? defaultSubtitle : _data.projectTitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: _tr('Compartir PDF por WhatsApp / Correo',
                'Share PDF via WhatsApp / Email', 'Compartilhar PDF'),
            onPressed: _shareReport,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.compliant),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: _tr('Descargar en Dispositivo', 'Download to Device Storage',
                'Baixar no Dispositivo'),
            onPressed: _isExporting ? null : _exportToStorage,
          ),
        ],
      ),
      body: SafeArea(
        child: PdfPreview(
          build: (format) => PdfReportService.generateReport(_data),
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          maxPageWidth: 720,
          loadingWidget: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.compliant),
                const SizedBox(height: 12),
                Text(
                  _tr('Generando Memoria Técnica...', 'Rendering Technical Compliance Memorandum...',
                      'Gerando Relatório Técnico...'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            PdfPreviewAction(
              icon: const Icon(Icons.draw, color: Colors.white),
              onPressed: (ctx, build, pageFormat) async {
                await _captureSignature();
              },
            ),
            PdfPreviewAction(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: (ctx, build, pageFormat) async {
                await _shareReport();
              },
            ),
            PdfPreviewAction(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: (ctx, build, pageFormat) async {
                await _exportToStorage();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Icon(
                hasSignature ? Icons.verified : Icons.draw_outlined,
                color: hasSignature ? AppColors.compliant : AppColors.caution,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSignature
                          ? _tr('Firma de Inspección Verificada', 'Inspector Sign-Off Verified',
                              'Assinatura Verificada')
                          : _tr('Firma de Inspección Pendiente', 'Inspection Signature Pending',
                              'Assinatura Pendente'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: hasSignature ? AppColors.compliant : AppColors.caution,
                      ),
                    ),
                    Text(
                      hasSignature
                          ? _tr(
                              'Firmado por ${_data.inspectorName} (${_data.agencyName})',
                              'Signed by ${_data.inspectorName} (${_data.agencyName})',
                              'Assinado por ${_data.inspectorName} (${_data.agencyName})',
                            )
                          : _tr(
                              'Toca para capturar firma del técnico / ${country.inspectionAuthorityShort}',
                              'Tap to capture technician or AHJ signature',
                              'Toque para capturar assinatura técnica',
                            ),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSignature ? AppColors.surfaceElevated : AppColors.compliant,
                  foregroundColor: hasSignature ? AppColors.textPrimary : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(hasSignature ? Icons.edit : Icons.draw, size: 16),
                label: Text(
                  hasSignature
                      ? _tr('Re-Firmar', 'Re-Sign', 'Reassinar')
                      : _tr('Firmar Dictamen', 'Sign Report', 'Assinar'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _captureSignature,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
