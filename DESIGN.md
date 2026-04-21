# Calorie Tracker — Design Document

**Status:** Draft v0.1
**Last updated:** 2026-04-20
**Target:** Public app store launch within 6 months

## Executive summary

A **protein-first nutrition tracker for Latin America** with **exchange-based logging** and a **tiered shared food database**. The wedge against MyFitnessPal is:

1. Curated Costa Rica / LatAm food database (local brands: Dos Pinos, Sabemás, etc.) vs. MFP's crowdsourced mess.
2. Protein-first UI (the metric lifters and recomposers actually care about) vs. calorie-first.
3. Three interchangeable input modes: grams, portions, and dietitian-style exchanges (intercambios) — no mainstream app does this well.

Social features are **not** the wedge. They are a v2 consideration, scoped to small-group accountability rather than a public feed.

## Non-goals

Naming these explicitly so they don't creep into scope:

- Social feed with food photos. (Food-tracking apps that add this become shame machines.)
- AI meal recognition from photos. (Mediocre results from even the best models; expensive; not our differentiator.)
- Recipe import from URLs. (Huge surface area, low early user value.)
- Fitness/workout tracking. (Separate product domain.)
- Full nutrition profile beyond macros + fiber. (Micronutrients come later if ever.)

## Architecture

Clean Architecture + BLoC, mirroring the OptiGasto project structure exactly. Same mental model, same folder conventions, same dependency injection pattern.

```
lib/
├── core/
│   ├── constants/           # Atwater factors, exchange tables, activity multipliers
│   ├── error/               # Failure classes, exceptions
│   ├── usecases/            # base UseCase<Type, Params>
│   ├── di/                  # get_it + injectable config
│   ├── router/              # go_router
│   ├── theme/
│   └── utils/               # macro math, TDEE calculator, unit converter
├── features/
│   ├── auth/
│   │   ├── data/            # Supabase auth datasource, repo impl
│   │   ├── domain/          # entities, repo interface, usecases
│   │   └── presentation/    # BLoC, pages, widgets
│   ├── profile/             # body weight, goals, TDEE, macro targets
│   ├── foods/               # shared DB: search, add, flag, upvote, detail
│   ├── logging/             # meal entries, daily view, templates, repeat-yesterday
│   ├── analytics/           # charts, trends, weekly/monthly views
│   └── social/              # v2 — folder scaffolded now, implemented later
└── main.dart
```

### Stack

| Concern | Choice |
|---|---|
| Backend | Supabase (Postgres, Auth, Storage, Edge Functions) |
| State management | `flutter_bloc` + `dartz` for `Either<Failure, T>` |
| DI | `get_it` + `injectable` |
| Routing | `go_router` |
| Immutable state | `freezed` + `build_runner` |
| Push notifications | Firebase Cloud Messaging (via `firebase_messaging` only — **no** Firestore, **no** Firebase Auth) |
| Secure storage | `flutter_secure_storage` (iOS Keychain / Android Keystore) |
| Charts | `fl_chart` |
| Barcode scan (v1.2+) | `mobile_scanner` |
| Auth providers | Email/password, Google Sign-In, Sign in with Apple (required for iOS app store) |

**Removed from current pubspec:** `cloud_firestore`, `firebase_auth`, `provider`, `shared_preferences` (replaced by `flutter_secure_storage`).

## Domain model

### Core rule: calories are derived, not stored

Protein, carbs, and fat are stored; calories are computed via the Atwater factors (4/4/9) as a Postgres generated column. This prevents the #1 bug in crowdsourced food databases: entries where the stored calorie value doesn't match the stored macros. If macros are right, calories are right. Always.

```dart
// lib/core/constants/atwater.dart
class Atwater {
  static const double kcalPerGramProtein = 4;
  static const double kcalPerGramCarbs = 4;
  static const double kcalPerGramFat = 9;

  static double calories({required double p, required double c, required double f}) =>
      p * kcalPerGramProtein + c * kcalPerGramCarbs + f * kcalPerGramFat;
}
```

### Entities (simplified — see `features/*/domain/entities/` for full code)

```dart
enum TrustTier { verified, community, personal }
enum LogInputMode { grams, portions, exchanges }
enum MealType { breakfast, lunch, dinner, snack }
enum Goal { deficit, maintain, surplus }

class Food {
  final String id;
  final String name;
  final List<String> aliases;
  final String? brand;
  final String? barcode;
  final FoodCategory category;
  final double referenceAmount;      // always 100 for /100g foods, or 1 for unit foods
  final String referenceUnit;         // 'g', 'ml', 'unit'
  final Macros macros;                // normalized to reference serving
  final List<Serving> servings;       // [(name: "scoop", gramsEquivalent: 30)]
  final TrustTier tier;
  final String? contributorId;
  final int upvotes;
  final int flags;
  // calories not stored — always compute from macros
}

class Macros {
  final double protein;  // grams
  final double carbs;    // grams
  final double fat;      // grams
  final double fiber;    // grams

  double get calories => Atwater.calories(p: protein, c: carbs, f: fat);
}

class MealEntry {
  final String id;
  final String userId;
  final String foodId;
  final FoodSnapshot snapshot;  // frozen macros at log time
  final double quantity;
  final String unit;
  final double gramsEquivalent; // resolved grams for analytics
  final MealType mealType;
  final LogInputMode inputMode;
  final DateTime consumedAt;
}
```

### Immutability and the snapshot pattern

Every `MealEntry` stores a **frozen copy** of the food's macros at log time. When someone edits a food (e.g., corrects a miscalculated protein value), existing meal entries continue to reflect what the user *actually* logged. This protects user history from retroactive edits.

Food edits are never in-place. They are "propose new version" — a new `foods` row is created, and the old row's `superseded_by` column points to the new one. Searches return the new version; old meal entries still reference the old one via snapshot.

## The exchange system (differentiator)

The Latin American dietitian convention, built into the app as a first-class input mode.

```dart
// lib/core/constants/exchanges.dart
class ExchangeTable {
  static const proteinGramsPerExchange = 7.0;
  static const carbsGramsPerExchange = 15.0;
  static const fatGramsPerExchange = 5.0;

  // Food-group shortcuts
  static const fruitCarbsPerExchange = 15.0;
  static const dairyCarbsPerExchange = 12.0;
  static const dairyProteinPerExchange = 8.0;
}
```

A single food can be logged in any of three modes, shown simultaneously in the UI:

- **Grams:** `350g pollo pechuga`
- **Portions:** `1 pechuga (≈350g)`
- **Exchanges:** `15.5 protein exchanges`

The `input_mode` field on `meal_entries` records which mode the user actually used, giving us signal about adoption.

## Supabase schema

Full schema with RLS policies lives in `SECURITY.md`. Abbreviated overview:

| Table | Purpose |
|---|---|
| `profiles` | User profile extension (weight, goals, targets); PII in separate `profile_health` table |
| `profile_health` | Encrypted sensitive health data (body weight, height, DOB) |
| `foods` | Shared food database, 3 tiers |
| `food_aliases` | Multilingual synonym search |
| `food_servings` | Named portions ("1 scoop = 30g") |
| `food_votes` | Upvote/flag signals |
| `meal_entries` | The log (with denormalized snapshot) |
| `meal_templates` + `meal_template_items` | Saved meals for fast re-logging |
| `daily_metrics` | Per-day basal metabolism, exercise burn, weight |
| `audit_log` | Append-only admin action trail |
| `rate_limits` | Per-user operation throttling |

Critical schema decisions:

- `foods.calories` is a **generated column** computed from macros. Cannot be inconsistent.
- `foods.tier` is never writable by users via direct UPDATE — only via `promote_food()` RPC called by admins.
- `meal_entries` has a denormalized `*_snapshot` for every macro.
- `pg_trgm` extension enabled for fuzzy name search; no external search service needed.
- CHECK constraints enforce physical plausibility (protein ≤ 100g per 100g of food, etc.).

## The core logging flow

### Home screen (daily view)

```
┌─────────────────────────────────────┐
│  Monday, Apr 20          [⚙ profile]│
├─────────────────────────────────────┤
│                                     │
│        ●●●●●●●○○○                   │
│       Protein: 147 / 180g           │
│                                     │
│  ●●●●○○○  ●●●●●○○  ●●●○○○○          │
│  Carbs     Calories  Fat            │
│  180/250g  1840/2200 48/70g         │
│                                     │
│  ─────────────────────────────      │
│                                     │
│  Breakfast                          │
│   Yogurt Griego Dos Pinos    220k   │
│   GNC Whey, 2 scoops         220k   │
│                                     │
│  Lunch                              │
│   Pollo Pechuga, 350g        354k   │
│   Rice, 150g                 195k   │
│                                     │
│  [⟲ Repeat yesterday]  [＋ Log food]│
└─────────────────────────────────────┘
```

Protein ring is visually dominant — this is the whole point.

### Log sheet

Opens from the "Log food" FAB. Three tabs:

1. **Recent** — foods you've logged in the last 30 days, ordered by frequency. This is the hot path. 80% of logs hit this.
2. **Templates** — saved meal templates (breakfast, pre-workout shake, etc.).
3. **Search** — the shared DB. Trigram + alias search. Tier badges visible.

After picking a food: serving picker with live macro preview and the three-mode toggle.

If search fails: "Add it" button at the bottom. Opens quick-add form — stays in `personal` tier by default with a "contribute to community" toggle (gated by 7-day account age, see `SECURITY.md`).

### The "repeat yesterday" primitive

One button that copies yesterday's entries to today. Your brother deletes the spreadsheet data every day and re-enters the same foods. This feature makes that a single tap. Probably the single highest-leverage retention feature in the app.

## Build plan — 6 months to public launch

The 6-week dogfooding plan scales up to a 6-month public launch. Weeks 1-6 are unchanged from the draft. What follows is months 2-6.

### Weeks 1-6: Core MVP (dogfoodable by you + brother)

- **Week 1:** Foundation — rip out Firestore/Firebase Auth, add Supabase + BLoC stack, auth + profile, RLS policies.
- **Week 2:** Shared DB foundation — seed ~80 foods from brother's spreadsheet (cleaned + label-verified), search with trigram, add personal food flow.
- **Week 3:** Core logging loop — log meal, daily view, protein-first rings, edit/delete.
- **Week 4:** Retention — meal templates, repeat-yesterday, daily_metrics, recent foods tab. **Start dogfooding here.**
- **Week 5:** Exchange system — exchange tables, input-mode toggle, named servings.
- **Week 6:** Polish — upvote/flag, basic trust scoring, charts (`fl_chart`), settings, CSV export, onboarding.

### Weeks 7-10: Hardening + private beta

- **Week 7:** Bug-fix sprint based on your own dogfood. No new features.
- **Week 8:** Security review pass (see `SECURITY.md` pre-launch checklist). Penetration test with a friend.
- **Week 9:** Onboard 3-5 trusted users. Instrument analytics (opt-in): daily active, logs per user, retention D1/D7/D30.
- **Week 10:** Fix whatever they broke.

### Weeks 11-16: Public beta features

- **Week 11-12:** Barcode scanning + OpenFoodFacts fallback. `mobile_scanner` integration.
- **Week 13:** Community food tier goes live to all users (with 7-day friction). Flag/review queue.
- **Week 14:** Trust scoring refinement. Admin dashboard (web) for food review queue.
- **Week 15:** Analytics view: weekly/monthly trends, weight tracking graph.
- **Week 16:** Localization polish — full es-CR → es (regional), English as secondary.

### Weeks 17-24: Launch prep

- **Week 17-18:** App store assets, screenshots, listings, privacy policy, terms of service.
- **Week 19-20:** App store submission (iOS review is the bottleneck — plan for 1-2 review cycles).
- **Week 21:** Soft launch in Costa Rica only (limit risk, concentrate user acquisition).
- **Week 22-24:** Monitor, fix, iterate. Expand regionally only after retention metrics prove out.

### What *not* to build in the first 6 months

- Friend accountability groups (v2).
- Workout tracking / activity integration (v2).
- AI photo recognition (v3 if ever).
- Web app (mobile first — mobile only, for launch).
- Premium tier / payments (defer until post-launch retention is proven).

## Success criteria

At public launch, the app is successful if:

- You and your brother have used it daily for 3+ months and prefer it to the spreadsheet.
- Food database has >500 verified entries covering the most common Costa Rican products.
- D30 retention in private beta >40% (industry benchmark for food trackers is ~20%).
- Zero critical security findings from pre-launch audit.
- App store review approved first attempt.

## Open questions

Things not yet decided that will need resolution before launch:

- Monetization: freemium (with premium analytics/unlimited templates) vs. one-time purchase vs. fully free at launch? Recommend: **free at launch**, decide monetization only after proving retention.
- Localization beyond es-CR: when to add other Spanish-speaking markets vs. staying regional.
- HealthKit / Health Connect integration: weight auto-sync is nice; full fitness integration is scope creep.
- Eventual web companion app for easier food database admin.

## References

- `SECURITY.md` — threat model, RLS policies, encryption, pre-launch checklist
- `MIGRATION_PLAN.md` — concrete week-1 PR checklist for Firebase → Supabase transition
- OptiGasto repo structure (reference implementation for Clean Architecture + BLoC pattern)
