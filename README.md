# MedStock

**B2B pharmacy ordering platform** — pharmacies browse a warehouse/distributor
catalog and place stock orders; warehouse staff manage the catalog, pricing and
incoming orders. Built with **Flutter** (Android · iOS · Web) + **Supabase**.

## Documentation

| Doc | Contents |
|-----|----------|
| [`docs/DOCUMENTATION.md`](docs/DOCUMENTATION.md) | **Full project documentation** — features, database, components, security, status |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Stack, layering, roadmap |
| [`docs/BRAND.md`](docs/BRAND.md) | Logo, color palette, typography, app icon |
| [`docs/NOTIFICATIONS.md`](docs/NOTIFICATIONS.md) | Firebase push setup |
| [`app/README.md`](app/README.md) | Build & run the Flutter app |

## Quick start

1. Create a Supabase project; run `backend/supabase/migrations/0001…0006.sql`
   then `backend/supabase/seed/seed.sql` in the SQL editor.
2. `cd app && flutter create . && flutter pub get`
3. `flutter run -d chrome --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…`

See [`app/README.md`](app/README.md) for full steps.

## Layout

```
app/       Flutter app (lib/core + lib/features, tests, assets)
backend/   Supabase migrations, seed, Edge Functions
docs/      Documentation + extracted reference data
```

---

*Origin: this project was built after the loss of the source of the owner's
existing Flutter app. See `docs/DOCUMENTATION.md` §1.*
