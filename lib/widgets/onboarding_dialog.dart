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
    final storage = widget.storageService;
    final isMexico = storage.isMexicoProfile;

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
                'Elige tu norma de cálculo y configura tus datos técnicos para memorias PDF (puedes cambiarlo cuando quieras en Ajustes).',
                'Select your code standard and set up your technician details for PDF reports (changeable anytime in Settings).',
                'Escolha sua norma de cálculo e configure seus dados para relatórios PDF.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _tr('PERFIL NORMATIVO', 'CODE STANDARD', 'PERFIL NORMATIVO'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.accent,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const Key('onboarding_profile_mexico'),
                    onTap: () async {
                      await storage.setNormativeCountry(NormativeCountry.mexico);
                      if (mounted) setState(() {});
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMexico
                            ? AppTheme.primary.withValues(alpha: 0.18)
                            : AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMexico ? AppTheme.primary : AppTheme.darkBorder,
                          width: isMexico ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🇲🇽', style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          const Text(
                            'México',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'NOM-001 • Métrico',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isMexico ? AppTheme.accent : AppTheme.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    key: const Key('onboarding_profile_usa'),
                    onTap: () async {
                      await storage.setNormativeCountry(NormativeCountry.usa);
                      if (mounted) setState(() {});
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: !isMexico
                            ? AppTheme.primary.withValues(alpha: 0.18)
                            : AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !isMexico ? AppTheme.primary : AppTheme.darkBorder,
                          width: !isMexico ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text('🇺🇸', style: TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          const Text(
                            'USA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'NEC (NFPA 70) • in/ft',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !isMexico ? AppTheme.accent : AppTheme.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                labelText: isMexico
                    ? _tr(
                        'UVIE / Organismo Verificador (Opcional)',
                        'UVIE / Inspection Agency (Optional)',
                        'Órgão Verificador (Opcional)',
                      )
                    : _tr(
                        'Especialidad / Organismo (Ej: Ingeniería Eléctrica, AHJ)',
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
                labelText: isMexico
                    ? _tr(
                        'Cédula Profesional / Registro UVIE (Opcional)',
                        'Professional License / UVIE ID (Optional)',
                        'Registro Profissional (Opcional)',
                      )
                    : _tr(
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
