import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/admin/data/admin_remote_config_repository.dart';
import 'package:unisafex/features/auth/presentation/providers/auth_provider.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
        label: 'explore',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore),
    _NavItem(
      label: 'nearby',
      icon: Icons.near_me_outlined,
      activeIcon: Icons.near_me,
    ),
    _NavItem(
        label: 'saved',
        icon: Icons.bookmark_border_outlined,
        activeIcon: Icons.bookmark),
    _NavItem(
      label: 'guide_request',
      icon: Icons.support_agent_outlined,
      activeIcon: Icons.support_agent,
    ),
    _NavItem(
        label: 'profile', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  static const List<String> _routes = [
    AppRoutes.home,
    AppRoutes.map,
    AppRoutes.favorites,
    AppRoutes.guideRequest,
    AppRoutes.profile,
  ];

  int _getActiveIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _routes.length; i++) {
      if (location == _routes[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = _getActiveIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final supportAttention = user == null
        ? false
        : (ref.watch(supportNeedsAttentionProvider).valueOrNull ?? false);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isActive = activeIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(_routes[index]),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Stack(
                              key: ValueKey('$isActive-$supportAttention'),
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  isActive ? item.activeIcon : item.icon,
                                  color: isActive
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.grey600
                                          : AppColors.grey400),
                                  size: 23,
                                ),
                                if (index == 4 && supportAttention)
                                  Positioned(
                                    right: -5,
                                    top: -5,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.cardDark
                                              : AppColors.cardLight,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.grey600
                                      : AppColors.grey400),
                            ),
                            child: Text(item.label.tr()),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
