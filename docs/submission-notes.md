# Folio — Submission Notes

Submission checklist, backend setup instructions and demo credentials for the
Folio project.

**Project:** Folio (Flutter + Laravel REST API) · **Version:** 1.0.0

> Replace every `<PLACEHOLDER>` below with your real values before submitting.

---

## 1. Submission Checklist

### Source code
- [x] Complete Flutter source code included (`lib/`, `pubspec.yaml`, `pubspec.lock`).
- [x] Platform folders included (`android/`, `ios/`) so the app builds out of the box.
- [x] Documentation included: `docs/user-guide.md`, `docs/developer-guide.md`,
      `docs/api-contract.md`, `docs/video-script.md`, and `README.md`.
- [x] Backend contract included: `docs/api-contract.md` — the specification the
      Laravel API must satisfy.
- [x] Bundled demo backend included (`lib/data/mock/`), so the app can be
      demonstrated without a server.
- [ ] Laravel backend source included (or a link to its repository).
      - ☐ Source included  ☐ Repository link: `<REPO_URL>`
- [ ] No secrets committed beyond the OAuth client ids (never commit keystores,
      `.env` files, API tokens or real card data).
- [ ] Demo video file/link included (see `docs/video-script.md`).
- [ ] Screenshots included (optional but recommended: home, catalog, checkout, admin).

### Builds
- [x] `flutter analyze` passes with no errors.
- [x] `flutter test` passes (85 tests, all green).
- [ ] `flutter build apk --release` produces an installable APK (if Android APK is required).
- [ ] The app starts on a clean install in **demo mode** (no server required).

### Packaging
- [ ] Zip extracted and re-run successfully by at least one other person.
- [ ] Zip named in the required **Batch/Group/Project-Title** format (see §4).

---

## 2. Backend Setup (Laravel API)

The Flutter app is a client of a **Laravel REST API**. The complete
specification lives in [`docs/api-contract.md`](api-contract.md): the response
envelope, pagination, error codes, authentication, every endpoint with its
payload, the data model and the implementation notes for the server side.

The bundled mock backend (`lib/data/mock/mock_transport.dart`) is a **reference
implementation** of the same contract, so you can read it — or run the app
against it — while you build the real server.

### 2.1 What the server must provide

| Area | Requirement |
|---|---|
| Envelope | Every endpoint returns `{ "success": …, "message": …, "data": …, "meta": … }`. |
| Casing | `snake_case` in request **and** response bodies. |
| Pagination | Laravel's `meta` block (`current_page`, `last_page`, `per_page`, `total`). |
| Errors | `422` with a per-field `errors` map; `401` for an invalid/expired token; `403` for a missing permission. |
| Auth | `POST /auth/login`, `/auth/register`, `/auth/google` return a bearer token in `data.token`; it is sent as `Authorization: Bearer <token>`. |
| Google | `POST /auth/google` takes an `id_token` and **verifies it with Google server-side**. |
| Admin | Every `/admin/*` endpoint requires the `admin` role. |
| Ownership | A customer may only read their own cart, wishlist, orders, addresses, payment methods and notifications. |

### 2.2 Running the server locally

```bash
cd folio-api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

### 2.3 Pointing the app at it

```bash
flutter run --dart-define=API_MODE=live --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

| Where the app runs | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` |
| iOS simulator | `http://127.0.0.1:8000/api` |
| Physical device | `http://<your-lan-ip>:8000/api` |

### 2.4 Database backup / export instructions

The backend uses a relational database, so a plain SQL dump is the export:

```bash
# Export
mysqldump -u <DB_USER> -p <DB_NAME> > database-backup/folio.sql

# Restore
mysql -u <DB_USER> -p <DB_NAME> < database-backup/folio.sql
```

Also include a `database-backup/README.txt` stating the export date, the
database name and the method used.

### 2.5 Seed data

The catalogue the UI expects is defined by the bundled fixture
`lib/data/mock/demo_catalog.dart`: **4 categories** (Fiction, Non-Fiction,
Academic, Comics), **18 books**, **17 authors** and **8 FAQs**. Either seed the
Laravel database with the same rows, or sign in as an admin and use
**Admin Dashboard → Seed Sample Data**, which creates the missing categories and
books through the admin API (existing records are never overwritten).

---

## 3. Demo Login Credentials

Use dedicated demo accounts (never a real personal account).

### Admin account
| Field | Value |
|-------|-------|
| Role | `admin` |
| Email | `admin@folio.app` |
| Password | `admin123` |

### Normal (customer) account
| Field | Value |
|-------|-------|
| Role | `customer` |
| Email | `reader@folio.app` |
| Password | `password123` |

> These two accounts are created by the bundled demo backend, so they work out
> of the box in demo mode — the Login screen even lists them. For a live
> server, create them yourself and set `role = "admin"` on the admin account
> (e.g. with `php artisan tinker`).

### Notes for the evaluator
- Running `flutter run` starts the app in **demo mode**: no server, no
  database, no configuration. The catalogue and both demo accounts are already
  loaded.
- To exercise the real API, start the Laravel app and run with
  `--dart-define=API_MODE=live --dart-define=API_BASE_URL=…`.
- **Google sign-in** needs an OAuth web client id. The checked-in platform files
  still carry the placeholder `YOUR_WEB_CLIENT_ID`, so that button will fail
  until you supply your own id — see the developer guide §3.5.

---

## 4. Zip / Folder Naming Convention

The submission zip folder **must** be named in the format:

```
Batch/Group/Project-Title
```

Examples:

```
Batch7/Group3/Folio-Flutter-Laravel-App
Batch07/Group-02/Folio
```

**Rules:**
- Use the exact **Batch** and **Group** numbers assigned to you.
- Use a clear **Project Title** with hyphens instead of spaces.
- Recommended internal structure:

```
Batch7-Group3-Folio/
├── README.md
├── docs/
│   ├── user-guide.md
│   ├── developer-guide.md
│   ├── api-contract.md
│   └── video-script.md
├── database-backup/
│   ├── README.txt
│   └── folio.sql
├── lib/                # full source
├── android/
├── ios/
└── pubspec.yaml
```

---

## 5. Pre-Submit Final Checks

- [ ] Zip name follows `Batch/Group/Project-Title`.
- [ ] README.md is up to date and points to the docs.
- [ ] `flutter analyze` and `flutter test` are clean, and the app launches from a fresh clone.
- [ ] The app runs in demo mode with no server (and in live mode against your Laravel API).
- [ ] Database export present under `database-backup/`.
- [ ] Demo admin + customer credentials listed in this file (and working).
- [ ] Video demo included or linked.
- [ ] No secrets (keystores, `.env` files, tokens) committed.

---

*See `user-guide.md` for the end-user guide, `developer-guide.md` for setup and
architecture and `api-contract.md` for the backend contract.*