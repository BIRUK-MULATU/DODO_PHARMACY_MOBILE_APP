# DODOMED

A study platform for the Ethiopian pharmacy exit exam / COC exam — a Flutter
app (3,000+ MCQs, a premium e-book, a manual bank-transfer payment flow, an
admin panel) backed by a Node/Express + MongoDB API.

This is a monorepo with two independent, sibling folders:

| Folder | What | Docs |
|---|---|---|
| [`frontend/`](frontend/) | The Flutter app | [`frontend/README.md`](frontend/README.md) |
| [`backend/`](backend/) | The Node/Express + MongoDB API | [`backend/README.md`](backend/README.md) |

They used to live nested (`backend/` inside the Flutter project folder) —
moved apart into these two top-level folders so each is a clean, independent
codebase (its own dependencies, its own `.gitignore`), while staying in one
repo/one git history.

## Quick start

```bash
# Backend (needs a local MongoDB — see backend/README.md)
cd backend
npm install && npm run seed && npm start

# Frontend, in a separate terminal
cd frontend
flutter pub get
flutter run -d chrome   # or a device/emulator
```

The app also runs fully offline with no backend at all (seeded mock data) —
see `frontend/README.md` for that mode and everything else: screen flow,
architecture, testing, animations. See `backend/README.md` for the API's
routes, the paywall model, auth, and what's still missing before a real
deploy.

Seeded accounts once the backend is running: learner `asterali@gmail.com` /
`12345`, admin `admin@dodomed.et` / `admin123` (any email starting with
`admin` gets the admin role).
