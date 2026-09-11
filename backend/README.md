# DODOMED backend

A small Express + MongoDB (Mongoose) REST API for the DODOMED Flutter app.
Node/Express + MongoDB, not the Supabase path originally discussed — this
sandbox already has a local `mongod` running, so no cloud account is needed
to develop against it.

## Run it

A MongoDB server must be reachable at `MONGODB_URI` (see `.env`). On this
machine one is already running as a system service (`systemctl status
mongod`), listening on `127.0.0.1:27017` with no auth.

```bash
cd backend
npm install        # first time only
npm run seed        # (re)creates the starter tracks/packs/questions/book/about + 2 accounts
npm start            # or `npm run dev` for auto-restart on save
```

Seeded accounts:
- Learner: `asterali@gmail.com` / `12345`
- Admin: `admin@dodomed.et` / `admin123` (any email starting with `admin`
  gets the admin role, same rule the old client-only login used)

Server listens on `http://localhost:4000` (`PORT` in `.env`). `GET /health`
returns `{"ok":true}` once it's up.

## Shape

- `src/models/` — Mongoose schemas mirroring `lib/data/models.dart`
  (`Track`, `ExamPack`, `Question`, `EBook`, `PaymentRequest`, `AboutInfo`,
  `User` — the real, persisted stand-in for `Profile`).
- `src/routes/` — one router per resource; `auth` issues/verifies JWTs,
  `exam` is a stricter, server-gated question endpoint the app doesn't call
  yet (see "The paywall" below), `questions`/`tracks`/`packs`/`books`/`about`
  are admin CRUD (plus public/authenticated read-only listing where the app
  needs it).
- `src/middleware/auth.js` — `requireAuth` (verifies the bearer JWT, loads
  `req.user`) and `requireAdmin` (403s unless `req.user.role === 'admin'`).
- `src/staticData.js` — the bundled-asset choice lists (`trackFigures`,
  `packImages`, `bookCovers`, `avatarChoices`) and bank accounts that used to
  live in `MockData` — not user data, so no DB collection for these.
- `src/seed.js` — idempotent-ish starter content (re-run any time to reset
  tracks/packs/questions/book/about; the two seed accounts are only created
  if missing, so re-seeding won't wipe real signups' progress... except it
  *does* wipe/recreate tracks/packs/questions each run — only run it against
  a throwaway/dev database, not one with real user-submitted content).

## The paywall

The Flutter app (`AppState.questionLocked`/`maxReachableIndex`,
`EBookReaderScreen`) has always held every question's `correctIndex` and
every book's full pages in memory at once, and enforced the free/paid split
purely by what the UI chooses to render — never by withholding content from
the client. The backend keeps that same trust model for `GET /api/questions`
and `GET /api/books` (any logged-in user gets everything, same as the old
`MockData`-seeded `AppState` did), so the existing screens work unchanged
against real, persisted data.

Two stricter endpoints exist alongside them but aren't called by the app
yet — a real hardening pass (making a modified/sniffing client unable to see
locked content at all, not just unable to render it) would switch to these
instead of the bulk listings above:
- `GET /api/exam/packs/:packId/questions/:index` / `POST .../answer` —
  reimplements `questionLocked` server-side against the user's *stored*
  progress and returns `{ locked: true }` with no question content at all
  when it doesn't pass, instead of trusting the client to hide it.
- `GET /api/books/:id` — same idea for a single book: pages/PDF beyond the
  free window are simply absent from the response unless the book is
  unlocked.

## Auth

`POST /api/auth/signup` / `/login` return `{ token, user }`; send the token
back as `Authorization: Bearer <token>` on everything else that needs it.
Tokens are plain JWTs (`JWT_SECRET` in `.env`), 30-day expiry, no refresh
flow yet — reasonable for this app's scope, revisit if that becomes a
problem.

`POST /api/auth/reset-password` (`{ email, code, newPassword }`) is a
dev/demo-only "forgot password": there's no mail service wired up, so `code`
is just a fixed, publicly-known value (`1234`, matching the front end's old
fully-simulated flow) rather than something actually emailed to the address.
It does genuinely update the real stored password for that account though —
replace this with a real emailed-token flow before this app is ever exposed
outside a dev/demo environment.

## Wired into the app

`lib/data/app_state.dart` talks to this backend through
`lib/data/api_client.dart`. By default (`AppState.api == null`) it doesn't —
the app runs fully offline against `lib/data/mock_data.dart`, which is what
every pre-existing test exercises. `authSignUp`/`authLogin` (called from
`login_screen.dart`/`signup_screen.dart`) and `tryAutoLogin` (called from
`splash_screen.dart`) switch that same `AppState` into an online session:
the catalog loads from here, and every admin CRUD/payment/progress method
syncs here in the background from then on. See the "Backend" section of the
main `README.md` for the exact mechanics, or `test/backend_integration_test.dart`
for it exercised end to end against `test/support/fake_backend.dart` (no
real Mongo/Express needed for `flutter test`).
