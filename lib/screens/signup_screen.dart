import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/api_client.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/assets.dart';
import '../widgets/primary_button.dart';
import 'auth/auth_scaffold.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signup() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Enter an email and a password to sign up.');
      return;
    }
    if (password != _confirm.text) {
      _showError("Passwords don't match.");
      return;
    }

    final state = AppStateScope.read(context);
    setState(() => _loading = true);
    try {
      // The form only collects email/phone/password — name and username
      // keep the app's default profile identity, same as before there was a
      // real backend to register them against.
      await state.authSignUp(
        name: state.profile.name,
        username: state.profile.username,
        email: email,
        password: password,
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.track,
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) {
        _showError("Couldn't reach the server. Check your connection and try again.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      hero: Img.signupHero,
      title: 'Sign up',
      fields: [
        AppTextField(
          hint: 'Email',
          icon: Icons.mail_outline,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        AppTextField(
          hint: 'Phone number',
          icon: Icons.phone_outlined,
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
        AppTextField(
          hint: 'Password',
          icon: Icons.lock_outline,
          controller: _password,
          obscure: true,
        ),
        const Text(
          'Confirm Password',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        AppTextField(
          hint: 'Password',
          icon: Icons.lock_outline,
          controller: _confirm,
          obscure: true,
        ),
      ],
      primary: PrimaryButton(
        label: _loading ? 'Signing up…' : 'Sign Up',
        style: DpButtonStyle.yellow,
        onPressed: _loading ? null : _signup,
      ),
      footer: AuthFooterLink(
        text: 'Already  have account?',
        action: 'Log in',
        onTap: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.login),
      ),
    );
  }
}
