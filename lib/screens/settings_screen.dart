import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';

/// Screen allowing the user to configure technician profile information
/// (which appears on PDF reports), select application language (ES / EN / PT),
/// and inspect Pro subscription status.
class SettingsScreen extends StatefulWidget {
  final StorageService? storageService;

  const SettingsScreen({super.key, this.storageService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final StorageService _storage;

  late final TextEditingController _technicianNameCtrl;
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _licenseNumberCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _agencyNameCtrl;
  late final TextEditingController _addressCtrl;

  bool _isLoading = true;
  bool _isPro = false;
  bool _isTrial = false;
  int _remainingDays = 0;

  @override
  void initState() {
    super.initState();
    _storage = widget.storageService ?? StorageService.instance;
    _technicianNameCtrl = TextEditingController();
    _companyNameCtrl = TextEditingController();
    _licenseNumberCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _agencyNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();

    _loadData();
    _storage.addListener(_onStorageChanged);
  }

  void _onStorageChanged() {
    if (mounted) {
      _loadData(isInitial: false);
    }
  }

  Future<void> _loadData({bool isInitial = true}) async {
    final profile = await _storage.getProfile();
    final isPro = await _storage.isProSubscriber();
    final isTrial = await _storage.isTrialActive();
    final remainingDays = await _storage.getRemainingTrialDays();

    if (isInitial) {
      _technicianNameCtrl.text = profile.technicianName;
      _companyNameCtrl.text = profile.companyName;
      _licenseNumberCtrl.text = profile.licenseNumber;
      _emailCtrl.text = profile.email;
      _phoneCtrl.text = profile.phone;
      _agencyNameCtrl.text = profile.agencyName;
      _addressCtrl.text = profile.address;
    }

    if (mounted) {
      setState(() {
        _isPro = isPro;
        _isTrial = isTrial;
        _remainingDays = remainingDays;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageChanged);
    _technicianNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _licenseNumberCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _agencyNameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    final updated = TechnicianProfile(
      technicianName: _technicianNameCtrl.text.trim(),
      companyName: _companyNameCtrl.text.trim(),
      licenseNumber: _licenseNumberCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      agencyName: _agencyNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    await _storage.saveProfile(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_storage.strings.settingsSavedSuccess} ✓'),
          backgroundColor: AppColors.compliant,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPrivacyPolicyModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _storage.strings.privacyPolicyBtn,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'ElectroNorm Pro opera bajo una estricta política de privacidad '
                  'Local-First. Todos los cálculos eléctricos, fórmulas, calibres, '
                  'perfiles técnicos y memorias descriptivas se almacenan únicamente '
                  'en el almacenamiento seguro de tu dispositivo. No vendemos, transferimos '
                  'ni procesamos datos técnicos en servidores externos.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.compliant,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(_storage.strings.close),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String code, String flag, String name) {
    final isSelected = _storage.localeCode == code;
    return Expanded(
      child: InkWell(
        key: Key('lang_option_$code'),
        onTap: () => _storage.setLocale(code),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.compliant.withValues(alpha: 0.16)
                : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.compliant : AppColors.borderSubtle,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.compliant : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.compliant),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
          filled: true,
          fillColor: AppColors.surfaceCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.compliant, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _storage,
      builder: (context, _) {
        final s = _storage.strings;

        if (_isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.bgDark,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.compliant),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          appBar: AppBar(
            backgroundColor: AppColors.bgDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              s.settingsTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LANGUAGE SELECTOR
                _buildSectionHeader(s.languageSelectorTitle, Icons.language_rounded),
                const SizedBox(height: 6),
                Text(
                  s.languageSelectorSubtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLanguageOption('es', '🇪🇸', s.languageSpanish),
                    const SizedBox(width: 8),
                    _buildLanguageOption('en', '🇺🇸', s.languageEnglish),
                    const SizedBox(width: 8),
                    _buildLanguageOption('pt', '🇧🇷', s.languagePortuguese),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. PRO SUBSCRIPTION CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isPro
                          ? [const Color(0xFF065F46), const Color(0xFF047857)]
                          : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isPro ? AppColors.compliant : const Color(0xFF2563EB))
                            .withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPro ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPro ? s.proActiveTitle : s.freePlanTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isPro
                                  ? (_isTrial
                                      ? '${s.trialActiveTitle} ($_remainingDays d)'
                                      : s.proActiveSubtitle)
                                  : s.freePlanSubtitle,
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      if (!_isPro)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaywallScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            s.upgradeBtn,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. TECHNICIAN & PROFESSIONAL PROFILE
                _buildSectionHeader(s.technicianProfileHeader, Icons.badge_outlined),
                const SizedBox(height: 6),
                Text(
                  s.technicianProfileDesc,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.3),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _technicianNameCtrl,
                        label: s.technicianNameLabel,
                        icon: Icons.person_outline,
                      ),
                      _buildTextField(
                        controller: _companyNameCtrl,
                        label: s.companyNameLabel,
                        icon: Icons.business_outlined,
                      ),
                      _buildTextField(
                        controller: _licenseNumberCtrl,
                        label: s.licenseNumberLabel,
                        icon: Icons.assignment_ind_outlined,
                      ),
                      _buildTextField(
                        controller: _emailCtrl,
                        label: s.emailLabel,
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        controller: _phoneCtrl,
                        label: s.phoneLabel,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        controller: _agencyNameCtrl,
                        label: s.agencyNameLabel,
                        icon: Icons.account_balance_outlined,
                      ),
                      _buildTextField(
                        controller: _addressCtrl,
                        label: s.addressLabel,
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton.icon(
                        key: const Key('btnSaveProfile'),
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: Text(s.saveSettingsBtn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.compliant,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4. APPLICABLE STANDARDS
                _buildSectionHeader(s.technicalStandardsHeader, Icons.bolt_rounded),
                const SizedBox(height: 6),
                Text(
                  s.technicalStandardsDesc,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.3),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _StandardBadge(label: 'NEC (NFPA 70) 2026/2023'),
                    _StandardBadge(label: 'NOM-001-SEDE'),
                    _StandardBadge(label: 'RETIE (Colombia)'),
                    _StandardBadge(label: 'NBR 5410 (Brasil)'),
                    _StandardBadge(label: 'IEC 60364'),
                  ],
                ),

                const SizedBox(height: 24),

                // 5. APPLICATION INFO & LEGAL
                _buildSectionHeader(s.appInfoTitle, Icons.info_outline_rounded),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Versión',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          Text(
                            s.appVersion,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showPrivacyPolicyModal,
                              icon: const Icon(Icons.shield_outlined, size: 16),
                              label: Text(s.privacyPolicyBtn, style: const TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.borderSubtle),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StandardBadge extends StatelessWidget {
  final String label;

  const _StandardBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
