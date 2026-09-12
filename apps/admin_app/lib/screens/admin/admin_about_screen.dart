import 'package:flutter/material.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import 'admin_scaffold.dart';

/// Edit the content of the drawer "About" screen.
class AdminAboutScreen extends StatefulWidget {
  const AdminAboutScreen({super.key});

  @override
  State<AdminAboutScreen> createState() => _AdminAboutScreenState();
}

class _AdminAboutScreenState extends State<AdminAboutScreen> {
  late final TextEditingController _version;
  late final TextEditingController _intro;
  late final TextEditingController _features;
  late final TextEditingController _unlocking;
  late final TextEditingController _email;
  late final TextEditingController _telegram;
  late final TextEditingController _phone;
  late final TextEditingController _footer;
  late final TextEditingController _marquee;
  late final TextEditingController _onboarding;

  @override
  void initState() {
    super.initState();
    final a = AppStateScope.read(context).aboutInfo;
    _version = TextEditingController(text: a.version);
    _intro = TextEditingController(text: a.intro);
    _features = TextEditingController(text: a.features.join('\n'));
    _unlocking = TextEditingController(text: a.unlocking);
    _email = TextEditingController(text: a.supportEmail);
    _telegram = TextEditingController(text: a.supportTelegram);
    _phone = TextEditingController(text: a.supportPhone);
    _footer = TextEditingController(text: a.footer);
    _marquee = TextEditingController(text: a.marqueeText);
    _onboarding = TextEditingController(text: a.onboardingSubtitle);
  }

  @override
  void dispose() {
    for (final c in [
      _version,
      _intro,
      _features,
      _unlocking,
      _email,
      _telegram,
      _phone,
      _footer,
      _marquee,
      _onboarding,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final state = AppStateScope.read(context);
    state.updateAboutInfo(state.aboutInfo.copyWith(
      version: _version.text.trim(),
      intro: _intro.text.trim(),
      features: _features.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      unlocking: _unlocking.text.trim(),
      supportEmail: _email.text.trim(),
      supportTelegram: _telegram.text.trim(),
      supportPhone: _phone.text.trim(),
      footer: _footer.text.trim(),
      marqueeText: _marquee.text.trim(),
      onboardingSubtitle: _onboarding.text.trim(),
    ));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('About page updated')),
    );
  }

  void _resetToDefault() {
    final seed = MockData.seedAboutInfo();
    setState(() {
      _version.text = seed.version;
      _intro.text = seed.intro;
      _features.text = seed.features.join('\n');
      _unlocking.text = seed.unlocking;
      _email.text = seed.supportEmail;
      _telegram.text = seed.supportTelegram;
      _phone.text = seed.supportPhone;
      _footer.text = seed.footer;
      _marquee.text = seed.marqueeText;
      _onboarding.text = seed.onboardingSubtitle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'About page',
      onBack: () => Navigator.of(context).maybePop(),
      actions: [
        TextButton(
          onPressed: _resetToDefault,
          child: const Text('Reset',
              style: TextStyle(
                  color: AppColors.yellow, fontWeight: FontWeight.w700)),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          const _Hint(
              'This is the “About” page users open from the side drawer.'),
          const SizedBox(height: 14),
          _label('App version'),
          _field(_version, hint: '1.0.0'),
          const SizedBox(height: 16),
          _label('Intro paragraph'),
          _field(_intro, maxLines: 5),
          const SizedBox(height: 16),
          _label('“What you get” — one bullet per line'),
          _field(_features, maxLines: 8),
          const SizedBox(height: 16),
          _label('“How unlocking works” paragraph'),
          _field(_unlocking, maxLines: 5),
          const SizedBox(height: 16),
          _label('Support — email'),
          _field(_email, hint: 'support@dodomed.et'),
          const SizedBox(height: 12),
          _label('Support — Telegram handle'),
          _field(_telegram, hint: '@dodomed'),
          const SizedBox(height: 12),
          _label('Support — phone'),
          _field(_phone, hint: '+251 …'),
          const SizedBox(height: 16),
          _label('Footer line'),
          _field(_footer, hint: '© 2026 DODOMED · Made in Ethiopia'),
          const SizedBox(height: 8),
          Text('Leave a field empty to hide that section on the About page.',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.5))),
          const SizedBox(height: 20),
          const _Hint(
              'The rest of these show up elsewhere in the app — the promo '
              'strip and the welcome screen. (Each exam pack has its own '
              '"About Questions" content now — edit that from the pack\'s '
              'own form, not here.)'),
          const SizedBox(height: 14),
          _label('Promo strip (loops under the header on Home/Dashboard/'
              'Track select/E-book)'),
          _field(_marquee, maxLines: 2),
          const SizedBox(height: 16),
          _label('Onboarding subtitle (under "WELCOME TO")'),
          _field(_onboarding, maxLines: 3),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.yellow,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _save,
            child: const Text('Save changes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _field(
    TextEditingController c, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
