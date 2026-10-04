# PharmaReserve — Flutter app

B2B pharmacy ordering app (pharmacies browse a warehouse catalog and order
stock). Flutter for Android, iOS, and Web from one codebase.

## Prerequisites

- Flutter SDK ≥ 3.19 (`flutter --version`)
- A Supabase project (free tier works)

## 1. Set up the backend (Supabase)

1. Create a project at https://supabase.com.
2. In the SQL editor, run, in order:
   - `../backend/supabase/migrations/0001_init.sql`
   - `../backend/supabase/migrations/0002_checkout.sql`
   - `../backend/supabase/migrations/0003_admin_policies.sql`
   - `../backend/supabase/migrations/0004_wallet_promos.sql`
   - `../backend/supabase/seed/seed.sql` (optional sample data)
3. (Optional, for live order updates) **Database → Replication** → enable
   Realtime for the `orders` table.
4. From **Project Settings → API**, copy the **Project URL** and the
   **anon public** key.

## 2. Generate platform folders

This repo tracks only `lib/`, `assets/`, and `pubspec.yaml`. Generate the
Android/iOS/web scaffolding once:

```bash
cd app
flutter create .
flutter pub get
```

## 3. Run

Pass the Supabase credentials as `--dart-define` (never hard-code them):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Web:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Tip: put the defines in a JSON file and use
`--dart-define-from-file=env.json` (git-ignored).

## Structure

```
lib/
  core/        config, DI (get_it), router (go_router), theme, session, errors
  features/
    auth/      login + pharmacy registration (Supabase auth)
    catalog/   product list, search, details
    cart/      cart + items
    orders/    (placeholder — next iteration)
    more/      language switch, logout
    shell/     bottom-nav home shell
```

## Status

MVP vertical slice: **auth + catalog + cart** are wired to Supabase. Next:
order creation/checkout, admin dashboard (web), promos, wallet. See
`../docs/ARCHITECTURE.md` for the roadmap.
