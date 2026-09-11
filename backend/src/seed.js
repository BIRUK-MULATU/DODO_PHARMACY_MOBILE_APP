// Seeds the database with the same starter content `MockData` used to hand
// the in-memory `AppState` — so the app looks identical on first run against
// the real backend. Safe to re-run: it wipes and rewrites these collections.
require('dotenv').config();
const bcrypt = require('bcryptjs');

const { connectDb } = require('./db');
const Track = require('./models/Track');
const ExamPack = require('./models/ExamPack');
const Question = require('./models/Question');
const EBook = require('./models/EBook');
const AboutInfo = require('./models/AboutInfo');
const User = require('./models/User');

async function seed() {
  await connectDb();

  await Promise.all([
    Track.deleteMany({}),
    ExamPack.deleteMany({}),
    Question.deleteMany({}),
    EBook.deleteMany({}),
  ]);

  await Track.insertMany([
    { _id: 'pharmacy', name: 'Pharmacy', figure: 'assets/images/pharmacist.png' },
    { _id: 'nursing', name: 'Nursing', figure: 'assets/images/nurse.png' },
  ]);

  await ExamPack.insertMany([
    {
      _id: 'exit-3000',
      trackId: 'pharmacy',
      title: '3000 Exit Question Sample Exam',
      image: 'assets/images/home_banner_1.png',
      questionCount: 3000,
      priceBirr: 550,
      freeLimit: 5,
    },
    {
      _id: 'coc-2800',
      trackId: 'pharmacy',
      title: '2800 COC Sample Question Exam',
      image: 'assets/images/home_banner_2.png',
      questionCount: 2800,
      priceBirr: 450,
      freeLimit: 5,
    },
  ]);

  await Question.insertMany([
    {
      packId: 'exit-3000',
      number: 200,
      total: 3000,
      prompt:
        'A 55-year-old patient with Heart Failure with Reduced Ejection Fraction (HFrEF) ' +
        'stabilized on Lisinopril, Spironolactone, and Furosemide presents with an acute ' +
        'gout attack. After managing the acute flare, which drug is the most appropriate ' +
        'long-term urate-lowering agent for this patient?',
      options: ['Naproxen', 'Colchicine', 'Allopurinol', 'Probenecid'],
      correctIndex: 2,
      explanation:
        'Allopurinol is a xanthine oxidase inhibitor and the first-line urate-lowering ' +
        'therapy for long-term chronic gout management. NSAIDs like Naproxen and ' +
        'anti-inflammatory agents like Colchicine are used only for acute gout flares or ' +
        'short-term prophylaxis during initiation, not for long-term uric acid reduction. ' +
        'Additionally, NSAIDs are contraindicated in heart failure as they cause fluid ' +
        'retention and deteriorate renal function.',
    },
    {
      packId: 'exit-3000',
      number: 201,
      total: 3000,
      prompt:
        'A patient on warfarin starts a new antibiotic and the INR rises sharply within ' +
        'three days. Which antibiotic is the most likely cause of this interaction?',
      options: ['Amoxicillin', 'Trimethoprim-sulfamethoxazole', 'Cephalexin', 'Nitrofurantoin'],
      correctIndex: 1,
      explanation:
        'Trimethoprim-sulfamethoxazole strongly inhibits CYP2C9, the enzyme responsible ' +
        'for metabolising the more potent S-enantiomer of warfarin, and also displaces ' +
        'warfarin from plasma protein binding. Both effects raise free warfarin levels and ' +
        'the INR, markedly increasing bleeding risk.',
    },
    {
      packId: 'exit-3000',
      number: 202,
      total: 3000,
      prompt:
        'Which counselling point is most important for a patient starting alendronate for ' +
        'osteoporosis?',
      options: [
        'Take with food to avoid stomach upset',
        'Take at bedtime with a small sip of water',
        'Take on an empty stomach with a full glass of water and stay upright for 30 minutes',
        'Crush the tablet if swallowing is difficult',
      ],
      correctIndex: 2,
      explanation:
        'Oral bisphosphonates have very low bioavailability that is abolished by food, and ' +
        'they are corrosive to the oesophageal mucosa. Taking the dose on an empty stomach ' +
        'with plain water and remaining upright for at least 30 minutes maximises absorption ' +
        'and minimises the risk of oesophagitis and ulceration.',
    },
    {
      packId: 'coc-2800',
      number: 1,
      total: 2800,
      prompt:
        'A community pharmacist receives a prescription for a child weighing 18 kg for ' +
        'amoxicillin 40 mg/kg/day divided every 8 hours. What is the correct single dose?',
      options: ['120 mg', '180 mg', '240 mg', '360 mg'],
      correctIndex: 2,
      explanation:
        '40 mg/kg/day × 18 kg = 720 mg/day. Divided into three doses (every 8 hours) that ' +
        'is 240 mg per dose.',
    },
  ]);

  await EBook.insertMany([
    {
      _id: 'book-coc',
      title: 'Pharmacy COC Examiner — 2800 Questions',
      priceBirr: 350,
      cover: 'assets/images/book_cover.png',
      freePages: 4,
      subjects: [
        'Pharmacology',
        'Clinical Pharmacy',
        'Public Health',
        'Pharmaceutics',
        'Pharmaceutical Chemistry',
        'Biopharmaceutics',
      ],
      pages: [
        'Chapter 1 — How to use this book\n\n' +
          'This guide follows the current national COC blueprint. Each ' +
          'chapter opens with a one-page summary, then works through ' +
          'exam-style questions with full explanations. Read the first ' +
          'few pages free; unlock the rest to get all 2,800 questions.',
        'Chapter 2 — Pharmacology essentials\n\n' +
          'Receptor theory, agonists and antagonists, dose–response ' +
          'curves, therapeutic index. Know the difference between ' +
          'competitive and non-competitive antagonism and how each ' +
          'shifts the dose–response curve.',
        'Chapter 3 — Autonomic drugs\n\n' +
          'Cholinergics, anticholinergics, adrenergics and blockers. ' +
          'Focus on the clinical uses and the classic adverse-effect ' +
          'clusters (dry mouth, blurred vision, urinary retention for ' +
          'antimuscarinics).',
        'Chapter 4 — Cardiovascular pharmacology\n\n' +
          'ACE inhibitors, ARBs, beta-blockers, calcium channel ' +
          'blockers, diuretics. Heart-failure guideline therapy and the ' +
          'monitoring each class needs (potassium, renal function).',
        'Chapter 5 — Antimicrobials\n\n' +
          'Beta-lactams, macrolides, fluoroquinolones, aminoglycosides. ' +
          'Spectra, key interactions (warfarin + co-trimoxazole), and ' +
          'the counselling points for each class.',
        'Chapter 6 — Endocrine & metabolic\n\n' +
          'Insulins and oral hypoglycaemics, thyroid replacement, ' +
          'corticosteroids, bisphosphonates. Alendronate counselling: ' +
          'empty stomach, full glass of water, stay upright 30 minutes.',
        'Chapter 7 — Clinical pharmacy practice\n\n' +
          'Medication reconciliation, therapeutic drug monitoring, ' +
          'renal and hepatic dose adjustment, and structured patient ' +
          'counselling.',
        'Chapter 8 — Public health & pharmacoepidemiology\n\n' +
          'Immunisation schedules, notifiable diseases, pharmacovigilance ' +
          'and adverse-drug-reaction reporting, and basic study designs.',
      ],
    },
  ]);

  await AboutInfo.findByIdAndUpdate(
    'singleton',
    {
      version: '1.0.0',
      intro:
        'DODOMED is a study companion for the Ethiopian pharmacy exit exam ' +
        'and the COC licensure exam. It brings the full question bank, ' +
        'worked explanations, mock exams and premium reference books into ' +
        'one app so you can prepare anywhere.',
      features: [
        '3,000+ exit-exam MCQs and 2,800+ COC questions, organised by ' +
          'subject and past-paper trends',
        "A step-by-step explanation for every question — why the answer is " +
          'right and why the others are wrong',
        'Timed mock exams that mirror the real paper',
        'Premium reference books, including full PDFs, readable in the app',
        'A progress dashboard: accuracy, streaks and exam-readiness at a ' +
          'glance',
      ],
      unlocking:
        'A few questions and the first pages of every book are free. To ' +
        'unlock everything you make a bank transfer and upload the receipt ' +
        'in the app — our team confirms it (usually within a couple of ' +
        'hours) and your access opens automatically.',
      supportEmail: 'support@dodomed.et',
      supportTelegram: '@dodomed',
      supportPhone: '+251 91 000 0000',
      footer: '© 2026 DODOMED · Made in Ethiopia',
    },
    { upsert: true },
  );

  // Seed accounts so the app is immediately usable end to end: one learner
  // (the account the UI used to hard-code) and one admin.
  const learnerEmail = 'asterali@gmail.com';
  if (!(await User.findOne({ email: learnerEmail }))) {
    await User.create({
      name: 'Aster Ali',
      username: 'Asterali',
      email: learnerEmail,
      passwordHash: await bcrypt.hash('12345', 10),
      phone: '+251913623093',
      role: 'user',
    });
  }

  const adminEmail = 'admin@dodomed.et';
  if (!(await User.findOne({ email: adminEmail }))) {
    await User.create({
      name: 'DODOMED Admin',
      username: 'admin',
      email: adminEmail,
      passwordHash: await bcrypt.hash('admin123', 10),
      phone: '',
      role: 'admin',
    });
  }

  console.log('[seed] done.');
  console.log('[seed] learner login: asterali@gmail.com / 12345');
  console.log('[seed] admin login:   admin@dodomed.et / admin123');
  process.exit(0);
}

seed().catch((err) => {
  console.error('[seed] failed:', err);
  process.exit(1);
});
