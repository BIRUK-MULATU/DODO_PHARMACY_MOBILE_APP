import 'package:flutter/widgets.dart';

import 'mock_data.dart';
import 'models.dart';
import 'pdf_store.dart';

/// App-wide state held in memory. Exposed to the widget tree through
/// [AppStateScope]. No backend — everything resets on restart.
class AppState extends ChangeNotifier {
  bool loggedIn = false;
  bool isAdmin = false;

  /// The track (field of study) the learner is currently browsing.
  String trackId = 'pharmacy';

  Profile profile = Profile(
    name: 'Aster Ali',
    username: 'Asterali',
    email: 'Asterali@gmail.com',
    password: '12345',
    phone: '+251913623093',
  );

  /// The live tracks. Seeded from [MockData]; the admin panel mutates it.
  final List<Track> tracks = MockData.seedTracks();

  /// The live exam packs. Seeded from [MockData]; the admin panel mutates it.
  final List<ExamPack> examPacks = MockData.seedExamPacks();

  /// The live premium book collection. Seeded from [MockData]; admin CRUD.
  final List<EBook> books = MockData.seedBooks();

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

  void chooseTrack(String id) {
    trackId = id;
    notifyListeners();
  }

  void updateProfile(Profile value) {
    profile = value;
    notifyListeners();
  }

  void setAvatar(String assetPath) {
    profile.avatar = assetPath;
    notifyListeners();
  }

  // --- Tracks (admin CRUD) ---------------------------------------------

  Track? trackById(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  String trackName(String id) => trackById(id)?.name ?? '—';

  List<ExamPack> packsForTrack(String trackId) =>
      examPacks.where((p) => p.trackId == trackId).toList();

  /// Packs shown to the learner for the track they picked. Falls back to every
  /// pack so the app is never empty if a track was removed.
  List<ExamPack> get visiblePacks {
    final scoped = packsForTrack(trackId);
    return scoped.isNotEmpty ? scoped : examPacks;
  }

  String newTrackId() => _newId('track');

  void addTrack(Track t) {
    tracks.add(t);
    notifyListeners();
  }

  void updateTrack(Track t) {
    final i = tracks.indexWhere((e) => e.id == t.id);
    if (i != -1) {
      tracks[i] = t;
      notifyListeners();
    }
  }

  /// Removes a track together with its packs and their questions.
  void deleteTrack(String id) {
    tracks.removeWhere((t) => t.id == id);
    final removedPackIds =
        examPacks.where((p) => p.trackId == id).map((p) => p.id).toSet();
    examPacks.removeWhere((p) => removedPackIds.contains(p.id));
    questions.removeWhere((q) => removedPackIds.contains(q.packId));
    if (trackId == id) {
      trackId = tracks.isNotEmpty ? tracks.first.id : '';
    }
    notifyListeners();
  }

  // --- Exam packs (admin CRUD) ----------------------------------------

  ExamPack? packById(String id) {
    for (final p in examPacks) {
      if (p.id == id) return p;
    }
    return null;
  }

  String newPackId() => _newId('pack');

  void addPack(ExamPack pack) {
    examPacks.add(pack);
    notifyListeners();
  }

  void updatePack(ExamPack pack) {
    final i = examPacks.indexWhere((e) => e.id == pack.id);
    if (i != -1) {
      examPacks[i] = pack;
      notifyListeners();
    }
  }

  /// Removes a pack together with its questions and any unlock/progress state.
  void deletePack(String id) {
    examPacks.removeWhere((p) => p.id == id);
    questions.removeWhere((q) => q.packId == id);
    _unlocked.remove(id);
    _answered.remove(id);
    _correct.remove(id);
    notifyListeners();
  }

  // --- Premium books (admin CRUD) -----------------------------------

  EBook? bookById(String id) {
    for (final b in books) {
      if (b.id == id) return b;
    }
    return null;
  }

  String newBookId() => _newId('book');

  void addBook(EBook book) {
    books.add(book);
    notifyListeners();
  }

  void updateBook(EBook book) {
    final i = books.indexWhere((e) => e.id == book.id);
    if (i != -1) {
      books[i] = book;
      notifyListeners();
    }
  }

  void deleteBook(String id) {
    final gone = books.where((b) => b.id == id).toList();
    books.removeWhere((b) => b.id == id);
    _unlocked.remove(id);
    for (final b in gone) {
      deleteSavedPdf(b.pdfPath);
    }
    notifyListeners();
  }

  /// A synthetic [ExamPack] so a book can travel through the shared payment
  /// flow (which keys everything on `id`, `title` and `priceBirr`).
  ExamPack purchasableForBook(EBook book) => ExamPack(
        id: book.id,
        title: book.title,
        image: book.cover,
        questionCount: book.pageCount,
        priceBirr: book.priceBirr,
        freeLimit: book.freePages,
      );

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

  ExamPack get primaryPack =>
      examPacks.isNotEmpty ? examPacks.first : MockData.seedExamPacks().first;
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
