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
        'heritage_catalog'.tr(),
        'heritage_catalog_description'.tr(),
        Icons.account_balance_rounded,
        AppRoutes.heritageCatalog
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
