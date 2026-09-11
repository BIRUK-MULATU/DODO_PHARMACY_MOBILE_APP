import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Shared chrome for the admin screens: a dark bar with a yellow title and an
/// optional action, over a light surface.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.onBack,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2E7),
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.yellow,
        elevation: 0,
        leading: onBack == null
            ? null
            : IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left, size: 30),
              ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.yellow,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: actions,
      ),
      body: body,
    );
  }
}

/// A labelled card used on the admin dashboard.
class AdminTile extends StatelessWidget {
  const AdminTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.yellow, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              if (badge != null && badge! > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.wrong,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
