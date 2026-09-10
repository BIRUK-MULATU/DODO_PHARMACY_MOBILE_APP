# DODOMED

Flutter app built from the Figma board `DODO PHARMA MOBILE (2).png` — a study
platform for the Ethiopian pharmacy exit exam / COC exam (3,000+ MCQs with
detailed explanations, a premium e-book, and a manual bank-transfer payment
flow).

Display name **DODOMED** everywhere the user sees it (splash wordmark, window
title, Android/iOS/web launcher label + icons). The Dart package is still
`dodo_pharmacy_mobile_app` internally.

The UI is fully front-end: all data is mocked in `lib/data/` and app state lives
in memory (`AppState`), so everything resets on restart. There is no backend.

Almost everything is hand-built with no third-party packages. The exceptions:
the **e-book PDF** feature — `file_selector` (admin picks a PDF from the device),
`pdfx` (renders it), `path_provider` (saves it into app storage) — and
`no_screenshot` for the **screenshot block** (see below). A PDF uploaded this
way lives only on that device until there is a backend to serve it.

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
flutter test                # 46 widget + unit tests (boot, every screen, admin CRUD, flows)
flutter analyze             # clean, no issues
```

## Screen flow

```
login → "Forgot password" → reset password (email → demo code 1234 → new password) → login

splash → onboarding → login / signup → track select ─┬─► home ──► about ──► exam ──► results
                                                     ├─► dashboard
                                                     ├─► e-book
                                                     └─► profile (edit / save)

exam (free limit reached) → pay prompt → payment method → upload receipt → pending
                                                       (waits for admin approval → payment success)

login with an "admin…" email → admin panel → { tracks · packs · e-books · questions · payment approvals } — all CRUD

e-book collection → open a book → read 4 pages free → lock → pay → (admin approves) → all pages unlock
```

`onGenerateRoute` in `lib/app/routes.dart` is the single source of navigation;
routes that take an `ExamPack` fall back to the primary pack so any screen can be
opened directly (deep links, `#/exam`, etc.).

### Admin panel (`lib/screens/admin/`)

Sign in with any email that starts with **`admin`** (e.g. `admin@dodomed.com`) —
`AppState.isAdmin` is set and login routes to `/admin` instead of the app.

Everything the learner sees is admin-editable, held in memory on `AppState`
(`tracks`, `examPacks`, `books`, `questions`) and seeded from `MockData.seed*()`:

- **Tracks** — full CRUD over the fields of study on the "what would you like to
  learn" screen (Pharmacy, Nursing, and any more — Midwifery, Lab, …). Each track
  has a name and an optional card figure. Deleting a track cascades to its packs
  and their questions (with a confirmation).
- **Exam packs** — full CRUD. A pack has a title (e.g. *3000 Exit Question Sample
  Exam*, *2800 COC Sample Question Exam*), a track, a question-bank size, a price,
  a free-question limit and a cover image (chosen from bundled assets — there is
  no file upload). Deleting a pack cascades to its questions. The Home screen
  shows the packs for the track the learner picked (`AppState.visiblePacks`).
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

Covered by `test/admin_test.dart` (question/pack/track CRUD + screens),
`test/ebook_test.dart` (book CRUD incl. PDF, the free-page gate, admin book
form) and `test/payment_flow_test.dart`.

### Profile (edit on-device)

`/profile` — the learner taps **Edit Profile** to make the name / email /
username / password / phone fields editable, then **Save** (validated) or
**Cancel**. Tapping the avatar opens a picker of bundled pictures. Changes go to
`AppState.updateProfile` / `AppState.setAvatar` and show immediately in the
drawer and every header avatar. Covered by `test/profile_edit_test.dart`.

### Free-question paywall + payment flow

Each `ExamPack` has a `freeLimit` (currently **5**). After the user answers that
many questions, `AppState.needsPayment(pack)` is true and the exam screen swaps
the answer options for a lock card with a **Go to Payment** button.

Flow: `pay prompt → payment method → upload receipt → pending → success`.
Submitting a receipt only bumps the attempt counter; the pack is unlocked on the
**success** screen (after the pending screen auto-confirms, simulating an admin
approval). "Nice one!" then `popUntil`s the whole payment stack back to the exam
screen that started it — still alive, progress intact, now unlocked.

Covered by `test/exam_paywall_test.dart` (the gate) and
`test/payment_flow_test.dart` (the full flow, end to end).

## Project layout

| Path | What |
|------|------|
| `lib/theme/` | Colours (`AppColors`), theme + display text styles, the app-wide fade/slide page transition |
| `lib/data/` | `models.dart`, `mock_data.dart` (question bank, banks, e-book, exam packs), `AppState` + `AppStateScope` (an `InheritedNotifier`) |
| `lib/app/` | `DodoPharmacyApp` (wraps `AppStateScope`, frames the app to phone width on wide screens) and `routes.dart` |
| `lib/widgets/` | Reusable pieces — see Animations below |
| `lib/screens/` | One file per screen; `screens/auth/` shares the login/sign-up shell; `screens/payment/` is the payment flow |

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
  sections never stack up. **About** → `AboutAppScreen` (`lib/screens/
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

- Wire `lib/data/` to a real API, add persistence for `AppState`, and replace the
  simulated receipt upload with a real image picker.
