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

  Future<void> _captureSignature() async {
    final result = await SignatureDialog.show(
      context,
      inspectorName: _data.inspectorName,
      licenseNumber: _data.licenseNumber,
      agencyName: _data.agencyName,
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
                  'Inspector signature embedded for ${result.inspectorName}',
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
            content: Text('Failed to share report: $e'),
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
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.compliant, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'PDF Exported Successfully',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
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
            content: Text('Error exporting file: $e'),
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

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compliance Report Preview', style: TextStyle(fontSize: 16)),
            Text(
              _data.projectTitle.isEmpty ? 'NFPA 70 Verification' : _data.projectTitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share PDF via WhatsApp / Email',
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
            tooltip: 'Download to Device Storage',
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
          loadingWidget: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.compliant),
                SizedBox(height: 12),
                Text(
                  'Rendering Technical Compliance Memorandum...',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                      hasSignature ? 'Inspector Sign-Off Verified' : 'Inspection Signature Pending',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: hasSignature ? AppColors.compliant : AppColors.caution,
                      ),
                    ),
                    Text(
                      hasSignature
                          ? 'Signed by ${_data.inspectorName} (${_data.agencyName})'
                          : 'Tap to capture technician or AHJ signature',
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
                  hasSignature ? 'Re-Sign' : 'Sign Report',
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
