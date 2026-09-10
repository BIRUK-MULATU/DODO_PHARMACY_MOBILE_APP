// Plain data models used across the app.

enum ExamTrack { pharmacy, nursing }

class Question {
  const Question({
    required this.number,
    required this.total,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.answerLabel,
    required this.explanation,
  });

  final int number;
  final int total;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String answerLabel;
  final String explanation;
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
