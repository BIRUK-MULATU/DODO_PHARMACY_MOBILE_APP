import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/assets.dart';
import '../widgets/primary_button.dart';
import 'auth/auth_scaffold.dart';

/// Simulated password reset (no backend): request a code for an email, then
/// enter the code + a new password. The demo code is always `1234`.
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

  void _reset() {
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
    if (state.profile.email.trim().toLowerCase() ==
        _email.text.trim().toLowerCase()) {
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

    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
              onPressed: _sendCode,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Resend code',
                  style: TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      primary: PrimaryButton(
        label: _codeSent ? 'Reset password' : 'Send reset code',
        style: DpButtonStyle.yellow,
        onPressed: _codeSent ? _reset : _sendCode,
      ),
      footer: AuthFooterLink(
        text: 'Remembered it?',
        action: 'Log in',
        onTap: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.login),
      ),
    );
  }
}
