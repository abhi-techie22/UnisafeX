import 'package:flutter/material.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About UniSafeX')),
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
          const _AboutSection(
            title: 'Our mission',
            text: 'UniSafeX helps international travelers explore India with '
                'practical destination details, safety guidance, nearby '
                'discovery and useful travel tools in one place.',
          ),
          const _AboutSection(
            title: 'What the app provides',
            text: 'Tourism discovery, travel planning, destination safety '
                'scores, live reference currency conversion, local phrases, '
                'saved places, location-based distances and booking previews.',
          ),
          const _AboutSection(
            title: 'Data and safety',
            text: 'Tourism information is stored in the UniSafeX database. '
                'Distances are calculated from coordinates. Safety scores and '
                'AI-style answers are guidance only and cannot guarantee '
                'personal safety or replace official advice.',
          ),
          const _AboutSection(
            title: 'Emergency reminder',
            text: 'For emergencies in India call 112. Tourist helpline: 1363. '
                'Always verify opening times, fees and travel conditions with '
                'official sources before visiting.',
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
