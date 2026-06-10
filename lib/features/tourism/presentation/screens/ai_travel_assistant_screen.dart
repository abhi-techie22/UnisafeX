import 'package:flutter/material.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class AiTravelAssistantScreen extends StatelessWidget {
  const AiTravelAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'What should I visit in Delhi in 2 days?',
      'Which places are safe at night?',
      'What is the best time to visit Jaipur?',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('AI Travel Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Travel Assistant coming soon',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Personalized, safety-aware India travel guidance is being '
              'prepared. No paid AI service is connected yet.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ...prompts.map(
              (prompt) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(prompt)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
