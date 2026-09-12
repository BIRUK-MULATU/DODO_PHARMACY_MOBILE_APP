import 'package:flutter/material.dart';

import 'package:dodomed_core/data/api_client.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'package:dodomed_core/widgets/app_image.dart';
import 'package:dodomed_core/screens/ebook_reader_screen.dart';
import 'admin_scaffold.dart';

/// One user's full detail: profile, real activity (dated), and direct
/// open/close control over every pack and book — independent of whatever a
/// specific payment request says, so admin can grant access outright or
/// correct a mistake without needing a receipt on file.
class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.user});
  final AdminUserSummary user;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  AdminUserActivity? _activity;
  bool _loading = true;
  Set<String> _unlocked = {};
  final Set<String> _pending = {};
  late bool _isAdmin = widget.user.isAdmin;
  bool _roleBusy = false;

  @override
  void initState() {
    super.initState();
    _unlocked = widget.user.unlockedPacks.toSet();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final activity =
          await AppStateScope.read(context).fetchUserActivity(widget.user.id);
      if (!mounted) return;
      setState(() {
        _activity = activity;
        _unlocked = activity.user.unlockedPacks.toSet();
        _isAdmin = activity.user.isAdmin;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isSelf =>
      widget.user.email.toLowerCase() ==
      AppStateScope.read(context).profile.email.toLowerCase();

  Future<void> _setRole(bool makeAdmin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(makeAdmin ? 'Make this user an admin?' : 'Remove admin access?'),
        content: Text(makeAdmin
            ? '${widget.user.name} will be able to manage tracks, packs, '
                'questions, payments, users, and Q&A — everything an admin can do.'
            : '${widget.user.name} will lose access to the admin panel and '
                'go back to being a regular learner.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(makeAdmin ? 'Make admin' : 'Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _roleBusy = true);
    try {
      final updated = await AppStateScope.read(context)
          .setUserRole(userId: widget.user.id, makeAdmin: makeAdmin);
      if (!mounted) return;
      setState(() {
        _isAdmin = updated.isAdmin;
        _roleBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _roleBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : "Couldn't update admin access.")),
      );
    }
  }

  Future<void> _toggle(String packId, bool unlock) async {
    setState(() {
      _pending.add(packId);
      if (unlock) {
        _unlocked.add(packId);
      } else {
        _unlocked.remove(packId);
      }
    });
    try {
      final updated = await AppStateScope.read(context).setUserAccess(
        userId: widget.user.id,
        packId: packId,
        unlock: unlock,
      );
      if (!mounted) return;
      setState(() {
        _pending.remove(packId);
        _unlocked = updated.toSet();
      });
    } catch (_) {
      if (!mounted) return;
      // Revert the optimistic change — the request didn't actually go through.
      setState(() {
        _pending.remove(packId);
        if (unlock) {
          _unlocked.remove(packId);
        } else {
          _unlocked.add(packId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update access. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final u = widget.user;

    return AdminScaffold(
      title: u.name,
      onBack: () => Navigator.of(context).maybePop(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _ProfileCard(user: u),
          const SizedBox(height: 16),
          _StatsRow(user: u),
          const SizedBox(height: 16),
          _RoleCard(
            isAdmin: _isAdmin,
            busy: _roleBusy,
            isSelf: _isSelf,
            onChanged: _setRole,
          ),
          const SizedBox(height: 20),
          const Text('Access — open or close any pack or book',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'This overrides whatever a payment request says — grant access '
            'directly, or revoke it.',
            style: TextStyle(
                fontSize: 12, color: Colors.black.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          for (final pack in state.examPacks)
            _AccessRow(
              key: ValueKey('access-${pack.id}'),
              icon: Icons.quiz_rounded,
              title: pack.title,
              subtitle: '${pack.priceBirr} Birr',
              open: _unlocked.contains(pack.id),
              busy: _pending.contains(pack.id),
              onChanged: (v) => _toggle(pack.id, v),
            ),
          for (final book in state.books)
            _AccessRow(
              key: ValueKey('access-${book.id}'),
              icon: Icons.menu_book_rounded,
              title: book.title,
              subtitle: '${book.priceBirr} Birr',
              open: _unlocked.contains(book.id),
              busy: _pending.contains(book.id),
              onChanged: (v) => _toggle(book.id, v),
              onPreview: () => Navigator.of(context).push(MaterialPageRoute(
                // Admin sessions always come back `unlocked: true` from the
                // backend for any book, so the reader's "Unlock" button
                // never actually renders here — this is just a safety
                // fallback, not a real path.
                builder: (_) => EBookReaderScreen(book: book, onUnlock: (_) async {}),
              )),
            ),
          const SizedBox(height: 20),
          const Text('Recent Activity',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_activity == null)
            const Text("Couldn't load activity.")
          else if (_activity!.recent.isEmpty)
            Text("This user hasn't answered any questions yet.",
                style: TextStyle(color: Colors.black.withValues(alpha: 0.55)))
          else
            for (final e in _activity!.recent) _ActivityRow(entry: e),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.ink,
            backgroundImage: AppImage.provider(user.avatar),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.55))),
                if (user.phone.isNotEmpty)
                  Text(user.phone,
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black.withValues(alpha: 0.45))),
                const SizedBox(height: 4),
                Text('Joined ${_formatDate(user.createdAt)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.45))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});
  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat('${user.totalAnswered}', 'Answered'),
        const SizedBox(width: 10),
        _Stat('${user.totalCorrect}', 'Correct'),
        const SizedBox(width: 10),
        _Stat('${user.bestStreak}', 'Best Streak'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColors.yellow.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Lets one admin promote another user to admin, or demote an admin back
/// to a regular learner — separate from a user's *content* access above.
/// Disabled when viewing your own account (an admin can't remove their own
/// access here — the server refuses it too, this just avoids a round trip
/// to find that out).
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.isAdmin,
    required this.busy,
    required this.isSelf,
    required this.onChanged,
  });

  final bool isAdmin;
  final bool busy;
  final bool isSelf;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings_rounded,
              size: 20, color: AppColors.ink.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin access',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  isSelf
                      ? "You can't change your own admin access here."
                      : 'Manages tracks, packs, questions, payments, users and Q&A.',
                  style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.black.withValues(alpha: 0.45)),
                ),
              ],
            ),
          ),
          Text(isAdmin ? 'Admin' : 'Learner',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isAdmin ? AppColors.correct : Colors.black45)),
          const SizedBox(width: 6),
          if (busy)
            const SizedBox(
                width: 32,
                height: 20,
                child: Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))))
          else
            Switch(
              key: const Key('admin-role-switch'),
              value: isAdmin,
              activeTrackColor: AppColors.correct,
              onChanged: isSelf ? null : onChanged,
            ),
        ],
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.open,
    required this.busy,
    required this.onChanged,
    this.onPreview,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool open;
  final bool busy;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.black.withValues(alpha: 0.45))),
              ],
            ),
          ),
          if (onPreview != null)
            IconButton(
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_outlined, size: 20),
              tooltip: 'Preview',
            ),
          Text(open ? 'Open' : 'Closed',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: open ? AppColors.correct : AppColors.wrong)),
          const SizedBox(width: 6),
          if (busy)
            const SizedBox(
                width: 32,
                height: 20,
                child: Center(
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))))
          else
            Switch(
              value: open,
              activeTrackColor: AppColors.correct,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(entry.wasCorrect ? Icons.check_circle : Icons.cancel,
              color: entry.wasCorrect ? AppColors.correct : AppColors.wrong,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.packTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Text(_formatDateTime(entry.at),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

String _formatDateTime(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${_months[d.month - 1]} ${d.day} · $h:$m';
}
