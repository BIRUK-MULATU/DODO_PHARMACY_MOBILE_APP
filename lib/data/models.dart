// Plain data models used across the app.

import 'dart:typed_data';

/// A field of study the learner picks on the "what would you like to learn"
/// screen (Pharmacy, Nursing, …). Fully editable from the admin panel.
class Track {
  Track({
    required this.id,
    required this.name,
    this.figure = '',
  });

  final String id;
  String name;

  /// Asset path for the cut-out figure shown on the track card. May be empty.
  String figure;

  Track copyWith({String? name, String? figure}) => Track(
        id: id,
        name: name ?? this.name,
        figure: figure ?? this.figure,
      );
}

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
  EBook({
    required this.id,
    required this.title,
    required this.priceBirr,
    required this.cover,
    required this.subjects,
    this.pages = const [],
    this.freePages = 4,
    this.pdfPath,
    this.pdfBytes,
    this.pdfName,
  });

  final String id;
  String title;
  int priceBirr;
  String cover;
  List<String> subjects;

  /// The book body as typed pages, one entry per page. Used when there is no
  /// [pdfPath] / [pdfBytes].
  List<String> pages;

  /// How many pages can be read before payment is required.
  int freePages;

  /// A PDF the admin uploaded from their device. On mobile/desktop it is saved
  /// to app storage and [pdfPath] points at it; on web only [pdfBytes] is set.
  String? pdfPath;
  Uint8List? pdfBytes;
  String? pdfName;

  bool get hasPdf =>
      (pdfPath != null && pdfPath!.isNotEmpty) ||
      (pdfBytes != null && pdfBytes!.isNotEmpty);

  int get pageCount => pages.length;

  EBook copyWith({
    String? title,
    int? priceBirr,
    String? cover,
    List<String>? subjects,
    List<String>? pages,
    int? freePages,
    String? pdfPath,
    Uint8List? pdfBytes,
    String? pdfName,
  }) {
    return EBook(
      id: id,
      title: title ?? this.title,
      priceBirr: priceBirr ?? this.priceBirr,
      cover: cover ?? this.cover,
      subjects: subjects ?? this.subjects,
      pages: pages ?? this.pages,
      freePages: freePages ?? this.freePages,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      pdfName: pdfName ?? this.pdfName,
    );
  }
}

class ExamPack {
  const ExamPack({
    required this.id,
    required this.title,
    required this.image,
    required this.questionCount,
    required this.priceBirr,
    required this.freeLimit,
    this.trackId = '',
  });

  final String id;

  /// Which [Track] this pack belongs to. Empty for stand-alone items (e-book).
  final String trackId;
  final String title;
  final String image;
  final int questionCount;
  final int priceBirr;

  /// How many questions can be answered before payment is required.
  final int freeLimit;

  ExamPack copyWith({
    String? trackId,
    String? title,
    String? image,
    int? questionCount,
    int? priceBirr,
    int? freeLimit,
  }) {
    return ExamPack(
      id: id,
      trackId: trackId ?? this.trackId,
      title: title ?? this.title,
      image: image ?? this.image,
      questionCount: questionCount ?? this.questionCount,
      priceBirr: priceBirr ?? this.priceBirr,
      freeLimit: freeLimit ?? this.freeLimit,
    );
  }
}

class Profile {
  Profile({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
    this.avatar = 'assets/images/avatar.png',
  });

  String name;
  String username;
  String email;
  String password;
  String phone;

  /// Asset path for the profile picture the user picked on their device.
  String avatar;

  Profile copyWith({
    String? name,
    String? username,
    String? email,
    String? password,
    String? phone,
    String? avatar,
  }) {
    return Profile(
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
    );
  }
}
