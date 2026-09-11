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

- `src/models/` — Mongoose schemas mirroring `../frontend/lib/data/models.dart`
  (`Track`, `ExamPack`, `Question`, `EBook`, `PaymentRequest`, `AboutInfo`,
  `Bank`, `User` — the real, persisted stand-in for `Profile`, which also
  carries `currentStreak`/`bestStreak`, `dailyActivity` (a date → count map,
  last 7 days read for "This Week"), and `recentActivity` (last 20 answered
  questions) for the dashboard).
- `src/routes/` — one router per resource; `auth` issues/verifies JWTs and
  handles the dev-only password reset, `exam` is the server-gated
  per-question endpoint the app actually reads exam questions through (plus
  `record-answer`/`activity`, which back the dashboard's real Best Streak/
  This Week/Recent Activity), `leaderboard` ranks every account for the
  dashboard's Rank stat + Leaderboard panel, `banks` is admin CRUD over the
  payment bank accounts (any logged-in user can list them — needed to pick
  one to pay), `users` is the admin-only "Users" page (every account's real
  dated activity, plus direct open/close access control per pack/book —
  see "Users" below), `qa` is the side-drawer "ask a question" flow (any
  logged-in user asks/reads their own; admin reads/answers/deletes any —
  see "Q&A" below), `questions`/`tracks`/`packs`/`books`/`about` are admin
  CRUD (plus public/authenticated read-only listing where the app needs it).
- `src/middleware/auth.js` — `requireAuth` (verifies the bearer JWT, loads
  `req.user`) and `requireAdmin` (403s unless `req.user.role === 'admin'`).
- `src/staticData.js` — the bundled-asset choice lists (`trackFigures`,
  `packImages`, `bookCovers`, `avatarChoices`) — genuinely static presets
  from the Flutter app's own asset bundle, so no DB collection for these.
- `src/seed.js` — idempotent-ish starter content (re-run any time to reset
  tracks/packs/questions/book/about; the two seed accounts are only created
  if missing, so re-seeding won't wipe real signups' progress... except it
  *does* wipe/recreate tracks/packs/questions each run — only run it against
  a throwaway/dev database, not one with real user-submitted content).
- `deploy/dodomed-backend.service` — a systemd unit for running this as a
  supervised, auto-restarting service on a real server; `deploy/backup.sh` —
  a daily `mongodump` cron script. Neither is used by local development.

## The paywall — enforced server-side

Every question and every book page is gated per-request against what's
actually stored for the caller, not by trusting the client to hide content
it already has:

- `GET /api/exam/packs/:packId/questions/:index` reimplements the free-limit
  check (`answered >= freeLimit || index >= freeLimit`, unless the pack is
  unlocked) against the user's *stored* progress, and returns
  `{ locked: true }` with **no question content at all** — not even a
  scrambled placeholder — when it doesn't pass. `PUT .../progress` persists
  what the client already computed (see `AppState.recordAnswer` — the client
  still evaluates correctness itself once it has a fetched question, same as
  it always did; nothing here withholds `correctIndex` from a question once
  it's actually been handed over). A stricter `POST .../answer` variant also
  exists (re-validates the answer server-side and returns
  `correct`/`correctIndex`/`explanation`) but isn't called by the app, which
  gets the same information straight from the fetched question instead.
- `GET /api/books/:id` returns a book's pages/PDF truncated to the free
  preview unless the caller has unlocked it (admins always see everything —
  editing a book they haven't personally "purchased" is still normal admin
  work).
- The bulk listings (`GET /api/questions`, `GET /api/books`) that *don't*
  gate per-item are scoped down instead: `/api/questions` is admin-only
  (`requireAdmin`) — a learner never gets a bulk dump of every answer.
  `/api/books` is metadata-only (title/cover/price/subjects/pageCount) for
  everyone except an admin, who needs the full content to prefill the edit
  form.

`../frontend/lib/data/app_state.dart` mirrors this split: `AppState.questions` only ever
bulk-populates for an admin session (`_loadCatalog`); a learner's exam
screen fetches one question at a time through `fetchExamQuestion`
(`../frontend/lib/screens/exam_screen.dart`'s `_slotFor`/`_ensureLoaded`), and the e-book
reader fetches a book's real content through `fetchBookDetail`
(`../frontend/lib/screens/ebook_reader_screen.dart`) instead of trusting the bulk list.

## Dashboard data

`POST /api/exam/packs/:packId/record-answer` (`{ wasCorrect, packTitle }`)
is the single event `AppState.recordAnswer` actually calls — it updates the
per-pack `progress` (same as the old `PUT .../progress`, which still exists
but is unused now) and, in the same request, the global correct-answer
streak, today's entry in `dailyActivity`, and the capped `recentActivity`
log. `GET /api/exam/activity` reads the last 7 days + up to 20 recent
entries back out for the dashboard's "This Week" bars and "Recent Activity"
list. `GET /api/leaderboard/me` ranks every account by total correct answers
for the dashboard's Rank stat and Leaderboard panel. None of this was fake
before — it simply didn't exist; the dashboard's "Best Streak"/"Rank"/"This
Week"/"Recent Activity" were hardcoded or mislabeled client-side values with
no backend behind them at all.

## Content admin control

(user: "the admin part can add delete every contents that is found on the
user so check it there is not the admin control must have control the
admin" — an audit turned up real gaps: content the user saw with zero admin
control at all, not just missing polish.)

- **Bank accounts** (`banks`) — where users are told to send money. Used to
  be hardcoded in the Flutter app with no way to change them without
  shipping a new build. Now full CRUD (`GET` open to any logged-in user —
  they need the list to pick one to pay; `POST`/`PUT`/`DELETE` admin-only).
  The admin picks the `id` themselves (a short code like `"CBE"`) rather
  than one being generated.
- **`AboutInfo` grew two fields** that used to be static strings baked into
  the Flutter client with no admin screen at all: `marqueeText` (the promo
  strip on Home/Dashboard/Track select/E-book) and `onboardingSubtitle`
  (under "WELCOME TO" on first launch). Both are on the existing
  `admin_about_screen.dart` form and sync through the existing `PUT
  /api/about`.
- **`ExamPack` grew its own `aboutSummary`/`aboutBullets`/`coreCourses`** —
  the summary line, bullet points, and "Core Courses Covered" list shown on
  `AboutQuestionsScreen` before a learner starts that pack. This briefly
  lived on `AboutInfo` as one shared list for every pack (no way to tell
  packs apart); moved to per-pack fields, edited on each pack's own form
  (`admin_pack_form_screen.dart`) and synced through `POST`/`PUT
  /api/packs/:id`.

Everything else the user sees was already admin-controlled before this
audit — tracks/packs/questions/books/about/payments all had full CRUD.

## Users — dated activity + direct access control

(user: "the admin must control all the users... a controlling page which is
for the user and for any access on the admin side what the users are doing
write date... make opened and closed [access] for user page")

`src/routes/users.js`, admin-only throughout:

- `GET /api/users` — every account, summarized (name/email/role/joined date,
  `totalAnswered`/`totalCorrect` summed across `progress`,
  `currentStreak`/`bestStreak`, `unlockedPacks`). Backs the admin "Users"
  list screen.
- `GET /api/users/:id/activity` — one user's real activity: the same 7-day
  `dailyActivity` breakdown and capped `recentActivity` log that
  `/api/exam/activity` returns for the caller's own dashboard, but for any
  user by id. Each `recentActivity` entry carries `packTitle`/`wasCorrect`/
  `at` (a real timestamp) — a dated log of what that user actually did, not
  just a running total.
- `PUT /api/users/:id/access` (`{ packId, unlock }`) — directly adds or
  removes one pack/book id from that user's `unlockedPacks`. This is
  **separate from, and overrides**, the existing payment-approval flow
  (`PUT /api/payments/:id/decide`), which still exists and still works —
  admin can now also grant access outright with no receipt on file, revoke
  it, or correct a mistake, for any pack or e-book (both are looked up by
  id — `ExamPack` or `EBook` — before the toggle is allowed).
- `PUT /api/users/:id/role` (`{ role: 'admin' | 'user' }`) — promotes a user
  to admin, or demotes an admin back to a regular user. Two safety rails:
  an admin can never remove their **own** admin access this way (avoids a
  mid-session self-lockout even if other admins exist), and the **last**
  remaining admin account can't be demoted (avoids locking everyone out —
  in practice this second check can only ever be reached by trying to
  demote yourself when you're the sole admin, since a *different* caller
  demoting another admin necessarily means at least 2 admins existed going
  in; both checks are kept for defense in depth).

`AdminUsersScreen`/`AdminUserDetailScreen` in the Flutter app call these
through `AppState.fetchAllUsers`/`fetchUserActivity`/`setUserAccess`/
`setUserRole`. The detail screen's per-book row also has a preview button
that opens `EBookReaderScreen` with that book, so admin can read the actual
content a user purchased — the same reader the user gets, not a separate
view. The role toggle sits above the per-pack/book access rows as a
distinct "Admin access" switch, disabled entirely when viewing your own
account.

## Q&A — a side-drawer "ask a question" flow, answered by admin

`src/models/QaQuestion.js` + `src/routes/qa.js`, the same shape as
`PaymentRequest` (server-generated id, `userId`/`userName` kept redundantly
so the admin list reads without a join):

- `POST /api/qa` (`{ question }`, any logged-in user) — asks a question.
- `GET /api/qa/mine` — the caller's own question/answer history, newest
  first. Backs the drawer's Q&A screen.
- `GET /api/qa` (admin-only) — every question from every user, **pending
  first** (`{status: -1, createdAt: -1}` — descending sorts `'pending'`
  before `'answered'` alphabetically), newest first within each group, so
  the ones needing attention float to the top. Backs the admin Q&A screen.
- `PUT /api/qa/:id/answer` (`{ answer }`, admin-only) — answers (or edits a
  previous answer to) a question; sets `status: 'answered'` and
  `answeredAt`.
- `DELETE /api/qa/:id` (admin-only) — removes a question (spam, duplicate).

`QaScreen` (drawer → "Q&A") lets a learner ask and see their own thread,
each answered one shown as a distinct "DODOMED Support ✓" card (not just
plain text) with the answer and date. `AdminQaScreen` (admin panel → "Q&A")
lists every question with an inline composer per pending item; offline
(only ever one demo learner) both screens fall back to `AppState.qaItems`
directly rather than hitting the network, so the feature is still fully
demoable without a backend. `AppState.askQuestion`/`fetchMyQuestions`/
`fetchAllQuestions`/`answerQuestion`/`deleteQuestionThread` wire it up;
`test/support/fake_backend.dart` mirrors all five routes and
`test/qa_test.dart` covers both screens and every `AppState` method, online
and offline.

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
**replace this with a real emailed-token flow before this app is ever
exposed outside a dev/demo environment** — as it stands, anyone who knows a
user's email can take over their account.

## Abuse protection

- `CORS_ORIGIN` (`.env`) restricts which web origins may call the API — see
  `.env.example`. Unset by default (accepts any origin), which is fine for
  local development but must be set to the real deployed domain(s) before
  going public. Only matters for the web build; native apps don't send an
  `Origin` header.
- Rate limiting (`express-rate-limit`, in `src/app.js`): 120 req/min per IP
  on all of `/api`, and a tighter 20 req/15min on `/api/auth` specifically
  (login/signup/reset-password — the ones worth brute-forcing). Keyed by IP
  in-memory, which is fine for one instance; move to a shared store (Redis)
  if this ever runs behind more than one.

## Not production-ready as-is — what's still missing

This backend is real (persists to Mongo, hashes passwords, gates content
server-side, rate-limited) and is genuinely wired into the Flutter app — but
deploying it for real users still needs, at minimum:
- **Real hosting.** Right now it's `localhost` against a local `mongod`.
  Needs a real MongoDB (Atlas, or a self-hosted instance with auth enabled —
  this one has none) and a real server (with `--dart-define=API_BASE_URL=...`
  pointed at it when building the app — see `../frontend/lib/data/api_client.dart`).
- **HTTPS.** Terminate TLS at the hosting layer (a platform's built-in
  HTTPS, or nginx + certbot on a VPS) — a real domain is a prerequisite.
- **Real email for password reset** — see "Auth" above.
- **The actual question bank.** `src/seed.js` only has a handful of real
  questions; the rest is demo content that loops.
- App-store requirements (signing, privacy policy, store listings) are
  untouched and outside this backend's scope entirely.

## Wired into the app

`../frontend/lib/data/app_state.dart` talks to this backend through
`../frontend/lib/data/api_client.dart`. By default (`AppState.api == null`) it doesn't —
the app runs fully offline against `../frontend/lib/data/mock_data.dart`, which is what
every pre-existing test exercises. `authSignUp`/`authLogin` (called from
`login_screen.dart`/`signup_screen.dart`) and `tryAutoLogin` (called from
`splash_screen.dart`) switch that same `AppState` into an online session:
the catalog loads from here, and every admin CRUD/payment/progress method
syncs here in the background from then on. `dashboard_screen.dart` fetches
`fetchRank`/`fetchDashboardActivity` on open for the Leaderboard/This
Week/Recent Activity panels (offline: rank is a trivial `1 of 1`, and This
Week/Recent Activity fall back to a small sample instead — there's no
persisted history to fetch offline). See the "Backend" section of the main
`README.md` for the exact mechanics, or `test/backend_integration_test.dart`
/ `test/exam_online_test.dart` / `test/dashboard_online_test.dart` for it
exercised end to end against `test/support/fake_backend.dart` (no real
Mongo/Express needed for `flutter test`).
