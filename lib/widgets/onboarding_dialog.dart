import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class OnboardingDialog extends StatefulWidget {
  final StorageService storageService;

  const OnboardingDialog({super.key, required this.storageService});

  static Future<void> show(
    BuildContext context, {
    StorageService? storageService,
  }) async {
    final storage = storageService ?? StorageService.instance;
    final seen = await storage.hasSeenOnboarding();
    if (seen) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OnboardingDialog(storageService: storage),
    );
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final _companyCtrl = TextEditingController();
  final _agencyCtrl = TextEditingController();
  final _techNameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();

  String _tr(String es, String en, String pt) {
    final lang = widget.storageService.localeCode;
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final p = await widget.storageService.getProfile();
    if (!mounted) return;
    setState(() {
      _companyCtrl.text = p.companyName;
      _agencyCtrl.text = p.agencyName;
      _techNameCtrl.text = p.technicianName;
      _licenseCtrl.text = p.licenseNumber;
    });
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _agencyCtrl.dispose();
    _techNameCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndFinish() async {
    final current = await widget.storageService.getProfile();
    final updated = current.copyWith(
      companyName: _companyCtrl.text.trim(),
      agencyName: _agencyCtrl.text.trim(),
      technicianName: _techNameCtrl.text.trim(),
      licenseNumber: _licenseCtrl.text.trim(),
    );

    await widget.storageService.saveProfile(updated);
    await widget.storageService.setHasSeenOnboarding(true);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _skip() async {
    await widget.storageService.setHasSeenOnboarding(true);
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.electrical_services_rounded,
                  color: AppTheme.accent,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _tr(
                '¡Bienvenido a ElectroNorm!',
                'Welcome to ElectroNorm!',
                'Bem-vindo ao ElectroNorm!',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'Configura los datos de tu empresa o perfil técnico para tus reportes PDF (puedes cambiarlos cuando quieras en Ajustes).',
                'Set up your company or technician details for your PDF reports (you can change them anytime in Settings).',
                'Configure os dados da sua empresa ou perfil técnico para seus relatórios PDF (você pode alterá-los em Ajustes).',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _companyCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _tr(
                  'Nombre de tu Empresa o Contratista *',
                  'Company or Contractor Name *',
                  'Nome da sua Empresa ou Empreiteira *',
                ),
                prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _agencyCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _tr(
                  'Especialidad / Organismo (Ej: Ingeniería Eléctrica, NEC)',
                  'Specialty / Bureau (e.g. Electrical Engineering, AHJ)',
                  'Especialidade / Órgão (Ex: Engenharia Elétrica, CREA)',
                ),
                prefixIcon: const Icon(Icons.work_outline_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _techNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _tr(
                  'Tu Nombre / Ingeniero Responsable (Opcional)',
                  'Your Name / Lead Engineer (Optional)',
                  'Seu Nome / Engenheiro Responsável (Opcional)',
                ),
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _licenseCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _tr(
                  'Matrícula / Licencia Profesional (Opcional)',
                  'Professional License # (Optional)',
                  'Registro Profissional / CREA (Opcional)',
                ),
                prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveAndFinish,
              icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
              label: Text(
                _tr(
                  'Comenzar a Calcular',
                  'Start Calculating',
                  'Começar a Calcular',
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _skip,
              child: Text(
                _tr(
                  'Omitir y configurar después',
                  'Skip and configure later',
                  'Pular e configurar depois',
                ),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
