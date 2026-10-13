import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../theme/app_theme.dart';

/// Container for inspector verification and signature data captured in the field.
class SignatureDialogResult {
  final Uint8List signatureBytes;
  final String inspectorName;
  final String licenseNumber;
  final String agencyName;

  const SignatureDialogResult({
    required this.signatureBytes,
    required this.inspectorName,
    required this.licenseNumber,
    required this.agencyName,
  });
}

/// Touch-optimized modal signature capture dialog adhering to Material 3 dark-first field theme.
class SignatureDialog extends StatefulWidget {
  final String initialInspectorName;
  final String initialLicense;
  final String initialAgency;

  const SignatureDialog({
    super.key,
    this.initialInspectorName = 'Robert Vance',
    this.initialLicense = 'ME-948210',
    this.initialAgency = 'City Electrical Inspection Bureau',
  });

  /// Displays the modal dialog and returns the captured signature result or null if cancelled.
  static Future<SignatureDialogResult?> show(
    BuildContext context, {
    String? inspectorName,
    String? licenseNumber,
    String? agencyName,
  }) {
    return showDialog<SignatureDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SignatureDialog(
        initialInspectorName: inspectorName ?? 'Robert Vance',
        initialLicense: licenseNumber ?? 'ME-948210',
        initialAgency: agencyName ?? 'City Electrical Inspection Bureau',
      ),
    );
  }

  /// Convenience shortcut that returns only the raw transparent PNG bytes.
  static Future<Uint8List?> showSignatureOnly(
    BuildContext context, {
    String? inspectorName,
  }) async {
    final result = await show(context, inspectorName: inspectorName);
    return result?.signatureBytes;
  }

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  late final SignatureController _controller;
  late final TextEditingController _nameController;
  late final TextEditingController _licenseController;
  late final TextEditingController _agencyController;

  bool _isExporting = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3.0,
      penColor: Colors.white,
      exportBackgroundColor: Colors.transparent,
      onDrawEnd: () {
        if (_validationError != null) {
          setState(() => _validationError = null);
        }
      },
    );
    _nameController = TextEditingController(text: widget.initialInspectorName);
    _licenseController = TextEditingController(text: widget.initialLicense);
    _agencyController = TextEditingController(text: widget.initialAgency);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _licenseController.dispose();
    _agencyController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_controller.isEmpty) {
      setState(() {
        _validationError = 'Please draw your signature on the pad before confirming.';
      });
      return;
    }

    setState(() => _isExporting = true);
    try {
      final pngBytes = await _controller.toPngBytes();
      if (!mounted) return;

      if (pngBytes == null || pngBytes.isEmpty) {
        setState(() {
          _isExporting = false;
          _validationError = 'Failed to extract signature image. Please redraw.';
        });
        return;
      }

      Navigator.of(context).pop(
        SignatureDialogResult(
          signatureBytes: pngBytes,
          inspectorName: _nameController.text.trim().isEmpty
              ? 'Inspector / AHJ'
              : _nameController.text.trim(),
          licenseNumber: _licenseController.text.trim().isEmpty
              ? 'N/A'
              : _licenseController.text.trim(),
          agencyName: _agencyController.text.trim().isEmpty
              ? 'Electrical Bureau'
              : _agencyController.text.trim(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _validationError = 'Error saving signature: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.compliant.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.draw_outlined,
                      color: AppColors.compliant,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inspector Digital Sign-Off',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'NFPA 70 Official Field Inspection Acceptance',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(null),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Inspector Name Field
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Inspector / Authority Having Jurisdiction Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              // License & Agency Grid
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _licenseController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'License / Cert #',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _agencyController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Agency / City Bureau',
                        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.textSecondary, size: 20),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Touch Signature Pad Surface
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Touch Signature Pad',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16, color: AppColors.caution),
                    label: const Text('Clear Stroke', style: TextStyle(color: AppColors.caution, fontSize: 12)),
                    onPressed: () => _controller.clear(),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.bgDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _validationError != null
                          ? AppColors.overfilled
                          : AppColors.borderHighContrast,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtly dashed signature line
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 1,
                          color: AppColors.borderSubtle,
                        ),
                      ),
                      Positioned(
                        bottom: 22,
                        left: 20,
                        child: Text(
                          'Sign above the line',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      // Interactive signature surface
                      Signature(
                        controller: _controller,
                        height: 180,
                        backgroundColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),

              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.overfilled, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(color: AppColors.overfilled, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderSubtle),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.compliant,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(
                        _isExporting ? 'Embedding Signature...' : 'Confirm Sign-Off',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: _isExporting ? null : _handleConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
