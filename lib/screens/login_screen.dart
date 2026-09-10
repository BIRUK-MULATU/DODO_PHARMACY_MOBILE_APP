import 'package:flutter/material.dart';

import '../app/routes.dart';
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
  final _email = TextEditingController(text: 'Asterali@gmail.com');
  final _password = TextEditingController(text: '12345');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    AppStateScope.read(context).logIn();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.track,
      (route) => false,
    );
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
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot password',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ),
      ],
      primary: PrimaryButton(
        label: 'Log in',
        style: DpButtonStyle.yellow,
        onPressed: _login,
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
