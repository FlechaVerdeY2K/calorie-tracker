# Migration Plan — Firebase → Supabase + BLoC + Clean Architecture

**Status:** Draft v0.1
**Last updated:** 2026-04-20
**Scope:** Week 1 of the 6-month build plan

This document is the concrete PR-by-PR checklist for the first week of work. It assumes a fresh start on the Firebase side (no user data to migrate — you confirmed the current Firebase project has no real users yet).

## Week 1 goal

At end of week 1:

- Supabase project is live with full schema + RLS policies applied.
- Flutter app compiles on the new stack (Supabase + BLoC + Clean Architecture + DI).
- Auth feature works end-to-end (email, Google, Apple sign-in).
- Profile feature works end-to-end (body weight, goals, auto-TDEE, macro targets).
- FCM still works for push notifications (Firebase is kept around only for this).
- Nothing else. No food DB. No logging. That's week 2+.

## PR sequence

Each bullet is a standalone PR. Keep PRs small and atomic — OptiGasto convention. Each should have a clear title, scope, and be reviewable in ≤30 minutes.

### PR 1: Repo hygiene and dependency swap

**Branch:** `chore/migrate-to-supabase-stack`

- Delete `cloud_firestore`, `firebase_auth`, `provider`, `shared_preferences` from `pubspec.yaml`.
- Add: `supabase_flutter`, `flutter_bloc`, `bloc`, `dartz`, `get_it`, `injectable`, `freezed_annotation`, `go_router`, `flutter_secure_storage`, `equatable`.
- Add dev deps: `build_runner`, `freezed`, `injectable_generator`, `json_serializable`, `bloc_test`, `mocktail`.
- Keep: `firebase_core`, `firebase_messaging`, `fl_chart`, `google_fonts`, `flutter_dotenv`, `google_sign_in`, `sign_in_with_apple`, `flutter_local_notifications`, `timezone`, `http`, `cupertino_icons`.
- Update `analysis_options.yaml` to match OptiGasto's lint rules.
- Delete `firestore.indexes.json`.
- Keep `firebase.json` but clean out Firestore config; retain only Cloud Messaging.
- Update `README.md` to reflect new stack.
- `flutter pub get`, verify build.

### PR 2: Supabase project setup and schema

**Branch:** `feat/supabase-schema`

This one is mostly out-of-repo (Supabase dashboard) + a migrations folder.

- Create Supabase project. Choose region: US-East for now. Note the URL and anon key.
- Create `supabase/migrations/` folder in repo.
- Write migration `0001_initial_schema.sql` containing:
  - `profiles` table
  - `profile_health` table with `pgsodium` setup
  - `foods` table with generated `calories` column
  - `food_aliases`
  - `food_servings`
  - `food_votes`
  - `meal_entries` with snapshot columns
  - `meal_templates` + `meal_template_items`
  - `daily_metrics`
  - `audit_log`
  - `rate_limits`
  - All indexes (trigram, foreign key, composite)
  - All CHECK constraints
- Write migration `0002_rls_policies.sql` containing every RLS policy from `SECURITY.md`.
- Write migration `0003_triggers_and_functions.sql` with:
  - `prevent_self_vote()`
  - `force_contributor_id()`
  - `promote_food(uuid, text)`
  - `updated_at` auto-update triggers on all tables
- Apply migrations via Supabase CLI. Verify in dashboard.
- Store Supabase URL + anon key in `.env` (add `.env.example` to repo; `.env` stays gitignored).

### PR 3: Core infrastructure

**Branch:** `feat/core-infrastructure`

- Create `lib/core/` folder structure per `DESIGN.md`.
- `lib/core/error/failures.dart` — `Failure` sealed class hierarchy (`ServerFailure`, `CacheFailure`, `AuthFailure`, `ValidationFailure`, `NetworkFailure`).
- `lib/core/error/exceptions.dart` — matching exceptions.
- `lib/core/usecases/usecase.dart` — `abstract class UseCase<Type, Params> { Future<Either<Failure, Type>> call(Params p); }`.
- `lib/core/usecases/no_params.dart`.
- `lib/core/di/injection.dart` — `@InjectableInit()` config.
- `lib/core/di/injection_config.dart` — generated file (via `build_runner`).
- `lib/core/router/app_router.dart` — `go_router` skeleton with auth guards.
- `lib/core/theme/app_theme.dart` — light + dark theme.
- `lib/core/constants/atwater.dart`, `exchanges.dart`, `activity_multipliers.dart`.
- `lib/core/utils/tdee_calculator.dart` — Mifflin-St Jeor BMR + activity multiplier + goal delta.
- `lib/core/utils/macro_targets.dart` — split TDEE into protein/carbs/fat targets.
- Run `build_runner`, commit generated files per OptiGasto convention.

### PR 4: Supabase client initialization

**Branch:** `feat/supabase-client`

- `lib/core/supabase/supabase_client.dart` — singleton wrapper around `Supabase.initialize()`.
- `lib/core/secure_storage/secure_storage_service.dart` — wrapper around `flutter_secure_storage`.
- Configure `Supabase.initialize()` with secure storage for auth persistence (via `localStorage: SecureLocalStorage()` custom implementation, OR verify the default is secure on both platforms — test on physical device).
- Update `main.dart` to init Supabase before `runApp`.
- `.env` loading via `flutter_dotenv` — verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` load correctly.

### PR 5: Auth feature — domain + data layers

**Branch:** `feat/auth-domain-data`

- `lib/features/auth/domain/entities/auth_user.dart` (freezed).
- `lib/features/auth/domain/repositories/auth_repository.dart` (abstract).
- `lib/features/auth/domain/usecases/`:
  - `sign_in_with_email.dart`
  - `sign_up_with_email.dart`
  - `sign_in_with_google.dart`
  - `sign_in_with_apple.dart`
  - `sign_out.dart`
  - `get_current_user.dart`
  - `watch_auth_state.dart` — returns `Stream<Either<Failure, AuthUser?>>`.
- `lib/features/auth/data/datasources/auth_remote_datasource.dart` — wraps `Supabase.auth`.
- `lib/features/auth/data/models/auth_user_model.dart` — fromJson/toJson.
- `lib/features/auth/data/repositories/auth_repository_impl.dart`.
- Register everything in DI with `@injectable` / `@LazySingleton`.
- Unit tests for use cases with `mocktail`.

### PR 6: Auth feature — presentation layer

**Branch:** `feat/auth-presentation`

- `lib/features/auth/presentation/bloc/auth_bloc.dart` — AuthBloc with events: `SignInRequested`, `SignUpRequested`, `SignedOut`, `AuthStateChanged`.
- States (freezed): `AuthInitial`, `AuthLoading`, `Authenticated(AuthUser)`, `Unauthenticated`, `AuthError(String)`.
- `lib/features/auth/presentation/pages/sign_in_page.dart`.
- `lib/features/auth/presentation/pages/sign_up_page.dart`.
- `lib/features/auth/presentation/pages/forgot_password_page.dart`.
- `lib/features/auth/presentation/widgets/social_sign_in_buttons.dart`.
- Wire up `go_router` redirect based on auth state.
- `bloc_test` coverage for all auth events.
- Manual smoke test: email sign-up, email sign-in, Google, Apple, sign-out.

### PR 7: Profile feature — domain + data + presentation

**Branch:** `feat/profile`

Bigger than the splits above, but profile is tightly coupled to TDEE computation and the onboarding flow. Keeping it one PR unless it grows beyond ~500 lines diff.

- Domain entities: `Profile`, `HealthData` (weight/height/DOB kept separate), `MacroTargets`.
- Repository: `ProfileRepository` with `getProfile`, `updateProfile`, `updateHealthData`.
- Use cases: `GetProfile`, `UpdateProfile`, `UpdateHealthData`, `ComputeTDEE`, `ComputeMacroTargets`.
- Data layer: `ProfileRemoteDataSource` with two tables (`profiles` + `profile_health`).
- BLoC: `ProfileBloc` with `LoadProfile`, `UpdateProfile`, `UpdateHealthData` events.
- Pages: `ProfilePage` (view + edit), `OnboardingFlowPage` (multi-step: name → sex/DOB → weight/height → activity → goal → review).
- On first successful sign-in, if profile is incomplete, redirect to onboarding.
- After onboarding, compute TDEE + macro targets and save to profile.
- Test: BLoC states, TDEE math accuracy against reference calculator.

### PR 8: FCM setup (kept from Firebase)

**Branch:** `feat/fcm-setup`

- Initialize `firebase_messaging` alongside Supabase in `main.dart`.
- Handle token refresh, store FCM token in `profiles.fcm_token` column (add to schema if missing — adjust migration).
- Platform-specific setup (iOS: APNs cert upload to Firebase; Android: `google-services.json`).
- No notifications actually sent yet — just the plumbing.
- Handle permission request flow gracefully.

### PR 9: Week 1 wrap-up and docs

**Branch:** `chore/week-1-wrap-up`

- Update `README.md` with setup instructions (Supabase project setup, `.env` creation, Firebase config).
- Add `CONTRIBUTING.md` if applicable.
- Commit `DESIGN.md`, `SECURITY.md`, this file (`MIGRATION_PLAN.md`) to `docs/`.
- Create GitHub issues for week 2+ tasks (food DB seeding, search, logging).
- Tag release `v0.1.0-alpha` — the "auth + profile works" milestone.

## Common pitfalls to avoid

- **Don't try to import user data from Firebase.** You confirmed it's empty. Skip migration code. Start fresh.
- **Don't skip tests in week 1.** The testing pattern you establish here is what the next 6 months will follow. Now is when it's cheap to fix bad patterns.
- **Don't skip RLS testing.** Before PR 9, spin up two test accounts and confirm they cannot read each other's data via direct Supabase queries in the dashboard SQL editor.
- **Don't commit `.env`.** Always check `git status` before committing when working near config.
- **Don't skip the CHECK constraints.** It's tempting to push them to a later migration; they're part of the threat model.

## Dependencies on external decisions

Before starting PR 1, resolve:

- [ ] Supabase region choice (US-East assumed).
- [ ] Supabase tier (Free for dev, Pro before launch — budget decision).
- [ ] Whether to use Supabase Auth's built-in OAuth or `google_sign_in` + `sign_in_with_apple` packages with custom token exchange (recommend: built-in Supabase OAuth for simplicity).
- [ ] App bundle IDs (`com.flechaverde.calorietracker.dev` vs prod).
- [ ] Firebase project — create a new one or reuse the existing calorie-tracker Firebase project? Recommend: keep existing, just strip Firestore/Auth usage.

## Definition of "week 1 done"

- [ ] All 9 PRs merged to `main`.
- [ ] App runs on iOS and Android physical devices.
- [ ] Can create account, sign in, complete onboarding, see own profile.
- [ ] Two test accounts cannot access each other's data (manual RLS test passed).
- [ ] `flutter test` passes.
- [ ] `v0.1.0-alpha` tagged.
- [ ] Design docs committed to `docs/`.

If this slips to week 1.5, that's fine — better a solid foundation than rushing onto a cracked one. If it slips to week 3, something is wrong; stop and reassess.
