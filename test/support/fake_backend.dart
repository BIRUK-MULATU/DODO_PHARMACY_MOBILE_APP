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
      };

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
    if (req.method == 'GET' && path == '/books') return _ok({'books': books});
    if (req.method == 'GET' && path == '/about') return _ok({'about': about});
    if (req.method == 'GET' && path == '/questions') return _ok({'questions': questions});

    // Generic CRUD for the slug-keyed collections (id may be client-supplied
    // — see backend/README.md — or generated here otherwise).
    final trackMatch = RegExp(r'^/tracks/(.+)$').firstMatch(path);
    final packMatch = RegExp(r'^/packs/(.+)$').firstMatch(path);
    final bookMatch = RegExp(r'^/books/(.+)$').firstMatch(path);
    final questionMatch = RegExp(r'^/questions/(.+)$').firstMatch(path);

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

    return _ok({'error': 'Not found (fake backend has no route for $path).'}, 404);
  }
}
