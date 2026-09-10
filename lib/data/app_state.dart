import 'package:flutter/widgets.dart';

import 'mock_data.dart';
import 'models.dart';

/// App-wide state held in memory. Exposed to the widget tree through
/// [AppStateScope]. No backend — everything resets on restart.
class AppState extends ChangeNotifier {
  bool loggedIn = false;
  bool isAdmin = false;
  ExamTrack track = ExamTrack.pharmacy;

  Profile profile = Profile(
    name: 'Aster Ali',
    username: 'Asterali',
    email: 'Asterali@gmail.com',
    password: '12345',
    phone: '+251913623093',
  );

  /// The live question bank. Seeded from [MockData]; the admin panel mutates it.
  final List<Question> questions = MockData.seedQuestions();

  /// Receipts uploaded by users, for the admin to approve or reject.
  final List<PaymentRequest> paymentRequests = [];

  int _idSeq = 0;
  String _newId(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';

  /// Per-pack: how many questions the user has answered.
  final Map<String, int> _answered = {};

  /// Per-pack: how many answered correctly.
  final Map<String, int> _correct = {};

  /// Packs the user has unlocked by paying.
  final Set<String> _unlocked = {};

  int uploadAttempts = 0;

  void logIn({bool asAdmin = false}) {
    loggedIn = true;
    isAdmin = asAdmin;
    notifyListeners();
  }

  void logOut() {
    loggedIn = false;
    isAdmin = false;
    notifyListeners();
  }

  void chooseTrack(ExamTrack value) {
    track = value;
    notifyListeners();
  }

  void updateProfile(Profile value) {
    profile = value;
    notifyListeners();
  }

  int answered(String packId) => _answered[packId] ?? 0;
  int correct(String packId) => _correct[packId] ?? 0;
  bool isUnlocked(String packId) => _unlocked.contains(packId);

  bool needsPayment(ExamPack pack) =>
      !isUnlocked(pack.id) && answered(pack.id) >= pack.freeLimit;

  double progress(ExamPack pack) =>
      (answered(pack.id) / pack.questionCount).clamp(0, 1);

  void recordAnswer({required String packId, required bool wasCorrect}) {
    _answered[packId] = (_answered[packId] ?? 0) + 1;
    if (wasCorrect) {
      _correct[packId] = (_correct[packId] ?? 0) + 1;
    }
    notifyListeners();
  }

  void unlock(String packId) {
    _unlocked.add(packId);
    notifyListeners();
  }

  void lock(String packId) {
    _unlocked.remove(packId);
    notifyListeners();
  }

  void registerUploadAttempt() {
    uploadAttempts++;
    notifyListeners();
  }

  // --- Questions (admin CRUD) --------------------------------------------

  List<Question> questionsForPack(String packId) =>
      questions.where((q) => q.packId == packId).toList();

  /// Loops the pack's questions so the exam can run past what's authored.
  Question examQuestion(ExamPack pack, int index) {
    final pool = questionsForPack(pack.id);
    final list = pool.isEmpty ? questions : pool;
    return list[index % list.length];
  }

  void addQuestion(Question q) {
    questions.add(q.id.isEmpty
        ? Question(
            id: _newId('q'),
            packId: q.packId,
            number: q.number,
            total: q.total,
            prompt: q.prompt,
            options: q.options,
            correctIndex: q.correctIndex,
            explanation: q.explanation,
          )
        : q);
    notifyListeners();
  }

  void updateQuestion(Question q) {
    final i = questions.indexWhere((e) => e.id == q.id);
    if (i != -1) {
      questions[i] = q;
      notifyListeners();
    }
  }

  void deleteQuestion(String id) {
    questions.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  String newQuestionId() => _newId('q');

  // --- Payment requests (admin approval) --------------------------------

  int get pendingPaymentCount =>
      paymentRequests.where((r) => r.status == PaymentStatus.pending).length;

  PaymentRequest? paymentRequestFor(String packId) {
    for (final r in paymentRequests.reversed) {
      if (r.packId == packId) return r;
    }
    return null;
  }

  PaymentRequest submitPaymentRequest({
    required ExamPack pack,
    required String bankCode,
  }) {
    final req = PaymentRequest(
      id: _newId('pay'),
      userName: profile.name,
      packId: pack.id,
      packTitle: pack.title,
      bankCode: bankCode,
      amountBirr: pack.priceBirr,
      submittedAt: DateTime.now(),
    );
    paymentRequests.add(req);
    notifyListeners();
    return req;
  }

  void decidePayment(String requestId, PaymentStatus decision) {
    final req = paymentRequests.firstWhere((r) => r.id == requestId);
    req.status = decision;
    if (decision == PaymentStatus.approved) {
      _unlocked.add(req.packId);
    } else {
      _unlocked.remove(req.packId);
    }
    notifyListeners();
  }

  // Aggregate stats for the dashboard.
  int get totalAnswered =>
      _answered.values.fold(0, (sum, value) => sum + value);
  int get totalCorrect =>
      _correct.values.fold(0, (sum, value) => sum + value);
  int get accuracyPercent =>
      totalAnswered == 0 ? 0 : ((totalCorrect / totalAnswered) * 100).round();

  ExamPack get primaryPack => MockData.examPacks.first;
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds.
  static AppState read(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<AppStateScope>()
        ?.widget as AppStateScope?;
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
