# MedStock — Project Documentation

B2B pharmacy ordering platform. Pharmacies browse a warehouse/distributor
catalog and place stock orders; warehouse staff manage the catalog, pricing
and incoming orders. Flutter (Android / iOS / Web) + Supabase.

> Related docs: [`ARCHITECTURE.md`](ARCHITECTURE.md) ·
> [`BRAND.md`](BRAND.md) · [`NOTIFICATIONS.md`](NOTIFICATIONS.md) ·
> app build/run: [`../app/README.md`](../app/README.md)

---

## 1. Context & origin

The project was created for the repository owner after they lost the source of
their existing Flutter app **PharmaLink**. Because PharmaLink ships as a Flutter
*release* build, its Dart source is AOT-compiled to machine code and **cannot be
decompiled**. Only recoverable material was reused — the feature/architecture
map, dependency list, API shape, and i18n strings (saved under
`docs/extracted/`). No proprietary binary, branding, or asset from PharmaLink is
shipped here. From there, **MedStock** was built fresh as a new product.

---

## 2. Tech stack

| Layer | Choice |
|-------|--------|
| Client | Flutter (one codebase: Android, iOS, Web) |
| Architecture | Clean Architecture (data / domain-ish / presentation) |
| State management | BLoC / Cubit (`flutter_bloc`) |
| Routing | `go_router` (with auth redirect) |
| DI | `get_it` |
| Backend | Supabase — Postgres, Auth, Storage, Realtime, auto REST |
| Data access | `supabase_flutter` wrapped in repositories |
| i18n | `easy_localization` (JSON, ar + en, RTL) |
| Push | Firebase Cloud Messaging (guarded) |
| CI | GitHub Actions (analyze + test) |

Validated in-env (Flutter 3.47 / Dart 3.13): `flutter analyze` clean,
`flutter test` passing (9), `flutter build web` succeeds.

---

## 3. Project structure

```
Reserve-/
├─ app/                              # Flutter app
│  ├─ assets/
│  │  ├─ brand/                      # logo SVGs + icon_1024.png
│  │  └─ translations/{en,ar}.json   # i18n
│  ├─ lib/
│  │  ├─ core/
│  │  │  ├─ config/env.dart          # --dart-define config
│  │  │  ├─ di/service_locator.dart  # get_it registrations
│  │  │  ├─ error/failures.dart
│  │  │  ├─ router/app_router.dart   # go_router + auth redirect
│  │  │  ├─ services/notification_service.dart
│  │  │  ├─ session/session_service.dart
│  │  │  ├─ theme/{app_colors,app_theme}.dart
│  │  │  └─ widgets/{brand_logo,empty_state,app_loader}.dart
│  │  ├─ features/
│  │  │  ├─ auth/      (login, register, reset) data+cubit+pages
│  │  │  ├─ catalog/   (list, search, filter, details) data+cubit+pages
│  │  │  ├─ cart/      (shared CartCubit) data+cubit+pages
│  │  │  ├─ orders/    (list, details, status, realtime) data+cubit+pages
│  │  │  ├─ wallet/    (balance, transactions) data+pages
│  │  │  ├─ admin/     (products, orders, promos) data+pages
│  │  │  └─ shell/     home_shell.dart (bottom nav + cart badge)
│  │  └─ main.dart
│  └─ test/                          # unit + smoke tests
├─ backend/supabase/
│  ├─ migrations/0001…0006.sql       # schema, RPC, policies
│  ├─ functions/send-notification/   # FCM Edge Function (template)
│  └─ seed/seed.sql                  # sample data
├─ docs/                             # this folder
└─ .github/workflows/ci.yml          # CI
```

Each feature follows: `data/` (models, repository) · `presentation/`
(cubit + state, pages, widgets).

---

## 4. Features

### 4.1 Pharmacy (buyer) app

| Screen | What it does |
|--------|--------------|
| **Login** | Email/password sign-in; "Forgot password?" (reset email); link to register. Shows the MedStock logo. |
| **Register** | Creates an auth user + a `pharmacies` row linked to the profile (name, license, phone, email, address). |
| **Catalog (Home)** | Product list; search by trade/generic name or company; **category chips**; **price-range filter** sheet; shimmer loading; empty/error states. |
| **Product details** | Trade/generic name, pharmacology, indications, dosage; Rx badge; number of distributor offers; **quantity selector**; add to cart (cheapest in-stock offer). |
| **Cart** | Line items with **quantity steppers** and remove; promo-code field; live total; checkout. Cart count shows as a **badge** on the nav bar. |
| **Orders** | List of the pharmacy's orders with status chips; **live-updates** (Realtime); order details (items, subtotal, discount, delivery fee, total, note). |
| **Wallet** | Balance card + transaction history (credit/debit). |
| **More** | Admin entry (if vendor/admin), Wallet, language switch (ar/en), logout. |

### 4.2 Warehouse (seller) dashboard — Flutter Web, role `vendor`/`admin`

| Tab | What it does |
|-----|--------------|
| **Products** | Lists the vendor's offers; edit price / discount / stock / availability; add a new product (catalog + offer). |
| **Incoming orders** | Orders placed to this vendor; change status via a bottom sheet; **live-updates** (Realtime). |
| **Promos** | Create promos (code, percent/fixed value, min order); toggle active. |

---

## 5. Database (Supabase / Postgres)

Migrations in `backend/supabase/migrations/`, applied in order.

### Tables

| Table | Purpose / key columns |
|-------|-----------------------|
| `vendors` | Warehouses/distributors — name, logo, status |
| `pharmacies` | Buyer accounts — name, license_number, phone, address, lat/lng, status |
| `profiles` | Links `auth.users` → role (`pharmacy`/`vendor`/`admin`) + pharmacy_id/vendor_id. Auto-created by trigger on sign-up. |
| `categories` | Drug categories — name_en, name_ar, parent_id, sort_order |
| `products` | Shared catalog — trade_name, generic_name, pharmacology, producer, indications, dosage, image_url, requires_rx |
| `vendor_products` | Per-vendor **price + stock** for a product (the "offers from distributors" model); discount_percent, is_available |
| `carts` / `cart_items` | One active cart per pharmacy; items reference a `vendor_products` row + quantity |
| `promos` | code, d_type (percent/fixed), d_value, min_order, vendor_id (null = platform-wide), validity window, is_active |
| `orders` | Per-vendor — status, subtotal, discount, delivery_fee, total, promo_code, note, delivered_at |
| `order_items` | Snapshot of product_name, unit_price, quantity, line_total |
| `wallets` / `wallet_transactions` | Per-pharmacy balance (auto-created) + credit/debit history |
| `favorite_vendors` | A pharmacy's favorite suppliers |
| `device_tokens` | FCM push tokens per user |

### Enums
`user_role`, `account_status`, `order_status`
(`pending`→`confirmed`→`processing`→`out_for_delivery`→`delivered`/`cancelled`),
`discount_type`, `wallet_txn_type`.

### `checkout` RPC (`0002`)
A `SECURITY DEFINER` function that, for the caller's cart: groups items by
vendor, creates **one order per vendor** with snapshotted item prices, applies
an optional promo, then empties the cart — all atomically. It resolves the
pharmacy from `auth.uid()`, so a caller can only check out their own cart.

### Row Level Security
RLS is enabled on every table. Summary:
- **Catalog** (`categories`, `products`, `vendors`, `vendor_products`, `promos`):
  readable by authenticated users; writable by admins; a vendor writes its own
  `vendor_products` and promos (and may add products).
- **Pharmacy-owned** (`carts`, `cart_items`, `orders` (own), `wallets`,
  `wallet_transactions`, `favorite_vendors`, `pharmacies` (own)): scoped to the
  signed-in pharmacy via `current_pharmacy_id()`.
- **Orders**: a pharmacy sees its own; a vendor sees orders placed to it;
  admins see all. Vendors/admins can update status.
- **device_tokens**: each user manages only their own.

Migrations: `0001` schema+RLS, `0002` checkout RPC, `0003` vendor-can-add-
products, `0004` wallet auto-create + vendor promos, `0005` device_tokens,
`0006` pharmacies policies.

---

## 6. Key app components

- **`service_locator.dart`** — registers repositories, `SessionService`,
  `NotificationService`, and the shared **`CartCubit`** (singleton, so the cart
  page, product add-to-cart, and nav badge stay in sync).
- **`app_router.dart`** — `go_router`; redirects to `/login` when signed out and
  to `/home` when signed in, driven by Supabase auth changes.
- **`SessionService`** — caches the current user's role, pharmacy_id, vendor_id.
- **Cubits** — `AuthCubit`, `CatalogCubit` (search/category/price filters),
  `CartCubit`, `OrdersCubit` (with Realtime subscription).
- **Theme** — `AppColors` (blue brand palette) + `AppTheme` (light/dark, M3).
- **Shared widgets** — `BrandLogo`, `EmptyState`, `AppLoader` / `ShimmerBox`.

---

## 7. Internationalization & brand

- `easy_localization` loads `assets/translations/{en,ar}.json` (99 keys each,
  kept in parity). Arabic triggers RTL automatically.
- Brand: logo (SVG), blue palette, app icon — see [`BRAND.md`](BRAND.md).
  Recommended font **Cairo** is documented there (not bundled: font CDNs were
  blocked in the build env; the app uses the system sans until enabled).

---

## 8. Push notifications (FCM)

Client integration is built and **guarded** (the app runs normally without
Firebase). Flow: `NotificationService.init()` → request permission → after
login `registerToken()` saves the FCM token to `device_tokens` → the
`send-notification` Edge Function pushes to a user's devices. Full setup
(flutterfire configure, web service worker, function deploy) in
[`NOTIFICATIONS.md`](NOTIFICATIONS.md).

---

## 9. Setup & run (summary)

1. Create a Supabase project; run migrations `0001`→`0006` then `seed/seed.sql`
   in the SQL editor. Disable "Confirm email" (Auth) for quick testing; enable
   Realtime for `orders` for live updates.
2. Copy the **Project URL** and **anon public** key.
3. `cd app && flutter create . && flutter pub get`
4. `flutter run -d chrome --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`
5. To try the dashboard: set your profile's `role='vendor'` and
   `vendor_id` to the seed vendor, then re-login → More → Warehouse dashboard.

Full details, including the admin SQL snippet, are in
[`../app/README.md`](../app/README.md).

---

## 10. Testing & CI

- `app/test/`: unit tests for pricing/best-offer, order/cart parsing, plus a
  smoke test (9 tests). Run `flutter test`.
- `.github/workflows/ci.yml`: runs `flutter analyze` + `flutter test` on every
  push to `main` and every PR (Flutter 3.47.6).

---

## 11. Security notes

- All data access is behind **RLS**; the Supabase `anon` key is safe to ship
  (gated by RLS) and is injected via `--dart-define`, never committed.
- The `checkout` RPC and auth triggers are `SECURITY DEFINER` and resolve the
  actor from `auth.uid()`, so users cannot act on others' data.
- The `send-notification` function uses the service-role key and a Firebase
  service account (secrets); review its auth before exposing it publicly.

---

## 12. Status, limitations & roadmap

**Done:** auth (+ reset), catalog (search/filter/categories), cart (+ qty),
checkout + orders (+ status + realtime, both sides), wallet (view), warehouse
dashboard (products/orders/promos), brand identity, push-notification
integration, i18n (ar/en), tests + CI.

**Known limitations (out of MVP scope):**
- No real **payment gateway**; the wallet is display-only and checkout does not
  charge. No wallet top-up / order-paid debits yet.
- No account/profile editing; no catalog pagination/infinite scroll.
- Product **images**: schema supports `image_url`, but no in-app upload yet
  (recommended next step: admin image upload to Supabase Storage).
- FCM sending requires the owner's Firebase project.
- Cairo brand font not bundled (see BRAND.md).

**Suggested next steps:** product-image upload (Storage), payment gateway +
wallet debits, order-status → push trigger, catalog pagination, account
settings, more tests.
