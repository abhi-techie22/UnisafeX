import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('about_unisafex'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 36),
        children: [
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: 42),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'UniSafeX',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 5),
          Text(
            AppConstants.appVersion,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          _AboutSection(
            title: 'our_mission'.tr(),
            text: 'mission_description'.tr(),
          ),
          _AboutSection(
            title: 'app_provides'.tr(),
            text: 'app_provides_description'.tr(),
          ),
          _AboutSection(
            title: 'data_safety'.tr(),
            text: 'data_safety_description'.tr(),
          ),
          _AboutSection(
            title: 'emergency_reminder'.tr(),
            text: 'emergency_reminder_description'.tr(),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Legal notices'),
              subtitle: const Text('Open-source and map attribution'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'UniSafeX',
                applicationVersion: AppConstants.appVersion,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            Text(text, style: const TextStyle(height: 1.55)),
          ],
        ),
      ),
    );
  }
}
