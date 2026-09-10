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

## Run

```bash
flutter pub get
flutter run                 # device / emulator
flutter run -d chrome       # web
flutter test                # 17 widget smoke tests (boot + every screen)
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

login with an "admin…" email → admin panel → { questions CRUD · payment approvals · packs }
```

`onGenerateRoute` in `lib/app/routes.dart` is the single source of navigation;
routes that take an `ExamPack` fall back to the primary pack so any screen can be
opened directly (deep links, `#/exam`, etc.).

### Admin panel (`lib/screens/admin/`)

Sign in with any email that starts with **`admin`** (e.g. `admin@dodomed.com`) —
`AppState.isAdmin` is set and login routes to `/admin` instead of the app.

- **Questions** — full CRUD over `AppState.questions` (seeded from `MockData`):
  list with search + pack filter, add/edit form (pack, number, prompt, 4 options
  with a tap-to-mark-correct radio, explanation), delete with confirmation. The
  exam reads live from `AppState.examQuestion(pack, i)`, so edits show immediately.
- **Payment requests** — every uploaded receipt becomes a `PaymentRequest`
  (`pending`). Admin **Approve** unlocks the pack for that user; **Reject** marks
  it rejected. The user's *pending* screen listens to `AppState` and moves to the
  success screen the moment its request is approved (or shows a "rejected — try
  again" state).
- **Exam packs** — read-only overview (price, free limit, authored count).

Covered by `test/admin_test.dart` and `test/payment_flow_test.dart`.

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
  staggered menu items, the transparent-cut-out jumping-kid PNG. Drawer items,
  and the **header avatar** on Home / Dashboard / E-Book / Track, all route via
  `AppRoutes.goToSection` — unwind to Home then push once, so the top-level
  sections never stack up.
- **Exam screen** — question-to-question slide+fade, option colour springs, a
  shake on a wrong answer, check/cross pop-in, explanation card reveal.

## Assets

- `assets/images/*.png` — cropped straight from the Figma export (hero
  illustrations, book cover, avatar). The track-select cards use transparent
  cutouts `pharmacist.png` / `nurse.png` (same character, same pose); `_TrackCard`
  in `track_select_screen.dart` composes both identically and responsively from
  the card's own width (`AspectRatio` + `LayoutBuilder`) — yellow scene, figure,
  drawn name pill. The DP logo is `assets/images/logo.png`.
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
