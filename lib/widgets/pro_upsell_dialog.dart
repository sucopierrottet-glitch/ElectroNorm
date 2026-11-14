import 'package:flutter/material.dart';
import '../screens/paywall_screen.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProUpsellDialog extends StatelessWidget {
  final StorageService storageService;
  final int remainingFreeProjects;

  const ProUpsellDialog({
    super.key,
    required this.storageService,
    this.remainingFreeProjects = 3,
  });

  static Future<void> show(
    BuildContext context, {
    StorageService? storageService,
  }) async {
    final storage = storageService ?? StorageService.instance;
    final isPro = await storage.isProSubscriber();
    if (isPro) return;

    final remaining = await storage.getRemainingFreeProjects();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProUpsellDialog(
        storageService: storage,
        remainingFreeProjects: remaining,
      ),
    );
  }

  String _tr(String es, String en, String pt) {
    final lang = storageService.localeCode.toLowerCase();
    if (lang.startsWith('en')) return en;
    if (lang.startsWith('pt')) return pt;
    return es;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = remainingFreeProjects;

    final quotaText = remaining > 0
        ? _tr(
            'Te quedan $remaining de 3 proyectos gratis este mes',
            'You have $remaining of 3 free projects left this month',
            'Você tem $remaining de 3 projetos grátis restantes neste mês',
          )
        : _tr(
            'Has agotado tus 3 proyectos gratis de este mes',
            'You have used your 3 free projects for this month',
            'Você usou seus 3 projetos grátis deste mês',
          );

    return Dialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF334155), width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _tr('ELECTRONORM PRO', 'ELECTRONORM PRO', 'ELECTRONORM PRO'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _tr(
                'Potencia tu ingeniería sin límites',
                'Power up your engineering without limits',
                'Impulsione sua engenharia sem limites',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            // Remaining quota pill
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: remaining > 0
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                        : Colors.orangeAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  quotaText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: remaining > 0
                        ? const Color(0xFF93C5FD)
                        : Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Benefits
            _buildBenefitRow(
              Icons.all_inclusive_rounded,
              const Color(0xFF3B82F6),
              _tr(
                'Proyectos y memorias PDF ilimitadas cada mes',
                'Unlimited projects & PDF compliance reports every month',
                'Projetos e relatórios PDF ilimitados todos os meses',
              ),
            ),
            const SizedBox(height: 10),
            _buildBenefitRow(
              Icons.verified_rounded,
              const Color(0xFF10B981),
              _tr(
                'Datos de tu empresa, licencia y sin marcas de agua',
                'Your company profile, license & no watermarks',
                'Dados da sua empresa, licença e sem marcas d’água',
              ),
            ),
            const SizedBox(height: 10),
            _buildBenefitRow(
              Icons.draw_rounded,
              const Color(0xFF8B5CF6),
              _tr(
                'Firma digital pericial, caída de tensión y derating ${storageService.normativeCountry.shortCode}',
                'Digital inspector signature, voltage drop & ${storageService.normativeCountry.shortCode} derating',
                'Assinatura digital técnica, queda de tensão e derating ${storageService.normativeCountry.shortCode}',
              ),
            ),
            const SizedBox(height: 22),

            // Primary CTA -> Go to Paywall
            ElevatedButton(
              key: const Key('btnUpsellContinuePro'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaywallScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              child: Text(
                _tr(
                  'Continuar a ElectroNorm PRO',
                  'Continue to ElectroNorm PRO',
                  'Continuar para o ElectroNorm PRO',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Secondary CTA -> Dismiss & continue normal use
            TextButton(
              key: const Key('btnUpsellCancelFree'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _tr(
                  'Cancelar y continuar gratis',
                  'Cancel and continue for free',
                  'Cancelar e continuar grátis',
                ),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
