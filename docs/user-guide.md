# Folio — User Guide

Welcome to **Folio**, a mobile shopping app for buying books. This guide walks
you through everything a customer can do in the app, step by step, and answers
the most common questions.

> **App:** Folio · **Platforms:** Android & iOS · **Version:** 1.0.0

---

## 1. Overview

**Folio** is a Flutter mobile application that lets readers:

- Browse a catalog of books organised by category (Fiction, Non-Fiction, Academic, Comics).
- Search by title/author and filter by price, rating and availability.
- Read book details, reviews and ratings, and leave their own review.
- Save books to a **Wishlist** and add them to a **Cart**.
- Checkout with a saved shipping address and payment method.
- Track orders through a live status timeline (Pending → Confirmed → Shipped → Delivered).
- Manage their profile, saved addresses and payment methods.

The app has **two kinds of accounts**:

| Role | What they can do |
|------|------------------|
| **Customer** | Browse, buy, review, manage own profile/orders. |
| **Admin** | Everything a customer can do, **plus** a full Admin Panel to manage books, categories, orders and users. |

The Admin Panel is only visible to accounts whose role is `admin`.

### 1.1 Two ways to run Folio

| Build | Where the data comes from | What you see |
|---|---|---|
| **Demo mode** (the default) | A sample catalogue that ships **inside the app** — no server and no setup needed. | The Login screen shows two ready-made demo accounts. |
| **Live mode** | The store's real server (a Laravel REST API). | No demo accounts — you sign in with your own account. |

Which one you get is decided when the app is built; you cannot switch it from
inside the app. Every screen behaves identically in both modes — only the data
behind it differs.

---

## 2. Getting Started

### 2.1 Create an account (Sign Up)

1. Open the app. On first launch you'll see the **Onboarding** screens — tap **Skip** or **Get Started**.
2. On the **Login** screen, tap **Register** (or *Don't have an account? Sign Up*).
3. Fill in:
   - **Full Name**
   - **Email**
   - **Phone Number** (optional but recommended for delivery)
   - **Password** and **Confirm Password**
4. Tap **Sign Up**. Your account is created on the store's server and you land on the **Home** screen.

If the e-mail is already registered, the form says so under the field — switch
to **Login** instead.

### 2.2 Log in

1. Open the **Login** screen (the app shows it automatically when you are signed out).
2. Enter your **Email** and **Password**.
3. Tap **Login**.

If you were already logged in, the app remembers you and takes you straight to Home.

### 2.3 Log in with Google

1. On the **Login** or **Register** screen, tap **Continue with Google**.
2. Pick your Google account.
3. Folio sends a Google **ID token** to the store's server, the server verifies it and signs you in. You land on the **Home** screen.

> The app never decides who you are — the **server** verifies the Google token
> every time. If you see *"Google sign-in failed"*, the app was probably built
> without a Google client id.

### 2.4 Demo accounts (demo mode only)

| Role | Email | Password |
|---|---|---|
| Customer | `reader@folio.app` | `password123` |
| Admin | `admin@folio.app` | `admin123` |

They are printed on the Login screen in demo mode, so you can simply type them
in. The demo customer already has a saved address and a saved card, so checkout
can be walked straight through.

### 2.5 Log out

1. Go to the **Profile** tab (bottom navigation, far right).
2. Scroll down and tap **Logout**.
3. Confirm in the dialog (**Logout**).

Your cart, wishlist and orders stay saved to your account and reappear the next time you log in.

### 2.6 Reset a forgotten password

1. On the **Login** screen, tap **Forgot Password?**
2. Enter the **email** associated with your account.
3. Tap **Send Reset Link**.
4. The app confirms with **Check your inbox** — follow the reset link in the email from the store to choose a new password.

> For security, the app shows the same confirmation whether or not the email exists (this prevents strangers from discovering registered emails).
>
> In demo mode there is no mailbox, so keep using the demo password.

---

## 3. Browsing Books

### 3.1 Home screen

The **Home** tab is your storefront. It shows:

- A **search bar** at the top.
- **Categories** — tap any category tile to see all books in it.
- **Bestsellers** — a horizontally scrollable row of popular titles.
- **New Arrivals** — the latest additions.
- **See All** buttons expand a section into the full **Catalog**.

### 3.2 Catalog tab

The **Catalog** tab lists every book in the store, newest first, and loads more
as you scroll (infinite scroll).

### 3.3 Search

1. Tap the **search bar** on Home (or the search icon).
2. Type a **title**, **author** or **genre** (e.g. "Silent Patient", "Michaelides").
3. Results update as you type. Tap a result to open the **Book Details** page.

### 3.4 Filters and sorting

1. On the **Catalog** screen, tap the **Filters** button.
2. Set any of:
   - **Category** (Fiction, Non-Fiction, Academic, Comics)
   - **Price Range** (min / max)
   - **Minimum Rating** (e.g. 4★ and up)
   - **In Stock Only**
   - **Sort By** — Newest, Oldest, Price: Low→High, Price: High→Low, Popularity, Rating
3. Tap **Apply**. The list updates instantly.
4. Tap **Reset** / **Clear All** to remove all filters.

---

## 4. Book Details, Reviews & Likes

### 4.1 Book Details

Open any book to see its cover, title, author, price, stock status, description,
average rating, and related books (*"You may also like"*).

- **Add to Cart** — adds the book (asks you to log in if you aren't).
- **Buy Now** — adds the book and jumps straight to checkout.

### 4.2 Write a review

1. On the Book Details page, scroll to **Reviews**.
2. Tap **Write a Review**.
3. Pick a **star rating** (1–5) and write a short **comment**.
4. Tap **Submit**. Your review appears at the top of the list, and the book's average rating updates automatically.

You can edit or delete **your own** review later.

### 4.3 Like a review

- Tap the **heart / thumbs-up** icon on any review to like it. Tap again to unlike.
- The like count updates for everyone. Each account can like a review only once.

---

## 5. Cart & Checkout

### 5.1 Add to cart

- From a **book card** or the **Book Details** page, tap **Add to Cart**.
- A badge on the **Cart** tab shows the total number of items. Books already in the cart increase in quantity.

### 5.2 Manage the cart

In the **Cart** tab you can:

- Change quantity with the **+ / −** selector (the quantity is capped at available stock, and reaching 0 removes the item).
- Remove a book with the trash icon.
- See the live **Subtotal**.

### 5.3 Checkout

1. Tap the **Cart** tab, then **Checkout**.
2. Choose a **Shipping Address**. Tap **Add Address** if you don't have one yet
   (Label, Line 1, Line 2, City, ZIP, Phone).
3. Choose a **Payment Method**. Tap **Add Payment** to save a card (brand, last 4
   digits, name, expiry) or use **Cash on Delivery**.
4. Review the **Subtotal**, **Shipping** and **Total**.
   - Shipping is **free on orders of $50 or more**; otherwise a flat $5.99 applies.
5. Tap **Place Order**.

You'll see the **Order Placed Successfully!** confirmation with your Order ID. Your cart is emptied automatically.

### 5.4 Add / manage a payment method

1. Go to **Profile → Payment Methods**.
2. Tap **Add Payment** and enter your card details (only the brand, last 4 digits,
   holder name and expiry are stored — never the full card number).
3. Set a **Default** method, edit or delete existing ones from the same screen.

> Payment in this build is a **simulation** for the demo/academic project. No real
> charge is made and no real card data is stored.

---

## 6. Orders & Tracking

### 6.1 View order history

1. Go to **Profile → My Orders** (or the Orders entry on your profile).
2. Every order shows its **Order ID**, date, total, item count and current **status chip**.

### 6.2 Order details & tracking

1. Tap an order to open **Order Details** (items, address, payment method, totals).
2. Tap **Track Order** to see a **live timeline**:
   **Pending → Confirmed → Shipped → Delivered**.
3. The current step is highlighted; a progress bar shows how far the order has got.

### 6.3 Cancel an order

- While an order is still active — **Pending**, **Confirmed** or **Shipped** — you
  can cancel it from the Order Details screen. The store's server has the final
  say on whether the cancellation is accepted.
- Cancelled orders show a **Cancelled** chip and cannot change status afterwards.

### 6.4 Notifications

As an admin updates your order status, you receive an **in-app notification**
(bell icon / notifications screen) telling you the new status.

---

## 7. Wishlist

- Tap the **heart** icon on any book card or on the Book Details page to save it.
- Open the **Wishlist** screen to see all saved books.
- From the Wishlist you can **move an item to the cart** or **remove** it.
- The wishlist is tied to your account and syncs across devices.

---

## 8. Profile, Addresses & Settings

Open the **Profile** tab to manage:

| Option | What it does |
|--------|--------------|
| **Edit Profile** | Update your **name**, **phone number** and **profile photo**. |
| **My Addresses** | Add, edit, delete addresses and set a **default**. |
| **Payment Methods** | Add, edit, delete saved cards and set a **default**. |
| **My Orders** | View order history and tracking. |
| **Wishlist** | View saved books. |
| **Notifications** | Read and clear in-app notifications. |
| **Dark Mode** | Toggle light/dark theme (persisted on your device). |
| **Logout** | Sign out of the app. |

**Address editing:** Profile → *My Addresses* → tap an address to edit, or
**Add Address** to create a new one. Only one address can be the default at a time.

**Profile photo:** In *Edit Profile*, tap the avatar to pick a new image from
your gallery.

---

## 9. Admin Panel (admin accounts only)

If your account role is **admin**, an **Admin** entry appears on the Profile
screen (and signing in takes you straight to the dashboard). The Admin Panel includes:

- **Dashboard** — total **Books**, **Orders**, **Pending** orders and **Revenue**.
  Also has a **"Seed Sample Data"** action that adds the sample books and
  categories to the catalogue (existing records are never overwritten).
- **Manage Books** — add, edit and delete books (title, author, price, stock,
  category, cover, description, bestseller/new-arrival flags).
- **Manage Categories** — add, edit and delete categories.
- **Manage Orders** — view all orders, filter by status, and advance an order's
  status (Confirm → Ship → Deliver) or cancel it.
- **Manage Users** — view all registered users and **block/unblock** accounts.
  Blocked users are signed out and cannot log back in.

---

## 10. Frequently Asked Questions (FAQ)

**1. Is Folio free to use?**
Yes. The app itself is free; you only "pay" for books during checkout (which is
simulated in this demo build).

**2. Do I need an account to browse?**
You can open the app and look around, but **adding to cart, buying, reviewing and
using the wishlist require login**.

**3. What is the difference between demo mode and live mode?**
Demo mode runs on a sample catalogue that is built into the app and shows two
demo accounts on the Login screen. Live mode talks to the store's real server.
Everything else on the screen is the same.

**4. I forgot my password. What do I do?**
Tap **Forgot Password?** on the Login screen, enter your email, and follow the
reset link sent to your inbox.

**5. Why don't I see my order after checkout?**
Give it a second to sync, then open **Profile → My Orders** and pull to refresh.
See Troubleshooting below if it still doesn't appear.

**6. Can I change my delivery address after ordering?**
No. The address is saved as a snapshot on the order at checkout. To use a new
address, cancel the order (if still allowed) and place a new one.

**7. What payment methods are supported?**
Saved cards (Visa/Mastercard/Amex — displayed as last 4 digits only) and
**Cash on Delivery**. No real card number is ever stored.

**8. Is shipping free?**
Shipping is **free for orders of $50 or more**; otherwise a flat **$5.99** applies.

**9. Can I review a book more than once?**
No — one review per book per account. You can **edit** your existing review
instead.

**10. Can I cancel an order after it has shipped?**
Cancellation is offered while the order is still active — **Pending**,
**Confirmed** or **Shipped**. Once **Delivered**, the order can no longer be
cancelled.

**11. How do I delete my account or data?**
Contact support / your administrator. Admins can remove a user profile from the
Admin Panel → Manage Users.

**12. Why can't I log in / my account says it's blocked?**
An administrator may have blocked your account (e.g. for abuse). Contact support
to resolve it.

**13. Where is my data stored?**
Your account, cart, wishlist and orders live on the store's **server** (a Laravel
REST API) and are tied to your account. On your device the app keeps only your
session token — stored in the phone's **secure keystore**, never in plain
settings — plus the theme choice and your recent searches.

---

## 11. Troubleshooting

### Login fails
- **"Invalid email or password."** — Double-check spelling and capitalisation, or
  use **Forgot Password?** to reset.
- **Email already registered (on sign-up).** — Use **Login** instead, or reset the password.
- **"Your account has been blocked."** — Contact support; an admin has disabled the account.
- **"Network error. Check your connection and try again."** — In live mode, verify your
  internet connection (Wi-Fi or mobile data) and retry. In demo mode this usually means
  the bundled catalogue could not be reached — restart the app.
- **Google sign-in cancelled** — This is not an error; reopen the Google sheet and
  complete the flow, or use email/password login.

### My order isn't showing
1. Pull down to **refresh** on the **My Orders** screen.
2. Make sure you're logged into the **same account** used to place the order.
3. Check your **connection** — orders are loaded from the store's server.
4. If it was just placed, wait a few seconds; the list may still be syncing.

### Checkout won't let me place the order
- Ensure you have a **shipping address** selected (or added).
- Ensure your **cart isn't empty** — an empty cart blocks checkout.
- If a book shows **Out of Stock**, remove it or reduce the quantity.

### Cart / Wishlist seems empty after logging in
- Cart and wishlist load **per account**. Make sure you logged in with the account
  you used before.

### Book images won't load
- The covers are fetched over the network (from the store's server in live mode, and
  from the catalogue's image links in demo mode), so a connection is needed for the
  pictures themselves. A placeholder image appears whenever a cover cannot be loaded.

### App shows "Something went wrong. Please try again."
- This is a generic server/network message. Check your connection and retry the
  action. If it persists, restart the app.

### Dark text / white screen at startup
- The app needs to reach the store's server in live mode. Check your connection and
  restart the app. If the app was never configured for a server, it should have
  started in demo mode.

---

*For developer and setup information, see `developer-guide.md`. For the backend
contract, see `api-contract.md`. For submission checklists and credentials, see
`submission-notes.md`.*