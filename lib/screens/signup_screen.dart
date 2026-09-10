import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../data/models.dart';
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

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _signup() {
    final state = AppStateScope.read(context);
    final current = state.profile;
    state.updateProfile(
      Profile(
        name: current.name,
        username: current.username,
        email: _email.text.trim().isEmpty ? current.email : _email.text.trim(),
        password:
            _password.text.isEmpty ? current.password : _password.text,
        phone: _phone.text.trim().isEmpty ? current.phone : _phone.text.trim(),
      ),
    );
    state.logIn();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.track,
      (route) => false,
    );
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
        label: 'Sign Up',
        style: DpButtonStyle.yellow,
        onPressed: _signup,
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
