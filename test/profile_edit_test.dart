import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodo_pharmacy_mobile_app/data/app_state.dart';
import 'package:dodo_pharmacy_mobile_app/screens/profile_screen.dart';
import 'package:dodo_pharmacy_mobile_app/widgets/app_image.dart';

import 'support/fake_file_selector.dart';

void main() {
  testWidgets('profile edit header fits a narrow phone without overflow',
      (tester) async {
    // A small phone in logical pixels.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    state.profile.name = 'Aster Wondimagegnehu Ali'; // a long name
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('Edit Profile'));
    await tester.pump();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull); // no RenderFlex overflow
  });

  testWidgets('user edits their profile on-device and it saves', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Fields start read-only.
    expect(find.text('Edit Profile'), findsOneWidget);

    await tester.tap(find.text('Edit Profile'));
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), 'Aster B. Ali');
    await tester.enterText(
        find.widgetWithText(TextField, 'Phone number'), '+251911000000');

    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(state.profile.name, 'Aster B. Ali');
    expect(state.profile.phone, '+251911000000');
    // Back to read-only view, header reflects the new name.
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Aster B. Ali'), findsWidgets);
  });

  testWidgets('an invalid email is rejected', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    final original = state.profile.email;
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    await tester.tap(find.text('Edit Profile'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'not-an-email');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.textContaining('valid email'), findsOneWidget);
    expect(state.profile.email, original);
  });

  test('AppState.setAvatar accepts a bundled asset or an uploaded data URI', () {
    final state = AppState();
    expect(state.profile.avatar, 'assets/images/avatar.png');

    state.setAvatar('assets/images/pharmacist.png');
    expect(state.profile.avatar, 'assets/images/pharmacist.png');

    const uploaded = 'data:image/png;base64,iVBORw0KGgo=';
    state.setAvatar(uploaded);
    expect(state.profile.avatar, uploaded);
  });

  testWidgets(
      'tapping the avatar goes straight to the device picker — no preset choice',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final previous = installFakeFileSelector();
    addTearDown(() => FileSelectorPlatform.instance = previous);

    final state = AppState();
    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Tap the camera badge on the avatar — used to open a sheet offering
    // "Choose from device" or a preset; now it opens the device picker
    // directly, with no sheet and no preset choice at all.
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pump();
    // Image decoding runs on the engine's real thread pool — needs runAsync.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Choose from device'), findsNothing);
    expect(find.text('…or pick one of these'), findsNothing);
    expect(AppImage.isUploaded(state.profile.avatar), isTrue);
    expect(find.text('Profile picture updated'), findsOneWidget);
  });
}
