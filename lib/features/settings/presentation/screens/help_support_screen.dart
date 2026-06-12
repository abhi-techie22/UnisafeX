import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('help_support'.tr())),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 34),
                const SizedBox(height: 18),
                Text(
                  'help_question'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'help_description'.tr(),
                  style: const TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('quick_help'.tr(),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          _SupportAction(
            icon: Icons.bug_report_outlined,
            title: 'report_problem'.tr(),
            subtitle: 'report_problem_subtitle'.tr(),
            onTap: () => _launch(
              context,
              Uri.parse(
                'https://github.com/abhi-techie22/UnisafeX/issues',
              ),
            ),
          ),
          _SupportAction(
            icon: Icons.phone_in_talk_outlined,
            title: 'tourist_helpline'.tr(),
            subtitle: 'tourist_helpline_subtitle'.tr(),
            onTap: () => _launch(context, Uri(scheme: 'tel', path: '1363')),
          ),
          _SupportAction(
            icon: Icons.emergency_outlined,
            title: 'emergency_assistance'.tr(),
            subtitle: 'emergency_assistance_subtitle'.tr(),
            onTap: () => _launch(context, Uri(scheme: 'tel', path: '112')),
          ),
          const SizedBox(height: 20),
          Text(
            'frequently_asked_questions'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _Faq(
            question: 'faq_profile_question'.tr(),
            answer: 'faq_profile_answer'.tr(),
          ),
          _Faq(
            question: 'faq_distance_question'.tr(),
            answer: 'faq_distance_answer'.tr(),
          ),
          _Faq(
            question: 'faq_currency_question'.tr(),
            answer: 'faq_currency_answer'.tr(),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('action_unavailable'.tr())),
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
