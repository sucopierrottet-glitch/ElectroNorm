import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

enum PaywallTier { annual, monthly }

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PaywallTier _selectedTier = PaywallTier.annual;
  bool _isPro = false;
  bool _isLoading = true;
  bool _hasPromptedRescue = false;

  // 5-tap secret demo toggle tracking
  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadSubscriberStatus();
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
    setState(() => _isLoading = true);
    if (_selectedTier == PaywallTier.annual) {
      await StorageService.instance.startTrial();
      await StorageService.instance.setSubscriptionTier('annual');
    } else {
      await StorageService.instance.setProSubscriber(true);
      await StorageService.instance.setSubscriptionTier('monthly');
    }
    if (mounted) {
      setState(() {
        _isPro = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.compliant,
          content: Text(
            _selectedTier == PaywallTier.annual
                ? '14-Day Free Trial Activated! Welcome to ElectroNorm Pro.'
                : 'Subscribed to ElectroNorm Pro Monthly!',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    final pro = await StorageService.instance.isProSubscriber();
    if (mounted) {
      setState(() {
        _isPro = pro;
        _isLoading = false;
      });
      if (pro) {
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
          const SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              'No active subscription found for this account.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> _handlePopAttempt() async {
    if (_isPro || _hasPromptedRescue) {
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
        title: const Row(
          children: [
            Icon(Icons.stars, color: AppColors.caution, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Wait! Unlock 14 Days Free',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Don\'t leave empty-handed. Try ElectroNorm Pro free for 14 days with zero commitment. Generate inspection-ready signed technical compliance reports on your job site.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            key: const Key('btnRescueDismiss'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Continue with Free Version',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            key: const Key('btnRescueClaimTrial'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.compliant,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Claim 14-Day Free Trial',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (claimTrial == true) {
      await StorageService.instance.startTrial();
      await StorageService.instance.setSubscriptionTier('annual');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return false;
    }
    return true;
  }

  void _openPrivacyPolicy() async {
    const url = 'https://sucopierrottet-glitch.github.io/ElectroNorm/privacy_policy.html';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _restorePurchases,
              child: const Text(
                'Restore',
                style: TextStyle(
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
                                  ? 'PRO MEMBER (UNLIMITED ACCESS ACTIVE)'
                                  : 'Professional Electrical Calculations & AHJ Reports',
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
                              'Unlimited Project Saves',
                              'Store infinite conduit runs & schedules locally on device',
                            ),
                            const Divider(color: AppColors.borderSubtle, height: 20),
                            _buildFeatureRow(
                              Icons.draw_outlined,
                              'Signed Technical PDF Reports',
                              'Export formal compliance reports with digital inspector sign-off',
                            ),
                            const Divider(color: AppColors.borderSubtle, height: 20),
                            _buildFeatureRow(
                              Icons.bolt,
                              'Voltage Drop & Thermal Derating',
                              'Full impedance matrix & ambient temperature correction factors',
                            ),
                            const Divider(color: AppColors.borderSubtle, height: 20),
                            _buildFeatureRow(
                              Icons.wifi_off,
                              '100% Offline Reliability',
                              'Zero cloud dependencies, zero tracking, zero ads in mechanical rooms',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pricing Tiers
                      // Tier 2: Annual Plan ($69.00/yr with 14-Day Free Trial)
                      _buildTierCard(
                        key: const Key('cardTierAnnual'),
                        tier: PaywallTier.annual,
                        title: 'Annual Pass',
                        price: '\$69.00/yr',
                        periodDetail: '\$5.75/month • Billed annually',
                        badgeText: '14-DAY FREE TRIAL',
                        savingsText: 'BEST VALUE • SAVE 36%',
                        isRecommended: true,
                      ),

                      const SizedBox(height: 12),

                      // Tier 1: Monthly Plan ($8.99/mo)
                      _buildTierCard(
                        key: const Key('cardTierMonthly'),
                        tier: PaywallTier.monthly,
                        title: 'Monthly Subscription',
                        price: '\$8.99/mo',
                        periodDetail: 'Flexible monthly billing • Cancel anytime',
                        badgeText: null,
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
                          onPressed: _subscribe,
                          child: Text(
                            _selectedTier == PaywallTier.annual
                                ? 'Start 14-Day Free Trial'
                                : 'Subscribe Now — \$8.99/mo',
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
                        _selectedTier == PaywallTier.annual
                            ? '14 days free, then \$69.00/year. Cancel anytime in Google Play.'
                            : 'Recurring billing. Cancel anytime in Google Play.',
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
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text('•', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                          GestureDetector(
                            onTap: _openPrivacyPolicy,
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(
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
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                if (savingsText != null)
                  Text(
                    savingsText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.caution,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
