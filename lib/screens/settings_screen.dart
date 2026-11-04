import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/signature_dialog.dart';
import 'paywall_screen.dart';
import 'welcome_landing_screen.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService? storageService;

  const SettingsScreen({super.key, this.storageService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _licenseController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _agencyController = TextEditingController();
  final _addressController = TextEditingController();

  String? _defaultSignatureBase64;
  bool _isPro = false;
  bool _isTrial = false;
  int _remainingTrialDays = 0;
  bool _isLoading = true;

  StorageService get _storage => widget.storageService ?? StorageService.instance;

  String _tr(String es, String en, String pt) {
    final lang = _storage.localeCode;
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _licenseController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _agencyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = _storage;
    final profile = await storage.getProfile();
    final isPro = await storage.isProSubscriber();
    final isTrial = await storage.isTrialActive();
    final days = await storage.getRemainingTrialDays();

    if (!mounted) return;
    setState(() {
      _nameController.text = profile.technicianName;
      _companyController.text = profile.companyName;
      _licenseController.text = profile.licenseNumber;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _agencyController.text = profile.agencyName;
      _addressController.text = profile.address;
      _defaultSignatureBase64 = profile.defaultSignatureBase64;
      _isPro = isPro;
      _isTrial = isTrial;
      _remainingTrialDays = days;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final storage = _storage;
    final current = await storage.getProfile();
    final profile = current.copyWith(
      technicianName: _nameController.text.trim(),
      companyName: _companyController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      agencyName: _agencyController.text.trim(),
      address: _addressController.text.trim(),
      defaultSignatureBase64: _defaultSignatureBase64,
      clearDefaultSignature: _defaultSignatureBase64 == null,
    );
    await storage.saveProfile(profile);

    if (!mounted) return;
    final s = storage.strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.settingsSavedSuccess),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _captureDefaultSignature() async {
    final result = await SignatureDialog.show(
      context,
      inspectorName:
          _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      licenseNumber:
          _licenseController.text.trim().isEmpty ? null : _licenseController.text.trim(),
      agencyName:
          _agencyController.text.trim().isEmpty ? null : _agencyController.text.trim(),
    );

    if (result != null && mounted) {
      final b64 = base64Encode(result.signatureBytes);
      setState(() {
        _defaultSignatureBase64 = b64;
        if (_nameController.text.trim().isEmpty && result.inspectorName.isNotEmpty) {
          _nameController.text = result.inspectorName;
        }
        if (_licenseController.text.trim().isEmpty && result.licenseNumber.isNotEmpty) {
          _licenseController.text = result.licenseNumber;
        }
        if (_agencyController.text.trim().isEmpty && result.agencyName.isNotEmpty) {
          _agencyController.text = result.agencyName;
        }
      });
      await _saveSettings();
    }
  }

  Future<void> _removeDefaultSignature() async {
    setState(() {
      _defaultSignatureBase64 = null;
    });
    await _saveSettings();
  }

  Future<void> _shareApp() async {
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.simpleappspg.electronorm';
    final message = _tr(
      'Te recomiendo ElectroNorm Pro para calcular llenado de tuberías NEC, caída de tensión y generar memorias técnicas en PDF desde el celular: $playStoreUrl',
      'Check out ElectroNorm Pro to calculate NEC conduit fill, voltage drop, and generate PDF compliance reports on your phone: $playStoreUrl',
      'Recomendo o ElectroNorm Pro para calcular ocupação de eletrodutos, queda de tensão e gerar relatórios técnicos em PDF no celular: $playStoreUrl',
    );
    await SharePlus.instance.share(ShareParams(text: message));
  }

  Future<void> _rateApp() async {
    final marketUri = Uri.parse('market://details?id=com.simpleappspg.electronorm');
    final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.simpleappspg.electronorm');
    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactSupport() async {
    final subject = Uri.encodeComponent('ElectroNorm Pro - Soporte / Sugerencia');
    final mailUri = Uri.parse('mailto:simpleappspg@gmail.com?subject=$subject');
    try {
      await launchUrl(mailUri);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr(
              'Escríbenos a: simpleappspg@gmail.com',
              'Email us at: simpleappspg@gmail.com',
              'Escreva para: simpleappspg@gmail.com',
            )),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://sucopierrottet-glitch.github.io/electronorm-privacy/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _storage,
      builder: (context, _) {
        final storage = _storage;
        final s = storage.strings;
        final currentLang = storage.localeCode;

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          appBar: AppBar(
            title: Text(s.settingsTitle),
            actions: [
              IconButton(
                key: const Key('btnSaveSettingsAppBar'),
                icon: const Icon(Icons.check_rounded, color: AppTheme.primary),
                tooltip: s.save,
                onPressed: _saveSettings,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 0. Language Selector (Same place and design as FieldQuote)
                      _buildSectionTitle(context, _tr('IDIOMA / LANGUAGE', 'LANGUAGE', 'IDIOMA')),
                      const SizedBox(height: 10),
                      Material(
                        color: AppTheme.darkCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppTheme.darkBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildLanguageOption(
                              code: 'es',
                              flag: '🇪🇸',
                              label: 'Español',
                              currentLang: currentLang,
                            ),
                            const Divider(height: 1, color: AppTheme.darkBorder),
                            _buildLanguageOption(
                              code: 'en',
                              flag: '🇺🇸',
                              label: 'English',
                              currentLang: currentLang,
                            ),
                            const Divider(height: 1, color: AppTheme.darkBorder),
                            _buildLanguageOption(
                              code: 'pt',
                              flag: '🇧🇷',
                              label: 'Português',
                              currentLang: currentLang,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // 1. Pro Status Card (Identical gradient banner to FieldQuote)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isPro
                              ? [const Color(0xFF059669), const Color(0xFF047857)]
                              : [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPro
                                      ? (_isTrial
                                          ? '${s.trialActiveTitle} ($_remainingTrialDays d)'
                                          : s.proActiveTitle)
                                      : s.freePlanTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isPro ? s.proActiveSubtitle : s.freePlanSubtitle,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isPro)
                            ElevatedButton(
                              key: const Key('btnSettingsUpgradePro'),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                                );
                                _loadSettings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: Text(
                                _tr('Mejorar', 'Upgrade', 'Assinar'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Professional & Company Data
                    _buildSectionTitle(context, s.technicianProfileHeader),
                    const SizedBox(height: 6),
                    Text(
                      s.technicianProfileDesc,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('inputSettingsTechName'),
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: s.technicianNameLabel,
                        prefixIcon:
                            const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('inputSettingsCompanyName'),
                      controller: _companyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: s.companyNameLabel,
                        prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('inputSettingsAgency'),
                      controller: _agencyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: s.agencyNameLabel,
                        prefixIcon:
                            const Icon(Icons.work_outline_rounded, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('inputSettingsLicense'),
                      controller: _licenseController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: s.licenseNumberLabel,
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('inputSettingsAddress'),
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: s.addressLabel,
                        prefixIcon:
                            const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(
                      context,
                      _tr('CONTACTO / CONTACT', 'CONTACT DETAILS', 'CONTATO'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('inputSettingsPhone'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: s.phoneLabel,
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('inputSettingsEmail'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: s.emailLabel,
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // 3. Default Digital Signature (Identical to FieldQuote)
                    _buildSectionTitle(
                      context,
                      _tr(
                        'FIRMA DIGITAL PREDETERMINADA',
                        'DEFAULT DIGITAL SIGNATURE',
                        'ASSINATURA DIGITAL PADRÃO',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tr(
                        'Tu firma de ingeniero o responsable técnico aparecerá automáticamente al pie de todas tus memorias de cálculo PDF.',
                        'Your engineer or inspector signature will automatically appear at the bottom of your PDF compliance reports.',
                        'Sua assinatura de responsável técnico aparecerá automaticamente no rodapé dos seus relatórios em PDF.',
                      ),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (_defaultSignatureBase64 != null && _defaultSignatureBase64!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppTheme.success.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 90,
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.memory(
                                base64Decode(_defaultSignatureBase64!),
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: _captureDefaultSignature,
                                  icon: const Icon(Icons.edit_rounded,
                                      size: 16, color: AppTheme.accent),
                                  label: Text(
                                    _tr('Cambiar Firma', 'Change Signature',
                                        'Alterar Assinatura'),
                                    style: const TextStyle(
                                        color: AppTheme.accent, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: _removeDefaultSignature,
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 16, color: AppTheme.error),
                                  label: Text(
                                    _tr('Eliminar', 'Remove', 'Remover'),
                                    style: const TextStyle(
                                        color: AppTheme.error, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: _captureDefaultSignature,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.darkBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.draw_rounded, color: AppTheme.accent),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _tr(
                                    'Configurar Firma Digital del Técnico / Ingeniero',
                                    'Set Up Default Technician / Engineer Signature',
                                    'Configurar Assinatura Digital do Técnico',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                    // 4. Applicable Electrical Standards
                    _buildSectionTitle(context, s.technicalStandardsHeader),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.technicalStandardsDesc,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStandardChip('NEC (NFPA 70)'),
                              _buildStandardChip('NOM-001-SEDE'),
                              _buildStandardChip('RETIE'),
                              _buildStandardChip('NBR 5410'),
                              _buildStandardChip('IEC 60364'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // 5. Community & Feedback (Exact match with FieldQuote)
                    _buildSectionTitle(
                      context,
                      _tr('COMUNIDAD Y OPINIONES', 'COMMUNITY & FEEDBACK',
                          'COMUNIDADE E OPINIÕES'),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: AppTheme.darkCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppTheme.darkBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            onTap: _shareApp,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.share_rounded,
                                  color: AppTheme.primary, size: 20),
                            ),
                            title: Text(
                              _tr(
                                'Compartir aplicación',
                                'Share application',
                                'Compartilhar aplicativo',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _tr(
                                'Recomienda ElectroNorm a otros colegas y electricistas',
                                'Recommend ElectroNorm to fellow electricians and engineers',
                                'Recomende o ElectroNorm para outros colegas e eletricistas',
                              ),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textSecondary),
                          ),
                          const Divider(height: 1, color: AppTheme.darkBorder),
                          ListTile(
                            onTap: _rateApp,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.star_rate_rounded,
                                  color: Color(0xFFFBBF24), size: 20),
                            ),
                            title: Text(
                              _tr(
                                'Calificar en Google Play',
                                'Rate on Google Play',
                                'Avaliar no Google Play',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _tr(
                                '¿Te ayuda la app? Apóyanos con 5 estrellas ⭐',
                                'Enjoying the app? Support us with 5 stars ⭐',
                                'Gostou do app? Apoie-nos com 5 estrelas ⭐',
                              ),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.open_in_new_rounded,
                                size: 18, color: AppTheme.textSecondary),
                          ),
                          const Divider(height: 1, color: AppTheme.darkBorder),
                          ListTile(
                            onTap: _contactSupport,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.mail_outline_rounded,
                                  color: AppTheme.success, size: 20),
                            ),
                            title: Text(
                              _tr(
                                'Soporte y Sugerencias',
                                'Support & Feedback',
                                'Suporte e Sugestões',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _tr(
                                'Envíanos tus dudas o ideas para mejorar',
                                'Send us your questions or feature requests',
                                'Envie suas dúvidas ou ideias de melhoria',
                              ),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textSecondary),
                          ),
                          const Divider(height: 1, color: AppTheme.darkBorder),
                          ListTile(
                            onTap: _openPrivacyPolicy,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.privacy_tip_outlined,
                                  color: AppTheme.accent, size: 20),
                            ),
                            title: Text(
                              s.privacyPolicyBtn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              s.appVersion,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.open_in_new_rounded,
                                size: 18, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // 6. Welcome Landing Button (Exact match with FieldQuote)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const WelcomeLandingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.rocket_launch_rounded,
                          size: 18, color: AppTheme.accent),
                      label: Text(
                        _tr(
                          'Ver Pantalla de Presentación / Landing',
                          'View Welcome Landing Screen',
                          'Ver Tela de Boas-Vindas / Landing',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.darkBorder),
                        backgroundColor: AppTheme.darkCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      key: const Key('btnSaveProfile'),
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        s.saveSettingsBtn,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required String code,
    required String flag,
    required String label,
    required String currentLang,
  }) {
    final isSelected = currentLang.toLowerCase().startsWith(code);
    return ListTile(
      key: Key('lang_option_$code'),
      onTap: () => _storage.setLocale(code),
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary)
          : const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF64748B)),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.accent,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
    );
  }

  Widget _buildStandardChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined, color: AppTheme.success, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
