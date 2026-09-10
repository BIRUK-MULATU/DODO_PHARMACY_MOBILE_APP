import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../theme/app_colors.dart';
import 'press_scale.dart';

/// Floating frosted tab bar for the top-level sections, in the style of the
/// App Store's bottom bar. Drop it in `Scaffold.bottomNavigationBar` together
/// with `extendBody: true` so content scrolls behind it.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current});

  /// 0 Home · 1 Dashboard · 2 E-Book · 3 Profile
  final int current;

  static const _items = <({IconData icon, String label, String route})>[
    (icon: Icons.home_rounded, label: 'Home', route: AppRoutes.home),
    (
      icon: Icons.insights_rounded,
      label: 'Dashboard',
      route: AppRoutes.dashboard
    ),
    (icon: Icons.menu_book_rounded, label: 'E-Book', route: AppRoutes.ebook),
    (icon: Icons.person_rounded, label: 'Profile', route: AppRoutes.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 14 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.ink.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      item: _items[i],
                      selected: i == current,
                      onTap: () =>
                          AppRoutes.goToSection(context, _items[i].route),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, String label, String route}) item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? AppColors.yellow
        : AppColors.ink.withValues(alpha: 0.55);

    return PressScale(
      onTap: selected ? null : onTap,
      scale: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.ink.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: fg, size: 21),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                height: 1.1,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
