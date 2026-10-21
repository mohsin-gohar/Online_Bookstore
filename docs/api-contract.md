# Folio — Laravel API Contract

**Version 1.0** · This document is the contract the Flutter client is written
against. It is the single source of truth for what the Laravel backend must
implement.

The bundled mock backend (`lib/data/mock/mock_transport.dart`) implements this
contract, so it doubles as a **reference implementation** you can read or run
while building the real server:

```bash
flutter run --dart-define=API_MODE=mock
```

---

## 1. Conventions

### 1.1 Base URL

Every path in this document is relative to the API root, e.g.
`http://10.0.2.2:8000/api`.

| Environment | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` |
| iOS simulator | `http://127.0.0.1:8000/api` |
| Physical device | `http://<your-lan-ip>:8000/api` |

Override at build time:

```bash
flutter run --dart-define=API_MODE=live --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

### 1.2 Response envelope

**Every** endpoint — success or failure — returns the same envelope:

```json
{
  "success": true,
  "message": "Success",
  "data": { },
  "meta": { }
}
```

| Field | Type | Notes |
|---|---|---|
| `success` | bool | `false` on any non-2xx response. |
| `message` | string | Human-readable summary. The app shows it verbatim on errors. |
| `data` | object \| array \| null | The payload. Omit the key when there is nothing to return. |
| `meta` | object \| null | Pagination block — present only on paginated endpoints. |

The client unwraps the envelope in exactly one place
(`lib/data/models/api_response.dart`), so the shape must not vary per
endpoint.

### 1.3 Pagination

Paginated endpoints use Laravel's standard resource pagination:

```json
"meta": {
  "current_page": 1,
  "last_page": 4,
  "per_page": 20,
  "total": 78,
  "from": 1,
  "to": 20
}
```

Query parameters: `page` (1-based) and `per_page` (default `20`, max `100`).

The client sends `per_page` on every request it expects to be paginated:
`20` for the catalogue and order lists (`ApiConstants.defaultPerPage` and
`catalogPerPage`), `50` for reviews and notifications, `100` for the
categories, authors and admin-user lists. `page` is only sent when it is
greater than `1`.

A few list endpoints are read by the client as a **plain array** in `data`
(`/books/{id}/reviews`, `/notifications`, `/admin/users`,
`/admin/categories`, `/admin/authors`): `meta` is optional for them, but
return it anyway so the response shape stays uniform.

### 1.4 Key casing

Responses use **`snake_case`** (Laravel's default Eloquent serialisation):
`cover_image`, `created_at`, `is_bestseller`. The client normalises keys to
`camelCase` on read (`normalizeKeys`) — for the top-level object *and* for
every entry of a nested list — so both conventions work, but `snake_case` is
the canonical form.

### 1.5 Errors

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email has already been taken."],
    "password": ["The password must be at least 8 characters."]
  }
}
```

| Status | Meaning | Client behaviour |
|---|---|---|
| `400` | Malformed request | Generic error toast. |
| `401` | Missing / invalid / expired bearer token | Clears the stored token, signs the user out, returns to the login screen. |
| `403` | Authenticated but not allowed (e.g. admin-only endpoint) | Error toast. |
| `404` | Resource not found | Error toast / empty state. |
| `422` | Validation failed | Per-field messages are shown under the matching inputs. |
| `429` | Rate limited | "Too many attempts. Try again shortly." |
| `500` | Server error | Generic error toast. |

> **Important:** `422` must include the `errors` object. The login and
> register forms use it to highlight the offending field.

### 1.6 Authentication

After `POST /auth/login` (or `/auth/register`, `/auth/google`) the server
returns a bearer token in `data.token`. The client stores it in the platform
keystore and sends it on every subsequent request:

```
Authorization: Bearer <token>
```

Tokens are opaque to the client. The client never asserts an identity of its
own — for Google sign-in it forwards the **ID token** and the server verifies
it with Google.

---

## 2. Endpoints

Legend: 🔒 = requires a bearer token · 👑 = admin role required ·
📄 = paginated

### 2.1 Authentication

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `POST` | `/auth/register` | — | Create a customer account. |
| `POST` | `/auth/login` | — | Email + password sign-in. |
| `POST` | `/auth/google` | — | Sign in with a Google ID token. |
| `POST` | `/auth/logout` | 🔒 | Invalidate the current token. |
| `POST` | `/auth/forgot-password` | — | Send a reset code. |
| `POST` | `/auth/reset-password` | — | Complete a reset. |
| `POST` | `/auth/verify-code` | — | Verify an emailed code. |
| `GET` | `/me` | 🔒 | The signed-in user. |
| `PUT` | `/me` | 🔒 | Update the profile. |
| `PUT` | `/me/password` | 🔒 | Change the password. |
| `POST` | `/uploads` | 🔒 | Upload an image (multipart). |

**`POST /auth/register`**

```json
{
  "name": "Ada Lovelace",
  "email": "ada@example.com",
  "password": "secret123",
  "phone": "+92 300 1234567"
}
```

→ `201`

```json
{
  "success": true,
  "message": "Account created.",
  "data": {
    "token": "1|xxxxxxxxxxxxxxxx",
    "user": {
      "id": "usr_01H...",
      "uid": "usr_01H...",
      "name": "Ada Lovelace",
      "email": "ada@example.com",
      "phone": "+92 300 1234567",
      "photo_url": "",
      "role": "customer",
      "is_blocked": false,
      "created_at": "2026-10-20T09:00:00.000000Z",
      "addresses": [],
      "payment_methods": []
    }
  }
}
```

`422` when the e-mail is taken:

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": { "email": ["The email has already been taken."] }
}
```

**`POST /auth/login`**

```json
{ "email": "ada@example.com", "password": "secret123" }
```

→ `200`, same body shape as register. `401` with
`{"success": false, "message": "Invalid email or password."}` for a wrong
password or unknown e-mail (use the same message for both so the endpoint
cannot be used to enumerate accounts).

**`POST /auth/google`**

```json
{ "id_token": "<google id token>" }
```

→ `200`, same body shape. The server verifies the ID token with Google and
either signs in the matching user or creates one. Never trust client-supplied
e-mail or name for Google sign-in — take them from the verified token.

**`POST /auth/forgot-password`**

```json
{ "email": "ada@example.com" }
```

→ `200`. The client ignores the body; answer with the same message whether or
not the address exists, so the endpoint cannot be used to enumerate accounts.
The bundled mock additionally returns `{"email": "...", "devCode": "123456"}`
so the flow can be demonstrated without a mailbox — **a real backend must
never return the code**.

**`POST /auth/verify-code`**

```json
{ "email": "ada@example.com", "code": "123456" }
```

→ `200` when the code matches the one issued by `/auth/forgot-password`,
`422` otherwise.

**`POST /auth/reset-password`**

```json
{ "email": "ada@example.com", "code": "123456", "password": "newsecret123" }
```

→ `200`. The body carries the six-digit `code` **and** the new `password`.

**`GET /me`** → `200`, `data` is the user object.

**`PUT /me`** — partial update of `name`, `phone`, `photo_url`:

```json
{ "name": "Ada Lovelace", "phone": "+92 300 1234567", "photo_url": "https://…" }
```

Only the keys that are present are changed; the client sends whichever subset
it is editing.

**`PUT /me/password`**

```json
{ "current_password": "secret123", "new_password": "newsecret123" }
```

→ `200` with `data: null`. The new password is sent as **`new_password`**
(not `password`) and is checked against `current_password`.

**`POST /uploads`** — `multipart/form-data` with a single `file` part.

→ `200` with the public URL of the stored image:

```json
{ "url": "https://cdn.example.com/uploads/cover.png", "path": "uploads/cover.png" }
```

The client reads `data.url`.

---

### 2.2 Catalogue

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/books` | — | List / search / filter books. 📄 |
| `GET` | `/books/{id}` | — | One book. |
| `GET` | `/categories` | — | All categories. 📄 |
| `GET` | `/categories/{id}` | — | One category. |
| `GET` | `/authors` | — | List / search authors. 📄 |
| `GET` | `/authors/{id}` | — | One author. |
| `GET` | `/reviews` | — | All reviews (admin counter). 📄 |
| `GET` | `/books/{id}/reviews` | — | The reviews of one book. |
| `POST` | `/books/{id}/reviews` | 🔒 | Write a review. |
| `PUT` | `/reviews/{id}` | 🔒 | Edit your review. |
| `DELETE` | `/reviews/{id}` | 🔒 | Delete your review. |
| `POST` | `/reviews/{id}/like` | 🔒 | Toggle a like. |
| `GET` | `/faqs` | — | Published FAQs. |
| `POST` | `/support/messages` | 🔒 | Contact support. |

**`GET /books` query parameters**

| Parameter | Type | Notes |
|---|---|---|
| `page` | int | 1-based page number. Only sent when greater than `1`. |
| `per_page` | int | Page size (default 20). |
| `search` | string | Matches title, author or category name (case-insensitive). |
| `category_id` | string | Restrict to one category. |
| `author_id` | string | Restrict to one author. |
| `author` | string | Restrict by author **name** — sent when only the name is known, not the id. |
| `min_price` / `max_price` | number | Inclusive price range. |
| `min_rating` | number | 0–5. |
| `in_stock` | bool | Only books with `stock > 0`. The client sends `1`. |
| `sort` | string | `newest`, `oldest`, `price_low_high`, `price_high_low`, `popularity`, `rating`. Always sent. |
| `bestsellers` | bool | Only `is_bestseller = true`. The client sends `1`. |
| `new_arrivals` | bool | Only `is_new_arrival = true`. The client sends `1`. |

**`sort` values** — the client sends exactly these six strings, and nothing
else:

| Value | Ordering |
|---|---|
| `newest` | `created_at` descending (the default). |
| `oldest` | `created_at` ascending. |
| `price_low_high` | `price` ascending. |
| `price_high_low` | `price` descending. |
| `popularity` | `review_count` descending. |
| `rating` | `rating` descending. |

**`GET /authors` query parameters**: `search` (matches the name),
`page`, `per_page`.

**`GET /categories` query parameters**: `page`, `per_page`.

**Book object**

```json
{
  "id": "book_1",
  "title": "The Hobbit",
  "author": "J. R. R. Tolkien",
  "author_id": "author_tolkien",
  "isbn": "9780261102217",
  "description": "Bilbo Baggins is swept into a quest…",
  "price": 12.99,
  "stock": 24,
  "cover_image": "https://…/hobbit.jpg",
  "images": ["https://…/hobbit-2.jpg"],
  "category_id": "cat_fiction",
  "category_name": "Fiction",
  "rating": 4.6,
  "review_count": 128,
  "is_bestseller": true,
  "is_new_arrival": false,
  "language": "English",
  "pages": 310,
  "publisher": "Allen & Unwin",
  "release_date": "1937-09-21T00:00:00.000000Z",
  "created_at": "2026-01-04T10:12:00.000000Z"
}
```

**Category object**

```json
{
  "id": "cat_fiction",
  "name": "Fiction",
  "description": "Novels, short stories and literature.",
  "image": "",
  "book_count": 12,
  "created_at": "2026-01-04T10:12:00.000000Z"
}
```

> The client reads `id`, `name`, `description`, `image`, `book_count` and
> `created_at`. An `icon` column may exist in the database, but the app never
> reads it.

**Author object**

```json
{
  "id": "author_tolkien",
  "name": "J. R. R. Tolkien",
  "bio": "…",
  "photo_url": "",
  "book_count": 2,
  "created_at": "2026-01-04T10:12:00.000000Z"
}
```

> The avatar key is **`photo_url`**, not `photo` — the client reads
> `photo_url`.

**FAQ object**

```json
{
  "id": "faq_1",
  "question": "How do I place an order?",
  "answer": "Open a book, tap “Add to Cart”, …",
  "category": "Ordering",
  "sort_order": 0
}
```

**Review object**

```json
{
  "id": "review_12",
  "book_id": "book_1",
  "user_id": "usr_01H...",
  "user_name": "Priya R.",
  "user_photo": "",
  "rating": 5,
  "comment": "An absorbing read.",
  "likes": 4,
  "liked_by": ["usr_01A...", "usr_01B..."],
  "created_at": "2026-10-18T08:00:00.000000Z"
}
```

**`POST /books/{book_id}/reviews`**

```json
{ "book_id": "book_1", "rating": 5, "comment": "An absorbing read." }
```

→ `201` with the created review. One review per user per book — return `422`
when the user has already reviewed that book. The server owns `user_id`,
`user_name` and `user_photo`; take them from the session, never from the
request body.

**`PUT /reviews/{id}`**

```json
{ "rating": 4, "comment": "Revised thoughts…" }
```

**`POST /reviews/{id}/like`** — no body; toggles the current user's like and
returns the updated review.

**`POST /support/messages`**

```json
{ "subject": "Delivery question", "message": "When will my order arrive?" }
```

→ `200` with the created message; the client reads `data.id` as the
confirmation id.

---

### 2.3 Shopping

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/cart` | 🔒 | The signed-in user's cart. |
| `POST` | `/cart/items` | 🔒 | Add a book to the cart. |
| `PATCH` | `/cart/items/{book_id}` | 🔒 | Change the quantity. |
| `DELETE` | `/cart/items/{book_id}` | 🔒 | Remove a line. |
| `DELETE` | `/cart` | 🔒 | Empty the cart. |
| `GET` | `/wishlist` | 🔒 | The signed-in user's wishlist. |
| `POST` | `/wishlist/{book_id}` | 🔒 | Add a book to the wishlist. |
| `DELETE` | `/wishlist/{book_id}` | 🔒 | Remove from the wishlist. |
| `DELETE` | `/wishlist` | 🔒 | Empty the wishlist. |

**`POST /cart/items`**

```json
{ "book_id": "book_1", "qty": 2 }
```

→ `200` with the **whole cart** (not just the changed line), so the client can
replace its state in one move.

**`PATCH /cart/items/{book_id}`**

```json
{ "qty": 3 }
```

→ `200` with the whole cart.

**`DELETE /cart/items/{book_id}`** — no body; → `200` with the whole cart.

**`DELETE /cart`** — no body; → `200` with the emptied cart.

**`POST /wishlist/{book_id}`**

```json
{ "book_id": "book_1" }
```

→ `200` with the whole wishlist. (The id is also the path segment; the body
simply repeats it.)

**`DELETE /wishlist/{book_id}`** — no body; → `200` with the whole wishlist.

**Cart object**

```json
{
  "user_id": "usr_01H...",
  "items": [
    {
      "book_id": "book_1",
      "title": "The Hobbit",
      "price": 12.99,
      "qty": 2,
      "cover_image": "https://…/hobbit.jpg"
    }
  ],
  "updated_at": "2026-10-20T09:10:00.000000Z"
}
```

> The cart carries **lines only** — `subtotal`, `shipping`, `total` and
> `item_count` are computed by the client from the lines, so the server must
> not expect the client to send them. The unit `price` is captured when the
> book is added to the cart.

**Wishlist object**

```json
{
  "user_id": "usr_01H...",
  "items": [
    {
      "book_id": "book_1",
      "title": "The Hobbit",
      "price": 12.99,
      "cover_image": "https://…/hobbit.jpg",
      "added_at": "2026-10-20T09:10:00.000000Z"
    }
  ]
}
```

---

### 2.4 Account

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/orders` | 🔒 | The signed-in user's orders. 📄 |
| `GET` | `/orders/{id}` | 🔒 | One order (owner or admin). |
| `POST` | `/orders` | 🔒 | Place an order. |
| `POST` | `/orders/{id}/cancel` | 🔒 | Cancel an order. |
| `GET` | `/addresses` | 🔒 | Saved addresses. |
| `POST` | `/addresses` | 🔒 | Add an address. |
| `PUT` | `/addresses/{id}` | 🔒 | Update an address. |
| `DELETE` | `/addresses/{id}` | 🔒 | Delete an address. |
| `GET` | `/payment-methods` | 🔒 | Saved payment methods. |
| `POST` | `/payment-methods` | 🔒 | Add a payment method. |
| `PUT` | `/payment-methods/{id}` | 🔒 | Update a payment method. |
| `DELETE` | `/payment-methods/{id}` | 🔒 | Delete a payment method. |
| `GET` | `/notifications` | 🔒 | The signed-in user's notifications. |
| `POST` | `/notifications` | 🔒 | Create a notification for the signed-in user. |
| `POST` | `/notifications/{id}/read` | 🔒 | Mark one as read. |
| `POST` | `/notifications/read-all` | 🔒 | Mark all as read. |
| `DELETE` | `/notifications/{id}` | 🔒 | Delete a notification. |

**`POST /orders`**

```json
{
  "address": "221B Baker Street, Marylebone, London, W1U 7SA",
  "payment_method": "Visa •••• 4242",
  "items": [
    {
      "book_id": "book_1",
      "title": "The Hobbit",
      "price": 12.99,
      "qty": 2,
      "cover_image": "https://…/hobbit.jpg"
    }
  ]
}
```

→ `201` with the created order. The three keys are:

| Key | What it is |
|---|---|
| `address` | A **one-line snapshot** of the chosen address (`line1, line2, city, zip`) — not an address id. |
| `payment_method` | A **label** for the chosen payment method (`"Visa •••• 4242"` or `"Cash on Delivery"`) — not a payment-method id. |
| `items` | The ordered lines, each `{book_id, title, price, qty, cover_image}`. |

The client does **not** send `shipping` or `total`: the server must recompute
the totals from the database prices, decrement the stock in a transaction and
reject the request with `422` when there is not enough stock.

**`POST /orders/{id}/cancel`**

```json
{ "reason": "Changed my mind" }
```

→ `200` with the cancelled order. The client always sends a `reason` (it
falls back to `"Cancelled by user"` when the user typed nothing).

**Order object**

```json
{
  "id": "ord_01H...",
  "user_id": "usr_01H...",
  "user_name": "Ada Lovelace",
  "items": [
    { "book_id": "book_1", "title": "The Hobbit", "price": 12.99, "qty": 2, "cover_image": "…" }
  ],
  "subtotal": 25.98,
  "shipping": 5.99,
  "total": 31.97,
  "status": "pending",
  "address": "221B Baker Street, Marylebone, London, W1U 7SA",
  "payment_method": "Visa •••• 4242",
  "order_date": "2026-10-20T09:10:00.000000Z",
  "delivery_date": "2026-10-23T09:10:00.000000Z",
  "timeline": [
    { "status": "pending",   "at": "2026-10-20T09:10:00.000000Z", "note": "Order placed." },
    { "status": "confirmed", "at": "2026-10-20T10:00:00.000000Z", "note": "Handed to courier" }
  ],
  "cancelled_reason": ""
}
```

> The order date is **`order_date`** (not `created_at`), and a timeline entry
> carries a free-text **`note`** (not a `label` — the client renders the
> status itself).

**Order statuses** — the client maps them 1:1:

`pending` · `confirmed` · `shipped` · `delivered` · `cancelled`

**`GET /orders` query parameters**: `page`, `per_page`. (The `status` filter
is only sent to `/admin/orders` — see §2.5.)

> Shipping is free at or above a subtotal of `$50`; below that a flat `$5.99`
> is charged. The client also computes this locally so the total is visible
> before checkout, but the **server value wins**.

**Address object**

```json
{
  "id": "addr_1",
  "label": "Home",
  "line1": "221B Baker Street",
  "line2": "Marylebone",
  "city": "London",
  "zip": "W1U 7SA",
  "phone": "+92 300 1234567",
  "is_default": true
}
```

`POST /addresses` and `PUT /addresses/{id}` send exactly these keys
(`AddressModel.toMap()`); the client reads exactly these keys back. Extra
columns such as `name`, `state` or `country` may exist in the database, but
the app neither sends nor reads them.

**Payment method object**

```json
{
  "id": "pm_1",
  "type": "Visa",
  "last4": "4242",
  "holder_name": "Ada Lovelace",
  "expiry": "12/30",
  "is_default": true
}
```

`POST /payment-methods` and `PUT /payment-methods/{id}` send exactly these
keys. The card brand lives in **`type`** (the display label, e.g. `"Visa"` or
`"Cash on Delivery"`) and the expiry is a single **`expiry`** string
(`"MM/YY"`) — there is no `brand` / `expiry_month` / `expiry_year` pair.

> The client never sends a full card number — only the brand, the last four
> digits, the holder name and the expiry.

**Notification object**

```json
{
  "id": "ntf_01H...",
  "title": "Order Shipped",
  "message": "Your order ord_01H… is now shipped.",
  "read": false,
  "type": "order",
  "order_id": "ord_01H...",
  "created_at": "2026-10-20T09:12:00.000000Z"
}
```

**`POST /notifications`**

```json
{
  "title": "Order Shipped",
  "message": "Your order ord_01H… is now shipped.",
  "read": false,
  "created_at": "2026-10-20T09:12:00.000000Z",
  "type": "order",
  "order_id": "ord_01H..."
}
```

The body is `NotificationModel.toMap()`. The **recipient is the signed-in
user** — the request carries no user id, so the server takes it from the
bearer token. The server owns `id` and `created_at`.

---

### 2.5 Admin

All admin endpoints require an `admin` role (`403` otherwise) — with one
exception: `PATCH /admin/books/{id}`, which the client calls itself from the
review flow (see §2.5).

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/stats` | Dashboard counters. |
| `GET` | `/admin/books` | Manage books. 📄 |
| `POST` | `/admin/books` | Create a book. |
| `PUT` | `/admin/books/{id}` | Update a book (full replacement). |
| `PATCH` | `/admin/books/{id}` | Refresh the denormalised rating aggregate. |
| `DELETE` | `/admin/books/{id}` | Delete a book. |
| `GET` | `/admin/categories` | Manage categories. 📄 |
| `POST` | `/admin/categories` | Create a category. |
| `PUT` | `/admin/categories/{id}` | Update a category. |
| `DELETE` | `/admin/categories/{id}` | Delete a category. |
| `GET` | `/admin/authors` | Manage authors. 📄 |
| `POST` | `/admin/authors` | Create an author. |
| `PUT` | `/admin/authors/{id}` | Update an author. |
| `DELETE` | `/admin/authors/{id}` | Delete an author. |
| `GET` | `/admin/orders` | Manage orders. 📄 |
| `PATCH` | `/admin/orders/{id}/status` | Advance an order's status. |
| `GET` | `/admin/users` | Manage users. |
| `PATCH` | `/admin/users/{id}/block` | Block / unblock a user. |

> `GET /admin/categories` and `GET /admin/authors` are implemented by the
> bundled mock but are not called by the current client — the admin screens
> read the catalogue through `/books`, `/categories` and `/authors`.

**`GET /admin/stats`**

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "total_books": 18,
    "total_categories": 4,
    "total_authors": 8,
    "total_users": 12,
    "total_orders": 42,
    "pending_orders": 6,
    "revenue": 1284.50
  }
}
```

The revenue figure is read from **`revenue`** — not `total_revenue`. That is
the only field the client reads from this endpoint; every other dashboard
counter comes from the `meta.total` of a dedicated list endpoint
(`/books`, `/admin/orders`, `/admin/orders?status=…`, `/reviews`).

**`PUT /admin/books/{id}`** — full update. The body is `BookModel.toMap()`:
`title`, `author`, `isbn`, `description`, `price`, `stock`, `cover_image`,
`category_id`, `category_name`, `rating`, `review_count`, `is_bestseller`,
`is_new_arrival`, `release_date`, `created_at`, `images`, `language`,
`pages`, `publisher`, `author_id` (plus `id`, which the server ignores —
it is the path segment).

**`PATCH /admin/books/{id}`** — partial update of the denormalised aggregate
only:

```json
{ "rating": 4.6, "review_count": 128 }
```

→ `200` with the updated book. The client sends this after a review is
written, edited or deleted, so the book's `rating` / `review_count` columns
stay in step with the review table. The server may ignore it and recompute
the aggregate itself — but the endpoint must not fail the request.

The client sends this from the review flow, so it is the one admin path a
signed-in **customer** calls: it needs a valid session, not the `admin` role.

**`PATCH /admin/orders/{id}/status`**

```json
{ "status": "shipped", "note": "Handed to courier" }
```

→ `200` with the updated order. The `note` is appended to the order's
timeline. Changing the status should also create a notification for the
order's owner (server-side, not through `/notifications`).

**`PATCH /admin/users/{id}/block`**

```json
{ "is_blocked": true }
```

→ `200` with the updated user.

**`GET /admin/orders` query parameters**: `page`, `per_page`, `status` (one
of the five order statuses). The `meta.total` of the filtered list is what the
dashboard's per-status counters are built from.

---

## 3. Data model

| Table | Key columns |
|---|---|
| `users` | `id`, `name`, `email` (unique), `password`, `phone`, `photo_url`, `role` (`customer`\|`admin`), `is_blocked`, `remember_token`, `timestamps` |
| `categories` | `id`, `name`, `description`, `image`, `book_count`, `timestamps` (`icon` is optional — the client never reads it) |
| `authors` | `id`, `name`, `bio`, `photo_url`, `book_count`, `timestamps` |
| `books` | `id`, `title`, `author_id`, `isbn`, `description`, `price`, `stock`, `cover_image`, `category_id`, `is_bestseller`, `is_new_arrival`, `language`, `pages`, `publisher`, `release_date`, `timestamps` (+ the denormalised `author`, `category_name`, `rating` and `review_count` the client reads) |
| `book_images` | `id`, `book_id`, `url` |
| `reviews` | `id`, `book_id`, `user_id`, `rating`, `comment`, `likes`, `liked_by`, `timestamps` |
| `review_likes` | `id`, `review_id`, `user_id` (unique pair) |
| `cart_items` | `id`, `user_id`, `book_id`, `title`, `price`, `qty`, `cover_image` (unique `user_id`+`book_id`) |
| `wishlist_items` | `id`, `user_id`, `book_id`, `title`, `price`, `cover_image`, `added_at` (unique pair) |
| `addresses` | `id`, `user_id`, `label`, `line1`, `line2`, `city`, `zip`, `phone`, `is_default` |
| `payment_methods` | `id`, `user_id`, `type`, `last4`, `holder_name`, `expiry`, `is_default` |
| `orders` | `id`, `user_id`, `user_name`, `subtotal`, `shipping`, `total`, `status`, `address`, `payment_method`, `order_date`, `delivery_date`, `cancelled_reason`, `timestamps` |
| `order_items` | `id`, `order_id`, `book_id`, `title`, `price`, `qty`, `cover_image` |
| `order_timeline` | `id`, `order_id`, `status`, `at`, `note` |
| `notifications` | `id`, `user_id`, `title`, `message`, `read`, `type`, `order_id`, `timestamps` |
| `support_messages` | `id`, `user_id`, `subject`, `message`, `timestamps` |
| `faqs` | `id`, `question`, `answer`, `category`, `sort_order` |
| `password_resets` | Laravel's default table |
| `personal_access_tokens` | Sanctum's default table |

`rating` and `review_count` on a book are derived from `reviews`; either
denormalise them onto `books` or compute them in the resource. The client
reads both fields, so they must be present on every book payload — and after
a review is written, edited or deleted the client PATCHes the recomputed pair
back to `/admin/books/{id}` (see §2.5).

---

## 4. Implementation notes for the Laravel side

* **Sanctum** bearer tokens are a good fit — the client sends
  `Authorization: Bearer <token>` and nothing else.
* **Resources** should emit `snake_case`; the client normalises to
  `camelCase`. Do not return `createdAt` and `created_at` both.
* **Request bodies** are `snake_case` too (`current_password`,
  `new_password`, `cover_image`, `is_blocked`, `review_count`, …).
* **Validation** must return Laravel's `errors` map with a `422` status.
* **Search** on `/books` should match `title`, `author` and `category.name`
  case-insensitively.
* **Sorting** must be whitelist-driven — never interpolate the `sort`
  parameter into an `ORDER BY` clause. The only accepted values are
  `newest`, `oldest`, `price_low_high`, `price_high_low`, `popularity` and
  `rating`.
* **Stock** must be decremented inside a transaction when an order is placed,
  and the order rejected with `422` when there is not enough stock.
* **Addresses and payment methods** are sent to `POST /orders` as *snapshots*
  (a one-line address string and a method label), never as ids — the server
  stores them on the order row.
* **Timeouts**: the client gives up after 15 s (connect) and 20 s (receive),
  and allows 60 s for a multipart upload. Keep the responses well inside
  those limits.
* **Authorisation**: a customer may only read their own cart, wishlist,
  orders, addresses, payment methods and notifications.

---

## 5. Verifying the implementation

The client ships a mock backend that implements this contract. To check a
live server against it, run the app in live mode and compare, or use the
repository's test suite, which exercises the mock end to end:

```bash
flutter test test/api_mock_test.dart   # the contract, as tests
flutter test test/app_smoke_test.dart  # the app, end to end
```
