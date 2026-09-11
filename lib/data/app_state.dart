import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'mock_data.dart';
import 'models.dart';
import 'pdf_store.dart';

const _tokenPrefsKey = 'dodomed_auth_token';

/// Shown in the profile edit form instead of the real password once it's
/// come from the backend (which never sends it back). Left alone on save —
/// only a value the user actually typed gets sent to the server.
const hiddenPasswordPlaceholder = '••••••';

/// App-wide state held in memory, exposed to the widget tree through
/// [AppStateScope]. By default (`api == null`) it behaves exactly as it
/// always did — seeded from [MockData], fully offline/in-memory, which is
/// what every existing test exercises. Calling [authLogin]/[authSignUp]/
/// [tryAutoLogin] switches it into "online" mode: [api] gets set, the catalog
/// (tracks/packs/questions/books/about) is replaced with what the real
/// backend has, and every mutation below also syncs there in the background.
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

  /// The live tracks. Seeded from [MockData] until an online session
  /// replaces them with the backend's own; the admin panel mutates it.
  List<Track> tracks = MockData.seedTracks();

  /// The live exam packs. Seeded from [MockData]; the admin panel mutates it.
  List<ExamPack> examPacks = MockData.seedExamPacks();

  /// The live premium book collection. Seeded from [MockData]; admin CRUD.
  List<EBook> books = MockData.seedBooks();

  /// The drawer "About" screen content. Editable from the admin panel.
  AboutInfo aboutInfo = MockData.seedAboutInfo();

  /// The live question bank. Seeded from [MockData]; the admin panel mutates it.
  List<Question> questions = MockData.seedQuestions();

  /// Receipts uploaded by users, for the admin to approve or reject.
  final List<PaymentRequest> paymentRequests = [];

  /// Set once a real backend session starts (see class doc). `null` means
  /// fully offline/in-memory — every existing screen and test behaves
  /// exactly as before.
  ApiClient? api;
  bool get isOnline => api != null;

  /// The most recent background sync failure (a create/update/delete that
  /// went to the server after the local state already changed), if any.
  /// Screens may surface this; nothing currently requires it to be read.
  String? syncError;

  void _syncFailed(Object error) {
    syncError = error.toString();
    notifyListeners();
  }

  int _idSeq = 0;
  String _newId(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_idSeq++}';

  /// Per-pack: how many questions the user has answered.
  final Map<String, int> _answered = {};

  /// Per-pack: how many answered correctly.
  final Map<String, int> _correct = {};

  /// Packs the user has unlocked by paying.
  final Set<String> _unlocked = {};

  int uploadAttempts = 0;

  /// Offline/demo login — no backend involved. Still used by tests and by
  /// any flow that hasn't been wired to the real API.
  void logIn({bool asAdmin = false}) {
    loggedIn = true;
    isAdmin = asAdmin;
    notifyListeners();
  }

  void logOut() {
    loggedIn = false;
    isAdmin = false;
    api = null;
    unawaited(_clearPersistedToken());
    notifyListeners();
  }

  // --- Real backend auth -------------------------------------------------

  /// How a fresh, unauthenticated [ApiClient] is created for signup/login/
  /// auto-login. Overridable so tests can point it at a fake backend instead
  /// of a real network call — see `test/support/fake_backend.dart`.
  ApiClient Function() apiClientFactory = ApiClient.new;

  /// Creates a real account on the backend and starts an online session.
  /// Throws [ApiException] on failure (e.g. email already registered) —
  /// callers should catch it and show `error.message`.
  Future<void> authSignUp({
    required String name,
    required String username,
    required String email,
    required String password,
    required String phone,
  }) async {
    final client = apiClientFactory();
    final res = await client.post('/auth/signup', {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
      'phone': phone,
    });
    await _startOnlineSession(client, res, knownPassword: password);
  }

  /// Logs into the real backend and starts an online session. Throws
  /// [ApiException] on failure (e.g. wrong password) — callers should catch
  /// it and show `error.message`.
  Future<void> authLogin({required String email, required String password}) async {
    final client = apiClientFactory();
    final res = await client.post('/auth/login', {'email': email, 'password': password});
    await _startOnlineSession(client, res, knownPassword: password);
  }

  /// Dev/demo-only password reset — see `backend/src/routes/auth.js` for why
  /// (no real mail service is wired up, so `code` is a fixed, publicly-known
  /// value rather than something actually emailed). Updates the real stored
  /// password for that account; doesn't log the caller in. Throws
  /// [ApiException] on failure (wrong code, no such account).
  Future<void> resetPasswordOnBackend({
    required String email,
    required String code,
    required String newPassword,
  }) {
    final client = apiClientFactory();
    return client.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  /// Called once at app start: if a token was saved from a previous session
  /// and it's still valid, resumes that session silently. Never throws —
  /// any failure (no saved token, expired token, backend unreachable) just
  /// leaves the app in its normal logged-out state.
  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenPrefsKey);
      if (token == null) return;
      final client = apiClientFactory()..token = token;
      final res = await client.get('/auth/me') as Map<String, dynamic>;
      await _applySession(client, res['user'] as Map<String, dynamic>);
    } catch (_) {
      // Fall back to the normal (logged-out) start-up path.
    }
  }

  Future<void> _startOnlineSession(
    ApiClient client,
    dynamic authResponse, {
    required String knownPassword,
  }) async {
    client.token = authResponse['token'] as String;
    await _applySession(
      client,
      authResponse['user'] as Map<String, dynamic>,
      knownPassword: knownPassword,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefsKey, client.token!);
  }

  Future<void> _applySession(
    ApiClient client,
    Map<String, dynamic> user, {
    String? knownPassword,
  }) async {
    api = client;
    profile = Profile(
      name: user['name'] as String,
      username: user['username'] as String,
      email: user['email'] as String,
      password: knownPassword ?? hiddenPasswordPlaceholder,
      phone: user['phone'] as String? ?? '',
      avatar: user['avatar'] as String? ?? 'assets/images/avatar.png',
    );
    isAdmin = user['role'] == 'admin';
    uploadAttempts = user['uploadAttempts'] as int? ?? 0;
    _unlocked
      ..clear()
      ..addAll((user['unlockedPacks'] as List? ?? const []).cast<String>());
    _answered.clear();
    _correct.clear();
    final progress = user['progress'] as Map<String, dynamic>? ?? const {};
    for (final entry in progress.entries) {
      final p = entry.value as Map<String, dynamic>;
      _answered[entry.key] = p['answered'] as int? ?? 0;
      _correct[entry.key] = p['correct'] as int? ?? 0;
    }
    await _loadCatalog();
    loggedIn = true;
    notifyListeners();
  }

  Future<void> _loadCatalog() async {
    final client = api;
    if (client == null) return;
    final results = await Future.wait([
      client.get('/tracks'),
      client.get('/packs'),
      client.get('/books'),
      client.get('/about'),
      client.get('/questions'),
    ]);
    tracks = ((results[0] as Map)['tracks'] as List)
        .map((j) => Track.fromJson(j as Map<String, dynamic>))
        .toList();
    examPacks = ((results[1] as Map)['packs'] as List)
        .map((j) => ExamPack.fromJson(j as Map<String, dynamic>))
        .toList();
    books = ((results[2] as Map)['books'] as List)
        .map((j) => EBook.fromJson(j as Map<String, dynamic>))
        .toList();
    final aboutJson = (results[3] as Map)['about'];
    if (aboutJson != null) aboutInfo = AboutInfo.fromJson(aboutJson as Map<String, dynamic>);
    questions = ((results[4] as Map)['questions'] as List)
        .map((j) => Question.fromJson(j as Map<String, dynamic>))
        .toList();
    if (tracks.isNotEmpty && !tracks.any((t) => t.id == trackId)) {
      trackId = tracks.first.id;
    }
  }

  Future<void> _clearPersistedToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefsKey);
  }

  void chooseTrack(String id) {
    trackId = id;
    notifyListeners();
  }

  void updateProfile(Profile value) {
    final client = api;
    if (client != null) {
      final changedPassword =
          value.password.isNotEmpty && value.password != hiddenPasswordPlaceholder;
      client.put('/auth/me', {
        'name': value.name,
        'username': value.username,
        'email': value.email,
        'phone': value.phone,
        if (changedPassword) 'password': value.password,
      }).catchError((Object e) => _syncFailed(e));
    }
    profile = value;
    notifyListeners();
  }

  void setAvatar(String assetPath) {
    profile.avatar = assetPath;
    api?.put('/auth/me', {'avatar': assetPath}).catchError((Object e) => _syncFailed(e));
    notifyListeners();
  }

  void updateAboutInfo(AboutInfo value) {
    aboutInfo = value;
    api?.put('/about', {
      'version': value.version,
      'intro': value.intro,
      'features': value.features,
      'unlocking': value.unlocking,
      'supportEmail': value.supportEmail,
      'supportTelegram': value.supportTelegram,
      'supportPhone': value.supportPhone,
      'footer': value.footer,
    }).catchError((Object e) => _syncFailed(e));
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
    api?.post('/tracks', {'id': t.id, 'name': t.name, 'figure': t.figure})
        .catchError((Object e) => _syncFailed(e));
    notifyListeners();
  }

  void updateTrack(Track t) {
    final i = tracks.indexWhere((e) => e.id == t.id);
    if (i != -1) {
      tracks[i] = t;
      api?.put('/tracks/${t.id}', {'name': t.name, 'figure': t.figure})
          .catchError((Object e) => _syncFailed(e));
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
    api?.delete('/tracks/$id').catchError((Object e) => _syncFailed(e));
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
    api?.post('/packs', {
      'id': pack.id,
      'trackId': pack.trackId,
      'title': pack.title,
      'image': pack.image,
      'questionCount': pack.questionCount,
      'priceBirr': pack.priceBirr,
      'freeLimit': pack.freeLimit,
    }).catchError((Object e) => _syncFailed(e));
    notifyListeners();
  }

  void updatePack(ExamPack pack) {
    final i = examPacks.indexWhere((e) => e.id == pack.id);
    if (i != -1) {
      examPacks[i] = pack;
      api?.put('/packs/${pack.id}', {
        'trackId': pack.trackId,
        'title': pack.title,
        'image': pack.image,
        'questionCount': pack.questionCount,
        'priceBirr': pack.priceBirr,
        'freeLimit': pack.freeLimit,
      }).catchError((Object e) => _syncFailed(e));
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
    api?.delete('/packs/$id').catchError((Object e) => _syncFailed(e));
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
    _syncBook(book, isNew: true);
    notifyListeners();
  }

  void updateBook(EBook book) {
    final i = books.indexWhere((e) => e.id == book.id);
    if (i != -1) {
      books[i] = book;
      _syncBook(book, isNew: false);
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
    api?.delete('/books/$id').catchError((Object e) => _syncFailed(e));
    notifyListeners();
  }

  /// Background sync for a created/edited book. PDFs travel to the backend
  /// as base64 (`pdfData`) regardless of whether this device is holding them
  /// as raw bytes (web) or as a saved on-device file (native) — see
  /// `pdf_store.dart`.
  Future<void> _syncBook(EBook book, {required bool isNew}) async {
    final client = api;
    if (client == null) return;
    try {
      final bytes = book.pdfBytes ?? await readSavedPdf(book.pdfPath);
      final body = {
        if (isNew) 'id': book.id,
        'title': book.title,
        'priceBirr': book.priceBirr,
        'cover': book.cover,
        'subjects': book.subjects,
        'pages': book.pages,
        'freePages': book.freePages,
        'pdfData': bytes != null ? base64Encode(bytes) : null,
        'pdfName': book.pdfName,
      };
      if (isNew) {
        await client.post('/books', body);
      } else {
        await client.put('/books/${book.id}', body);
      }
    } catch (e) {
      _syncFailed(e);
    }
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

  /// Whether the question at [index] (0-based) is behind the paywall. Locked
  /// when the pack isn't unlocked AND either the free answers are used up OR the
  /// question sits past the free window — so skipping ahead with "Next" without
  /// answering can't reveal questions beyond the free limit.
  bool questionLocked(ExamPack pack, int index) =>
      !isUnlocked(pack.id) &&
      (answered(pack.id) >= pack.freeLimit || index >= pack.freeLimit);

  /// The highest question index a learner may open right now (0-based).
  int maxReachableIndex(ExamPack pack) => isUnlocked(pack.id)
      ? pack.questionCount - 1
      : pack.freeLimit.clamp(0, pack.questionCount - 1);

  double progress(ExamPack pack) =>
      (answered(pack.id) / pack.questionCount).clamp(0, 1);

  void recordAnswer({required String packId, required bool wasCorrect}) {
    _answered[packId] = (_answered[packId] ?? 0) + 1;
    if (wasCorrect) {
      _correct[packId] = (_correct[packId] ?? 0) + 1;
    }
    api?.put('/exam/packs/$packId/progress', {
      'answered': _answered[packId],
      'correct': _correct[packId] ?? 0,
    }).catchError((Object e) => _syncFailed(e));
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
    final local = q.id.isEmpty
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
        : q;
    questions.add(local);
    final client = api;
    if (client != null) {
      client.post('/questions', local.toJson()).then((res) {
        // The server assigns its own id — swap the locally-generated one for
        // the real one so later edits/deletes target the right document.
        final created = Question.fromJson((res as Map)['question'] as Map<String, dynamic>);
        final i = questions.indexWhere((e) => e.id == local.id);
        if (i != -1) questions[i] = created;
        notifyListeners();
      }).catchError((Object e) {
        _syncFailed(e);
      });
    }
    notifyListeners();
  }

  void updateQuestion(Question q) {
    final i = questions.indexWhere((e) => e.id == q.id);
    if (i != -1) {
      questions[i] = q;
      api?.put('/questions/${q.id}', q.toJson()).catchError((Object e) => _syncFailed(e));
      notifyListeners();
    }
  }

  void deleteQuestion(String id) {
    questions.removeWhere((q) => q.id == id);
    api?.delete('/questions/$id').catchError((Object e) => _syncFailed(e));
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
    String receiptImage = '',
  }) {
    final req = PaymentRequest(
      id: _newId('pay'),
      userName: profile.name,
      packId: pack.id,
      packTitle: pack.title,
      bankCode: bankCode,
      amountBirr: pack.priceBirr,
      submittedAt: DateTime.now(),
      receiptImage: receiptImage,
    );
    paymentRequests.add(req);
    final client = api;
    if (client != null) {
      client.post('/payments', {
        'packId': pack.id,
        'packTitle': pack.title,
        'bankCode': bankCode,
        'amountBirr': pack.priceBirr,
        'receiptImage': receiptImage,
      }).then((res) {
        // Swap the locally-generated id for the server's real one so a later
        // admin decision (which targets the server) can find it again.
        final created = PaymentRequest.fromJson((res as Map)['request'] as Map<String, dynamic>);
        final i = paymentRequests.indexWhere((r) => r.id == req.id);
        if (i != -1) paymentRequests[i] = created;
        notifyListeners();
      }).catchError((Object e) {
        _syncFailed(e);
      });
    }
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
    api?.put('/payments/$requestId/decide', {
      'status': decision == PaymentStatus.approved ? 'approved' : 'rejected',
    }).catchError((Object e) => _syncFailed(e));
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
