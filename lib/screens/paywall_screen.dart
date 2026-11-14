import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/billing_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

enum PaywallTier { annual, monthly }

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PaywallTier _selectedTier = PaywallTier.monthly;
  bool _isPro = false;
  bool _isLoading = true;
  bool _hasPromptedRescue = false;
  bool _hasHandledSuccess = false;

  late final BillingService _billingService;

  // 5-tap secret demo toggle tracking
  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _billingService = BillingService(storageService: StorageService.instance);
    _billingService.addListener(_onBillingChanged);
    _billingService.init();
    _loadSubscriberStatus();
  }

  @override
  void dispose() {
    _billingService.removeListener(_onBillingChanged);
    _billingService.dispose();
    super.dispose();
  }

  String _tr(String es, String en, String pt) {
    final lang = StorageService.instance.localeCode.toLowerCase();
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  void _onBillingChanged() {
    if (!mounted) return;

    if (_billingService.purchaseSucceeded && !_hasHandledSuccess) {
      _hasHandledSuccess = true;
      _isPro = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.compliant,
          content: Text(
            _tr(
              '¡Bienvenido a ElectroNorm PRO! Plan activado con éxito.',
              'Welcome to ElectroNorm Pro! Plan activated successfully.',
              'Bem-vindo ao ElectroNorm PRO! Plano ativado com sucesso.',
            ),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    if (_billingService.lastError != null && !_billingService.isPurchasePending) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_billingService.lastError!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {});
  }

  Future<void> _loadSubscriberStatus() async {
    final pro = await StorageService.instance.isProSubscriber();
    if (mounted) {
      setState(() {
        _isPro = pro;
        _isLoading = false;
      });
    }
  }

  void _handleSecretTap() async {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!).inMilliseconds > 2000) {
      _secretTapCount = 1;
    } else {
      _secretTapCount++;
    }
    _lastTapTime = now;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      final newPro = !_isPro;
      await StorageService.instance.setProSubscriber(newPro);
      await StorageService.instance.setDemoMode(newPro);
      if (mounted) {
        setState(() {
          _isPro = newPro;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newPro ? AppColors.compliant : AppColors.surfaceElevated,
            content: Text(
              'Secret Demo Mode: Pro Status ${newPro ? "ENABLED (Full Access)" : "RESET (Free Tier)"}',
              style: TextStyle(
                color: newPro ? Colors.black : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _subscribe() async {
    final errorCode = await _billingService.buySubscription(
      isYearly: _selectedTier == PaywallTier.annual,
    );

    if (!mounted || errorCode == null) return;

    String message;
    if (errorCode == 'store_unavailable') {
      message = _tr(
        'Google Play Store no está disponible en este dispositivo.',
        'Google Play Store is not available on this device.',
        'A Google Play Store não está disponível neste dispositivo.',
      );
    } else if (errorCode == 'product_not_found') {
      message = _tr(
        'La suscripción aún se está sincronizando con Google Play. Intenta nuevamente en unos minutos.',
        'Subscription is still syncing with Google Play. Please try again in a few minutes.',
        'A assinatura ainda está sincronizando com o Google Play. Tente novamente em alguns minutos.',
      );
    } else {
      message = _tr(
        'No se pudo iniciar el proceso de compra en Google Play.',
        'Could not start the purchase flow on Google Play.',
        'Não foi possível iniciar o processo de compra no Google Play.',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restorePurchases() async {
    final errorCode = await _billingService.restorePurchases();
    if (!mounted) return;

    if (errorCode != null) {
      final pro = await StorageService.instance.isProSubscriber();
      if (!mounted) return;
      if (pro) {
        setState(() => _isPro = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.compliant,
            content: Text(
              'Pro subscription restored successfully!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              _tr(
                'No se encontraron suscripciones activas asociadas a tu cuenta de Google Play.',
                'No active subscription found for this account.',
                'Nenhuma assinatura ativa encontrada para sua conta do Google Play.',
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted || _hasHandledSuccess) return;
      final pro = await StorageService.instance.isProSubscriber();
      if (!mounted) return;
      if (!pro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              _tr(
                'No se encontraron suscripciones activas asociadas a tu cuenta de Google Play.',
                'No active subscription found for this account.',
                'Nenhuma assinatura ativa encontrada para sua conta do Google Play.',
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<bool> _handlePopAttempt() async {
    final hasAnyTrial = _billingService.hasFreeTrialOffer(isYearly: false) ||
        _billingService.hasFreeTrialOffer(isYearly: true);
    if (_isPro || _hasPromptedRescue || !hasAnyTrial) {
      return true;
    }
    _hasPromptedRescue = true;
    final claimTrial = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const Key('dialogRescue'),
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.caution, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.stars, color: AppColors.caution, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _tr(
                  '¡Espera! Desbloquea 7 Días Gratis',
                  'Wait! Unlock 7 Days Free',
                  'Espere! Libere 7 Dias Grátis',
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _tr(
            'Prueba ElectroNorm Pro gratis por 7 días sin compromiso. Genera memorias técnicas firmadas listas para verificación en obra.',
            'Don\'t leave empty-handed. Try ElectroNorm Pro free for 7 days with zero commitment. Generate inspection-ready signed technical compliance reports on your job site.',
            'Experimente o ElectroNorm Pro grátis por 7 dias sem compromisso. Gere relatórios técnicos assinados em campo.',
          ),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            key: const Key('btnRescueDismiss'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _tr('Seguir con Versión Gratis', 'Continue with Free Version',
                  'Continuar Grátis'),
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            key: const Key('btnRescueClaimTrial'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.compliant,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              _tr('Activar 7 Días Gratis', 'Claim 7-Day Free Trial', 'Testar 7 Dias Grátis'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (claimTrial == true) {
      if (StorageService.isTestEnvironment) {
        await StorageService.instance.startTrial();
        await StorageService.instance.setSubscriptionTier('monthly');
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return false;
      }
      setState(() => _selectedTier = PaywallTier.monthly);
      await _subscribe();
      return false;
    }
    return true;
  }

  void _openPrivacyPolicy() async {
    const url = 'https://sucopierrottet-glitch.github.io/electronorm-privacy/';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final monthlyProduct = _billingService.monthlyProduct;
    final yearlyProduct = _billingService.yearlyProduct;
    final isBusy = _billingService.isPurchasePending;
    final country = StorageService.instance.normativeCountry;

    final annualPriceText = yearlyProduct != null
        ? '${yearlyProduct.price}/${_tr("año", "yr", "ano")}'
        : (StorageService.isTestEnvironment ? '\$69.00/yr' : _tr('Consultar precio', 'Check price', 'Consultar preço'));
    final monthlyPriceText = monthlyProduct != null
        ? '${monthlyProduct.price}/${_tr("mes", "mo", "mês")}'
        : (StorageService.isTestEnvironment ? '\$8.99/mo' : _tr('Consultar precio', 'Check price', 'Consultar preço'));
    final annualPeriodDetail = yearlyProduct != null
        ? _tr('Facturado anualmente • Cancela cuando quieras', 'Billed annually • Cancel anytime', 'Cobrado anualmente • Cancele quando quiser')
        : (StorageService.isTestEnvironment ? '\$5.75/month • Billed annually' : _tr('Facturado anualmente', 'Billed annually', 'Cobrado anualmente'));
    final selectedProduct =
        _selectedTier == PaywallTier.annual ? yearlyProduct : monthlyProduct;
    final selectedPriceText =
        _selectedTier == PaywallTier.annual ? annualPriceText : monthlyPriceText;
    final hasSelectedPrice =
        selectedProduct != null || StorageService.isTestEnvironment;
    final hasAnnualTrial = _billingService.hasFreeTrialOffer(isYearly: true);
    final hasMonthlyTrial = _billingService.hasFreeTrialOffer(isYearly: false);
    final selectedHasTrial =
        _selectedTier == PaywallTier.annual ? hasAnnualTrial : hasMonthlyTrial;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handlePopAttempt();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () async {
              final shouldPop = await _handlePopAttempt();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop(false);
              }
            },
          ),
          actions: [
            TextButton(
              key: const Key('btnRestorePaywall'),
              onPressed: isBusy ? null : _restorePurchases,
              child: Text(
                _tr('Restaurar', 'Restore', 'Restaurar'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.compliant))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header & 5-tap Demo Trigger
                      GestureDetector(
                        key: const Key('btnSecretDemoToggle'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _handleSecretTap,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.caution.withValues(alpha: 0.15),
                                border: Border.all(color: AppColors.caution, width: 2),
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                color: AppColors.caution,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'ElectroNorm Pro',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isPro
                                  ? _tr(
                                      'MIEMBRO PRO (ACCESO ILIMITADO ACTIVO)',
                                      'PRO MEMBER (UNLIMITED ACCESS ACTIVE)',
                                      'MEMBRO PRO (ACESSO ILIMITADO ATIVO)',
                                    )
                                  : _tr(
                                      'Cálculos Eléctricos y Dictámenes ${country.codeBadge}',
                                      'Professional Electrical Calculations & ${country.inspectionAuthorityShort} Reports',
                                      'Cálculos Elétricos e Relatórios Técnicos',
                                    ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: _isPro ? AppColors.compliant : AppColors.textSecondary,
                                fontWeight: _isPro ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Feature Highlights
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            _buildFeatureRow(
                              Icons.all_inclusive,
                              _tr('Proyectos Guardados Ilimitados', 'Unlimited Project Saves',
                                  'Projetos Salvos Ilimitados'),
                              _tr(
                                'Guarda todos tus tramos y cédulas sin conexión en el dispositivo',
                                'Store infinite conduit runs & schedules locally on device',
                                'Armazene infinitos cálculos localmente',
                              ),
                            ),
                            const Divider(color: AppColors.borderSubtle, height: 20),
                            _buildFeatureRow(
                              Icons.draw_outlined,
                              _tr('Memorias PDF Firmadas (${country.shortCode})',
                                  'Signed Technical PDF Reports',
                                  'Relatórios PDF Assinados'),
                              _tr(
                                'Exporta memorias de cumplimiento con firma digital de verificación',
                                'Export formal compliance reports with digital inspector sign-off',
                                'Exporte relatórios formais com assinatura digital',
                              ),
                            ),
                            const Divider(color: AppColors.borderSubtle, height: 20),
                            _buildFeatureRow(
                              Icons.bolt,
                              _tr('Caída de Tensión y Derating Térmico',
                                  'Voltage Drop & Thermal Derating',
                                  'Queda de Tensão e Fator Térmico'),
                              _tr(
                                'Matriz de impedancia completa y factores por temperatura ambiente',
                                'Full impedance matrix & ambient temperature correction factors',
                                'Matriz de impedância e fatores de temperatura',
                              ),
                            ),
                            const Divider(color: AppColors.borderSubtle, height: 20),
                            _buildFeatureRow(
                              Icons.wifi_off,
                              _tr('100% Confiable Sin Internet', '100% Offline Reliability',
                                  '100% Confiável Offline'),
                              _tr(
                                'Sin dependencia de la nube, sin rastreo, sin anuncios en obra',
                                'Zero cloud dependencies, zero tracking, zero ads in mechanical rooms',
                                'Sem nuvem, sem rastreamento, sem anúncios',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pricing Tiers
                      _buildTierCard(
                        key: const Key('cardTierAnnual'),
                        tier: PaywallTier.annual,
                        title: _tr('Pase Anual', 'Annual Pass', 'Passe Anual'),
                        price: annualPriceText,
                        periodDetail: annualPeriodDetail,
                        badgeText: hasAnnualTrial
                            ? _tr('7 DÍAS GRATIS', '7-DAY FREE TRIAL', '7 DIAS GRÁTIS')
                            : null,
                        savingsText:
                            _tr('MEJOR VALOR • AHORRA 36%', 'BEST VALUE • SAVE 36%', 'ECONOMIZE 36%'),
                        isRecommended: true,
                      ),

                      const SizedBox(height: 12),

                      _buildTierCard(
                        key: const Key('cardTierMonthly'),
                        tier: PaywallTier.monthly,
                        title: _tr('Suscripción Mensual', 'Monthly Subscription',
                            'Assinatura Mensal'),
                        price: monthlyPriceText,
                        periodDetail: _tr(
                          'Cobro mensual flexible • Cancela cuando quieras',
                          'Flexible monthly billing • Cancel anytime',
                          'Cobrança mensal • Cancele quando quiser',
                        ),
                        badgeText: hasMonthlyTrial
                            ? _tr('7 DÍAS GRATIS', '7-DAY FREE TRIAL', '7 DIAS GRÁTIS')
                            : null,
                        savingsText: null,
                        isRecommended: false,
                      ),

                      const SizedBox(height: 24),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          key: const Key('btnSubscribePaywall'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.compliant,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: isBusy ? null : _subscribe,
                          child: isBusy
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  selectedHasTrial
                                      ? _tr('Iniciar Prueba Gratis 7 Días',
                                          'Start 7-Day Free Trial', 'Iniciar 7 Dias Grátis')
                                      : (hasSelectedPrice
                                          ? '${_tr("Suscribirse", "Subscribe Now", "Assinar")} — $selectedPriceText'
                                          : _tr('Suscribirse Ahora', 'Subscribe Now', 'Assinar Agora')),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        selectedHasTrial
                            ? (hasSelectedPrice
                                ? _tr(
                                    '7 días gratis, luego $selectedPriceText. Cancela en cualquier momento en Google Play.',
                                    '7 days free, then $selectedPriceText. Cancel anytime in Google Play.',
                                    '7 dias grátis, depois $selectedPriceText. Cancele no Google Play.',
                                  )
                                : _tr(
                                    '7 días gratis, luego tarifa estándar. Cancela cuando quieras en Google Play.',
                                    '7 days free, then standard plan rate. Cancel anytime in Google Play.',
                                    '7 dias grátis, depois tarifa padrão. Cancele no Google Play.',
                                  ))
                            : (hasSelectedPrice
                                ? _tr(
                                    'Cobro recurrente ($selectedPriceText). Cancela en cualquier momento en Google Play.',
                                    'Recurring billing ($selectedPriceText). Cancel anytime in Google Play.',
                                    'Cobrança recorrente ($selectedPriceText). Cancele no Google Play.',
                                  )
                                : _tr(
                                    'Cobro recurrente. Cancela en cualquier momento en Google Play.',
                                    'Recurring billing. Cancel anytime in Google Play.',
                                    'Cobrança recorrente. Cancele no Google Play.',
                                  )),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),

                      const SizedBox(height: 20),

                      // Legal Footer
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          GestureDetector(
                            onTap: _openPrivacyPolicy,
                            child: Text(
                              _tr('Política de Privacidad', 'Privacy Policy',
                                  'Política de Privacidade'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text('•', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                          GestureDetector(
                            onTap: _openPrivacyPolicy,
                            child: Text(
                              _tr('Términos de Servicio', 'Terms of Service', 'Termos de Serviço'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.compliant.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.compliant, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required Key key,
    required PaywallTier tier,
    required String title,
    required String price,
    required String periodDetail,
    required String? badgeText,
    required String? savingsText,
    required bool isRecommended,
  }) {
    final isSelected = _selectedTier == tier;

    return InkWell(
      key: key,
      onTap: () => setState(() => _selectedTier = tier),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.compliant
                : (isRecommended ? AppColors.caution.withValues(alpha: 0.5) : AppColors.borderSubtle),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.compliant.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.compliant, width: 1),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.compliant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    periodDetail,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                if (savingsText != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      savingsText,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.caution,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
