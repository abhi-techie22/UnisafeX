import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';

class TravelToolkitScreen extends StatelessWidget {
  const TravelToolkitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      (
        'Smart Trip Planner',
        'Build a practical multi-day city itinerary.',
        Icons.route_rounded,
        AppRoutes.tripPlanner
      ),
      (
        'Currency Helper',
        'Quick USD, EUR, and GBP estimates in INR.',
        Icons.currency_exchange,
        AppRoutes.currencyHelper
      ),
      (
        'Local Phrase Book',
        'Essential English to Hindi travel phrases.',
        Icons.translate_rounded,
        AppRoutes.phraseBook
      ),
      (
        'AI Travel Assistant',
        'Preview the next generation of trip guidance.',
        Icons.auto_awesome,
        AppRoutes.aiAssistant
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Travel Toolkit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.travel_explore, color: Colors.white, size: 34),
                SizedBox(height: 14),
                Text(
                  'Everything you need for India',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Plan confidently, understand local essentials, and keep '
                  'important travel tools close at hand.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ...tools.map(
            (tool) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(tool.$3, color: AppColors.primary),
                ),
                title: Text(tool.$1),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(tool.$2),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => context.push(tool.$4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
