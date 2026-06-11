import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 34),
                SizedBox(height: 18),
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Find answers, contact support, or access India’s emergency '
                  'and tourist helplines.',
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Quick help', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _SupportAction(
            icon: Icons.bug_report_outlined,
            title: 'Report a problem',
            subtitle: 'Open the UniSafeX GitHub issue tracker',
            onTap: () => _launch(
              context,
              Uri.parse(
                'https://github.com/abhi-techie22/UnisafeX/issues',
              ),
            ),
          ),
          _SupportAction(
            icon: Icons.phone_in_talk_outlined,
            title: 'Tourist helpline',
            subtitle: 'Call 1363 within India',
            onTap: () => _launch(context, Uri(scheme: 'tel', path: '1363')),
          ),
          _SupportAction(
            icon: Icons.emergency_outlined,
            title: 'Emergency assistance',
            subtitle: 'Call India emergency number 112',
            onTap: () => _launch(context, Uri(scheme: 'tel', path: '112')),
          ),
          const SizedBox(height: 20),
          Text(
            'Frequently asked questions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const _Faq(
            question: 'Why is my profile not saving?',
            answer:
                'Confirm your email and sign in first. Profile updates require '
                'an active Supabase session. Keep the app open until the saved '
                'confirmation appears.',
          ),
          const _Faq(
            question: 'How are nearby distances calculated?',
            answer:
                'UniSafeX calculates straight-line distance from your live GPS '
                'or chosen starting location to each destination coordinate.',
          ),
          const _Faq(
            question: 'Are currency rates exact?',
            answer: 'Rates are reference values. Your bank, card or exchange '
                'counter may apply a different rate and additional fees.',
          ),
          const _Faq(
            question: 'Can I book hotels and flights now?',
            answer:
                'Booking search forms are available, but live inventory and '
                'checkout require approved partner API integrations.',
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This action is not available here.')),
      );
    }
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
        onTap: onTap,
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(question),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(answer, style: const TextStyle(height: 1.5))],
      ),
    );
  }
}
