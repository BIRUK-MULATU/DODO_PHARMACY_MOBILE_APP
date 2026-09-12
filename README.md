# DODOMED

A study platform for the Ethiopian pharmacy exit exam / COC exam — 3,000+
MCQs, a premium e-book, a manual bank-transfer payment flow — backed by a
Node/Express + MongoDB API.

This is a monorepo. **On this branch (`separeteUA`), the Admin and User
experiences are two completely separate, independently buildable and
deployable Flutter apps**, sharing one backend and one Dart package of
common code:

| Folder | What | Docs |
|---|---|---|
| [`apps/user_app/`](apps/user_app/) | The learner-facing app (this is the original app — same package name, same Android/iOS identity) | [`apps/user_app/README.md`](apps/user_app/README.md) |
| [`apps/admin_app/`](apps/admin_app/) | The staff-only admin app — a separate installable app (own `applicationId`/bundle id/app name: "DODOMED Admin") | [`apps/admin_app/README.md`](apps/admin_app/README.md) |
| [`packages/dodomed_core/`](packages/dodomed_core/) | Shared Dart package: `AppState`, the API client, models, theme, reusable widgets, and the auth/splash/e-book-reader screens both apps use — consumed by both apps as a local path dependency | — |
| [`backend/`](backend/) | The Node/Express + MongoDB API — unchanged, serves both apps identically | [`backend/README.md`](backend/README.md) |

Neither app can log the other's account type in — logging into `user_app`
with an admin account (or `admin_app` with a learner account) is rejected
client-side with a message pointing at the right app. Both otherwise talk
to the exact same backend.

`apps/user_app` used to also contain every admin screen
(`lib/screens/admin/`) directly; those moved out into `apps/admin_app`,
and everything both apps needed (data layer, design system, a few
shared screens) moved into `packages/dodomed_core` so neither app
duplicates that logic. See each folder's own README for details specific
to it.

## Quick start

```bash
# Backend (needs a local MongoDB — see backend/README.md)
cd backend
npm install && npm run seed && npm start

# User app, in a separate terminal
cd apps/user_app
flutter pub get
flutter run -d chrome   # or a device/emulator

# Admin app, in a separate terminal
cd apps/admin_app
flutter pub get
flutter run -d chrome
```

Both apps also run fully offline with no backend at all (seeded mock
data) — see each app's own README for that mode and everything else:
screen flow, architecture, testing, animations. See `backend/README.md`
for the API's routes, the paywall model, auth, and what's still missing
before a real deploy.

Seeded accounts once the backend is running: learner `asterali@gmail.com` /
`12345` (use in `user_app`), admin `admin@dodomed.et` / `admin123` (use in
`admin_app`) — any email starting with `admin` gets the admin role.
