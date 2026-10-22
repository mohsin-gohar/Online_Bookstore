# Book Store — Video Demo Script

A **5–7 minute** walkthrough for demoing the Book Store app. Each section lists the
**on-screen actions** and a **one-line voiceover** to read aloud. Timings are
guidelines — adjust to your pace.

> **Before you record:** log out or use a fresh install. The app runs on its
> bundled demo catalogue by default, so no server is needed — the login screen
> shows the two demo accounts (`reader@bookstore.app` / `password123` and
> `admin@bookstore.app` / `admin123`). If you record against the live Laravel API
> instead, make sure the catalogue is seeded (Admin → Seed Sample Data). Record
> in portrait, on a real device or emulator.

---

### 0:00 – 0:15 · Intro

**On screen:** App splash → onboarding.
**Voiceover:** *"Hi, this is Book Store — a Flutter mobile app for buying books, powered by a Laravel REST API, with a complete customer shopping flow and an admin panel."*

---

### 0:15 – 0:50 · Sign Up & Login

**On screen:** Onboarding → **Register** → create an account → land on Home. Then log out and sign back in with the demo customer account.
**Voiceover:** *"Let's start by creating an account — I'll enter my name, email, phone and password, tap Sign Up, and I'm taken straight to the home screen. I can also sign in with my existing credentials, use Google, or reset a forgotten password."*

---

### 0:50 – 1:25 · Home & Catalog Browse

**On screen:** Scroll the **Home** screen — categories, bestsellers, new arrivals. Tap **Catalog** tab and scroll the full list.
**Voiceover:** *"The home screen shows categories, bestsellers and new arrivals, while the catalog lists every book with smooth infinite scrolling."*

---

### 1:25 – 2:00 · Search & Filters

**On screen:** Tap the **search bar**, type a title/author. Open **Filters**, set a category, price range, minimum rating and a sort order, tap **Apply**, then **Reset**.
**Voiceover:** *"I can search by title or author, and combine filters like category, price range, rating and stock, then sort the results — all updating instantly."*

---

### 2:00 – 2:45 · Book Details, Review & Like

**On screen:** Open a **book** → show cover, price, stock, description, related books. Scroll to **Reviews** → **Write a Review** → pick stars + comment → submit. Tap the **heart** on a review to like it.
**Voiceover:** *"On the details page I can read the description and reviews, write my own star rating and comment, and like other readers' reviews — the book's average rating updates automatically."*

---

### 2:45 – 3:20 · Add to Cart

**On screen:** Tap **Add to Cart** from details; go to the **Cart** tab; change quantity with **+ / −**; show the cart badge; remove an item.
**Voiceover:** *"Adding a book updates the cart badge, and in the cart I can adjust quantities or remove items before checking out."*

---

### 3:20 – 4:10 · Checkout & Payment

**On screen:** Tap **Checkout**; pick/add a **shipping address**; pick/add a **payment method** (show last-4 card and Cash on Delivery); show subtotal, shipping, total; tap **Place Order** → success screen.
**Voiceover:** *"At checkout I choose a saved address and payment method — or add a new one — review the totals, and place my order, which clears my cart and shows a confirmation."*

---

### 4:10 – 4:45 · Order Tracking

**On screen:** **Profile → My Orders** → open the new order → **Track Order** → show the timeline (Pending → Confirmed → Shipped → Delivered); show the notification for a status change.
**Voiceover:** *"In My Orders I can open any order to see its details and track it live through the status timeline — Pending, Confirmed, Shipped and Delivered — with in-app notifications as it progresses."*

---

### 4:45 – 5:10 · Wishlist

**On screen:** Tap the **heart** on a book → open **Wishlist** → show saved item → move it to cart / remove it.
**Voiceover:** *"The wishlist lets me save books for later and move them straight into the cart whenever I'm ready."*

---

### 5:10 – 5:40 · Profile & Address Edit

**On screen:** **Profile** tab → **Edit Profile** (change name/phone) → **My Addresses** → add/edit an address, set default → **Payment Methods** → show toggle **Dark Mode**.
**Voiceover:** *"From my profile I can edit my details, manage multiple shipping addresses and payment methods, and switch between light and dark mode."*

---

### 5:40 – 6:40 · Admin Panel

**On screen:** Log in as **admin** → **Admin Dashboard** (Books, Orders, Pending, Revenue) → **Manage Books** (add/edit/delete) → **Manage Categories** → **Manage Orders** (filter by status, advance status) → **Manage Users** (block/unblock).
**Voiceover:** *"As an admin I get a dashboard with sales statistics, and full management screens to add or edit books and categories, update order statuses, and block or unblock users — which the customer sees reflected instantly."*

---

### 6:40 – 7:00 · Outro

**On screen:** Return to the Home screen.
**Voiceover:** *"That's Book Store — a complete, end-to-end book shopping experience built with Flutter and a Laravel REST API. Thanks for watching."*

---

## Recording Tips

- Keep the pointer/touches deliberate and slow enough to follow.
- Use a seeded catalogue so every section has content — the bundled demo data is
  already filled; on the live API use **Admin → Seed Sample Data** first.
- Have a second device/tab ready (or a spare login) to show an admin status change
  reflecting on the customer's Orders screen.
- Keep total runtime under ~7 minutes; trim catalog scrolling if you're over.