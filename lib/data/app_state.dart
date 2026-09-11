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

/// Result of [AppState.fetchExamQuestion] — exactly one of `locked` or
/// `question` is meaningful: a locked index never carries question content.
class ExamQuestionFetch {
  const ExamQuestionFetch({required this.locked, required this.question});
  final bool locked;
  final Question? question;
}

/// Result of [AppState.fetchBookDetail] — [book]'s `pages`/PDF are truncated
/// to the free preview unless [unlocked].
class BookDetailFetch {
  const BookDetailFetch({required this.book, required this.unlocked});
  final EBook book;
  final bool unlocked;
}

/// One day's worth of dashboard "This Week" activity.
class WeeklyActivityDay {
  const WeeklyActivityDay({required this.weekday, required this.count});
  final String weekday; // a single letter: M, T, W, …
  final int count;
}

/// One entry in the dashboard's "Recent Activity" list — a single question
/// that was actually answered, not a fabricated example.
class ActivityEntry {
  const ActivityEntry({
    required this.packTitle,
    required this.wasCorrect,
    required this.at,
  });
  final String packTitle;
  final bool wasCorrect;
  final DateTime at;
}

/// Result of [AppState.fetchDashboardActivity].
class DashboardActivity {
  const DashboardActivity({required this.week, required this.recent});
  final List<WeeklyActivityDay> week;
  final List<ActivityEntry> recent;
}

/// Result of [AppState.fetchRank] — 1-based position on the leaderboard.
class RankFetch {
  const RankFetch({required this.rank, required this.totalUsers});
  final int rank;
  final int totalUsers;
}

/// One row on the admin "Users" page — a summary of a real account. See
/// [AppState.fetchAllUsers].
class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.role,
    required this.createdAt,
    required this.unlockedPacks,
    required this.totalAnswered,
    required this.totalCorrect,
    required this.currentStreak,
    required this.bestStreak,
  });

  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String avatar;
  final String role;
  final DateTime createdAt;
  final List<String> unlockedPacks;
  final int totalAnswered;
  final int totalCorrect;
  final int currentStreak;
  final int bestStreak;

  bool get isAdmin => role == 'admin';

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) => AdminUserSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String? ?? '',
        avatar: json['avatar'] as String? ?? 'assets/images/avatar.png',
        role: json['role'] as String? ?? 'user',
        createdAt: DateTime.parse(json['createdAt'] as String),
        unlockedPacks: (json['unlockedPacks'] as List? ?? const []).cast<String>(),
        totalAnswered: json['totalAnswered'] as int? ?? 0,
        totalCorrect: json['totalCorrect'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
      );
}

/// Result of [AppState.fetchUserActivity] — one user's real activity, for
/// the admin "Users" detail page (same shape as the dashboard's own
/// activity, just for an arbitrary user rather than the caller).
class AdminUserActivity {
  const AdminUserActivity({
    required this.user,
    required this.week,
    required this.recent,
  });
  final AdminUserSummary user;
  final List<WeeklyActivityDay> week;
  final List<ActivityEntry> recent;
}

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

  /// The live bank accounts users transfer payment to. Seeded from
  /// [MockData]; the admin panel mutates it.
  List<BankAccount> banks = MockData.seedBanks();

  /// Receipts uploaded by users, for the admin to approve or reject.
  final List<PaymentRequest> paymentRequests = [];

  /// The current user's own Q&A thread — questions they've asked and any
  /// answers back. Seeded with a couple of demo entries so the screen isn't
  /// empty offline; online, [fetchMyQuestions] replaces this with the real
  /// thread. The admin "all questions" view is fetched separately (see
  /// [fetchAllQuestions]) since offline there's only ever this one learner.
  List<QaItem> qaItems = MockData.seedQaItems();

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

  /// The current and longest-ever run of consecutive correct answers,
  /// across every pack (a single global "study streak", not per-pack).
  /// Tracked locally in [recordAnswer] regardless of online/offline mode —
  /// this one is real either way, not just when there's a backend.
  int currentStreak = 0;
  int bestStreak = 0;

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
    currentStreak = user['currentStreak'] as int? ?? 0;
    bestStreak = user['bestStreak'] as int? ?? 0;
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
      client.get('/banks'),
      // Full question content (including every answer) is only fetched in
      // bulk for an admin session, for the question-bank CRUD screens. A
      // learner's exam instead fetches one gated question at a time via
      // `fetchExamQuestion` — see "The paywall" in backend/README.md.
      if (isAdmin) client.get('/questions'),
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
    banks = ((results[4] as Map)['banks'] as List)
        .map((j) => BankAccount.fromJson(j as Map<String, dynamic>))
        .toList();
    questions = isAdmin
        ? ((results[5] as Map)['questions'] as List)
            .map((j) => Question.fromJson(j as Map<String, dynamic>))
            .toList()
        : [];
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
      'marqueeText': value.marqueeText,
      'onboardingSubtitle': value.onboardingSubtitle,
    }).catchError((Object e) => _syncFailed(e));
    notifyListeners();
  }

  // --- Bank accounts (admin CRUD) ---------------------------------------

  BankAccount? bankByCode(String code) {
    for (final b in banks) {
      if (b.code == code) return b;
    }
    return null;
  }

  void addBank(BankAccount b) {
    banks.add(b);
    api?.post('/banks', {
      'id': b.code,
      'name': b.name,
      'owner': b.owner,
      'number': b.number,
    }).catchError((Object e) {
      _syncFailed(e);
    });
    notifyListeners();
  }

  void updateBank(BankAccount b) {
    final i = banks.indexWhere((e) => e.code == b.code);
    if (i != -1) {
      banks[i] = b;
      api?.put('/banks/${b.code}', {
        'name': b.name,
        'owner': b.owner,
        'number': b.number,
      }).catchError((Object e) {
        _syncFailed(e);
      });
      notifyListeners();
    }
  }

  void deleteBank(String code) {
    banks.removeWhere((b) => b.code == code);
    api?.delete('/banks/$code').catchError((Object e) {
      _syncFailed(e);
    });
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
      'aboutSummary': pack.aboutSummary,
      'aboutBullets': pack.aboutBullets,
      'coreCourses': pack.coreCourses,
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
        'aboutSummary': pack.aboutSummary,
        'aboutBullets': pack.aboutBullets,
        'coreCourses': pack.coreCourses,
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

  /// Fetches a single book's full-or-gated content — server-gated when
  /// online (the catalog's bulk `books` list only ever carries metadata for
  /// a non-admin session — see `_loadCatalog` — so this is the only source
  /// of page/PDF content for a learner reading a book online). Callers
  /// should only use this when [isOnline]; offline callers already have
  /// full content via [bookById].
  Future<BookDetailFetch> fetchBookDetail(String bookId) async {
    final res = await api!.get('/books/$bookId') as Map<String, dynamic>;
    final json = res['book'] as Map<String, dynamic>;
    return BookDetailFetch(
      book: EBook.fromJson(json),
      unlocked: json['unlocked'] as bool? ?? false,
    );
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
      currentStreak++;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
    } else {
      currentStreak = 0;
    }
    final client = api;
    if (client != null) {
      client.post('/exam/packs/$packId/record-answer', {
        'wasCorrect': wasCorrect,
        'packTitle': packById(packId)?.title ?? '',
      }).catchError((Object e) {
        _syncFailed(e);
      });
    }
    notifyListeners();
  }

  /// Fetches the dashboard's "This Week"/"Recent Activity" data. Only
  /// meaningful when [isOnline] — offline there's no persisted history to
  /// fetch (progress resets on restart same as everything else offline), so
  /// callers should keep their own local/demo fallback for that case.
  Future<DashboardActivity> fetchDashboardActivity() async {
    final res = await api!.get('/exam/activity') as Map<String, dynamic>;
    final week = (res['week'] as List)
        .map((j) => WeeklyActivityDay(
              weekday: (j as Map)['weekday'] as String,
              count: j['count'] as int,
            ))
        .toList();
    final recent = (res['recent'] as List)
        .map((j) => ActivityEntry(
              packTitle: (j as Map)['packTitle'] as String,
              wasCorrect: j['wasCorrect'] as bool,
              at: DateTime.parse(j['at'] as String),
            ))
        .toList();
    return DashboardActivity(week: week, recent: recent);
  }

  /// Fetches the caller's real leaderboard position. Offline there's only
  /// ever one (local, demo) learner, so this returns a trivial `1 of 1`
  /// without a network call.
  Future<RankFetch> fetchRank() async {
    if (!isOnline) return const RankFetch(rank: 1, totalUsers: 1);
    final res = await api!.get('/leaderboard/me') as Map<String, dynamic>;
    return RankFetch(rank: res['rank'] as int, totalUsers: res['totalUsers'] as int);
  }

  // --- Admin: user management ("Users" page) ----------------------------

  /// Every real account — the admin "Users" page. Only ever meaningful
  /// online (there's only ever one local/demo user offline).
  Future<List<AdminUserSummary>> fetchAllUsers() async {
    final res = await api!.get('/users') as Map<String, dynamic>;
    return (res['users'] as List)
        .map((j) => AdminUserSummary.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// One user's real activity — what they've actually been doing, with
  /// dates — for the admin "Users" detail page.
  Future<AdminUserActivity> fetchUserActivity(String userId) async {
    final res = await api!.get('/users/$userId/activity') as Map<String, dynamic>;
    return AdminUserActivity(
      user: AdminUserSummary.fromJson(res['user'] as Map<String, dynamic>),
      week: (res['week'] as List)
          .map((j) => WeeklyActivityDay(
                weekday: (j as Map)['weekday'] as String,
                count: j['count'] as int,
              ))
          .toList(),
      recent: (res['recent'] as List)
          .map((j) => ActivityEntry(
                packTitle: (j as Map)['packTitle'] as String,
                wasCorrect: j['wasCorrect'] as bool,
                at: DateTime.parse(j['at'] as String),
              ))
          .toList(),
    );
  }

  /// Directly grants or revokes one pack/book for one user — the admin
  /// "open"/"close" access control, independent of any specific payment
  /// request (that flow still works too; this corrects or overrides it, or
  /// grants access outright). Returns the user's updated unlocked-pack list.
  Future<List<String>> setUserAccess({
    required String userId,
    required String packId,
    required bool unlock,
  }) async {
    final res = await api!.put('/users/$userId/access', {
      'packId': packId,
      'unlock': unlock,
    }) as Map<String, dynamic>;
    final user = res['user'] as Map<String, dynamic>;
    return (user['unlockedPacks'] as List).cast<String>();
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

  /// Fetches a single exam question the way [ExamScreen] actually needs it:
  /// gated server-side when online (a locked index never leaves the server
  /// at all — see `GET /api/exam/packs/:id/questions/:index` and "The
  /// paywall" in backend/README.md), or the existing fully-local logic when
  /// offline. Bulk `questions` is never fetched for a non-admin online
  /// session (see `_loadCatalog`), so this is the only source of question
  /// content for a learner taking an exam online.
  Future<ExamQuestionFetch> fetchExamQuestion({
    required ExamPack pack,
    required int index,
  }) async {
    if (!isOnline) {
      final locked = questionLocked(pack, index);
      return ExamQuestionFetch(
        locked: locked,
        question: locked ? null : examQuestion(pack, index),
      );
    }
    final res = await api!.get('/exam/packs/${pack.id}/questions/$index') as Map<String, dynamic>;
    final locked = res['locked'] as bool;
    return ExamQuestionFetch(
      locked: locked,
      question: locked ? null : Question.fromJson(res['question'] as Map<String, dynamic>),
    );
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

  // --- Q&A ("Ask a question" screen + admin management) -----------------

  /// Asks a question from the current user. Shows up locally right away;
  /// syncs in the background when online (and swaps the locally-generated
  /// id for the server's real one, same as [submitPaymentRequest], so a
  /// later admin answer — which targets the server id — can find it again).
  void askQuestion(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final item = QaItem(
      id: _newId('qa'),
      askedByName: profile.name,
      question: trimmed,
      createdAt: DateTime.now(),
    );
    qaItems.insert(0, item);
    final client = api;
    if (client != null) {
      client.post('/qa', {'question': trimmed}).then((res) {
        final created =
            QaItem.fromJson((res as Map)['question'] as Map<String, dynamic>);
        final i = qaItems.indexWhere((q) => q.id == item.id);
        if (i != -1) qaItems[i] = created;
        notifyListeners();
      }).catchError((Object e) {
        _syncFailed(e);
      });
    }
    notifyListeners();
  }

  /// Refetches the current user's own Q&A thread from the backend — call
  /// when opening the Q&A screen online so it shows what's really there
  /// (an answer given from another device/session, for instance), not just
  /// whatever happened to already be in memory.
  Future<void> fetchMyQuestions() async {
    if (!isOnline) return;
    final res = await api!.get('/qa/mine') as Map<String, dynamic>;
    qaItems = (res['questions'] as List)
        .map((j) => QaItem.fromJson(j as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  /// Admin: every question from every learner. Online-only — offline there's
  /// only ever this one demo learner, so the admin Q&A screen falls back to
  /// [qaItems] directly rather than calling this.
  Future<List<QaItem>> fetchAllQuestions() async {
    final res = await api!.get('/qa') as Map<String, dynamic>;
    return (res['questions'] as List)
        .map((j) => QaItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Admin: answers (or edits a previous answer to) a question. Updates the
  /// local copy if it happens to be in [qaItems] (the offline/self-answer
  /// case); the admin Q&A screen otherwise manages its own fetched list and
  /// applies the returned item itself.
  Future<QaItem> answerQuestion({required String id, required String answer}) async {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) {
      throw ApiException('An answer is required.');
    }
    QaItem updated;
    if (isOnline) {
      final res =
          await api!.put('/qa/$id/answer', {'answer': trimmed}) as Map<String, dynamic>;
      updated = QaItem.fromJson(res['question'] as Map<String, dynamic>);
    } else {
      final i = qaItems.indexWhere((q) => q.id == id);
      if (i == -1) throw ApiException('Question not found.');
      qaItems[i]
        ..answer = trimmed
        ..status = QaStatus.answered
        ..answeredAt = DateTime.now();
      updated = qaItems[i];
    }
    final i = qaItems.indexWhere((q) => q.id == id);
    if (i != -1) qaItems[i] = updated;
    notifyListeners();
    return updated;
  }

  /// Admin: removes a question (spam, duplicate, etc.).
  void deleteQuestionThread(String id) {
    qaItems.removeWhere((q) => q.id == id);
    api?.delete('/qa/$id').catchError((Object e) => _syncFailed(e));
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
