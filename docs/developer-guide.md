# Folio — Developer Guide

A Flutter + Laravel REST API bookstore app (Android & iOS). This document
explains the architecture, folder structure, the REST data model, API
authentication and authorisation, how to set the project up from scratch, how to
test it and how to extend it.

---

## 1. Project Overview & Tech Stack

**Folio** is a mobile e-commerce application for buying books, with a complete
customer shopping flow (browse → cart → checkout → order tracking) and a full
admin panel (manage books, categories, orders and users).

| Layer | Technology | Purpose |
|-------|-----------|---------|
| UI framework | **Flutter** (Dart SDK ^3.12.2) | Cross-platform iOS/Android app |
| Backend | **Laravel REST API** | Accounts, catalogue, cart, orders, admin |
| HTTP client | **dio** | REST calls, bearer-token interceptor, error mapping |
| Auth | **google_sign_in** + server-issued bearer tokens | Email/password & Google sign-in |
| Token storage | **flutter_secure_storage** | Android Keystore / iOS Keychain |
| State management | **provider** (ChangeNotifier) | App-wide state, DI of repositories |
| Navigation | **go_router** | Declarative routing, deep links, route guards |
| Local storage | **shared_preferences** | Theme mode, onboarding flag, recent searches |
| UI extras | `cached_network_image`, `flutter_rating_bar`, `carousel_slider`, `shimmer`, `lottie`, `flutter_animate` | Images, ratings, carousels, skeletons, animations |
| Utilities | `intl`, `image_picker`, `uuid`, `email_validator` | Formatting, image picking, ids, validation |
| Bundled backend | `lib/data/mock/` | An in-memory implementation of the API contract |
| Dev tooling | `flutter_test`, `flutter_lints` | Tests and static analysis |

**Version:** 1.0.0+1 · **App name:** Folio

### Key dependencies (from `pubspec.yaml`)

```yaml
google_sign_in: ^7.1.1
provider: ^6.1.5
go_router: ^16.2.1
cached_network_image: ^3.4.1
flutter_rating_bar: ^4.0.1
carousel_slider: ^5.1.1
shimmer: ^3.0.0
lottie: ^3.3.1
intl: ^0.20.2
shared_preferences: ^2.5.3
image_picker: ^1.2.0
uuid: ^4.5.1
email_validator: ^3.0.0
flutter_animate: ^4.5.2
dio: ^5.11.1
flutter_secure_storage: ^11.2.0
```

### 1.1 Two backends, one contract

The app never talks to a database. It talks to a **transport**, and the
transport is chosen at build time:

| Mode | Selected with | Transport | Use it for |
|---|---|---|---|
| **Mock** (default) | *(nothing — `API_MODE` defaults to `mock`)* | `MockApiTransport` — an in-memory Laravel server | Demos, prototyping, tests |
| **Live** | `--dart-define=API_MODE=live` | `HttpApiTransport` — Dio over HTTP | The real Laravel API |

Both speak the **same** contract ([`docs/api-contract.md`](api-contract.md)), so
a screen that works in mock mode works unchanged against the server.

---

## 2. Folder Structure

The project follows a **layered architecture** with four top-level folders
inside `lib/`, plus `main.dart` and `app.dart` at the root.

```
lib/
├── main.dart                 # Entry point: local storage init, runApp
├── app.dart                  # Root widget: MultiProvider + MaterialApp.router
│
├── core/                     # Cross-cutting: nothing business-specific
│   ├── constants/            # app_colors, app_sizes, app_strings, api_constants
│   ├── routes/               # app_routes, app_pages (GoRouter), admin_guard, app_navigation
│   ├── services/             # local_storage_service (SharedPreferences wrapper)
│   ├── theme/                # app_theme (light + dark Material 3)
│   └── utils/                # formatters, validators, snackbar_helper
│
├── data/                     # Data layer: talks to the REST API
│   ├── models/               # Plain Dart models (BookModel, UserModel, OrderModel, ApiResponse, …)
│   ├── repositories/         # One repository per resource (Book, Cart, Order, …)
│   ├── services/             # api_factory, api_client (Dio), api_transport, token_storage_service,
│   │                         # google_sign_in_service, sample_data_service, app_exceptions
│   └── mock/                 # mock_transport (in-memory Laravel) + demo_catalog (fixtures)
│
├── logic/                    # State layer: ChangeNotifier providers (view-models)
│   └── *_provider.dart       # AuthProvider, BookProvider, CartProvider, OrderProvider, …
│
└── presentation/             # UI layer: screens & widgets
    ├── auth/                 # login, register, forgot_password
    ├── onboarding/           # onboarding_screen
    ├── splash/               # splash_screen
    ├── shell/                # customer_shell (bottom navigation)
    ├── home/                 # home_screen + widgets
    ├── catalog/              # catalog, search, category_books + filter_sheet
    ├── book_details/         # book_details_screen + review widgets
    ├── cart/                 # cart_screen
    ├── checkout/             # checkout, order_success + address/payment sheets
    ├── orders/               # my_orders, order_details, track_order + widgets
    ├── wishlist/             # wishlist_screen
    ├── profile_screen.dart, edit_profile_screen.dart, addresses_screen.dart,
    │   payments_screen.dart, notifications_screen.dart
    ├── admin/                # manage_books, manage_categories, manage_orders, manage_users
    ├── admin_dashboard_screen.dart
    └── common_widgets/       # reusable widgets (buttons, cards, states, fields…)
```

### What lives where — quick reference

| Folder | Contains | Example |
|--------|----------|---------|
| `core/` | App-wide constants, theme, routing table, small utilities. **No business logic.** | `AppRoutes`, `AppColors`, `ApiConstants` |
| `data/models/` | Immutable data classes with `fromMap` / `toMap` / `copyWith`. Parse the API's `snake_case` payloads. | `BookModel`, `OrderModel` |
| `data/repositories/` | Reads/writes one REST resource, returns models, maps errors to `AppException`. | `BookRepository`, `OrderRepository` |
| `data/services/` | The HTTP plumbing: the Dio client, the transport interface, the token store, Google sign-in. | `ApiClient`, `TokenStorageService` |
| `data/mock/` | The bundled in-memory backend and the catalogue fixtures it serves. | `MockApiTransport`, `demo_catalog.dart` |
| `logic/` | `ChangeNotifier` providers holding in-memory state; call repositories; expose loading/error/data. | `AuthProvider`, `CartProvider` |
| `presentation/` | Screens (one per route) and their widgets. Reads providers via `Provider`. | `HomeScreen`, `CheckoutScreen` |

---

## 3. Setup Instructions

### 3.1 Prerequisites

- **Flutter SDK** (stable, Dart ^3.12.2). Install from
  <https://docs.flutter.dev/get-started/install> and verify:
  ```bash
  flutter --version
  flutter doctor
  ```
- **Android Studio** (with an emulator) or **Xcode** (for iOS), or a physical
  device.
- *(Live mode only)* **PHP 8.2+**, **Composer**, and a **Laravel** application
  that implements [`docs/api-contract.md`](api-contract.md).

### 3.2 Clone and install dependencies

```bash
cd bookstore_app
flutter pub get
```

### 3.3 Choose a backend

#### Mock mode (default)

```bash
flutter run
```

Nothing else is needed. The bundled mock backend seeds 4 categories, 18 books,
17 authors, 8 FAQs and two demo accounts, and answers every request with the
contract's envelope. It also simulates ~180 ms of latency, so the loading
states are real.

> The mock is a *faithful* stand-in, not a shortcut: `snake_case` payloads,
> Laravel-style pagination `meta`, `422` validation errors and bearer-token
> sessions.

#### Live mode

Start the Laravel server, then run the app with the mode and the base URL:

```bash
# Terminal 1 — the API
cd ../folio-api
php artisan serve --host=0.0.0.0 --port=8000

# Terminal 2 — the app
flutter run --dart-define=API_MODE=live --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

| Where the app runs | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` (the host machine) |
| iOS simulator | `http://127.0.0.1:8000/api` |
| Physical device | `http://<your-lan-ip>:8000/api` |

On a physical device the phone and the computer must be on the same Wi-Fi
network, and the Laravel server must listen on `0.0.0.0`.

### 3.4 Build-time defines

All of these are `--dart-define`s, read in
`lib/core/constants/api_constants.dart`:

| Define | Default | Meaning |
|---|---|---|
| `API_MODE` | `mock` | `mock` → bundled backend · `live` → the Laravel API |
| `API_BASE_URL` | platform default (see above) | The API root, without a trailing slash |
| `GOOGLE_CLIENT_ID` | *(empty)* | The OAuth **web** client id (iOS & web) |
| `GOOGLE_SERVER_CLIENT_ID` | *(empty)* | The OAuth **web** client id used as the server client id on Android |

`API_MODE=live` without `API_BASE_URL` falls back to `http://10.0.2.2:8000/api`
on Android and `http://127.0.0.1:8000/api` everywhere else.

### 3.5 Google Sign-In setup

The app asks Google for an **ID token** and posts it to `POST /auth/google`;
the server verifies the token and issues the session. The client never decides
who the user is.

To make the button work you need an OAuth **web** client id (Google Cloud
console → APIs & Services → Credentials → OAuth client ID → *Web application*).
Supply it in one of two ways.

**a) At build time**

```bash
flutter run --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com \
           --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com
```

**b) In the platform files** — both ship with the placeholder
`YOUR_WEB_CLIENT_ID`:

| File | Key |
|---|---|
| `android/app/src/main/res/values/strings.xml` | `default_web_client_id` |
| `ios/Runner/Info.plist` | `GIDClientID` and `GIDServerClientID` |

On iOS the app also needs a **URL scheme** for the Google callback. Add the
reversed client id to `CFBundleURLTypes` in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

The Laravel side needs the same client id, so it can verify the ID token it
receives.

### 3.6 Android notes

- The **INTERNET** permission is declared in the debug manifest
  (`android/app/src/debug/AndroidManifest.xml`).
- Cleartext HTTP is enabled **only in debug builds**, through
  `android:usesCleartextTraffic="true"` plus `@xml/network_security_config`. A
  release build must use an `https://` base URL.
- The network-security config it points at ships with the project:
  `android/app/src/debug/res/xml/network_security_config.xml`. The debug
  manifest and the debug-only resource are merged together in debug builds,
  so cleartext HTTP is permitted there and only there — the release build
  contains neither of them.
- The app label is `Folio`
  (`android/app/src/main/AndroidManifest.xml`).

### 3.7 iOS notes

- `CFBundleDisplayName` is `Folio` (`ios/Runner/Info.plist`).
- Add the Google URL scheme as described in §3.5 if you use Google sign-in.
- On the simulator, `127.0.0.1` reaches the Mac's `localhost`, so
  `http://127.0.0.1:8000/api` works out of the box. For a physical device, use
  the Mac's LAN IP.

### 3.8 Demo accounts (mock mode)

The mock backend always creates these two accounts, and the login screen shows
them while running in mock mode:

| Role | Email | Password |
|---|---|---|
| Customer | `reader@folio.app` | `password123` |
| Admin | `admin@folio.app` | `admin123` |

The demo customer starts with a saved address and a saved card, so checkout can
be walked straight through.

In **live** mode, create the equivalent accounts in your Laravel database, and
promote one to `role = "admin"` (for example with `php artisan tinker`).

### 3.9 Run the app

```bash
flutter run                                        # mock mode
flutter run --dart-define=API_MODE=live \
            --dart-define=API_BASE_URL=http://10.0.2.2:8000/api   # live mode
```

Select a device/emulator when prompted. For release builds:

```bash
flutter build apk        # Android
flutter build ios        # iOS (requires macOS + Xcode)
```

---

## 4. Architecture

The app uses a **three-layer architecture** (data → logic → presentation) wired
together with **Provider**. Dependencies always point downward — the UI never
talks to the transport directly.

```
┌──────────────────────────┐
│  presentation/  (Widgets / Screens)                        │
│   reads providers via context.watch / context.read          │
└───────────────▲────────────────────────────┬──────────────┘
                │ notifyListeners()           │ method calls
┌───────────────┴────────────────────────────▼──────────────┐
│  logic/  (ChangeNotifier Providers = view-models)          │
│   AuthProvider, BookProvider, CartProvider, OrderProvider… │
└───────────────▲────────────────────────────┬──────────────┘
                │ models                      │ REST calls
┌───────────────┴────────────────────────────▼──────────────┐
│  data/  (Repositories → Services → ApiTransport)           │
│   BookRepository → ApiFactory → HttpApiTransport | MockApi │
└────────────────────────────────────────────────────────────┘
```

### 4.1 The transport seam

`data/services/api_transport.dart` is the seam every repository talks to:

```dart
abstract class ApiTransport {
  Future<ApiResponse> get(String path, {Map<String, dynamic>? query});
  Future<ApiResponse> post(String path, {Object? body});
  Future<ApiResponse> put(String path, {Object? body});
  Future<ApiResponse> patch(String path, {Object? body});
  Future<ApiResponse> delete(String path, {Object? body});
  Future<ApiResponse> upload(String path, FormData formData);
}
```

`ApiFactory.transport` returns the implementation for the current mode, and it
is a **singleton** — one transport and one token store for the whole app. That
matters in mock mode: two transports would mean two separate in-memory
databases, and a book added to the cart on one screen would vanish on another.

### 4.2 State management with Provider

Every screen reads state from a `ChangeNotifier` provider; the provider is the
**single source of truth** for that slice of the app. All providers are created
once in `app.dart` using `MultiProvider` and injected with their repository:

```dart
ChangeNotifierProvider<CartProvider>(
  create: (ctx) => CartProvider(repository: ctx.read<CartRepository>()),
```

Screens consume them like this:

```dart
final cart = context.watch<CartProvider>();   // rebuilds on change
final itemCount = cart.itemCount;
```

**Consistent 3-state contract.** Providers expose `isLoading` / `error` /
`data` and the UI renders loading, empty, error and success states from those
fields (see `AsyncState<T>` in `book_provider.dart` for the catalog).

**Session sync.** `CartProvider`, `WishlistProvider`, `NotificationProvider` and
`ProfileProvider` expose an `onUserChanged(uid)` method. A single
`UserSessionSync` widget (see
`presentation/common_widgets/user_session_sync.dart`) listens to `AuthProvider`
and calls `onUserChanged` on each provider when the signed-in user changes — so
logging in and out cleanly (re)loads or clears each user's data.

**Cross-provider communication.** `OrderProvider` depends on
`NotificationProvider` via `ChangeNotifierProxyProvider`: when an admin changes
an order's status, a callback (`onStatusChanged`) raises a notification for the
order's owner — without the two providers referencing each other directly.

**Theme** is managed by `ThemeProvider` and persisted with `shared_preferences`
through `LocalStorageService`.

### 4.3 The repository pattern

Each REST resource has **one repository** in `data/repositories/`. A
repository's job is to:

1. Build the request (path + query/body) and send it through the transport.
2. Convert the `data` payload into typed models.
3. Translate HTTP failures into domain `AppException`s (`ServerException`,
   `ValidationException`, `UnauthenticatedException`, …) so providers never see
   Dio or HTTP types.

Example — `BookRepository.queryBooks`:

```dart
Future<PageResult<BookModel>> queryBooks(BookQuery query) async {
  final ApiResponse response = await _api.get(
    ApiConstants.books,
    query: query.toQueryParameters(),
  );
  return response.toPageResult<BookModel>(BookModel.fromMap);
}
```

The filter and sort state is a small value object (`BookQuery`) that knows how
to serialise itself into Laravel's query parameters:

```dart
Map<String, dynamic> toQueryParameters({int? page}) {
  final Map<String, dynamic> params = <String, dynamic>{
    'per_page': pageSize,
    'sort': sort.apiValue,
  };
  if (searchTerm.trim().isNotEmpty) params['search'] = searchTerm.trim();
  if (categoryId != null && categoryId!.isNotEmpty) {
    params['category_id'] = categoryId;
  }
  // … min_price, max_price, min_rating, in_stock, bestsellers, new_arrivals, page
  return params;
}
```

Repositories are **stateless** (no in-memory cache); providers hold state.

### 4.4 Models and key casing

Models are immutable value objects with `fromMap`, `toMap` and `copyWith`. The
API serialises `snake_case` (`cover_image`, `created_at`, `is_bestseller`),
while the models are written in `camelCase`; `normalizeKeys` in
`data/models/model_helpers.dart` converts the **top-level** keys on read, so
every `fromMap` stays free of per-field key juggling. Keys that are already
camelCase are passed through untouched.

### 4.5 The response envelope

Every endpoint — success or failure — returns
`{ "success": …, "message": …, "data": …, "meta": … }`. The envelope is
unwrapped in exactly **one** place (`data/models/api_response.dart`), so the
shape never varies per endpoint:

```dart
final ApiResponse response = await _api.get(ApiConstants.books, query: params);
final PageResult<BookModel> page = response.toPageResult<BookModel>(BookModel.fromMap);
```

`ApiMeta` mirrors Laravel's pagination block (`current_page`, `last_page`,
`per_page`, `total`, `from`, `to`) and turns it into the app's `PageResult<T>`.

### 4.6 Errors

`ApiClient.mapError` translates HTTP status codes into the app's exception
hierarchy:

| Status | Exception | Effect in the UI |
|---|---|---|
| `400` | `ValidationException` | Generic error toast. |
| `401` | `UnauthenticatedException` | The stored token is cleared and the user is signed out. |
| `403` | `AccountBlockedException` | Error toast ("no access to this action"). |
| `404` | `ServerException('not-found')` | Error toast / empty state. |
| `409` | `EmailAlreadyInUseException` | The register form flags the e-mail field. |
| `422` | `ValidationException.withFields` | Per-field messages shown under the matching inputs. |
| `429` | `ServerException` | "Too many attempts. Please wait a moment and try again." |
| `5xx` | `ServerException` | "The server is unavailable. Try again shortly." |
| timeout / connection error | `NetworkException` | "The server took too long to respond." |

---

## 5. Data Model

The data model is **not** defined by the Flutter app: the app is a client of
the Laravel API, and the contract for that API is
[`docs/api-contract.md`](api-contract.md) — §3 for the tables and columns, §2
for every payload. What follows is how the app maps the REST resources onto its
own models.

### 5.1 REST resources

| Resource | Endpoints | App model(s) |
|---|---|---|
| Auth | `POST /auth/register`, `/auth/login`, `/auth/google`, `/auth/logout`, `/auth/forgot-password`, `/auth/reset-password`, `/auth/verify-code` | `UserModel` |
| Profile | `GET /me`, `PUT /me`, `PUT /me/password` | `UserModel` |
| Catalogue | `GET /books`, `/books/{id}`, `/categories`, `/categories/{id}`, `/authors`, `/authors/{id}` | `BookModel`, `CategoryModel`, `AuthorModel` |
| Reviews | `GET /reviews`, `/books/{id}/reviews`, `POST /books/{id}/reviews`, `PUT /reviews/{id}`, `DELETE /reviews/{id}`, `POST /reviews/{id}/like` | `ReviewModel` |
| Shopping | `GET /cart`, `POST /cart/items`, `PATCH /cart/items/{book_id}`, `DELETE /cart/items/{book_id}`, `DELETE /cart`, `GET /wishlist`, `POST /wishlist/{book_id}`, `DELETE /wishlist/{book_id}` | `CartModel`, `CartItemModel`, `WishlistModel` |
| Account | `/orders`, `/addresses`, `/payment-methods`, `/notifications` | `OrderModel`, `OrderItemModel`, `NotificationModel` |
| Help | `GET /faqs`, `POST /support/messages`, `POST /uploads` | `FaqModel` |
| Admin | `/admin/stats`, `/admin/books`, `/admin/categories`, `/admin/authors`, `/admin/orders`, `/admin/users` | the same models, admin screens |

### 5.2 The server-side tables

The Laravel schema the contract expects (the full column list is in
`docs/api-contract.md` §3):

| Table | Holds |
|---|---|
| `users` | Accounts, including `role` (`customer` \| `admin`) and `is_blocked` |
| `categories`, `authors`, `books`, `book_images` | The catalogue |
| `reviews`, `review_likes` | Ratings and the like toggle |
| `cart_items`, `wishlist_items` | Per-user shopping lists |
| `orders`, `order_items`, `order_timeline` | Orders and their status history |
| `addresses`, `payment_methods` | Saved addresses and cards |
| `notifications` | In-app notifications |
| `faqs` | The help content |
| `password_resets`, `personal_access_tokens` | Laravel's password resets and the bearer tokens |

### 5.3 What the app expects on every payload

- **Books** always carry `rating` and `review_count` (denormalised on the
  server), plus `author`, `author_id`, `category_id`, `category_name`,
  `cover_image`, `images[]`, `is_bestseller` and `is_new_arrival`.
- **Reviews** carry `user_name` and `user_photo`, so the list renders without a
  second request.
- **Cart** carries `subtotal`, `shipping`, `total` and `item_count`. The client
  also computes the total locally so it can be shown before checkout, but the
  **server value wins**.
- **Orders** carry `status` and a `timeline[]` of `{status, label, at}` entries.
  The client maps the statuses 1:1: `pending → confirmed → shipped → delivered`,
  or `cancelled`. The transitions are enforced client-side by
  `OrderStatus.canTransitionTo` and must be enforced on the server too.
- **Payment methods** only ever carry the brand and the last four digits — the
  client never sends a full card number.

### 5.4 The bundled demo catalogue

`lib/data/mock/demo_catalog.dart` is the fixture the contract is written
against: 4 categories (`cat_fiction`, `cat_nonfiction`, `cat_academic`,
`cat_comics`), 18 books, 17 authors and 8 FAQs. The Laravel `books`,
`categories` and `authors` tables should be seeded with the same rows. The
Admin Dashboard's **Seed Sample Data** action pushes exactly these rows through
`POST /admin/categories` and `POST /admin/books`, and never overwrites an
existing record.

---

## 6. API Authentication, Authorisation & Token Storage

The server is the only authority: the client stores a credential, presents it on
every request, and obeys what the server says. There is no client-side security
boundary to bypass, because there is no client-side security.

### 6.1 The bearer token

```
POST /auth/login  →  { "success": true, "data": { "token": "1|xxx", "user": { … } } }
```

The token is opaque to the client. It is sent on every subsequent request:

```
Authorization: Bearer <token>
```

The interceptor in `data/services/api_client.dart` attaches it automatically, so
repositories never touch the header themselves. `POST /auth/logout` invalidates
the token on the server and clears it locally.

### 6.2 Token storage

The token lives in the **platform keystore**, via `flutter_secure_storage`
(`TokenStorageService`):

| Platform | Backing store |
|---|---|
| Android | Android Keystore (encrypted preferences) |
| iOS | Keychain |
| Windows | Credential Locker |

It is never written to `SharedPreferences` (which only holds the theme mode, the
onboarding flag and the recent searches) and never appears in a log. Every
keystore call is wrapped in a 2-second timeout and falls back to an in-memory
map, so a wedged keystore can never freeze the splash screen.

### 6.3 Session expiry

When the server answers `401`, the client:

1. clears the stored token,
2. calls `ApiFactory.onUnauthorized`, which the app wires to a clean sign-out,
3. routes back to the login screen.

A `403` is **not** an expiry: it is a permission error and only shows a message.

### 6.4 Google sign-in is verified server-side

The client obtains a Google **ID token** and posts it to `POST /auth/google`:

```json
{ "id_token": "<google id token>" }
```

The **server** verifies it with Google and takes the e-mail, name and picture
from the *verified* token — never from the request body. The client must never
be trusted to assert an identity, and it never does: it holds no secret and
cannot mint a session.

### 6.5 Role-based authorisation

The user's `role` (`customer` or `admin`) comes from the server (`GET /me`, and
the `user` object in every auth response). The client uses it for
**presentation** only: to show the Admin entry in the Profile screen and to
guard the `/admin/*` routes with `AdminGuard.redirect`.

Every admin endpoint is protected **on the server**:

| Endpoint group | Rule |
|---|---|
| `/admin/*` | `admin` role required — `403` otherwise. |
| `/cart`, `/wishlist`, `/orders`, `/addresses`, `/payment-methods`, `/notifications` | The signed-in user's own rows only. |
| `POST /books/{id}/reviews` | `user_id` and `user_name` come from the session, not the body. One review per user per book (`422` otherwise). |
| `PUT` / `DELETE /reviews/{id}` | The author of the review, or an admin. |
| `POST /reviews/{id}/like` | Any signed-in user; the like is recorded per user, so a double-like is impossible. |
| `POST /orders` | The server recomputes the total from the database prices and rejects the order with `422` when the stock is insufficient. |
| `POST /orders/{id}/cancel` | The owner, and only while the order is not terminal. |

### 6.6 Rules the Laravel backend must enforce

These are **server** responsibilities — the client only mirrors them:

- Hash the passwords (bcrypt/Argon) and never return them.
- Use the same message for an unknown e-mail and a wrong password, so the
  endpoint cannot be used to enumerate accounts.
- Return Laravel's `errors` map with a `422` for validation failures.
- Whitelist the `sort` parameter — never interpolate it into an `ORDER BY`
  clause.
- Decrement stock inside a transaction when an order is placed.
- Rate-limit the auth endpoints (`429`).
- Keep role changes server-side: a customer must never be able to set `role` on
  themselves.
- Serve `https` in production and keep the API's CORS policy tight.

---

## 7. Routing

Routes are declared **declaratively** with `go_router` in
`core/routes/app_pages.dart`, using path/name constants from
`core/routes/app_routes.dart`.

- **Customer shell** — a `StatefulShellRoute.indexedStack` provides the 4-tab
  bottom navigation (Home / Catalog / Cart / Profile) with an independent
  navigation stack per tab.
- **Pushed routes** — search, book details, category list, orders, checkout,
  wishlist, profile sub-pages.
- **Admin routes** (`/admin/*`) are protected by `AdminGuard.redirect`, which
  returns a redirect to `/login` (not signed in) or `/home` (signed in, not an
  admin).
- **Global redirect** — `AppPages._redirect` keeps unauthenticated users on the
  auth screens (or onboarding, on a fresh install) and sends an authenticated
  admin straight to the Admin Dashboard.

Example route:

```dart
GoRoute(
  path: AppRoutes.bookDetailsPath,   // '/book/:id'
  name: AppRoutes.bookDetailsName,
  builder: (context, state) => BookDetailsScreen(
    bookId: state.pathParameters['id'] ?? '',
  ),
),
```

Navigate with `context.go(AppRoutes.homePath)` or
`context.goNamed(AppRoutes.bookDetailsName, pathParameters: {'id': bookId})`.
A 404 `errorBuilder` catches unknown paths.

---

## 8. Adding a New Feature

Worked example: **add a "favorites count" badge on the book details page** —
but the same steps apply to any feature. Work **bottom-up** (data → logic → UI).

### Step 1 — (if needed) extend the contract

If the feature needs data the server does not expose yet, add it to
`docs/api-contract.md` **first**, and implement it in the mock backend
(`lib/data/mock/mock_transport.dart`) so the client can be built against it
before the Laravel side exists. The mock is the reference implementation.

### Step 2 — (if needed) extend the data layer

Add a method to the relevant repository in `data/repositories/`:

```dart
// data/repositories/book_repository.dart
Future<int> countFavorites(String bookId) async {
  final ApiResponse response = await _api.get(ApiConstants.book(bookId));
  return (response.map['favoriteCount'] as num?)?.toInt() ?? 0;
}
```

### Step 3 — expose state in a provider

Add loading/error/data fields and an action to a `logic/` provider. Keep the
three-state contract:

```dart
// logic/book_provider.dart
int? _favoriteCount;
int? get favoriteCount => _favoriteCount;

Future<void> loadFavoriteCount(String bookId) async {
  try {
    _favoriteCount = await _books.countFavorites(bookId);
  } on AppException catch (e) {
    // record error
  }
  notifyListeners();
}
```

### Step 4 — build the UI

Add or extend a widget in `presentation/`, reading the provider:

```dart
// presentation/book_details/book_details_screen.dart (excerpt)
final count = context.watch<BookProvider>().favoriteCount;
// render `count` in a badge
```

### Step 5 — (if it's a new screen) register a route

```dart
// core/routes/app_routes.dart
static const String statsPath = '/stats';
// core/routes/app_pages.dart
GoRoute(path: AppRoutes.statsPath, builder: (c, s) => const StatsScreen()),
```

### Step 6 — secure it

If the feature exposes new data, the **Laravel** side must authorise it (see
§6). The client's route guard is a convenience, not a security control.

### Step 7 — test

```bash
flutter analyze
flutter test
flutter run
```

**Checklist for any new feature:** contract → repository → provider → widget →
route (if needed) → server authorisation → analyze/test.

---

## 9. Testing

The suite is plain `flutter_test` — no mocking framework and no network. The
bundled mock backend plays the part of the server, so the tests are
hermetic and fast.

| File | What it covers |
|---|---|
| `test/api_mock_test.dart` | **The API contract as executable tests** — catalogue, search, filters, sorting, categories and authors, registration and sign-in, session protection, cart lines, order placement and stock, reviews and the reference data. |
| `test/app_smoke_test.dart` | **The real app widget** booted against the mock backend: onboarding → login → home. |
| `test/models_test.dart` | Model parsing (`fromMap`, `copyWith`, key normalisation). |
| `test/validators_test.dart` | The form validators. |
| `test/widgets_test.dart`, `test/widget_test.dart` | The reusable widgets. |
| `test/fake_data_factory_test.dart` | The test-data factories in `test/factories/`. |

### Commands

```bash
flutter test                            # the whole suite
flutter test test/api_mock_test.dart    # the contract only
flutter test test/app_smoke_test.dart   # the end-to-end app boot
flutter test --coverage                 # with coverage
flutter analyze                         # static analysis / lints
```

### Writing a test against the API

The transport is injected through `ApiFactory`, so a test can drive the real
repositories against the in-memory backend:

```dart
final TokenStorageService tokens = TokenStorageService.inMemory();
final MockApiTransport transport = MockApiTransport(tokenStorage: tokens);
ApiFactory.overrideTokenStorage(tokens);
ApiFactory.overrideTransport(transport);

final BookRepository books = BookRepository(transport: transport);
final PageResult<BookModel> page = await books.queryBooks(
  const BookQuery(pageSize: 50),
);
expect(page.items, isNotEmpty);
```

> The smoke test never uses `pumpAndSettle` — the app runs looping animations
> (the onboarding carousel auto-advances, the loading placeholders shimmer), so
> the tests advance the clock with explicit `pump` calls instead.

### Checking a live server

Run the app in live mode and walk the flows, or point the contract tests at
your Laravel instance. `docs/api-contract.md` §5 lists the checks.

---

## 10. Handy Commands

```bash
flutter pub get                 # install dependencies
flutter run                     # run in mock mode (no server needed)
flutter run --dart-define=API_MODE=live \
             --dart-define=API_BASE_URL=http://10.0.2.2:8000/api   # run against Laravel
flutter analyze                 # static analysis / lints
flutter test                    # run the tests
flutter test test/api_mock_test.dart    # the API contract, as tests
flutter build apk               # release APK
```

---

## 11. Known Limitations & Future Improvements

### Known limitations (this build)

- **Payments are simulated.** Checkout records a payment *method label* only;
  no payment gateway (Stripe/PayPal) is integrated, and no card data is stored.
- **No push notifications.** Status-change notifications are in-app only; there
  is no push integration.
- **The mock backend lives in memory.** Everything is lost when the app
  restarts — it is a demo aid, not a database.
- **Admin promotion is a server-side operation.** Promoting a user to `admin` is
  done in the Laravel database (there is no in-app "promote to admin" flow).
- **Search is a simple query**, not full-text or typo-tolerant.
- **Images require connectivity** (they are loaded over HTTP by
  `cached_network_image`).
- **The FAQ list has a local fallback**: when `GET /faqs` is unreachable the
  bundled demo list is shown, so the Help screen always has content.
- **Cleartext HTTP is debug-only**: the debug network-security config ships
  with the project (`android/app/src/debug/res/xml/network_security_config.xml`),
  so a release build must point at an `https://` base URL — see §3.6.

### Future improvements

- Integrate a real payment gateway and server-side order confirmation.
- Add push notifications for order status changes and server-side aggregates
  for the dashboard totals.
- Full-text search (Algolia/Typesense or a Laravel search index).
- In-app admin promotion, audit logs and richer analytics dashboards.
- Offline-first caching and optimistic updates.
- Localisation (the `AppStrings`/`AppSizes`/`AppColors` layers are ready for an
  `l10n` migration) and accessibility passes.
- CI (analyze + test on every push).

---

*See `user-guide.md` for end-user documentation, `api-contract.md` for the
backend contract and `submission-notes.md` for the submission checklist and demo
credentials.*