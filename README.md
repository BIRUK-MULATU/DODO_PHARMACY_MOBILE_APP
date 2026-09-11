# DODOMED

Flutter app built from the Figma board `DODO PHARMA MOBILE (2).png` — a study
platform for the Ethiopian pharmacy exit exam / COC exam (3,000+ MCQs with
detailed explanations, a premium e-book, and a manual bank-transfer payment
flow).

Display name **DODOMED** everywhere the user sees it (splash wordmark, window
title, Android/iOS/web launcher label + icons). The Dart package is still
`dodo_pharmacy_mobile_app` internally.

There is a real backend now — see `backend/` (Node/Express + MongoDB). By
default the app still runs fully offline, seeded from `lib/data/mock_data.dart`
into an in-memory `AppState` (everything resets on restart) — every test
exercises exactly this path. Logging in or signing up for real (see
"Backend" below) switches that same `AppState` into an online session: the
catalog, auth, payments and exam progress all persist on the server instead.

### Responsiveness

`app.dart` clamps the OS text-scale to `0.9…1.2` and frames wide screens in a
430-px phone card. `test/responsive_test.dart` renders every screen at three
viewports (**360×720**, **430×900**, and **360×760 at 1.2× text**) and fails on
any `RenderFlex` overflow — every long label sits in a `Flexible`/`Expanded`
with `maxLines` + ellipsis, and the wave header lets its headline take up to two
lines within its fixed extent.

Almost everything is hand-built with no third-party packages. The exceptions:
`file_selector` (admin picks a PDF **or an image** from the device), `pdfx`
(renders a PDF), `path_provider` (saves a picked PDF into app storage), and
`no_screenshot` for the **screenshot block** (see below). Uploaded files live
only on that device until there is a backend to serve them.

### Admin image uploads

Everywhere the admin picks an image — exam-pack cover, track card figure, e-book
cover — the picker (`ImagePickerRow` in `lib/widgets/app_image.dart`) has an
**Upload** tile alongside the bundled presets. A picked image is downscaled
(via `dart:ui`, no package) and stored inline as a `data:` URI in the same
string field. `AppImage` renders either a bundled `assets/…` path or a `data:`
URI, and is used at every display site (home, track-select, e-book, about, and
all the admin lists). Covered by `test/image_upload_test.dart`.

### Screenshot / screen-recording block

`ScreenshotGuard` (`lib/widgets/screenshot_guard.dart`) wraps the whole app.
On Android it sets `FLAG_SECURE`, so the OS refuses the capture and shows its
own message. iOS can't be stopped by any app, so the captured image comes out
blank and — like Android 14+ — a screenshot or a screen recording pops a
"Screenshots are off" dialog. No-op on web / desktop, and silently disabled
where the plugin channel is unavailable (tests).

## Run

```bash
flutter pub get
flutter run                 # device / emulator
flutter run -d chrome       # web
flutter test                # 193 widget + unit tests (every screen, responsive sweep, admin CRUD, flows, backend sync)
flutter analyze             # clean, no issues
```

The app runs fine on its own (offline/mock mode, above). To use the real
backend instead — persistent accounts, catalog, payments and progress — also
run:

```bash
cd backend
npm install && npm run seed && npm start   # see backend/README.md
```

then sign up or log in from the app as normal (seeded accounts:
`asterali@gmail.com` / `12345`, `admin@dodomed.et` / `admin123` — any
`admin…` email is an admin). See "Backend" below for what that switch
actually changes.

**Running on a physical phone via USB** (`flutter run` targeting a real
device, not an emulator): `10.0.2.2` — the app's default backend address on
Android — is a special loopback that **only exists inside an emulator**; on
a real phone it resolves to nothing, so login/signup just silently fail
with no useful error. Fix: tunnel the phone's `localhost:4000` back to this
machine over the same USB cable, then override the base URL to use it:

```bash
adb reverse tcp:4000 tcp:4000
flutter run --dart-define=API_BASE_URL=http://localhost:4000/api
```

(Re-run `adb reverse` any time the phone is unplugged and replugged — the
tunnel doesn't survive a USB disconnect.) The backend (`npm start` above)
and a local MongoDB (`systemctl status mongod`) both need to already be
running on this machine first.

**Building a release APK to hand out directly (not through the Play
Store)**: point it at a real, reachable backend with
`flutter build apk --release --dart-define=API_BASE_URL=https://your-backend-domain/api`
— the default base URL only ever resolves to `localhost`/`10.0.2.2`, which
nothing outside this machine can reach. `android/app/src/main/AndroidManifest.xml`
now declares the `INTERNET` permission (it used to only be granted to
debug/profile builds via Flutter's default template — a release build built
before this fix couldn't reach the network at all, silently). The backend
itself also needs real, public HTTPS hosting first — see backend/README.md's
"Not production-ready as-is" for what that still requires.

## Screen flow

```
login → "Forgot password" → reset password (email → demo code 1234 → new password) → login

splash → onboarding → login / signup → track select ─┬─► home ──► about ──► exam ──► results
                                                     ├─► dashboard
                                                     ├─► e-book
                                                     └─► profile (edit / save)

exam (free limit reached) → pay prompt → payment method → upload receipt → pending
                                                       (waits for admin approval → payment success)

login with an "admin…" email → admin panel → { tracks · packs · e-books · questions · payment approvals · users · Q&A } — all CRUD

e-book collection → open a book → read 4 pages free → lock → pay → (admin approves) → all pages unlock

side drawer → Q&A → ask a question → admin panel → Q&A → answer it → shows back up for the learner
```

`onGenerateRoute` in `lib/app/routes.dart` is the single source of navigation;
routes that take an `ExamPack` fall back to the primary pack so any screen can be
opened directly (deep links, `#/exam`, etc.).

### Admin panel (`lib/screens/admin/`)

Sign in with any email that starts with **`admin`** (e.g. `admin@dodomed.com`) —
`AppState.isAdmin` is set and login routes to `/admin` instead of the app.

Everything the learner sees is admin-editable, held in memory on `AppState`
(`tracks`, `examPacks`, `books`, `questions`, `aboutInfo`, `banks`) and
seeded from `MockData.seed*()`:

- **Tracks** — full CRUD over the fields of study on the "what would you like to
  learn" screen (Pharmacy, Nursing, and any more — Midwifery, Lab, …). Each track
  has a name and an optional card figure. Deleting a track cascades to its packs
  and their questions (with a confirmation).
- **Exam packs** — full CRUD. A pack has a title (e.g. *3000 Exit Question Sample
  Exam*, *2800 COC Sample Question Exam*), a track, a question-bank size, a price,
  a free-question limit, a cover image (a bundled preset **or an upload from
  the device** — see *Admin image uploads*), and **its own "About Questions"
  content** (`aboutSummary`/`aboutBullets`/`coreCourses` — the summary line,
  bullet points, and "Core Courses Covered" list shown on `AboutQuestionsScreen`
  before the learner starts that pack; each pack has its own, not shared —
  used to be one global list for every pack, with no way to tell packs apart).
  Deleting a pack cascades to its questions. The Home screen shows the packs
  for the track the learner picked (`AppState.visiblePacks`).
- **E-books** — full CRUD over `AppState.books`. A book has a title, price,
  cover, subjects, a **free-page count**, and its content is **either an uploaded
  PDF** (`Upload PDF from device` in the form → saved to app storage via
  `path_provider`, path/bytes on `EBook.pdfPath` / `pdfBytes`) **or typed pages**
  (one field, split on a line containing only `---`). On the user side
  (`/ebook` collection → `EBookReaderScreen`) the first *N* pages are readable
  (PDF pages rendered with `pdfx`); the rest are locked behind a one-time payment
  that runs through the same receipt-upload → admin-approval flow
  (`AppState.purchasableForBook` makes a book travel as a synthetic `ExamPack`).
  Approval unlocks the book live.
- **Questions** — full CRUD over `AppState.questions`: list with search + pack
  filter, add/edit form (pack, number, prompt, 4 options with a tap-to-mark
  radio, explanation), delete with confirmation. The exam reads live from
  `AppState.examQuestion(pack, i)`, so edits show immediately.
- **Payment requests** — every uploaded receipt becomes a `PaymentRequest`
  (`pending`). Admin **Approve** unlocks the pack for that user; **Reject** marks
  it rejected. The user's *pending* screen listens to `AppState` and moves to the
  success screen the moment its request is approved (or shows a "rejected — try
  again" state).
- **About page** — edits `AppState.aboutInfo` (an `AboutInfo`): version, intro,
  the "What you get" bullets (one per line), the "how unlocking works"
  paragraph, support email / Telegram / phone, and the footer — plus two
  fields that used to be hardcoded with **no** admin control at all: the
  promo strip text (loops under the header on Home/Dashboard/Track select/
  E-book) and the onboarding subtitle (under "WELCOME TO"). (The "About
  Questions" bullets/core-courses used to live here too as one shared list —
  they're per-pack now, edited on each pack's own form instead; see "Exam
  packs" above.) `AboutAppScreen` (the drawer "About") renders live from it
  and hides any section left empty. **Reset** restores
  `MockData.seedAboutInfo()`.
- **Bank accounts** — full CRUD over `AppState.banks`, the accounts shown on
  the payment-method screen telling users where to transfer money. Also used
  to be hardcoded with no admin control — a real gap, since it's the one
  piece of content directly tied to real money. The admin picks the code
  (e.g. `CBE`) themselves; deleting the last one disables checkout instead
  of crashing.
- **Users** — every real account (`AdminUsersScreen`, online-only — there's
  only ever one local/demo user offline), each showing when they joined and
  how much they've answered. Tap one for `AdminUserDetailScreen`: profile,
  stats (answered/correct/best streak), a dated **Recent Activity** log (what
  they answered and when — not just a running total), and an **Access**
  section listing every exam pack and e-book with an Open/Closed switch the
  admin can flip directly (`AppState.setUserAccess` → `PUT
  /api/users/:id/access`). This is separate from, and overrides, the
  payment-approval flow above — admin can grant or revoke access outright
  without a receipt on file, or correct a mistake. Each book row also has a
  **preview** button that opens `EBookReaderScreen` so admin can read the
  actual book the user purchased, the same page the user gets.
- **Q&A** (`AdminQaScreen`) — every question asked from the app's side-drawer
  Q&A screen, pending ones first, each with an inline composer to answer (or
  edit a previous answer) and a delete button for spam/duplicates. Answering
  shows up back on the learner's own Q&A screen as a clearly-branded
  "DODOMED Support ✓" card with the answer and the date — not a raw text
  dump. Offline (only ever one demo learner) falls back to that learner's
  own thread, so the feature is still fully exercisable without a backend.

Covered by `test/admin_test.dart` (question/pack/track/bank CRUD + screens),
`test/ebook_test.dart` (book CRUD incl. PDF, the free-page gate, admin book
form), `test/image_upload_test.dart` (uploaded covers/figures),
`test/about_admin_test.dart` (About-page editing),
`test/admin_content_control_test.dart` (every admin-edited content field
actually showing up where the user sees it — the promo strip, onboarding
subtitle, About Questions bullets, and bank accounts),
`test/admin_users_test.dart` (the Users list + detail screens, and
`AppState.fetchAllUsers`/`fetchUserActivity`/`setUserAccess` against a fake
backend), `test/qa_test.dart` (asking, answering, deleting — both screens
and the underlying `AppState` methods, online and offline) and
`test/payment_flow_test.dart`.

### Profile (edit on-device)

`/profile` — the learner taps **Edit Profile** to make the name / email /
username / password / phone fields editable, then **Save** (validated) or
**Cancel**. Tapping the avatar opens a sheet with **Choose from device** (same
`pickImageAsDataUri` helper as the admin image uploads) plus bundled presets.
Changes go to `AppState.updateProfile` / `AppState.setAvatar` (a `data:` URI or
an asset path) and show immediately in the drawer and every header avatar (all
now use `AppImage.provider`). Covered by `test/profile_edit_test.dart`.

### Free-question paywall + payment flow

Each `ExamPack` has a `freeLimit` (currently **5**). Questions **0…freeLimit-1**
are free to read and answer; question `freeLimit` onward is locked
(`AppState.questionLocked(pack, index)`) — the exam screen hides the prompt and
options and shows a lock card with **Go to Payment**. Forward navigation
(`Next`, the review-navigator grid) is clamped to `AppState.maxReachableIndex`,
so skipping ahead with **Next** without answering can't reveal later questions.
`needsPayment(pack)` (free answers used up) is a subset of this.

Flow: `pay prompt → payment method → upload receipt → pending → success`.
On the upload screen, **"Tap to upload receipt" opens the real device picker**
(`pickImageAsDataUri`) — the chosen photo previews in place and
`AppState.submitPaymentRequest(..., receiptImage:)` carries it onto the
`PaymentRequest`, so `AdminPaymentsScreen` shows the actual uploaded photo
(tap to view full-screen) instead of a placeholder. Submitting only bumps the
attempt counter; the pack is unlocked once an admin **Approve**s the request —
the pending screen reacts live and moves to **success**. "Nice one!" then
`popUntil`s the whole payment stack back to the exam screen that started it —
still alive, progress intact, now unlocked.

Covered by `test/exam_paywall_test.dart` (the gate), `test/receipt_upload_test.dart`
(the device picker, unit + widget) and `test/payment_flow_test.dart` (the full
flow, end to end — both use `test/support/fake_file_selector.dart` to fake the
OS file dialog). In an online session, the receipt and the approval both sync
to the backend too (see "Backend" below).

### Results screen (`results_screen.dart`)

Shows the *real* correct/answered counts and accuracy from the exam just
finished (`ResultsArgs.correct`/`.answered`, both genuine — `exam_screen.dart`
tracks them per-question as the learner answers). It used to instead show a
fabricated number: the sample score scaled up to the size of the whole
question bank (e.g. 4/5 correct in a 3000-question pack displayed as
"2400 / 3000", as if the full bank had been answered). Now it's
`{correct} / {answered} correct` plus an accuracy badge, and a real **grade**
(`_Grade.forAccuracy` in `results_screen.dart`) with a message that actually
matches the result instead of one generic "Well done!" every time:

| Accuracy | Grade | Message |
|---|---|---|
| ≥ 90% | Excellent! | "You deserve it! 🏆" |
| ≥ 75% | Very Good! | "Great performance — keep it up!" |
| ≥ 50% | Good | "Solid effort — keep practising to get even better." |
| < 50% | Needs Improvement | "Don't worry — improve it! Review the explanations and try again." |

The confetti burst only plays at 50%+ too — celebrating a score that needs
improvement felt dishonest. Covered by `test/results_screen_test.dart` (one
case per tier, plus the anti-fabrication check above).

### Dashboard (`dashboard_screen.dart`)

Every stat and chart is backed by real data, not a fixed demo value:
Answered/Accuracy/the progress hero/the readiness gauge were always real;
**Best Streak**, **Rank**, **This Week**, and **Recent Activity** were
hardcoded or mislabeled until this pass (Best Streak used to just show total
correct answers; Rank was a literal `12` that never changed; This Week and
Recent Activity never reflected anything the learner actually did). Now:

- **Best Streak** is a real current/longest run of consecutive correct
  answers, tracked in `AppState.recordAnswer` — works offline too, not just
  online, since it's just local arithmetic.
- **Rank** and the new **Leaderboard** panel (rank badge + position bar) come
  from `AppState.fetchRank` — a genuine cross-account leaderboard when
  online (`GET /api/leaderboard/me`), a trivial `1 of 1` offline.
- **This Week** and **Recent Activity** come from `AppState.
  fetchDashboardActivity` (`GET /api/exam/activity`) when online; offline
  (no persisted history to fetch) they fall back to a small sample so the
  panel isn't empty.
- New **Pack Progress** panel — a progress bar per exam pack, not just the
  primary one shown in the hero card, using data already on `AppState` (no
  backend call).
- The exam-readiness gauge's `CustomPainter` had a real bug fixed in the
  same pass: its radius came from the panel's full *width* while the box was
  only 130px tall, so the arc painted outside its own box. The radius is now
  derived from both dimensions and can't exceed its container. The "This
  Week" bars now scale to the available width instead of a fixed pixel size.

Covered by `test/dashboard_online_test.dart` (the real online panels,
end to end through the actual screen) plus new cases in
`test/backend_integration_test.dart` for the streak/activity/rank data
itself.

## Backend

`backend/` is a small Express + MongoDB API (see `backend/README.md` for
setup, routes, and its own curl-verified walkthrough). `AppState` talks to it
through `lib/data/api_client.dart`; by default (`AppState.api == null`) it
never does — the app is fully offline/mock, which is what every existing
screen and test exercises. `authLogin`/`authSignUp` (real calls from
`login_screen.dart`/`signup_screen.dart`) set `api` and switch the *same*
`AppState` instance into an online session:

- The catalog (tracks/packs/questions/books/about) is replaced with what the
  server has, and every admin create/update/delete additionally fires a
  background sync call (the local list still updates immediately — a sync
  failure is recorded in `AppState.syncError`, not surfaced as a blocking
  error, matching how snappy the offline admin panel always felt).
- `submitPaymentRequest`/`decidePayment` sync the same way, and
  `recordAnswer` persists answered/correct counts per pack so progress
  survives a restart or follows the account to another device.
- The splash screen calls `AppState.tryAutoLogin()` first: if a token was
  saved (`shared_preferences`) from a previous session and the server still
  accepts it, the session resumes silently before deciding whether to land
  on onboarding or home.
- The free-question/free-page paywall is enforced **server-side**, not just
  by what the UI chooses to render: `lib/screens/exam_screen.dart` fetches
  one question at a time through `AppState.fetchExamQuestion`
  (`GET /api/exam/packs/:id/questions/:index`) instead of reading a bulk,
  fully-trusting local list — a locked index comes back with no question
  content at all, enforced against the user's *stored* progress. Same idea
  for books: `lib/screens/ebook_reader_screen.dart` fetches gated content
  through `AppState.fetchBookDetail` (`GET /api/books/:id`) rather than
  trusting the catalog's bulk `books` list, which now only ever carries
  metadata (title/cover/price/pageCount) for a non-admin session — see
  backend/README.md's "The paywall" for the full picture, including why the
  admin question-bank CRUD screens are unaffected (they legitimately need
  full content, and only ever load in bulk for an admin session).
- `forgot_password_screen.dart`'s reset calls
  `AppState.resetPasswordOnBackend` — a real reset (dev/demo fixed code —
  see backend/README.md's "Auth") against whatever account matches the
  typed email on the server, not just whatever profile happens to be cached
  locally. If no backend is reachable at all (a genuine connection failure,
  not a real rejection from a real server) it falls back to the original
  fully-local demo behaviour.
- The backend itself has basic abuse protection now too (CORS restriction,
  rate limiting on auth endpoints) — see backend/README.md's "Abuse
  protection". It is **not** production-ready as one unit though — see its
  "Not production-ready as-is" section for the concrete list (real hosting,
  HTTPS, real email for password reset, the actual question content).
- `lib/data/api_client.dart`'s base URL is overridable at build time
  (`--dart-define=API_BASE_URL=https://...`) instead of hardcoded to
  `localhost`/`10.0.2.2` — required for any build that isn't running against
  a backend on the same machine.

Covered by `test/backend_integration_test.dart` (11 tests against
`test/support/fake_backend.dart`, an in-memory fake of the whole API — no
real Mongo/Express needed for `flutter test`), `test/exam_online_test.dart`
(the gated exam-question fetch, end to end through the real screen),
`test/forgot_password_test.dart` (backend reset, wrong code, and the
no-backend fallback), plus the fix to `test/signup_phone_test.dart` that
came with wiring sign-up to the real call.

## Project layout

| Path | What |
|------|------|
| `lib/theme/` | Colours (`AppColors`), theme + display text styles, the app-wide fade/slide page transition |
| `lib/data/` | `models.dart`, `mock_data.dart` (question bank, banks, e-book, exam packs), `api_client.dart` (thin HTTP wrapper), `AppState` + `AppStateScope` (an `InheritedNotifier`) |
| `lib/app/` | `DodoPharmacyApp` (wraps `AppStateScope`, frames the app to phone width on wide screens) and `routes.dart` |
| `lib/widgets/` | Reusable pieces — see Animations below |
| `lib/screens/` | One file per screen; `screens/auth/` shares the login/sign-up shell; `screens/payment/` is the payment flow |
| `backend/` | The Express + MongoDB API — see backend/README.md |

## Animations

Everything moves. Key building blocks:

- **`Entrance`** — fade + slide-up on mount, delay baked into the controller as an
  `Interval` (never a timer, so it can't get stuck). `staggered([...])` wraps a
  list of children with increasing delays.
- **`PressScale`** — springy press-down on every button / card.
- **`PrimaryButton`** — the chunky pill button (dark / yellow / outline / green),
  optional DP mark, press-scale + drop shadow.
- **`SwipeToStart`** — slide-to-unlock control on the onboarding screen: drag the
  DP thumb across the track to continue; springs back below ~72%. Covered by
  `test/swipe_to_start_test.dart`.
- **`AppBottomNav`** — floating, glassy near-transparent tab bar (App Store
  style) on the Home / Dashboard / E-Book / Profile screens; blurred, dark
  icons/labels, the current section a filled dark pill. Taps route via
  `AppRoutes.goToSection`. Covered by `test/bottom_nav_test.dart`. Those screens
  use `extendBody: true` so content scrolls behind it.
- **`DpLogo`** — the "dp" pill mark as a `CustomPainter`; `progress` 0→1 slides the
  two halves together (splash screen).
- **`MarqueeTicker`** — infinite promo strip under every dark header.
- **`AnimatedProgressBar`**, **`CountUp`**, **`Pulse`** (`lib/widgets/animated_bits.dart`).
- **`ConfettiBurst`** — dependency-free `CustomPainter` confetti on the results and
  payment-success screens.
- **`BottomWaveClipper` / `TopWaveClipper` / `WaveHeader`** — the black wavy headers.
  On Home / Dashboard / E-Book / Track / Profile the header is placed via
  **`SliverPinnedHeader`** (a fixed-extent `SliverPersistentHeader`, `pinned:
  true`), so the top nav bar stays put while the page scrolls under it. Covered
  by `test/pinned_header_test.dart`.
- **`ReviewNavigatorSheet`** — draggable bottom sheet with a staggered grid of
  question chips (green = correct, red = wrong, ringed = current).
- **`AppDrawer`** — frosted, semi-transparent yellow panel on a sweeping curve
  (`BackdropFilter` blur, no solid background — the screen shows through),
  staggered menu items (Profile / Home / Dashboard / E-Book / Admin panel /
  **About** / Log Out), the transparent-cut-out jumping-kid PNG. Drawer items,
  and the **header avatar** on Home / Dashboard / E-Book / Track, all route via
  `AppRoutes.goToSection` — unwind to Home then push once, so the top-level
  sections never stack up — except drawer **Home**, which resets the stack to
  the track picker (`/track`, the first screen after login), exactly like
  signing in. **About** → `AboutAppScreen` (`lib/screens/
  about_app_screen.dart`): version, what the app is, feature list, how unlocking
  works, support contacts.
- **Exam screen** — question-to-question slide+fade, option colour springs, a
  shake on a wrong answer, check/cross pop-in, explanation card reveal.

## Assets

- `assets/images/*.png` — cropped straight from the Figma export (hero
  illustrations, book cover, avatar). The login / sign-up heroes are keyed to
  transparent so they float on the dark auth header with no rectangle. The
  track-select cards use transparent cutouts (`pharmacist.png` / `nurse.png` and
  friends — an admin picks one per track, or none); `_TrackCard` in
  `track_select_screen.dart` composes every card identically and responsively
  from its own width (`AspectRatio` + `LayoutBuilder`) — yellow scene, figure,
  drawn name pill. `MockData.packImages` / `trackFigures` / `avatarChoices` are
  the bundled images the admin and the user can choose from (no file upload).
  The DP logo is `assets/images/logo.png`.
- `assets/images/logo.png` — the DODOMED "dp" pill mark (transparent background);
  `DpLogo` renders it, tinting for dark surfaces. App/launcher icons are generated
  from it into `android/.../mipmap-*` + `drawable-*` (legacy + adaptive),
  `ios/.../AppIcon.appiconset`, and `web/icons/`.
- `assets/fonts/Nunito-*.ttf` — the **Nunito** family (weights 400–900), bundled
  and set as the app-wide `fontFamily` in `AppTheme`. Static instances cut from
  the OFL variable font; licence in `assets/fonts/OFL.txt`.

## Notes / next steps

- The real device receipt/image pickers, the real backend (`AppState` ↔
  `backend/`, persistence, real auth), and server-side paywall enforcement
  (the exam/e-book reader fetch gated content per-item now, instead of
  trusting a bulk-fetched list — see "Backend" above) are all done.
- `forgot_password_screen.dart` resets the real account's password on the
  backend, but there's still no real *email* flow behind it — the "code" is
  a fixed, publicly-known demo value (`1234`), not something actually
  emailed (see `POST /api/auth/reset-password` in backend/README.md — this
  is a real account-security gap, not just a missing nicety, until it's
  replaced with a real emailed-token flow). No JWT refresh either — the
  30-day token just expires and drops back to a normal login.
- **Not ready to actually deploy** — see backend/README.md's "Not
  production-ready as-is" for the concrete list: real hosting (right now
  it's `localhost` against a local, auth-less `mongod`), HTTPS, real email
  for password reset, and the real question-bank content (the seed data is
  only a handful of real questions).
