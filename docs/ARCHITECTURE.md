# PharmaReserve — B2B Pharmacy Ordering Platform

A B2B marketplace where **pharmacies** browse the catalog of **warehouses /
distributors** and place stock orders. Inspired by, and informed by analysis
of, the owner's existing PharmaLink app (a Flutter app of the same domain).

## Product summary

- **Who uses it:** pharmacy owners/staff (the buyers) and warehouse/vendor
  staff + platform admins (the sellers/operators).
- **Core flows (MVP):**
  1. **Auth** — pharmacy registration + login; account approval by the
     warehouse/admin.
  2. **Catalog** — browse drugs by category, search by trade/generic name or
     company, filter by price; product details (generic name, pharmacology,
     producer, price, availability).
  3. **Cart & Orders** — add to cart, apply promo, checkout, track order
     status through delivery rounds.
  4. **Admin dashboard** (Flutter Web) — manage products, pricing, stock, and
     review/fulfil orders.

## Tech stack

| Layer | Choice |
|-------|--------|
| Client | Flutter (Android, iOS, Web — single codebase) |
| Architecture | Clean Architecture (presentation / domain / data) |
| State mgmt | BLoC / Cubit (`flutter_bloc`) |
| Routing | `go_router` |
| DI | `get_it` (+ `injectable` optional) |
| Backend | **Supabase** — Postgres, Auth, Storage, Realtime, auto REST |
| Data access | `supabase_flutter` (+ repositories wrapping it) |
| Admin | Flutter Web build of the same app (admin shell) |

This mirrors the architecture recovered from the reference app
(BLoC + go_router + get_it + clean layering — see
`docs/extracted/reference_app_dart_files.txt`) while replacing its proprietary
.NET/SignalR backend with Supabase (Realtime replaces SignalR).

## Layering (per feature)

```
features/<feature>/
  data/          # models (DTOs), datasources (supabase), repositories impl
  domain/        # entities, repository interfaces, usecases
  presentation/  # cubits/blocs, pages, widgets
```

Shared infrastructure lives in `core/` (config, DI, router, theme, network,
error handling, shared widgets) — same split as the reference app's `core/`.

## Backend (Supabase)

Schema lives in `backend/supabase/migrations/`. Highlights:

- `pharmacies` (buyer accounts) and `vendors` (warehouses) as the two sides.
- `products` is the shared drug catalog; `vendor_products` holds each vendor's
  **price + stock** for a product (the B2B multi-distributor model — the
  reference app surfaced this as "Offers from distributors").
- `orders` are per-vendor; `order_items` snapshot name/price at purchase time.
- `promos`, `wallets` + `wallet_transactions`, `favorites` (favorite
  suppliers) round out the MVP.
- **Row Level Security** scopes each pharmacy to its own cart/orders/wallet,
  and each vendor to its own products/orders; platform admins see all.

## Status / roadmap

- [x] Repo + architecture + extracted reference data
- [ ] DB schema + RLS (in progress)
- [ ] Flutter app scaffold (core: config, DI, router, theme, Supabase)
- [ ] Auth feature (register pharmacy / login)
- [ ] Catalog feature (list, search, filter, details)
- [ ] Cart + checkout + orders
- [ ] Admin dashboard (web)
- [ ] Seed data + end-to-end run instructions

## Notes on the reference app

The reference APK is a **Flutter release build**; its Dart source is AOT-
compiled to machine code and **cannot be decompiled back to source**. What we
reuse is the recoverable material: the feature/architecture map, the full
dependency list (`docs/extracted/reference_packages.txt`), API/endpoint shape,
and the i18n strings (`docs/extracted/i18n_reference/`). No proprietary binary,
branding, or copyrighted asset from the reference app is shipped in this new
app.
