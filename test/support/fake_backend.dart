// A minimal in-memory stand-in for the real Node/Express backend
// (`backend/`), so widget/unit tests can exercise `AppState`'s online
// auth/sync paths (`authSignUp`, `authLogin`, `tryAutoLogin`, and every
// background-sync call they trigger) without a real server or network.
//
// Install it via `AppState().apiClientFactory = fakeBackend.client;` (or
// pass a pre-populated [FakeBackend] to reuse the same fake data/session
// across a test's setup and its assertions).
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dodo_pharmacy_mobile_app/data/api_client.dart';

class FakeBackend {
  FakeBackend();

  /// email -> user record (including the plaintext password — this is a
  /// test double, not a real auth system).
  final Map<String, Map<String, dynamic>> users = {};
  int _idSeq = 0;

  final List<Map<String, dynamic>> tracks = [];
  final List<Map<String, dynamic>> packs = [];
  final List<Map<String, dynamic>> books = [];
  final List<Map<String, dynamic>> questions = [];
  final List<Map<String, dynamic>> payments = [];
  final List<Map<String, dynamic>> banks = [];
  final List<Map<String, dynamic>> qaQuestions = [];
  Map<String, dynamic>? about;

  /// Builds an [ApiClient] backed by this fake — pass as
  /// `AppState().apiClientFactory`.
  ApiClient client() => ApiClient(baseUrl: 'http://fake/api', client: MockClient(_handle));

  Map<String, dynamic> _userJson(Map<String, dynamic> u) => {
        'id': u['id'],
        'name': u['name'],
        'username': u['username'],
        'email': u['email'],
        'phone': u['phone'] ?? '',
        'avatar': u['avatar'] ?? 'assets/images/avatar.png',
        'role': u['role'],
        'unlockedPacks': u['unlockedPacks'] ?? [],
        'uploadAttempts': u['uploadAttempts'] ?? 0,
        'progress': u['progress'] ?? {},
        'currentStreak': u['currentStreak'] ?? 0,
        'bestStreak': u['bestStreak'] ?? 0,
      };

  // Mirrors backend/src/routes/users.js's `summarize` — createdAt isn't
  // tracked per-user in this fake, so it's synthesized as "now" (tests that
  // care about it seed their own value on the user map first).
  Map<String, dynamic> _adminUserJson(Map<String, dynamic> u) {
    var totalAnswered = 0;
    var totalCorrect = 0;
    final progress = u['progress'] as Map<String, dynamic>? ?? {};
    for (final entry in progress.values) {
      final e = entry as Map<String, dynamic>;
      totalAnswered += e['answered'] as int? ?? 0;
      totalCorrect += e['correct'] as int? ?? 0;
    }
    return {
      'id': u['id'],
      'name': u['name'],
      'username': u['username'],
      'email': u['email'],
      'phone': u['phone'] ?? '',
      'avatar': u['avatar'] ?? 'assets/images/avatar.png',
      'role': u['role'],
      'createdAt':
          (u['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      'unlockedPacks': u['unlockedPacks'] ?? [],
      'totalAnswered': totalAnswered,
      'totalCorrect': totalCorrect,
      'currentStreak': u['currentStreak'] ?? 0,
      'bestStreak': u['bestStreak'] ?? 0,
    };
  }

  http.Response _ok(Object json, [int code = 200]) =>
      http.Response(jsonEncode(json), code, headers: {'content-type': 'application/json'});

  Map<String, dynamic>? _userForToken(String? authHeader) {
    if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;
    final token = authHeader.substring(7);
    for (final u in users.values) {
      if (u['token'] == token) return u;
    }
    return null;
  }

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api', '');
    final body = req.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(req.body) as Map<String, dynamic>;
    final caller = _userForToken(req.headers['Authorization']);

    if (req.method == 'POST' && path == '/auth/signup') {
      final email = (body['email'] as String).trim().toLowerCase();
      if (users.containsKey(email)) {
        return _ok({'error': 'An account with that email already exists.'}, 409);
      }
      final user = {
        'id': 'u${_idSeq++}',
        'name': body['name'],
        'username': body['username'],
        'email': email,
        'password': body['password'],
        'phone': body['phone'] ?? '',
        'role': email.startsWith('admin') ? 'admin' : 'user',
        'avatar': 'assets/images/avatar.png',
        'unlockedPacks': <String>[],
        'uploadAttempts': 0,
        'progress': <String, dynamic>{},
        'currentStreak': 0,
        'bestStreak': 0,
        'dailyActivity': <String, int>{},
        'recentActivity': <Map<String, dynamic>>[],
        'token': 'tok-$email',
      };
      users[email] = user;
      return _ok({'token': user['token'], 'user': _userJson(user)}, 201);
    }

    if (req.method == 'POST' && path == '/auth/login') {
      final email = (body['email'] as String).trim().toLowerCase();
      final user = users[email];
      if (user == null || user['password'] != body['password']) {
        return _ok({'error': 'Invalid email or password.'}, 401);
      }
      return _ok({'token': user['token'], 'user': _userJson(user)});
    }

    if (req.method == 'POST' && path == '/auth/reset-password') {
      final email = (body['email'] as String).trim().toLowerCase();
      if (body['code'] != '1234') {
        return _ok({'error': 'Incorrect code. (Demo code is 1234.)'}, 400);
      }
      final user = users[email];
      if (user == null) return _ok({'error': 'No account with that email.'}, 404);
      user['password'] = body['newPassword'];
      return _ok({'ok': true});
    }

    if (req.method == 'GET' && path == '/auth/me') {
      if (caller == null) return _ok({'error': 'Invalid or expired token.'}, 401);
      return _ok({'user': _userJson(caller)});
    }

    if (req.method == 'PUT' && path == '/auth/me') {
      if (caller == null) return _ok({'error': 'Invalid or expired token.'}, 401);
      for (final key in ['name', 'username', 'phone', 'avatar']) {
        if (body.containsKey(key)) caller[key] = body[key];
      }
      if (body['email'] != null) caller['email'] = (body['email'] as String).toLowerCase();
      if (body['password'] != null) caller['password'] = body['password'];
      return _ok({'user': _userJson(caller)});
    }

    if (req.method == 'GET' && path == '/tracks') return _ok({'tracks': tracks});
    if (req.method == 'GET' && path == '/packs') return _ok({'packs': packs});
    if (req.method == 'GET' && path == '/about') return _ok({'about': about});
    if (req.method == 'GET' && path == '/banks') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      return _ok({'banks': banks});
    }

    // Metadata-only for the bulk list unless the caller is an admin — mirrors
    // backend/src/routes/books.js so `AppState._loadCatalog` behaves the
    // same against this fake as against the real server.
    if (req.method == 'GET' && path == '/books') {
      final isAdmin = caller?['role'] == 'admin';
      return _ok({
        'books': books.map((b) {
          final json = {...b, 'pageCount': (b['pages'] as List).length};
          if (!isAdmin) {
            json['pages'] = <String>[];
            json['pdfData'] = null;
          }
          return json;
        }).toList(),
      });
    }

    // Admin-only bulk question content — mirrors backend/src/routes/questions.js.
    if (req.method == 'GET' && path == '/questions') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      if (caller['role'] != 'admin') return _ok({'error': 'Admin access required.'}, 403);
      return _ok({'questions': questions});
    }

    // Generic CRUD for the slug-keyed collections (id may be client-supplied
    // — see backend/README.md — or generated here otherwise).
    final trackMatch = RegExp(r'^/tracks/(.+)$').firstMatch(path);
    final packMatch = RegExp(r'^/packs/(.+)$').firstMatch(path);
    final bookMatch = RegExp(r'^/books/([^/]+)$').firstMatch(path);
    final questionMatch = RegExp(r'^/questions/(.+)$').firstMatch(path);
    final bankMatch = RegExp(r'^/banks/(.+)$').firstMatch(path);

    // Gated single-book fetch — mirrors backend/src/routes/books.js.
    if (req.method == 'GET' && bookMatch != null) {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      final b = books.firstWhere(
        (e) => e['id'] == bookMatch.group(1),
        orElse: () => <String, dynamic>{},
      );
      if (b.isEmpty) return _ok({'error': 'Book not found.'}, 404);
      final unlockedPacks = (caller['unlockedPacks'] as List).cast<String>();
      final unlocked = unlockedPacks.contains(b['id']) || caller['role'] == 'admin';
      final json = {...b, 'pageCount': (b['pages'] as List).length, 'unlocked': unlocked};
      if (!unlocked) {
        json['pdfData'] = null;
        final freePages = b['freePages'] as int? ?? 4;
        json['pages'] = (b['pages'] as List).cast<String>().take(freePages).toList();
      }
      return _ok({'book': json});
    }

    if (req.method == 'POST' && path == '/tracks') {
      final t = {'id': body['id'] ?? 'track-${_idSeq++}', 'name': body['name'], 'figure': body['figure'] ?? ''};
      tracks.add(t);
      return _ok({'track': t}, 201);
    }
    if (req.method == 'PUT' && trackMatch != null) {
      final t = tracks.firstWhere((e) => e['id'] == trackMatch.group(1));
      t.addAll({'name': body['name'] ?? t['name'], 'figure': body['figure'] ?? t['figure']});
      return _ok({'track': t});
    }
    if (req.method == 'POST' && path == '/banks') {
      final id = ((body['id'] as String?) ?? '').trim().isEmpty
          ? 'bank-${_idSeq++}'
          : (body['id'] as String).trim();
      final b = {'id': id, 'name': body['name'], 'owner': body['owner'], 'number': body['number']};
      banks.add(b);
      return _ok({'bank': b}, 201);
    }
    if (req.method == 'PUT' && bankMatch != null) {
      final b = banks.firstWhere((e) => e['id'] == bankMatch.group(1));
      b.addAll({
        'name': body['name'] ?? b['name'],
        'owner': body['owner'] ?? b['owner'],
        'number': body['number'] ?? b['number'],
      });
      return _ok({'bank': b});
    }
    if (req.method == 'DELETE' && bankMatch != null) {
      banks.removeWhere((e) => e['id'] == bankMatch.group(1));
      return _ok({'ok': true});
    }

    if (req.method == 'DELETE' && trackMatch != null) {
      tracks.removeWhere((e) => e['id'] == trackMatch.group(1));
      return _ok({'ok': true});
    }

    if (req.method == 'POST' && path == '/packs') {
      final p = {
        'id': body['id'] ?? 'pack-${_idSeq++}',
        'trackId': body['trackId'] ?? '',
        'title': body['title'],
        'image': body['image'] ?? '',
        'questionCount': body['questionCount'],
        'priceBirr': body['priceBirr'],
        'freeLimit': body['freeLimit'],
        'aboutSummary': body['aboutSummary'] ?? '',
        'aboutBullets': body['aboutBullets'] ?? <String>[],
        'coreCourses': body['coreCourses'] ?? <String>[],
      };
      packs.add(p);
      return _ok({'pack': p}, 201);
    }
    if (req.method == 'PUT' && packMatch != null) {
      final p = packs.firstWhere((e) => e['id'] == packMatch.group(1));
      p.addAll(body);
      return _ok({'pack': p});
    }
    if (req.method == 'DELETE' && packMatch != null) {
      packs.removeWhere((e) => e['id'] == packMatch.group(1));
      return _ok({'ok': true});
    }

    if (req.method == 'POST' && path == '/books') {
      final b = {
        'id': body['id'] ?? 'book-${_idSeq++}',
        'title': body['title'],
        'priceBirr': body['priceBirr'],
        'cover': body['cover'] ?? '',
        'subjects': body['subjects'] ?? [],
        'pages': body['pages'] ?? [],
        'freePages': body['freePages'] ?? 4,
        'pdfData': body['pdfData'],
        'pdfName': body['pdfName'],
      };
      books.add(b);
      return _ok({'book': b}, 201);
    }
    if (req.method == 'PUT' && bookMatch != null) {
      final b = books.firstWhere((e) => e['id'] == bookMatch.group(1));
      b.addAll(body);
      return _ok({'book': b});
    }
    if (req.method == 'DELETE' && bookMatch != null) {
      books.removeWhere((e) => e['id'] == bookMatch.group(1));
      return _ok({'ok': true});
    }

    if (req.method == 'POST' && path == '/questions') {
      final q = {
        'id': 'q-${_idSeq++}',
        'packId': body['packId'],
        'number': body['number'] ?? 0,
        'total': body['total'] ?? 0,
        'prompt': body['prompt'],
        'options': body['options'],
        'correctIndex': body['correctIndex'],
        'explanation': body['explanation'],
      };
      questions.add(q);
      return _ok({'question': q}, 201);
    }
    if (req.method == 'PUT' && questionMatch != null) {
      final q = questions.firstWhere((e) => e['id'] == questionMatch.group(1));
      q.addAll(body);
      return _ok({'question': q});
    }
    if (req.method == 'DELETE' && questionMatch != null) {
      questions.removeWhere((e) => e['id'] == questionMatch.group(1));
      return _ok({'ok': true});
    }

    if (req.method == 'PUT' && path == '/about') {
      about = {...?about, ...body};
      return _ok({'about': about});
    }

    if (req.method == 'POST' && path == '/payments') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      final p = {
        'id': 'pay-${_idSeq++}',
        'userName': caller['name'],
        'packId': body['packId'],
        'packTitle': body['packTitle'],
        'bankCode': body['bankCode'],
        'amountBirr': body['amountBirr'],
        'submittedAt': DateTime.now().toIso8601String(),
        'status': 'pending',
        'receiptImage': body['receiptImage'] ?? '',
      };
      payments.add(p);
      return _ok({'request': p}, 201);
    }
    if (req.method == 'GET' && path == '/payments') return _ok({'requests': payments});

    final decideMatch = RegExp(r'^/payments/(.+)/decide$').firstMatch(path);
    if (req.method == 'PUT' && decideMatch != null) {
      final p = payments.firstWhere((e) => e['id'] == decideMatch.group(1));
      p['status'] = body['status'];
      final owner = users.values.firstWhere((u) => u['name'] == p['userName']);
      final unlocked = (owner['unlockedPacks'] as List).cast<String>();
      if (body['status'] == 'approved') {
        if (!unlocked.contains(p['packId'])) unlocked.add(p['packId'] as String);
      } else {
        unlocked.remove(p['packId']);
      }
      return _ok({'request': p});
    }

    final progressMatch = RegExp(r'^/exam/packs/(.+)/progress$').firstMatch(path);
    if (req.method == 'PUT' && progressMatch != null) {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      final progress = caller['progress'] as Map<String, dynamic>;
      progress[progressMatch.group(1)!] = {'answered': body['answered'], 'correct': body['correct']};
      return _ok({'ok': true});
    }

    // What AppState.recordAnswer actually calls — mirrors
    // backend/src/routes/exam.js's record-answer route.
    final recordMatch = RegExp(r'^/exam/packs/([^/]+)/record-answer$').firstMatch(path);
    if (req.method == 'POST' && recordMatch != null) {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      final packId = recordMatch.group(1)!;
      final pack = packs.firstWhere((p) => p['id'] == packId, orElse: () => <String, dynamic>{});
      if (pack.isEmpty) return _ok({'error': 'Pack not found.'}, 404);
      final wasCorrect = body['wasCorrect'] as bool;

      final progress = caller['progress'] as Map<String, dynamic>;
      final current = progress[packId] as Map<String, dynamic>? ?? {'answered': 0, 'correct': 0};
      progress[packId] = {
        'answered': (current['answered'] as int) + 1,
        'correct': (current['correct'] as int) + (wasCorrect ? 1 : 0),
      };

      if (wasCorrect) {
        caller['currentStreak'] = (caller['currentStreak'] as int? ?? 0) + 1;
        caller['bestStreak'] = [caller['bestStreak'] as int? ?? 0, caller['currentStreak'] as int]
            .reduce((a, b) => a > b ? a : b);
      } else {
        caller['currentStreak'] = 0;
      }

      final dayKey = DateTime.now().toIso8601String().substring(0, 10);
      final dailyActivity = (caller['dailyActivity'] as Map<String, dynamic>? ?? {});
      dailyActivity[dayKey] = (dailyActivity[dayKey] as int? ?? 0) + 1;
      caller['dailyActivity'] = dailyActivity;

      final recent = (caller['recentActivity'] as List? ?? []).cast<Map<String, dynamic>>();
      caller['recentActivity'] = [
        {
          'packId': packId,
          'packTitle': body['packTitle'] ?? pack['title'],
          'wasCorrect': wasCorrect,
          'at': DateTime.now().toIso8601String(),
        },
        ...recent,
      ].take(20).toList();

      return _ok({
        'answered': progress[packId]['answered'],
        'correct': progress[packId]['correct'],
        'currentStreak': caller['currentStreak'],
        'bestStreak': caller['bestStreak'],
      });
    }

    // Backs the dashboard's "This Week"/"Recent Activity" — mirrors
    // backend/src/routes/exam.js.
    if (req.method == 'GET' && path == '/exam/activity') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      const weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      final dailyActivity = (caller['dailyActivity'] as Map<String, dynamic>? ?? {});
      final today = DateTime.now();
      final week = [
        for (var i = 6; i >= 0; i--)
          () {
            final d = today.subtract(Duration(days: i));
            final key = d.toIso8601String().substring(0, 10);
            return {
              'date': key,
              'weekday': weekdayLetters[d.weekday % 7],
              'count': dailyActivity[key] ?? 0,
            };
          }(),
      ];
      return _ok({'week': week, 'recent': caller['recentActivity'] ?? []});
    }

    // Ranks every account by total correct answers — mirrors
    // backend/src/routes/leaderboard.js.
    if (req.method == 'GET' && path == '/leaderboard/me') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      final ranked = users.values.map((u) {
        final progress = u['progress'] as Map<String, dynamic>? ?? {};
        var correct = 0;
        for (final entry in progress.values) {
          correct += (entry as Map<String, dynamic>)['correct'] as int? ?? 0;
        }
        return MapEntry(u['id'], correct);
      }).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final position = ranked.indexWhere((e) => e.key == caller['id']);
      return _ok({
        'rank': position == -1 ? ranked.length : position + 1,
        'totalUsers': ranked.length,
      });
    }

    // The admin "Users" page — mirrors backend/src/routes/users.js.
    if (req.method == 'GET' && path == '/users') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      if (caller['role'] != 'admin') return _ok({'error': 'Admin access required.'}, 403);
      return _ok({'users': users.values.map(_adminUserJson).toList()});
    }

    final userActivityMatch = RegExp(r'^/users/([^/]+)/activity$').firstMatch(path);
    if (req.method == 'GET' && userActivityMatch != null) {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      if (caller['role'] != 'admin') return _ok({'error': 'Admin access required.'}, 403);
      final target = users.values.firstWhere(
        (u) => u['id'] == userActivityMatch.group(1),
        orElse: () => <String, dynamic>{},
      );
      if (target.isEmpty) return _ok({'error': 'User not found.'}, 404);

      const weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      final dailyActivity = (target['dailyActivity'] as Map<String, dynamic>? ?? {});
      final today = DateTime.now();
      final week = [
        for (var i = 6; i >= 0; i--)
          () {
            final d = today.subtract(Duration(days: i));
            final key = d.toIso8601String().substring(0, 10);
            return {
              'date': key,
              'weekday': weekdayLetters[d.weekday % 7],
              'count': dailyActivity[key] ?? 0,
            };
          }(),
      ];
      return _ok({
        'user': _adminUserJson(target),
        'week': week,
        'recent': target['recentActivity'] ?? [],
      });
    }

    final userAccessMatch = RegExp(r'^/users/([^/]+)/access$').firstMatch(path);
    if (req.method == 'PUT' && userAccessMatch != null) {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      if (caller['role'] != 'admin') return _ok({'error': 'Admin access required.'}, 403);
      final target = users.values.firstWhere(
        (u) => u['id'] == userAccessMatch.group(1),
        orElse: () => <String, dynamic>{},
      );
      if (target.isEmpty) return _ok({'error': 'User not found.'}, 404);
      final packId = body['packId'] as String?;
      final unlock = body['unlock'];
      if (packId == null || unlock is! bool) {
        return _ok({'error': 'packId and unlock (boolean) are required.'}, 400);
      }
      final known = packs.any((p) => p['id'] == packId) || books.any((b) => b['id'] == packId);
      if (!known) return _ok({'error': 'No pack or book with that id.'}, 404);

      final unlocked = (target['unlockedPacks'] as List).cast<String>();
      if (unlock && !unlocked.contains(packId)) unlocked.add(packId);
      if (!unlock && unlocked.contains(packId)) unlocked.remove(packId);
      target['unlockedPacks'] = unlocked;
      return _ok({'user': _adminUserJson(target)});
    }

    // Gated single-question fetch — mirrors backend/src/routes/exam.js.
    final examQuestionMatch = RegExp(r'^/exam/packs/([^/]+)/questions/(\d+)$').firstMatch(path);
    if (req.method == 'GET' && examQuestionMatch != null) {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      final packId = examQuestionMatch.group(1)!;
      final index = int.parse(examQuestionMatch.group(2)!);
      final pack = packs.firstWhere((p) => p['id'] == packId, orElse: () => <String, dynamic>{});
      if (pack.isEmpty) return _ok({'error': 'Pack not found.'}, 404);

      final unlockedPacks = (caller['unlockedPacks'] as List).cast<String>();
      final unlocked = unlockedPacks.contains(packId);
      final freeLimit = pack['freeLimit'] as int;
      final progress = caller['progress'] as Map<String, dynamic>;
      final answered = (progress[packId]?['answered'] as int?) ?? 0;
      final locked = !unlocked && (answered >= freeLimit || index >= freeLimit);
      if (locked) {
        return _ok({'locked': true, 'index': index, 'total': pack['questionCount']});
      }

      var pool = questions.where((q) => q['packId'] == packId).toList();
      if (pool.isEmpty) pool = questions;
      if (pool.isEmpty) return _ok({'error': 'No questions exist yet.'}, 404);
      final question = pool[index % pool.length];
      return _ok({
        'locked': false,
        'index': index,
        'total': pack['questionCount'],
        'question': question,
      });
    }

    // Q&A — mirrors backend/src/routes/qa.js.
    if (req.method == 'POST' && path == '/qa') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      final question = ((body['question'] as String?) ?? '').trim();
      if (question.isEmpty) return _ok({'error': 'question is required.'}, 400);
      final q = {
        'id': 'qa-${_idSeq++}',
        'userId': caller['id'],
        'userName': caller['name'],
        'question': question,
        'answer': '',
        'status': 'pending',
        'answeredAt': null,
        'createdAt': DateTime.now().toIso8601String(),
      };
      qaQuestions.add(q);
      return _ok({'question': q}, 201);
    }
    if (req.method == 'GET' && path == '/qa/mine') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      final mine = qaQuestions.where((q) => q['userId'] == caller['id']).toList()
        ..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
      return _ok({'questions': mine});
    }
    if (req.method == 'GET' && path == '/qa') {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      if (caller['role'] != 'admin') return _ok({'error': 'Admin access required.'}, 403);
      final all = List<Map<String, dynamic>>.from(qaQuestions)
        ..sort((a, b) {
          // Pending before answered, newest first within each group —
          // mirrors the real route's `{status: -1, createdAt: -1}` sort.
          final statusCmp = (b['status'] as String).compareTo(a['status'] as String);
          if (statusCmp != 0) return statusCmp;
          return (b['createdAt'] as String).compareTo(a['createdAt'] as String);
        });
      return _ok({'questions': all});
    }
    final qaAnswerMatch = RegExp(r'^/qa/([^/]+)/answer$').firstMatch(path);
    if (req.method == 'PUT' && qaAnswerMatch != null) {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      if (caller['role'] != 'admin') return _ok({'error': 'Admin access required.'}, 403);
      final answer = ((body['answer'] as String?) ?? '').trim();
      if (answer.isEmpty) return _ok({'error': 'answer is required.'}, 400);
      final q = qaQuestions.firstWhere(
        (e) => e['id'] == qaAnswerMatch.group(1),
        orElse: () => <String, dynamic>{},
      );
      if (q.isEmpty) return _ok({'error': 'Question not found.'}, 404);
      q['answer'] = answer;
      q['status'] = 'answered';
      q['answeredAt'] = DateTime.now().toIso8601String();
      return _ok({'question': q});
    }
    final qaMatch = RegExp(r'^/qa/([^/]+)$').firstMatch(path);
    if (req.method == 'DELETE' && qaMatch != null) {
      if (caller == null) return _ok({'error': 'Missing bearer token.'}, 401);
      if (caller['role'] != 'admin') return _ok({'error': 'Admin access required.'}, 403);
      qaQuestions.removeWhere((e) => e['id'] == qaMatch.group(1));
      return _ok({'ok': true});
    }

    return _ok({'error': 'Not found (fake backend has no route for $path).'}, 404);
  }
}
