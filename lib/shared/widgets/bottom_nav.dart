import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNav({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/community')) return 2;
    if (location.startsWith('/more') ||
        location.startsWith('/profile') ||
        location.startsWith('/notifications') ||
        location.startsWith('/leaderboard') ||
        location.startsWith('/settings')) {
      return 3;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.history);
      case 2:
        context.go(AppRoutes.community);
      case 3:
        context.go(AppRoutes.more);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.emeraldDeep,
      body: child,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _selectedIndex(context),
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  static const _items = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(
      Icons.calendar_today_outlined,
      Icons.calendar_today,
      'History',
    ),
    _NavItem(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Community'),
    _NavItem(Icons.menu, Icons.menu_open, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emeraldDeep.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.h,
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = currentIndex == i;
              final item = _items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        color: selected ? AppColors.gold : AppColors.textMuted,
                        size: 22.r,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.label,
                        style: AppTextStyles.bodySmall(context).copyWith(
                          fontSize: 10.sp,
                          color: selected
                              ? AppColors.gold
                              : AppColors.textMuted,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
