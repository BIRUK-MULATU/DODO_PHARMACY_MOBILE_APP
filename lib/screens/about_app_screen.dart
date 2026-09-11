import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dp_logo.dart';
import '../widgets/entrance.dart';
import '../widgets/wave.dart';

/// "About the app" — reached from the side drawer. Content lives on
/// [AppState.aboutInfo] and is editable from the admin panel.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final info = AppStateScope.of(context).aboutInfo;
    final support = <(IconData, String)>[
      if (info.supportEmail.trim().isNotEmpty)
        (Icons.mail_outline, info.supportEmail.trim()),
      if (info.supportTelegram.trim().isNotEmpty)
        (Icons.send_rounded, 'Telegram: ${info.supportTelegram.trim()}'),
      if (info.supportPhone.trim().isNotEmpty)
        (Icons.phone_outlined, info.supportPhone.trim()),
    ];

    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: Column(
        children: [
          WaveHeader(
            height: 116,
            title: 'About',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: staggered([
                  Center(
                    child: Column(
                      children: [
                        const DpLogo(size: 76, color: AppColors.ink),
                        const SizedBox(height: 10),
                        const Text('DODOMED',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                        if (info.version.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Version ${info.version.trim()}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppColors.ink.withValues(alpha: 0.5))),
                        ],
                      ],
                    ),
                  ),
                  if (info.intro.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(info.intro.trim(),
                        style: AppTheme.body.copyWith(height: 1.5)),
                  ],
                  if (info.features.any((f) => f.trim().isNotEmpty)) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('What you get'),
                    const SizedBox(height: 10),
                    ...info.features
                        .where((f) => f.trim().isNotEmpty)
                        .map((f) => _Bullet(f.trim())),
                  ],
                  if (info.unlocking.trim().isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const _SectionTitle('How unlocking works'),
                    const SizedBox(height: 10),
                    Text(info.unlocking.trim(),
                        style: AppTheme.body.copyWith(height: 1.5)),
                  ],
                  if (support.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const _SectionTitle('Support'),
                    const SizedBox(height: 10),
                    for (final s in support)
                      _InfoRow(icon: s.$1, text: s.$2),
                  ],
                  if (info.footer.trim().isNotEmpty) ...[
                    const SizedBox(height: 26),
                    Center(
                      child: Text(
                        info.footer.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900));
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: CircleAvatar(radius: 3, backgroundColor: AppColors.ink),
          ),
          Expanded(child: Text(text, style: AppTheme.body.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
