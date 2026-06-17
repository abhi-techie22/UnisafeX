import 'package:easy_localization/easy_localization.dart';
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
        'smart_trip_planner'.tr(),
        'trip_planner_description'.tr(),
        Icons.route_rounded,
        AppRoutes.tripPlanner
      ),
      (
        'currency_helper'.tr(),
        'currency_description'.tr(),
        Icons.currency_exchange,
        AppRoutes.currencyHelper
      ),
      (
        'local_phrase_book'.tr(),
        'phrase_book_description'.tr(),
        Icons.translate_rounded,
        AppRoutes.phraseBook
      ),
      (
        'ai_travel_assistant'.tr(),
        'ai_description'.tr(),
        Icons.auto_awesome,
        AppRoutes.aiAssistant
      ),
      (
        'All destinations',
        'Browse monuments and tourist places by category, city and rating',
        Icons.account_balance_rounded,
        '${AppRoutes.placesList}?title=All Destinations'
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('travel_toolkit'.tr())),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.travel_explore, color: Colors.white, size: 34),
                const SizedBox(height: 14),
                Text(
                  'toolkit_hero_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'toolkit_hero_description'.tr(),
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ...tools.map(
            (tool) => _ToolkitCard(
              title: tool.$1,
              description: tool.$2,
              icon: tool.$3,
              onTap: () => context.push(tool.$4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolkitCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolkitCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
