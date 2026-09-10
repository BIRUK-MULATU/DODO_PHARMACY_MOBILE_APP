import 'package:flutter/widgets.dart';

import 'mock_data.dart';
import 'models.dart';

/// App-wide state held in memory. Exposed to the widget tree through
/// [AppStateScope]. No backend — everything resets on restart.
class AppState extends ChangeNotifier {
  bool loggedIn = false;
  ExamTrack track = ExamTrack.pharmacy;

  Profile profile = Profile(
    name: 'Aster Ali',
    username: 'Asterali',
    email: 'Asterali@gmail.com',
    password: '12345',
    phone: '+251913623093',
  );

  /// Per-pack: how many questions the user has answered.
  final Map<String, int> _answered = {};

  /// Per-pack: how many answered correctly.
  final Map<String, int> _correct = {};

  /// Packs the user has unlocked by paying.
  final Set<String> _unlocked = {};

  int uploadAttempts = 0;

  void logIn() {
    loggedIn = true;
    notifyListeners();
  }

  void logOut() {
    loggedIn = false;
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

  void registerUploadAttempt() {
    uploadAttempts++;
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
