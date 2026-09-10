// Plain data models used across the app.

enum ExamTrack { pharmacy, nursing }

class Question {
  Question({
    required this.id,
    required this.packId,
    required this.number,
    required this.total,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String id;

  /// Which [ExamPack] this question belongs to.
  final String packId;
  final int number;
  final int total;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  /// e.g. "C) Allopurinol"
  String get answerLabel =>
      '${String.fromCharCode(65 + correctIndex)}) ${options[correctIndex]}';

  Question copyWith({
    String? packId,
    int? number,
    int? total,
    String? prompt,
    List<String>? options,
    int? correctIndex,
    String? explanation,
  }) {
    return Question(
      id: id,
      packId: packId ?? this.packId,
      number: number ?? this.number,
      total: total ?? this.total,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
    );
  }
}

enum PaymentStatus { pending, approved, rejected }

/// A receipt a user uploaded, awaiting an admin decision.
class PaymentRequest {
  PaymentRequest({
    required this.id,
    required this.userName,
    required this.packId,
    required this.packTitle,
    required this.bankCode,
    required this.amountBirr,
    required this.submittedAt,
    this.status = PaymentStatus.pending,
  });

  final String id;
  final String userName;
  final String packId;
  final String packTitle;
  final String bankCode;
  final int amountBirr;
  final DateTime submittedAt;
  PaymentStatus status;
}

class BankAccount {
  const BankAccount({
    required this.code,
    required this.name,
    required this.owner,
    required this.number,
  });

  final String code;
  final String name;
  final String owner;
  final String number;
}

class EBook {
  const EBook({
    required this.title,
    required this.priceBirr,
    required this.cover,
    required this.subjects,
  });

  final String title;
  final int priceBirr;
  final String cover;
  final List<String> subjects;
}

class ExamPack {
  const ExamPack({
    required this.id,
    required this.title,
    required this.image,
    required this.questionCount,
    required this.priceBirr,
    required this.freeLimit,
  });

  final String id;
  final String title;
  final String image;
  final int questionCount;
  final int priceBirr;

  /// How many questions can be answered before payment is required.
  final int freeLimit;
}

class Profile {
  Profile({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
  });

  String name;
  String username;
  String email;
  String password;
  String phone;
}
