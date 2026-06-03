import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unisafex/core/constants/app_constants.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/settings/presentation/screens/locale_provider.dart';

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
    (ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppConstants.cacheKeyTheme);
    if (value == 'light') state = ThemeMode.light;
    else if (value == 'dark') state = ThemeMode.dark;
    else state = ThemeMode.system;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cacheKeyTheme, mode.name);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('settings'.tr()),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'appearance'.tr()),

          _SettingTile(
            icon: Icons.palette_outlined,
            title: 'choose_theme'.tr(),
            subtitle: themeMode == ThemeMode.system
                ? 'system_default'.tr()
                : themeMode == ThemeMode.light
                    ? 'light_mode'.tr()
                    : 'dark_mode'.tr(),
            onTap: () => _showThemeSheet(context, ref, themeMode),
          ),

          _SectionHeader(title: 'language'.tr()),

          _SettingTile(
            icon: Icons.language_outlined,
            title: 'choose_language'.tr(),
            subtitle: currentLocale.languageCode.toUpperCase(),
            onTap: () => _showLanguageSheet(context, ref, currentLocale),
          ),

          _SectionHeader(title: 'notifications'.tr()),

          _SettingTile(
            icon: Icons.notifications_outlined,
            title: 'notifications'.tr(),
            trailing: Switch.adaptive(
              value: true,
              onChanged: (_) {},
              activeColor: AppColors.primary,
            ),
          ),

          _SectionHeader(title: 'app_version'.tr()),

          _SettingTile(
            icon: Icons.info_outline_rounded,
            title: 'app_version'.tr(),
            subtitle: AppConstants.appVersion,
          ),

          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            title: 'privacy_policy'.tr(),
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.description_outlined,
            title: 'terms_of_service'.tr(),
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.help_outline_rounded,
            title: 'help_support'.tr(),
            onTap: () {},
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showThemeSheet(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.grey700 : AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('choose_theme'.tr(),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            ...ThemeMode.values.map((mode) {
              final label = mode == ThemeMode.system
                  ? 'system_default'.tr()
                  : mode == ThemeMode.light
                      ? 'light_mode'.tr()
                      : 'dark_mode'.tr();
              final icon = mode == ThemeMode.system
                  ? Icons.brightness_auto_rounded
                  : mode == ThemeMode.light
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined;

              return ListTile(
                leading: Icon(icon,
                    color: current == mode ? AppColors.primary : null),
                title: Text(label),
                trailing: current == mode
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setMode(mode);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(
      BuildContext context, WidgetRef ref, Locale currentLocale) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langs = [
      {'code': 'en', 'name': 'English'},
      {'code': 'hi', 'name': 'हिन्दी (Hindi)'},
      {'code': 'fr', 'name': 'Français (French)'},
      {'code': 'de', 'name': 'Deutsch (German)'},
      {'code': 'es', 'name': 'Español (Spanish)'},
      {'code': 'zh', 'name': '中文 (Chinese)'},
      {'code': 'ja', 'name': '日本語 (Japanese)'},
      {'code': 'ko', 'name': '한국어 (Korean)'},
      {'code': 'ar', 'name': 'العربية (Arabic)'},
      {'code': 'ru', 'name': 'Русский (Russian)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.grey700 : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('choose_language'.tr(),
                  style: Theme.of(sheetContext).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: langs.length,
                  itemBuilder: (_, i) {
                    final lang = langs[i];
                    final isCurrent =
                        currentLocale.languageCode == lang['code'];
                    return ListTile(
                      title: Text(lang['name']!),
                      trailing: isCurrent
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(lang['code']!));
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppColors.grey500,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? AppColors.grey600 : AppColors.grey400)
              : null),
      onTap: onTap,
    );
  }
}