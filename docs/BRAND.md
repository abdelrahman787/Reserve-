# MedStock — Brand guidelines

B2B pharmacy supply platform. The identity reads **corporate, medical,
trustworthy** — a clean blue system with a distribution/warehouse mark.

## Logo

Assets live in `app/assets/brand/`:

| File | Use |
|------|-----|
| `logo_icon.svg` | Full-bleed app icon (rounded blue badge) |
| `logo_mark.svg` | The mark on a blue badge (in-app, compact) |
| `logo_horizontal.svg` | Mark + wordmark lockup (headers, marketing) |
| `icon_1024.png` | 1024×1024 raster, source for launcher icons |

**The mark** = a shipping/warehouse box carrying a medical cross, with an
upward "dispatch" arrow — medicine moving from warehouse to pharmacy.

**In-app lockup**: `BrandLogo` widget (`lib/core/widgets/brand_logo.dart`)
renders the mark + wordmark ("Med" deep blue, "Stock" primary blue).

Clear space: keep at least half the mark's height clear around the logo.
Don't recolor the mark, stretch it, or place the blue badge on a busy
photo without a solid backing.

## Color palette

| Token | Hex | Use |
|-------|-----|-----|
| Primary | `#1E63D0` | Primary actions, links, "Stock" |
| Primary dark | `#14459A` | Headers, "Med", gradients |
| Primary light | `#4C8DF0` | Dark-mode primary, highlights |
| Accent | `#16B6A0` | Availability / success |
| Danger | `#E5484D` | Errors, destructive |
| Warning | `#F2A33C` | Warnings |
| Ink | `#0F1E3D` | Primary text |
| Muted | `#64748B` | Secondary text |
| Border | `#E2E8F0` | Dividers, input borders |
| Background | `#F4F7FC` | App background (light) |
| Surface | `#FFFFFF` | Cards, inputs |

Defined in code: `lib/core/theme/app_colors.dart`; applied in
`lib/core/theme/app_theme.dart` (light + dark).

## Typography

Recommended brand typeface: **Cairo** (excellent Arabic + Latin, matches the
geometric mark). It is **not bundled yet** — the build environment could not
fetch the font files. To enable it:

1. Add the Cairo TTFs (Regular/Medium/SemiBold/Bold) under `app/assets/fonts/`.
2. Declare them under `flutter: fonts:` in `pubspec.yaml`.
3. Set `fontFamily: 'Cairo'` (and matching `TextTheme`) in `AppTheme`.

Until then the app uses the platform default sans, which renders Arabic and
Latin cleanly. Weights in use: 400 body, 600 labels, 700–800 headings/wordmark.

## App icon

Generate platform launcher icons from the 1024 raster:

```bash
cd app
flutter create .            # generate platform folders
dart run flutter_launcher_icons
```

Config is already in `pubspec.yaml` (`flutter_launcher_icons:`), icon source
`assets/brand/icon_1024.png`, adaptive background `#1E63D0`.
