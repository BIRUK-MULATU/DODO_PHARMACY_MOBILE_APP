import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dodomed_admin/app/routes.dart';
import 'package:dodomed_core/data/app_state.dart';
import 'package:dodomed_core/data/mock_data.dart';
import 'package:dodomed_core/data/models.dart';
import 'package:dodomed_admin/screens/admin/admin_bank_form_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_banks_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_pack_form_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_packs_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_payments_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_questions_screen.dart';
import 'package:dodomed_admin/screens/admin/admin_tracks_screen.dart';

Widget _host(AppState state, Widget home) => AppStateScope(
      state: state,
      child: MaterialApp(home: home, onGenerateRoute: AppRoutes.onGenerateRoute),
    );

void main() {
  test('AppState question CRUD', () {
    final s = AppState();
    final before = s.questions.length;

    final q = Question(
      id: s.newQuestionId(),
      packId: 'exit-3000',
      number: 999,
      total: 3000,
      prompt: 'What is the antidote for an acetaminophen overdose?',
      options: ['Naloxone', 'N-acetylcysteine', 'Flumazenil', 'Atropine'],
      correctIndex: 1,
      explanation: 'N-acetylcysteine replenishes glutathione stores.',
    );
    s.addQuestion(q);
    expect(s.questions.length, before + 1);
    expect(s.questions.last.answerLabel, 'B) N-acetylcysteine');

    s.updateQuestion(q.copyWith(correctIndex: 0));
    expect(s.questions.firstWhere((e) => e.id == q.id).answerLabel,
        'A) Naloxone');

    s.deleteQuestion(q.id);
    expect(s.questions.length, before);
  });

  testWidgets('admin approves a payment request and the pack unlocks',
      (tester) async {
    final s = AppState();
    final pack = MockData.seedExamPacks().first;
    s.submitPaymentRequest(pack: pack, bankCode: 'CBE');
    expect(s.pendingPaymentCount, 1);
    expect(s.isUnlocked(pack.id), isFalse);

    await tester.pumpWidget(_host(s, const AdminPaymentsScreen()));
    await tester.pump();

    expect(find.text('Pending'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pump();

    expect(s.isUnlocked(pack.id), isTrue);
    expect(s.pendingPaymentCount, 0);
    expect(find.text('Approved'), findsOneWidget);
  });

  testWidgets('admin questions list shows a delete confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    final count = s.questions.length;
    await tester.pumpWidget(_host(s, const AdminQuestionsScreen()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    expect(find.text('Delete question?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(s.questions.length, count - 1);
  });

  test('AppState exam-pack CRUD cascades to its questions', () {
    final s = AppState();
    final before = s.examPacks.length;

    final pack = ExamPack(
      id: s.newPackId(),
      trackId: 'pharmacy',
      title: '1500 Internship Prep',
      image: MockData.packImages.first,
      questionCount: 1500,
      priceBirr: 300,
      freeLimit: 3,
    );
    s.addPack(pack);
    expect(s.examPacks.length, before + 1);
    expect(s.packsForTrack('pharmacy').map((p) => p.id), contains(pack.id));

    s.addQuestion(Question(
      id: s.newQuestionId(),
      packId: pack.id,
      number: 1,
      total: 1500,
      prompt: 'A sample question long enough to pass validation.',
      options: ['a', 'b', 'c', 'd'],
      correctIndex: 0,
      explanation: 'Because it is the sample answer, clearly.',
    ));
    final qCount = s.questions.length;

    s.updatePack(pack.copyWith(priceBirr: 999, freeLimit: 10));
    expect(s.packById(pack.id)!.priceBirr, 999);
    expect(s.packById(pack.id)!.freeLimit, 10);

    s.deletePack(pack.id);
    expect(s.examPacks.length, before);
    expect(s.questions.length, qCount - 1); // its question went too
  });

  test('AppState track CRUD cascades to packs and questions', () {
    final s = AppState();
    final track = Track(id: s.newTrackId(), name: 'Midwifery');
    s.addTrack(track);
    expect(s.tracks.map((t) => t.id), contains(track.id));

    s.addPack(ExamPack(
      id: s.newPackId(),
      trackId: track.id,
      title: '900 Midwifery Sample',
      image: MockData.packImages.first,
      questionCount: 900,
      priceBirr: 200,
      freeLimit: 5,
    ));
    final packId = s.packsForTrack(track.id).single.id;
    s.addQuestion(Question(
      id: s.newQuestionId(),
      packId: packId,
      number: 1,
      total: 900,
      prompt: 'Another sample question, sufficiently long here.',
      options: ['a', 'b', 'c', 'd'],
      correctIndex: 1,
      explanation: 'A perfectly reasonable explanation string.',
    ));

    s.updateTrack(track.copyWith(name: 'Clinical Midwifery'));
    expect(s.trackName(track.id), 'Clinical Midwifery');

    s.deleteTrack(track.id);
    expect(s.tracks.map((t) => t.id), isNot(contains(track.id)));
    expect(s.packsForTrack(track.id), isEmpty);
    expect(s.questions.where((q) => q.packId == packId), isEmpty);
  });

  testWidgets('admin adds an exam pack through the form', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    final before = s.examPacks.length;

    await tester.pumpWidget(_host(s, const AdminPacksScreen()));
    await tester.pump();

    await tester.tap(find.text('New pack'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).first, '4000 Master Question Bank');
    await tester.enterText(find.byType(TextFormField).at(1), '4000'); // bank size
    await tester.enterText(find.byType(TextFormField).at(2), '5'); // free
    await tester.enterText(find.byType(TextFormField).at(3), '600'); // price

    await tester.tap(find.text('Add pack'));
    await tester.pumpAndSettle();

    expect(s.examPacks.length, before + 1);
    expect(s.examPacks.last.title, '4000 Master Question Bank');
    expect(s.examPacks.last.questionCount, 4000);
  });

  testWidgets(
      "admin sets a pack's own About Questions content through the form",
      (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    final pack = s.examPacks.first;

    await tester.pumpWidget(_host(s, AdminPackFormScreen(pack: pack)));
    await tester.pump();

    final fields = find.byType(TextFormField);
    // 0: title, 1: bank size, 2: free, 3: price, 4: about summary,
    // 5: about bullets, 6: core courses.
    await tester.enterText(fields.at(4), 'A brand new summary line');
    await tester.enterText(fields.at(5), 'Custom bullet one\nCustom bullet two');
    await tester.enterText(fields.at(6), 'Custom course one');

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = s.packById(pack.id)!;
    expect(saved.aboutSummary, 'A brand new summary line');
    expect(saved.aboutBullets, ['Custom bullet one', 'Custom bullet two']);
    expect(saved.coreCourses, ['Custom course one']);
  });

  testWidgets('admin tracks screen lists the seeded tracks and can delete',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    await tester.pumpWidget(_host(s, const AdminTracksScreen()));
    await tester.pump();

    expect(find.text('Pharmacy'), findsOneWidget);
    expect(find.text('Nursing'), findsOneWidget);

    // Delete Nursing (it has no packs in the seed data).
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pump();
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(s.tracks.map((t) => t.name), isNot(contains('Nursing')));
  });

  testWidgets('admin banks screen lists the seeded banks and can delete',
      (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    await tester.pumpWidget(_host(s, const AdminBanksScreen()));
    await tester.pump();

    expect(find.textContaining('CBE'), findsOneWidget);
    expect(find.textContaining('BOA'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pump();
    await tester.tap(find.text('Delete'));
    await tester.pump();

    expect(s.banks.map((b) => b.code), isNot(contains('BOA')));
  });

  testWidgets('admin adds a bank account through the form', (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final s = AppState();
    final before = s.banks.length;
    await tester.pumpWidget(_host(s, const AdminBankFormScreen()));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).at(0), 'AWASH');
    await tester.enterText(find.byType(TextFormField).at(1), 'Awash Bank');
    await tester.enterText(find.byType(TextFormField).at(2), 'Test Owner');
    await tester.enterText(find.byType(TextFormField).at(3), '55555');
    await tester.tap(find.text('Add bank'));
    await tester.pump();

    expect(s.banks.length, before + 1);
    expect(s.banks.last.code, 'AWASH');
    expect(s.banks.last.name, 'Awash Bank');
  });
}
