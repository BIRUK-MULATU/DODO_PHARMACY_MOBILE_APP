# DODOMED Admin

The staff-only half of DODOMED — a separate Flutter app from
`../user_app/` (the learner-facing app), sharing the same backend
(`../../backend/`) and the same data layer/design system
(`../../packages/dodomed_core/`).

## Why a separate app

Originally this was one app with an in-app "Admin panel" gated by
`if (state.isAdmin)`. Per the user's request to split Admin and User into
"completely separate applications... developed, maintained, built, and
deployed independently," this app now has its own `main.dart`, its own
route table (no `home`/`track`/`dashboard`/etc. — those don't exist here at
all), its own Android `applicationId` (`com.dodopharmacy.dodomed_admin`)
and iOS bundle id (`com.dodopharmacy.dodomedAdmin`) so it can be installed
side by side with the user app, and its own app name ("DODOMED Admin").

Nothing about the admin features themselves changed — every screen in
`lib/screens/admin/` is the same code, same UI, same business logic as
before the split; only its imports were repointed at
`package:dodomed_core/...` for the data layer/theme/widgets it shares with
the user app, and at its own `package:dodomed_admin/app/routes.dart`.

## Run

```bash
flutter pub get
flutter run                 # device / emulator
flutter run -d chrome       # web
flutter test
flutter analyze             # clean, no issues
```

Needs the backend running for real data (`cd ../../backend && npm start`);
without it, this still runs against the same offline/mock `AppState` seed
as the user app (one demo learner's worth of data — enough to exercise
every screen, just not multi-user).

Seeded admin account: `admin@dodomed.et` / `admin123` (any email starting
with `admin` gets the admin role — enforced server-side).

## Auth — admin-only, enforced client-side

`LoginScreen`/`SignUpScreen` (from `dodomed_core`) are given this app's
`isAllowed: (state) => state.isAdmin` and a denied message telling a
non-admin account to use the DODOMED (user) app instead — the session is
logged back out immediately if the check fails. There's no server-side
change: the same `POST /api/auth/login`/`/signup` the user app calls.

## What's here (`lib/screens/admin/`)

Full CRUD over everything the learner sees, held on the shared `AppState`:

- **Tracks** — fields of study; deleting one cascades to its packs and questions.
- **Exam packs** — title, track, price, free-question limit, cover image,
  and each pack's own "About Questions" content (summary/bullets/core
  courses) shown to a learner before they start it.
- **E-books** — title, price, cover, subjects, free-page count, content
  either an uploaded PDF or typed pages.
- **Questions** — the exam question bank; the learner's exam reads live
  from this.
- **Payment requests** — approve/reject uploaded receipts; approving
  unlocks the pack/book for that user immediately.
- **About page** — the app-info content shown in the user app's drawer.
- **Bank accounts** — where users are told to transfer payment.
- **Users** — every real account, dated activity, direct open/close access
  control per pack/book (independent of the payment-approval flow above),
  and promoting/demoting admin access itself (with a "can't demote the
  last admin" / "can't demote yourself" safety rail). A book row's preview
  button opens the same `EBookReaderScreen` the user app uses, so admin can
  read what a user actually purchased.
- **Q&A** — every question a learner asked from the user app's Q&A screen,
  pending ones first, answer inline; the answer shows back up on the
  learner's side.

## Testing

`test/admin_test.dart`, `test/admin_users_test.dart`, `test/qa_test.dart`,
`test/ebook_test.dart`, `test/receipt_upload_test.dart`,
`test/about_admin_test.dart`, `test/responsive_test.dart` (overflow sweep
across every admin screen). The counterpart user-facing half of each
split test (asking a question, the free-page reader, submitting a
receipt, etc.) lives in `../user_app/test/`; shared `AppState`-level
coverage (e.g. the Q&A backend methods both apps call) lives in
`../../packages/dodomed_core/test/`.
