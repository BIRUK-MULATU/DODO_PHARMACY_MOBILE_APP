import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/api_client.dart';
import '../data/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/assets.dart';
import '../widgets/primary_button.dart';
import 'auth/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'asterali@gmail.com');
  final _password = TextEditingController(text: '12345');

  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Enter your email and password.')));
      return;
    }

    final state = AppStateScope.read(context);
    setState(() => _loading = true);
    try {
      await state.authLogin(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        state.isAdmin ? AppRoutes.admin : AppRoutes.track,
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text("Couldn't reach the server. Check your connection and try again.")));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      hero: Img.loginHero,
      title: 'login',
      fields: [
        AppTextField(
          hint: 'Email',
          icon: Icons.mail_outline,
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        AppTextField(
          hint: 'Password',
          icon: Icons.lock_outline,
          controller: _password,
          obscure: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Navigator.of(context)
                .pushNamed(AppRoutes.forgotPassword),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Forgot password',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
        ),
      ],
      beforePrimary: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Text(
          'Tip: sign in with an “admin…” email to open the admin panel.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ink.withValues(alpha: 0.55),
          ),
        ),
      ),
      primary: PrimaryButton(
        label: _loading ? 'Logging in…' : 'Log in',
        style: DpButtonStyle.yellow,
        onPressed: _loading ? null : _login,
      ),
      footer: AuthFooterLink(
        text: 'Don’t have account?',
        action: 'Sign up',
        onTap: () =>
            Navigator.of(context).pushReplacementNamed(AppRoutes.signup),
      ),
    );
  }
}
