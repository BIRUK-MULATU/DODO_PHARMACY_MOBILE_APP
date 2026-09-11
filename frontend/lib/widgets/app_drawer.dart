import 'dart:ui';

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import 'app_image.dart';
import 'assets.dart';
import 'entrance.dart';
import 'press_scale.dart';

/// Side menu: a frosted, semi-transparent yellow panel on a single sweeping
/// curve, a small avatar, a tight menu list, the celebrating kid and a Log Out
/// pill. No solid backgrounds — the screen shows through.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop(); // close the drawer
    if (route == AppRoutes.track) {
      // "Home" goes back to the first screen after login (the track picker),
      // resetting the stack just like signing in does.
      if (ModalRoute.of(context)?.settings.name != route) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
      }
      return;
    }
    AppRoutes.goToSection(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final size = MediaQuery.of(context).size;
    final items = <_DrawerItem>[
      _DrawerItem(Icons.person, 'Profile', AppRoutes.profile),
      _DrawerItem(Icons.home_rounded, 'Home', AppRoutes.track),
      _DrawerItem(Icons.dashboard_rounded, 'Dashboard', AppRoutes.dashboard),
      _DrawerItem(Icons.menu_book_rounded, 'E-Book', AppRoutes.ebook),
      _DrawerItem(Icons.forum_rounded, 'Q&A', AppRoutes.qa),
      if (state.isAdmin)
        _DrawerItem(
            Icons.admin_panel_settings_rounded, 'Admin panel', AppRoutes.admin),
      _DrawerItem(Icons.info_outline_rounded, 'About', AppRoutes.aboutApp),
    ];

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: size.width * 0.8,
      child: Stack(
        children: [
          // Frosted, translucent yellow panel on a sweeping curve.
          Positioned.fill(
            child: ClipPath(
              clipper: _PanelClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x8CFFDE00),
                        Color(0x66F3C700),
                        Color(0x33CBB400),
                        Color(0x00CBB400),
                      ],
                      stops: [0.0, 0.4, 0.68, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Celebrating kid (transparent PNG) on the lower half.
          Positioned(
            left: 0,
            right: -10,
            bottom: -6,
            child: Image.asset(
              Img.kid,
              height: size.height * 0.4,
              alignment: Alignment.bottomCenter,
              fit: BoxFit.contain,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Entrance(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.ink.withValues(alpha: 0.7),
                            width: 2),
                        image: DecorationImage(
                          image: AppImage.provider(state.profile.avatar),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...staggered(
                    [
                      for (final item in items)
                        _DrawerRow(
                          item: item,
                          onTap: () => _navigate(context, item.route),
                        ),
                    ],
                    start: const Duration(milliseconds: 130),
                    step: const Duration(milliseconds: 65),
                  ),
                  const Spacer(),
                  Entrance(
                    delay: const Duration(milliseconds: 420),
                    child: PressScale(
                      onTap: () {
                        Navigator.of(context).pop();
                        state.logOut();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (_) => false,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: AppColors.ink, size: 20),
                            SizedBox(width: 8),
                            Text('Log Out',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({required this.item, required this.onTap});
  final _DrawerItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.ink, size: 22),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single sweeping curve: the yellow bulges right near the top, then arcs
/// inward and narrows toward the bottom-left.
class _PanelClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.57, 0)
      ..cubicTo(
        w * 0.82, h * 0.10,
        w * 0.80, h * 0.28,
        w * 0.66, h * 0.42,
      )
      ..cubicTo(
        w * 0.54, h * 0.55,
        w * 0.42, h * 0.74,
        w * 0.22, h,
      )
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
