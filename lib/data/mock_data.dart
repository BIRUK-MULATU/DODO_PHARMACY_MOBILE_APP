import 'models.dart';

/// Static content that stands in for a backend.
class MockData {
  MockData._();

  static const List<ExamPack> examPacks = [
    ExamPack(
      id: 'exit-3000',
      title: '3000  Exit Question Sample Exam',
      image: 'assets/images/home_banner_1.png',
      questionCount: 3000,
      priceBirr: 550,
      freeLimit: 5,
    ),
    ExamPack(
      id: 'coc-2800',
      title: '2800 COC Sample Question Exam',
      image: 'assets/images/home_banner_2.png',
      questionCount: 2800,
      priceBirr: 450,
      freeLimit: 5,
    ),
  ];

  static const EBook premiumBook = EBook(
    title: 'Pharmacy COC Examiner — 2800 Questions',
    priceBirr: 350,
    cover: 'assets/images/book_cover.png',
    subjects: [
      'Pharmacology',
      'Clinical Pharmacy',
      'Public Health',
      'Pharmaceutics',
      'Pharmaceutical Chemistry',
      'Biopharmaceutics',
    ],
  );

  static const List<BankAccount> banks = [
    BankAccount(
      code: 'CBE',
      name: 'Commercial Bank of Ethiopia',
      owner: 'Yishak Abraham',
      number: '1000641510584',
    ),
    BankAccount(
      code: 'BOA',
      name: 'Bank of Abyssinia',
      owner: 'Yishak Abraham',
      number: '1000641510584',
    ),
  ];

  static const List<String> aboutBullets = [
    '3,000 Total MCQs: Comprehensive question bank organized by subject, difficulty, and year-by-year past exam trends.',
    'Multi-Year Questions: Incorporates previous national exit exam and licensure questions alongside model questions tailored to current curriculum blueprints.',
    'Detailed Explanations: Every question includes a thorough step-by-step breakdown explaining why the correct choice is right and why distractors are incorrect.',
    'Mock Practice Tests: Multi-year exam simulations to help build stamina, speed, and exam confidence.',
  ];

  static const List<String> coreCourses = [
    'Pharmacology & Therapeutics',
    'Pharmaceutics & Industrial Pharmacy',
    'Pharmaceutical Chemistry',
    'Clinical Pharmacy & Pharmacy Practice',
    'Public Health & Pharmacoepidemiology',
  ];

  /// A small pool that loops to simulate the full question bank. The admin
  /// panel adds to / edits this list (in memory) via [AppState].
  static List<Question> seedQuestions() => [
    Question(
      id: 'q-200',
      packId: 'exit-3000',
      number: 200,
      total: 3000,
      prompt:
          'A 55-year-old patient with Heart Failure with Reduced Ejection Fraction (HFrEF) '
          'stabilized on Lisinopril, Spironolactone, and Furosemide presents with an acute '
          'gout attack. After managing the acute flare, which drug is the most appropriate '
          'long-term urate-lowering agent for this patient?',
      options: ['Naproxen', 'Colchicine', 'Allopurinol', 'Probenecid'],
      correctIndex: 2,
      explanation:
          'Allopurinol is a xanthine oxidase inhibitor and the first-line urate-lowering '
          'therapy for long-term chronic gout management. NSAIDs like Naproxen and '
          'anti-inflammatory agents like Colchicine are used only for acute gout flares or '
          'short-term prophylaxis during initiation, not for long-term uric acid reduction. '
          'Additionally, NSAIDs are contraindicated in heart failure as they cause fluid '
          'retention and deteriorate renal function.',
    ),
    Question(
      id: 'q-201',
      packId: 'exit-3000',
      number: 201,
      total: 3000,
      prompt:
          'A patient on warfarin starts a new antibiotic and the INR rises sharply within '
          'three days. Which antibiotic is the most likely cause of this interaction?',
      options: [
        'Amoxicillin',
        'Trimethoprim-sulfamethoxazole',
        'Cephalexin',
        'Nitrofurantoin',
      ],
      correctIndex: 1,
      explanation:
          'Trimethoprim-sulfamethoxazole strongly inhibits CYP2C9, the enzyme responsible '
          'for metabolising the more potent S-enantiomer of warfarin, and also displaces '
          'warfarin from plasma protein binding. Both effects raise free warfarin levels and '
          'the INR, markedly increasing bleeding risk.',
    ),
    Question(
      id: 'q-202',
      packId: 'exit-3000',
      number: 202,
      total: 3000,
      prompt:
          'Which counselling point is most important for a patient starting alendronate for '
          'osteoporosis?',
      options: [
        'Take with food to avoid stomach upset',
        'Take at bedtime with a small sip of water',
        'Take on an empty stomach with a full glass of water and stay upright for 30 minutes',
        'Crush the tablet if swallowing is difficult',
      ],
      correctIndex: 2,
      explanation:
          'Oral bisphosphonates have very low bioavailability that is abolished by food, and '
          'they are corrosive to the oesophageal mucosa. Taking the dose on an empty stomach '
          'with plain water and remaining upright for at least 30 minutes maximises absorption '
          'and minimises the risk of oesophagitis and ulceration.',
    ),
    Question(
      id: 'q-coc-1',
      packId: 'coc-2800',
      number: 1,
      total: 2800,
      prompt:
          'A community pharmacist receives a prescription for a child weighing 18 kg for '
          'amoxicillin 40 mg/kg/day divided every 8 hours. What is the correct single dose?',
      options: ['120 mg', '180 mg', '240 mg', '360 mg'],
      correctIndex: 2,
      explanation:
          '40 mg/kg/day × 18 kg = 720 mg/day. Divided into three doses (every 8 hours) that '
          'is 240 mg per dose.',
    ),
  ];
}
