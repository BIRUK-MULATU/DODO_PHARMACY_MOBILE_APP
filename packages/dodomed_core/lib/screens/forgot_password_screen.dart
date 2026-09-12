import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/assets.dart';
import '../widgets/primary_button.dart';
import 'auth/auth_scaffold.dart';

/// Password reset. There's no real mail service wired up, so — like before
/// there was a backend — the "code" is a fixed, publicly-known demo value
/// rather than something actually emailed. When a backend is reachable this
/// updates the real account's password there (see
/// `AppState.resetPasswordOnBackend`); if it isn't, it falls back to the
/// original fully-local demo behaviour (only works for whichever profile is
/// currently loaded).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _demoCode = '1234';

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _sendCode() {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _codeSent = true;
      _error = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reset code $_demoCode sent to $email')),
    );
  }

  Future<void> _reset() async {
    if (_code.text.trim() != _demoCode) {
      setState(() => _error = 'Incorrect code. (Demo code is $_demoCode.)');
      return;
    }
    if (_password.text.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords don’t match.');
      return;
    }

    final state = AppStateScope.read(context);
    final email = _email.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Tries the real backend first — this is what actually resets a real
      // account's password, regardless of which profile happens to be
      // loaded locally right now.
      await state.resetPasswordOnBackend(
        email: email,
        code: _code.text.trim(),
        newPassword: _password.text,
      );
    } on ApiException catch (e) {
      // A real backend responded and rejected this — show its reason rather
      // than silently falling back.
      if (mounted) setState(() => _loading = false);
      if (mounted) setState(() => _error = e.message);
      return;
    } catch (_) {
      // No backend reachable at all — fall back to the original, fully-local
      // demo behaviour so this screen still works without one running.
      if (state.profile.email.trim().toLowerCase() != email.toLowerCase()) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = "Couldn't reach the server to reset that account.";
          });
        }
        return;
      }
      state.updateProfile(
        Profile(
          name: state.profile.name,
          username: state.profile.username,
          email: state.profile.email,
          password: _password.text,
          phone: state.profile.phone,
        ),
      );
    }

    if (!mounted) return;
    // This screen is shared by both the user and admin apps, each with its
    // own route table — '/login' is the one route name both apps register
    // identically, so it's used directly here rather than as a parameter.
    Navigator.of(context).pushReplacementNamed('/login');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated — please log in.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      hero: Img.loginHero,
      title: _codeSent ? 'New password' : 'Reset password',
      showSocial: false,
      fields: [
        AppTextField(
          hint: 'Email',
          icon: Icons.mail_outline,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          readOnly: _codeSent,
        ),
        if (_codeSent) ...[
          AppTextField(
            hint: 'Reset code',
            icon: Icons.pin_outlined,
            controller: _code,
            keyboardType: TextInputType.number,
          ),
          AppTextField(
            hint: 'New password',
            icon: Icons.lock_outline,
            controller: _password,
            obscure: true,
          ),
          const Text(
            'Confirm password',
            style:
                TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          AppTextField(
            hint: 'New password',
            icon: Icons.lock_outline,
            controller: _confirm,
            obscure: true,
          ),
        ],
      ],
      beforePrimary: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                _error!,
                style: const TextStyle(
                    color: AppColors.wrong, fontWeight: FontWeight.w700),
              ),
            ),
          if (_codeSent)
            TextButton(
              onPressed: _loading ? null : _sendCode,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Resend code',
                  style: TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      primary: PrimaryButton(
        label: _codeSent
            ? (_loading ? 'Resetting…' : 'Reset password')
            : 'Send reset code',
        style: DpButtonStyle.yellow,
        onPressed: _loading ? null : (_codeSent ? _reset : _sendCode),
      ),
      footer: AuthFooterLink(
        text: 'Remembered it?',
        action: 'Log in',
        onTap: () =>
            Navigator.of(context).pushReplacementNamed('/login'),
      ),
    );
  }
}
