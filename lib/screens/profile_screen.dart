import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_text_field.dart';
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
  String? _error;
  late final Map<String, TextEditingController> _c;

  @override
  void initState() {
    super.initState();
    _c = {
      'Name': TextEditingController(),
      'Email': TextEditingController(),
      'Username': TextEditingController(),
      'Password': TextEditingController(),
      'Phone number': TextEditingController(),
    };
    _resetControllers();
  }

  void _resetControllers() {
    final p = AppStateScope.read(context).profile;
    _c['Name']!.text = p.name;
    _c['Email']!.text = p.email;
    _c['Username']!.text = p.username;
    _c['Password']!.text = p.password;
    _c['Phone number']!.text = p.phone;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startEditing() => setState(() {
        _error = null;
        _editing = true;
      });

  void _cancel() => setState(() {
        _error = null;
        _editing = false;
        _resetControllers();
      });

  void _save() {
    final name = _c['Name']!.text.trim();
    final email = _c['Email']!.text.trim();
    final username = _c['Username']!.text.trim();
    final password = _c['Password']!.text;
    final phone = _c['Phone number']!.text.trim();

    if (name.isEmpty || username.isEmpty) {
      setState(() => _error = 'Name and username can’t be empty.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 4) {
      setState(() => _error = 'Password must be at least 4 characters.');
      return;
    }

    AppStateScope.read(context).updateProfile(
      AppStateScope.read(context).profile.copyWith(
            name: name,
            email: email,
            username: username,
            password: password,
            phone: phone,
          ),
    );
    setState(() {
      _error = null;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  Future<void> _pickAvatar() async {
    final state = AppStateScope.read(context);
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.yellow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final a in MockData.avatarChoices)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, a),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: state.profile.avatar == a
                              ? AppColors.ink
                              : Colors.transparent,
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: AssetImage(a),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (chosen != null) {
      state.setAvatar(chosen);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    }
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
                          child: GestureDetector(
                            onTap: _pickAvatar,
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
                                    image: DecorationImage(
                                      image: AssetImage(state.profile.avatar),
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
                              Row(
                                children: [
                                  PressScale(
                                    onTap:
                                        _editing ? _save : _startEditing,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.ink,
                                        borderRadius:
                                            BorderRadius.circular(22),
                                      ),
                                      child: Text(
                                        _editing
                                            ? 'Save Profile'
                                            : 'Edit Profile',
                                        style: const TextStyle(
                                          color: AppColors.yellow,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_editing) ...[
                                    const SizedBox(width: 10),
                                    PressScale(
                                      onTap: _cancel,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          border: Border.all(
                                              color: AppColors.ink,
                                              width: 1.5),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_editing)
                      Text(
                        'Tap the camera to change your picture. Edit any field '
                        'below, then Save.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: AppColors.ink.withValues(alpha: 0.6),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.wrong,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
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
                          keyboardType: entry.key == 'Email'
                              ? TextInputType.emailAddress
                              : entry.key == 'Phone number'
                                  ? TextInputType.phone
                                  : null,
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
