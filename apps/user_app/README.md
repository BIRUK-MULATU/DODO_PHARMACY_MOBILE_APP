# DODOMED

> This is the learner-facing app — the admin panel is a separate app at
> `../admin_app/`, and `../../backend/` holds the Node API (see
> `../../README.md` for the full repo layout). Every command below assumes
> your shell is already inside this `apps/user_app/` directory.

Flutter app built from the Figma board `DODO PHARMA MOBILE (2).png` — a study
platform for the Ethiopian pharmacy exit exam / COC exam (3,000+ MCQs with
detailed explanations, a premium e-book, and a manual bank-transfer payment
flow).

Display name **DODOMED** everywhere the user sees it (splash wordmark, window
title, Android/iOS/web launcher label + icons). The Dart package is still
`dodo_pharmacy_mobile_app` internally.

There is a real backend now — see `../../backend/` (Node/Express + MongoDB). By
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
cd ../../backend
npm install && npm run seed && npm start   # see ../../backend/README.md
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
itself also needs real, public HTTPS hosting first — see ../../backend/README.md's
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

e-book collection → open a book → read 4 pages free → lock → pay → (admin approves in ../admin_app) → all pages unlock

side drawer → Q&A → ask a question → (admin answers in ../admin_app) → shows back up here

An "admin…" email is rejected by this app's login/signup — see "Admin
panel — moved to a separate app" below.
```

`onGenerateRoute` in `lib/app/routes.dart` is the single source of navigation;
routes that take an `ExamPack` fall back to the primary pack so any screen can be
opened directly (deep links, `#/exam`, etc.).

### Admin panel — moved to a separate app

This app used to also contain the full admin panel
(`lib/screens/admin/`). On this branch, that's a **separate app**:
`../admin_app/` — its own `main.dart`, its own route table, its own
`applicationId`/bundle id/app name ("DODOMED Admin"), sharing the same
backend and the same `AppState` (via `../../packages/dodomed_core`). See
`../admin_app/README.md` for what it covers (tracks/packs/questions/
books/payments/about/banks/users/Q&A — full CRUD, unchanged from before).

This app's `LoginScreen`/`SignUpScreen` reject an admin account with a
message pointing at the admin app instead of routing anywhere admin-shaped
— there's no `/admin` route here at all.

## Backend

`../../backend/` is a small Express + MongoDB API (see `../../backend/README.md` for
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
  ../../backend/README.md's "The paywall" for the full picture, including why the
  admin question-bank CRUD screens are unaffected (they legitimately need
  full content, and only ever load in bulk for an admin session).
- `forgot_password_screen.dart`'s reset calls
  `AppState.resetPasswordOnBackend` — a real reset (dev/demo fixed code —
  see ../../backend/README.md's "Auth") against whatever account matches the
  typed email on the server, not just whatever profile happens to be cached
  locally. If no backend is reachable at all (a genuine connection failure,
  not a real rejection from a real server) it falls back to the original
  fully-local demo behaviour.
- The backend itself has basic abuse protection now too (CORS restriction,
  rate limiting on auth endpoints) — see ../../backend/README.md's "Abuse
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
| `../../backend/` | The Express + MongoDB API — see ../../backend/README.md |

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
  `../../backend/`, persistence, real auth), and server-side paywall enforcement
  (the exam/e-book reader fetch gated content per-item now, instead of
  trusting a bulk-fetched list — see "Backend" above) are all done.
- `forgot_password_screen.dart` resets the real account's password on the
  backend, but there's still no real *email* flow behind it — the "code" is
  a fixed, publicly-known demo value (`1234`), not something actually
  emailed (see `POST /api/auth/reset-password` in ../../backend/README.md — this
  is a real account-security gap, not just a missing nicety, until it's
  replaced with a real emailed-token flow). No JWT refresh either — the
  30-day token just expires and drops back to a normal login.
- **Not ready to actually deploy** — see ../../backend/README.md's "Not
  production-ready as-is" for the concrete list: real hosting (right now
  it's `localhost` against a local, auth-less `mongod`), HTTPS, real email
  for password reset, and the real question-bank content (the seed data is
  only a handful of real questions).
