import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_text_field.dart';
import '../widgets/assets.dart';
import '../widgets/entrance.dart';
import '../widgets/press_scale.dart';
import '../widgets/wave.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    final p = AppStateScope.read(context).profile;
    _c = {
      'Name': TextEditingController(text: p.name),
      'Email': TextEditingController(text: p.email),
      'Username': TextEditingController(text: p.username),
      'Password': TextEditingController(text: p.password),
      'Phone number': TextEditingController(text: p.phone),
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggle() {
    if (_editing) {
      AppStateScope.read(context).updateProfile(
        Profile(
          name: _c['Name']!.text,
          email: _c['Email']!.text,
          username: _c['Username']!.text,
          password: _c['Password']!.text,
          phone: _c['Phone number']!.text,
        ),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
    setState(() => _editing = !_editing);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final icons = {
      'Name': Icons.person_outline,
      'Email': Icons.mail_outline,
      'Username': Icons.alternate_email,
      'Password': Icons.lock_outline,
      'Phone number': Icons.phone_outlined,
    };

    return Scaffold(
      backgroundColor: AppColors.yellow,
      drawer: const AppDrawer(),
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(current: 3),
      body: Builder(
        builder: (context) => Column(
          children: [
            WaveHeader(
              height: 120,
              title: 'My Profile',
              onMenu: () => Scaffold.of(context).openDrawer(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Entrance(
                          child: Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.yellowDeep,
                                    width: 4,
                                  ),
                                  image: const DecorationImage(
                                    image: AssetImage(Img.avatar),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.ink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: AppColors.yellow,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.profile.name,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '@${state.profile.username}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink.withValues(alpha: 0.45),
                                ),
                              ),
                              const SizedBox(height: 8),
                              PressScale(
                                onTap: _toggle,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.ink,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Text(
                                    _editing ? 'Save Profile' : 'Edit Profile',
                                    style: const TextStyle(
                                      color: AppColors.yellow,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    ...staggered([
                      for (final entry in _c.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AppTextField(
                          hint: entry.key,
                          icon: icons[entry.key]!,
                          controller: entry.value,
                          readOnly: !_editing,
                          obscure: entry.key == 'Password',
                        ),
                        const SizedBox(height: 14),
                      ],
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
