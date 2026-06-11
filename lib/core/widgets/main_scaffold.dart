import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
        label: 'Explore',
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore),
    _NavItem(
        label: 'Booking',
        icon: Icons.luggage_outlined,
        activeIcon: Icons.luggage),
    _NavItem(
      label: 'Nearby',
      icon: Icons.near_me_outlined,
      activeIcon: Icons.near_me,
    ),
    _NavItem(
        label: 'Saved',
        icon: Icons.bookmark_border_outlined,
        activeIcon: Icons.bookmark),
    _NavItem(
        label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  static const List<String> _routes = [
    AppRoutes.home,
    AppRoutes.booking,
    AppRoutes.map,
    AppRoutes.favorites,
    AppRoutes.profile,
  ];

  int _getActiveIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.booking)) return 1;
    for (int i = 0; i < _routes.length; i++) {
      if (location == _routes[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeIndex = _getActiveIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              key: ValueKey(isActive),
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.grey600
                                      : AppColors.grey400),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w400,
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.grey600
                                      : AppColors.grey400),
                            ),
                            child: Text(item.label),
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
