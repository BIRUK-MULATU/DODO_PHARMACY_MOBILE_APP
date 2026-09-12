import 'package:flutter/material.dart';

import '../../app/routes.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'package:dodomed_core/widgets/app_image.dart';
import 'admin_scaffold.dart';

/// The admin "Users" page — every real account, with enough of a summary to
/// spot who's active at a glance. Tap a user to see their full activity
/// (dated) and directly open/close their access to any pack or book.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AdminUserSummary>? _users;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = AppStateScope.read(context);
    if (!state.isOnline) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await state.fetchAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final users = _users;

    return AdminScaffold(
      title: users != null ? 'Users (${users.length})' : 'Users',
      onBack: () => Navigator.of(context).maybePop(),
      body: !state.isOnline
          ? _Notice(
              icon: Icons.cloud_off_rounded,
              text: 'User accounts only exist with the backend connected — '
                  'sign in online to manage them.',
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _Notice(
                      icon: Icons.error_outline_rounded,
                      text: "Couldn't load users. Pull down to try again.",
                      onRetry: _load,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: users!.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(32),
                              children: const [
                                Center(child: Text('No accounts yet.')),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                              itemCount: users.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _UserCard(
                                user: users[i],
                                onTap: () async {
                                  await Navigator.of(context).pushNamed(
                                    AppRoutes.adminUserDetail,
                                    arguments: users[i],
                                  );
                                  if (mounted) _load();
                                },
                              ),
                            ),
                    ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});
  final AdminUserSummary user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final joined = _formatDate(user.createdAt);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.ink,
                backgroundImage: AppImage.provider(user.avatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                        if (user.isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('ADMIN',
                                style: TextStyle(
                                    color: AppColors.yellow,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black.withValues(alpha: 0.55))),
                    const SizedBox(height: 4),
                    Text('Joined $joined · ${user.totalAnswered} answered · '
                        '${user.unlockedPacks.length} unlocked',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.black45),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
