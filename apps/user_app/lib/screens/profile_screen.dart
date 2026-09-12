import 'package:flutter/material.dart';

import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import 'package:dodomed_core/widgets/app_image.dart';
import 'package:dodomed_core/widgets/app_text_field.dart';
import 'package:dodomed_core/widgets/entrance.dart';
import 'package:dodomed_core/widgets/press_scale.dart';
import 'package:dodomed_core/widgets/wave.dart';

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

  // Only source for a profile picture is the device's own photo picker — no
  // preset-avatar fallback, so tapping the avatar goes straight to it
  // instead of opening a sheet with a choice to make.
  Future<void> _pickAvatar() async {
    final state = AppStateScope.read(context);
    String? uri;
    var pickError = false;
    try {
      uri = await pickImageAsDataUri(maxWidth: 600);
    } catch (_) {
      pickError = true;
    }

    if (!mounted) return;
    if (pickError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the image picker.")),
      );
      return;
    }
    if (uri != null) {
      state.setAvatar(uri);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Avatar + name -------------------------------------
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Entrance(
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.yellowDeep,
                                      width: 4,
                                    ),
                                    image: DecorationImage(
                                      image: AppImage.provider(
                                          state.profile.avatar),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.ink,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.yellow,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.profile.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${state.profile.username}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      AppColors.ink.withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // --- Edit / Save / Cancel ----------------------------
                    if (_editing)
                      Row(
                        children: [
                          Expanded(
                            child: _PillButton(
                              label: 'Save',
                              filled: true,
                              onTap: _save,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PillButton(
                              label: 'Cancel',
                              filled: false,
                              onTap: _cancel,
                            ),
                          ),
                        ],
                      )
                    else
                      _PillButton(
                        label: 'Edit Profile',
                        filled: true,
                        onTap: _startEditing,
                      ),
                    if (_editing) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Tap the camera to change your picture, edit any field '
                        'below, then Save.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.ink.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.wrongFill.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.wrong,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // --- Fields -----------------------------------------
                    ...staggered([
                      for (final entry in _c.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 16,
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
                        const SizedBox(height: 18),
                      ],
                    ]),
                    const SizedBox(height: 8),
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

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(23),
          border: filled
              ? null
              : Border.all(color: AppColors.ink, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? AppColors.yellow : AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

