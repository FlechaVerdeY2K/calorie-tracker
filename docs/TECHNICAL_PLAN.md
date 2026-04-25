# Calorie Tracker — Complete Technical Plan

**Status:** Authoritative reference document
**Last updated:** 2026-04-23
**Purpose:** Self-contained build plan that can be executed PR-by-PR without external guidance.

This document consolidates everything needed to build the Calorie Tracker app from current state (Firebase scaffold) to public app store launch. Keep it in `docs/TECHNICAL_PLAN.md` in the repo and update it as decisions change.

---

## Table of contents

1. [Product summary](#1-product-summary)
2. [Decisions locked in](#2-decisions-locked-in)
3. [Architecture overview](#3-architecture-overview)
4. [Complete Supabase schema](#4-complete-supabase-schema)
5. [RLS policies (full text)](#5-rls-policies-full-text)
6. [Triggers, functions, and RPCs](#6-triggers-functions-and-rpcs)
7. [Flutter project structure](#7-flutter-project-structure)
8. [Core utilities and constants](#8-core-utilities-and-constants)
9. [Feature-by-feature build spec](#9-feature-by-feature-build-spec)
10. [Complete 6-month PR sequence](#10-complete-6-month-pr-sequence)
11. [Testing strategy](#11-testing-strategy)
12. [Code patterns and conventions](#12-code-patterns-and-conventions)
13. [Edge Functions](#13-edge-functions)
14. [Seeding the food database](#14-seeding-the-food-database)
15. [Pre-launch checklist](#15-pre-launch-checklist)
16. [Common pitfalls and debugging](#16-common-pitfalls-and-debugging)
17. [Glossary and references](#17-glossary-and-references)

---

## 1. Product summary

**What:** A protein-first nutrition tracker for Latin America with exchange-based logging and a tiered shared food database.

**Why it's different:**
1. Curated Costa Rica / LatAm food database (Dos Pinos, Sabemás, etc.) vs. MyFitnessPal's crowdsourced mess.
2. Protein-first UI — the metric lifters and recomposers actually care about — vs. calorie-first.
3. Three interchangeable input modes: grams, portions, and dietitian-style exchanges (intercambios).

**Who it's for:** People in Costa Rica / LatAm who want to hit protein goals without fighting with a food database that doesn't know what "Yogurt Griego Dos Pinos" is. Initial users: you and your brother, expanding to public launch within 6 months.

**Non-goals (do not build):**
- Social feed with food photos (shame machine territory).
- AI meal recognition from photos (mediocre, expensive, not a differentiator).
- Recipe import from URLs (huge surface area, low early value).
- Fitness/workout tracking (separate product domain).
- Micronutrients beyond fiber (maybe later).
- Web app (mobile only for launch).

---

## 2. Decisions locked in

These have been decided. Do not revisit without strong reason.

| Decision | Choice | Rationale |
|---|---|---|
| Backend | Supabase (Postgres) | Relational queries fit food search better than Firestore; aligns with OptiGasto stack |
| State management | flutter_bloc | Same pattern as OptiGasto; mature |
| Architecture | Clean Architecture | Same pattern as OptiGasto |
| DI | get_it + injectable | Standard pattern |
| Routing | go_router | Standard pattern |
| Immutable models | freezed | Standard pattern |
| Push notifications | FCM (kept from Firebase) | Supabase has no native equivalent |
| Secure storage | flutter_secure_storage | Keychain/Keystore backed; required for tokens |
| Firebase project | Reuse existing | `google-services.json` already configured |
| OAuth approach | Native flows (google_sign_in + sign_in_with_apple) with `signInWithIdToken` | Better UX; iOS app store compliance |
| Community food contributions | Open with 7-day account age friction | Balances accessibility and abuse prevention |
| Health data privacy | GDPR-grade strict, column-level encryption on weight/height/DOB | Health data is legally sensitive |
| Initial user base | Public launch within 6 months | Drives security-first design |
| Supabase region | US-East (initially) | Costa Rica launch; EU region required before EU marketing |
| Localization | es-CR primary, en secondary | Regional focus first |

---

## 3. Architecture overview

### Layered architecture (Clean Architecture)

Each feature has three layers with strict dependency rules:

```
┌─────────────────────────────────────────┐
│  Presentation (BLoC + Widgets)          │  depends on → Domain
├─────────────────────────────────────────┤
│  Domain (Entities + UseCases + Repos)   │  depends on → nothing (pure Dart)
├─────────────────────────────────────────┤
│  Data (DataSources + Models + Impl)     │  depends on → Domain
└─────────────────────────────────────────┘
```

- **Domain** is pure Dart — no Flutter, no Supabase, no external deps beyond `dartz` and `equatable`. It defines what the feature does.
- **Data** implements the repository interfaces from domain, talks to Supabase, converts between `Model` (JSON) and `Entity` (domain).
- **Presentation** consumes use cases through BLoC, knows nothing about Supabase.

### Error handling

Every repository method returns `Either<Failure, T>` from `dartz`. No exceptions leak from the data layer into the domain or presentation layers.

```dart
abstract class FoodRepository {
  Future<Either<Failure, List<Food>>> searchFoods(String query);
}
```

### Top-level stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.5+, Material 3 |
| State | `flutter_bloc` with `freezed` states |
| Navigation | `go_router` with auth-aware redirects |
| DI | `get_it` registered via `injectable` codegen |
| Backend | Supabase (Postgres + Auth + Storage + Edge Functions) |
| Push | Firebase Cloud Messaging |
| Secure storage | `flutter_secure_storage` (iOS Keychain / Android Keystore) |
| Charts | `fl_chart` |
| Barcode (v1.2+) | `mobile_scanner` |

---

## 4. Complete Supabase schema

This is the authoritative schema. Save as `supabase/migrations/0001_initial_schema.sql`.

```sql
-- ============================================================================
-- Calorie Tracker — Initial Schema
-- Migration: 0001_initial_schema.sql
-- ============================================================================

-- Extensions
create extension if not exists pg_trgm;
create extension if not exists pgcrypto;
create extension if not exists pgsodium;

-- ----------------------------------------------------------------------------
-- Profiles: user profile extension (non-sensitive data)
-- ----------------------------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (length(display_name) between 1 and 50),
  sex text check (sex in ('male', 'female', 'other')),
  activity_level text check (activity_level in ('sedentary','light','moderate','active','very_active')),
  goal text check (goal in ('deficit','maintain','surplus')),
  target_protein_g numeric(6,2) check (target_protein_g >= 0 and target_protein_g <= 500),
  target_carbs_g numeric(6,2) check (target_carbs_g >= 0 and target_carbs_g <= 1000),
  target_fat_g numeric(6,2) check (target_fat_g >= 0 and target_fat_g <= 500),
  target_calories integer check (target_calories >= 500 and target_calories <= 10000),
  preferred_log_mode text default 'grams' check (preferred_log_mode in ('grams','portions','exchanges')),
  trust_score integer default 10 check (trust_score between 0 and 100),
  locale text default 'es-CR',
  fcm_token text,
  is_admin boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ----------------------------------------------------------------------------
-- Profile health: sensitive data, column-level encrypted via pgsodium
-- ----------------------------------------------------------------------------
create table profile_health (
  profile_id uuid primary key references profiles(id) on delete cascade,
  body_weight_kg_encrypted bytea,  -- encrypted via pgsodium
  height_cm_encrypted bytea,
  birth_date_encrypted bytea,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ----------------------------------------------------------------------------
-- Foods: shared food database
-- ----------------------------------------------------------------------------
create table foods (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(name) between 1 and 100),
  name_normalized text not null,  -- lowercase, unaccented, for search
  brand text,
  barcode text,
  category text not null check (category in (
    'beef','chicken','pork','fish','dairy','eggs','carbs','fruit','vegetable',
    'fats','oil','drink','snack','supplement','seasoning','prepared','other'
  )),
  reference_amount numeric(8,2) not null check (reference_amount > 0),
  reference_unit text not null check (reference_unit in ('g','ml','unit')),
  protein_g numeric(6,2) not null check (protein_g >= 0),
  carbs_g numeric(6,2) not null check (carbs_g >= 0),
  fat_g numeric(6,2) not null check (fat_g >= 0),
  fiber_g numeric(6,2) default 0 check (fiber_g >= 0),
  -- Computed column: calories from Atwater factors
  calories numeric(7,2) generated always as (protein_g * 4 + carbs_g * 4 + fat_g * 9) stored,
  tier text not null default 'community' check (tier in ('verified','community','personal')),
  contributor_id uuid references profiles(id) on delete set null,
  visibility text not null default 'public' check (visibility in ('public','private')),
  upvotes integer default 0,
  flags integer default 0,
  locale text default 'es-CR',
  superseded_by uuid references foods(id),
  deleted_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  -- Physical plausibility: for /100g foods, macros can't exceed 100g total
  constraint macros_physical check (
    case when reference_unit = 'g' and reference_amount = 100 then
      protein_g + carbs_g + fat_g <= 100
      and protein_g <= 100 and carbs_g <= 100 and fat_g <= 100
    else true end
  )
);

create index foods_name_trgm_idx on foods using gin (name_normalized gin_trgm_ops);
create index foods_category_idx on foods(category) where deleted_at is null;
create index foods_tier_idx on foods(tier) where deleted_at is null;
create index foods_barcode_idx on foods(barcode) where barcode is not null and deleted_at is null;
create index foods_contributor_idx on foods(contributor_id);

-- ----------------------------------------------------------------------------
-- Food aliases: multilingual/synonym search
-- ----------------------------------------------------------------------------
create table food_aliases (
  id uuid primary key default gen_random_uuid(),
  food_id uuid not null references foods(id) on delete cascade,
  alias text not null,
  alias_normalized text not null,
  locale text default 'es-CR'
);

create index food_aliases_trgm_idx on food_aliases using gin (alias_normalized gin_trgm_ops);
create index food_aliases_food_idx on food_aliases(food_id);

-- ----------------------------------------------------------------------------
-- Food servings: named portions ("1 scoop = 30g")
-- ----------------------------------------------------------------------------
create table food_servings (
  id uuid primary key default gen_random_uuid(),
  food_id uuid not null references foods(id) on delete cascade,
  name text not null,  -- "scoop", "slice", "medium breast"
  grams_equivalent numeric(8,2) not null check (grams_equivalent > 0)
);

create index food_servings_food_idx on food_servings(food_id);

-- ----------------------------------------------------------------------------
-- Food votes: upvote/flag signals
-- ----------------------------------------------------------------------------
create table food_votes (
  id uuid primary key default gen_random_uuid(),
  food_id uuid not null references foods(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  vote_type text not null check (vote_type in ('upvote','flag')),
  reason text check (length(reason) <= 500),
  created_at timestamptz default now(),
  unique (food_id, user_id, vote_type)
);

create index food_votes_food_idx on food_votes(food_id);
create index food_votes_user_idx on food_votes(user_id);

-- ----------------------------------------------------------------------------
-- Meal entries: the log with denormalized snapshot
-- ----------------------------------------------------------------------------
create table meal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  food_id uuid not null references foods(id),
  -- Snapshot columns protect history from food edits
  food_name_snapshot text not null,
  protein_snapshot numeric(6,2) not null check (protein_snapshot >= 0),
  carbs_snapshot numeric(6,2) not null check (carbs_snapshot >= 0),
  fat_snapshot numeric(6,2) not null check (fat_snapshot >= 0),
  fiber_snapshot numeric(6,2) default 0 check (fiber_snapshot >= 0),
  calories_snapshot numeric(7,2) not null check (calories_snapshot >= 0),
  quantity numeric(8,2) not null check (quantity > 0),
  unit text not null,
  grams_equivalent numeric(8,2) not null check (grams_equivalent > 0),
  meal_type text check (meal_type in ('breakfast','lunch','dinner','snack')),
  input_mode text default 'grams' check (input_mode in ('grams','portions','exchanges')),
  consumed_at timestamptz not null default now(),
  created_at timestamptz default now()
);

create index meal_entries_user_date_idx on meal_entries(user_id, consumed_at desc);
create index meal_entries_food_idx on meal_entries(food_id);

-- ----------------------------------------------------------------------------
-- Meal templates: saved meals for fast re-logging
-- ----------------------------------------------------------------------------
create table meal_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  name text not null check (length(name) between 1 and 50),
  meal_type text check (meal_type in ('breakfast','lunch','dinner','snack')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table meal_template_items (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references meal_templates(id) on delete cascade,
  food_id uuid not null references foods(id),
  quantity numeric(8,2) not null check (quantity > 0),
  unit text not null,
  sort_order integer default 0
);

create index meal_template_items_template_idx on meal_template_items(template_id);

-- ----------------------------------------------------------------------------
-- Daily metrics: per-day basal metabolism, exercise burn, weight
-- ----------------------------------------------------------------------------
create table daily_metrics (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  date date not null,
  basal_metabolism integer check (basal_metabolism > 0),
  exercise_burn integer default 0 check (exercise_burn >= 0),
  weight_kg_encrypted bytea,  -- encrypted like profile_health
  notes text check (length(notes) <= 1000),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (user_id, date)
);

create index daily_metrics_user_date_idx on daily_metrics(user_id, date desc);

-- ----------------------------------------------------------------------------
-- Rate limits: per-user operation throttling
-- ----------------------------------------------------------------------------
create table rate_limits (
  user_id uuid not null references profiles(id) on delete cascade,
  action text not null,
  window_start timestamptz not null,
  count integer not null default 1,
  primary key (user_id, action, window_start)
);

create index rate_limits_cleanup_idx on rate_limits(window_start);

-- ----------------------------------------------------------------------------
-- Audit log: append-only admin action trail
-- ----------------------------------------------------------------------------
create table audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles(id),
  action text not null,
  target_type text,
  target_id uuid,
  ip_address inet,
  user_agent text,
  metadata jsonb,
  created_at timestamptz default now()
);

create index audit_log_actor_idx on audit_log(actor_id, created_at desc);
create index audit_log_action_idx on audit_log(action, created_at desc);
create index audit_log_target_idx on audit_log(target_type, target_id);
```

---

## 5. RLS policies (full text)

Save as `supabase/migrations/0002_rls_policies.sql`.

```sql
-- ============================================================================
-- Row-Level Security Policies
-- Migration: 0002_rls_policies.sql
-- ============================================================================

-- Enable RLS on all user-data tables
alter table profiles enable row level security;
alter table profile_health enable row level security;
alter table foods enable row level security;
alter table food_aliases enable row level security;
alter table food_servings enable row level security;
alter table food_votes enable row level security;
alter table meal_entries enable row level security;
alter table meal_templates enable row level security;
alter table meal_template_items enable row level security;
alter table daily_metrics enable row level security;
alter table audit_log enable row level security;
alter table rate_limits enable row level security;

-- ----------------------------------------------------------------------------
-- Profiles
-- ----------------------------------------------------------------------------
create policy "profiles_select_own" on profiles
  for select using (auth.uid() = id);

create policy "profiles_insert_own" on profiles
  for insert with check (auth.uid() = id);

create policy "profiles_update_own" on profiles
  for update using (auth.uid() = id)
  with check (
    auth.uid() = id
    -- User cannot modify trust_score or is_admin
    and trust_score = (select trust_score from profiles where id = auth.uid())
    and is_admin = (select is_admin from profiles where id = auth.uid())
  );

-- NO delete policy. Deletion via delete_account() Edge Function.

-- ----------------------------------------------------------------------------
-- Profile health
-- ----------------------------------------------------------------------------
create policy "profile_health_select_own" on profile_health
  for select using (auth.uid() = profile_id);

create policy "profile_health_insert_own" on profile_health
  for insert with check (auth.uid() = profile_id);

create policy "profile_health_update_own" on profile_health
  for update using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

-- ----------------------------------------------------------------------------
-- Foods
-- ----------------------------------------------------------------------------
-- Readable: verified (not deleted), public community under flag threshold, own personal
create policy "foods_select_public" on foods for select using (
  (tier = 'verified' and deleted_at is null)
  or (tier = 'community' and visibility = 'public' and flags < 3 and deleted_at is null)
  or (contributor_id = auth.uid())
);

-- Insertable: only community (with account age check) or personal
create policy "foods_insert_own" on foods for insert with check (
  contributor_id = auth.uid()
  and tier in ('community', 'personal')
  and superseded_by is null
  and deleted_at is null
  and (
    tier = 'personal'
    or (select created_at from auth.users where id = auth.uid()) < now() - interval '7 days'
  )
);

-- Updatable: only own personal, cannot change tier/contributor
create policy "foods_update_own_personal" on foods for update using (
  contributor_id = auth.uid() and tier = 'personal'
) with check (
  contributor_id = auth.uid()
  and tier = 'personal'
);

-- ----------------------------------------------------------------------------
-- Food aliases and servings: tied to food ownership
-- ----------------------------------------------------------------------------
create policy "food_aliases_select" on food_aliases for select using (
  exists (
    select 1 from foods f where f.id = food_id
    and (
      (f.tier in ('verified','community') and f.deleted_at is null)
      or f.contributor_id = auth.uid()
    )
  )
);

create policy "food_aliases_insert" on food_aliases for insert with check (
  exists (
    select 1 from foods f where f.id = food_id
    and f.contributor_id = auth.uid()
    and f.tier = 'personal'
  )
);

create policy "food_aliases_delete" on food_aliases for delete using (
  exists (
    select 1 from foods f where f.id = food_id
    and f.contributor_id = auth.uid()
    and f.tier = 'personal'
  )
);

create policy "food_servings_select" on food_servings for select using (
  exists (
    select 1 from foods f where f.id = food_id
    and (
      (f.tier in ('verified','community') and f.deleted_at is null)
      or f.contributor_id = auth.uid()
    )
  )
);

create policy "food_servings_insert" on food_servings for insert with check (
  exists (
    select 1 from foods f where f.id = food_id
    and f.contributor_id = auth.uid()
    and f.tier = 'personal'
  )
);

create policy "food_servings_delete" on food_servings for delete using (
  exists (
    select 1 from foods f where f.id = food_id
    and f.contributor_id = auth.uid()
    and f.tier = 'personal'
  )
);

-- ----------------------------------------------------------------------------
-- Food votes
-- ----------------------------------------------------------------------------
create policy "votes_select_own" on food_votes
  for select using (user_id = auth.uid());

create policy "votes_insert_own" on food_votes for insert with check (
  user_id = auth.uid()
);

create policy "votes_delete_own" on food_votes
  for delete using (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- Meal entries
-- ----------------------------------------------------------------------------
create policy "meals_select_own" on meal_entries
  for select using (user_id = auth.uid());

create policy "meals_insert_own" on meal_entries
  for insert with check (user_id = auth.uid());

create policy "meals_update_own" on meal_entries
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "meals_delete_own" on meal_entries
  for delete using (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- Meal templates
-- ----------------------------------------------------------------------------
create policy "templates_all_own" on meal_templates for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "template_items_all_own" on meal_template_items for all
  using ((select user_id from meal_templates where id = template_id) = auth.uid())
  with check ((select user_id from meal_templates where id = template_id) = auth.uid());

-- ----------------------------------------------------------------------------
-- Daily metrics
-- ----------------------------------------------------------------------------
create policy "metrics_all_own" on daily_metrics for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- Rate limits: users can see their own, writes via triggers/functions only
-- ----------------------------------------------------------------------------
create policy "rate_limits_select_own" on rate_limits
  for select using (user_id = auth.uid());

-- No direct insert/update/delete — only via SECURITY DEFINER functions

-- ----------------------------------------------------------------------------
-- Audit log: admin-only read, append-only via SECURITY DEFINER
-- ----------------------------------------------------------------------------
create policy "audit_log_admin_select" on audit_log for select using (
  exists (select 1 from profiles where id = auth.uid() and is_admin = true)
);

-- No insert/update/delete policies — append-only via functions

-- ----------------------------------------------------------------------------
-- Statement timeouts: prevent expensive query DoS
-- ----------------------------------------------------------------------------
alter role anon set statement_timeout = '5s';
alter role authenticated set statement_timeout = '5s';
```

---

## 6. Triggers, functions, and RPCs

Save as `supabase/migrations/0003_triggers_and_functions.sql`.

```sql
-- ============================================================================
-- Triggers, Functions, RPCs
-- Migration: 0003_triggers_and_functions.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Auto-update `updated_at` columns
-- ----------------------------------------------------------------------------
create or replace function set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger profiles_updated_at before update on profiles
  for each row execute function set_updated_at();
create trigger profile_health_updated_at before update on profile_health
  for each row execute function set_updated_at();
create trigger foods_updated_at before update on foods
  for each row execute function set_updated_at();
create trigger meal_templates_updated_at before update on meal_templates
  for each row execute function set_updated_at();
create trigger daily_metrics_updated_at before update on daily_metrics
  for each row execute function set_updated_at();

-- ----------------------------------------------------------------------------
-- Normalize food name (lowercase, unaccented) on insert/update
-- ----------------------------------------------------------------------------
create extension if not exists unaccent;

create or replace function normalize_food_name() returns trigger
language plpgsql as $$
begin
  new.name_normalized := lower(unaccent(new.name));
  return new;
end;
$$;

create trigger foods_normalize_name before insert or update on foods
  for each row execute function normalize_food_name();

create or replace function normalize_alias() returns trigger
language plpgsql as $$
begin
  new.alias_normalized := lower(unaccent(new.alias));
  return new;
end;
$$;

create trigger aliases_normalize before insert or update on food_aliases
  for each row execute function normalize_alias();

-- ----------------------------------------------------------------------------
-- Force contributor_id to auth.uid() on food insert (prevent spoofing)
-- ----------------------------------------------------------------------------
create or replace function force_contributor_id() returns trigger
language plpgsql security definer as $$
begin
  new.contributor_id := auth.uid();
  return new;
end;
$$;

create trigger foods_force_contributor before insert on foods
  for each row execute function force_contributor_id();

-- ----------------------------------------------------------------------------
-- Prevent self-voting on foods
-- ----------------------------------------------------------------------------
create or replace function prevent_self_vote() returns trigger
language plpgsql security definer as $$
begin
  if exists (
    select 1 from foods
    where id = new.food_id and contributor_id = new.user_id
  ) then
    raise exception 'cannot vote on your own food submission';
  end if;
  return new;
end;
$$;

create trigger food_votes_no_self before insert on food_votes
  for each row execute function prevent_self_vote();

-- ----------------------------------------------------------------------------
-- Maintain vote counts on foods
-- ----------------------------------------------------------------------------
create or replace function update_food_vote_counts() returns trigger
language plpgsql security definer as $$
begin
  if tg_op = 'INSERT' then
    if new.vote_type = 'upvote' then
      update foods set upvotes = upvotes + 1 where id = new.food_id;
    else
      update foods set flags = flags + 1 where id = new.food_id;
    end if;
  elsif tg_op = 'DELETE' then
    if old.vote_type = 'upvote' then
      update foods set upvotes = greatest(0, upvotes - 1) where id = old.food_id;
    else
      update foods set flags = greatest(0, flags - 1) where id = old.food_id;
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

create trigger food_votes_counts after insert or delete on food_votes
  for each row execute function update_food_vote_counts();

-- ----------------------------------------------------------------------------
-- Admin RPC: promote food tier
-- ----------------------------------------------------------------------------
create or replace function promote_food(food_id uuid, new_tier text)
returns void language plpgsql security definer as $$
begin
  if not exists (select 1 from profiles where id = auth.uid() and is_admin = true) then
    raise exception 'admin privileges required';
  end if;

  if new_tier not in ('verified', 'community') then
    raise exception 'invalid tier';
  end if;

  update foods set tier = new_tier where id = food_id;

  insert into audit_log (actor_id, action, target_type, target_id, metadata)
  values (auth.uid(), 'promote_food', 'food', food_id,
          jsonb_build_object('new_tier', new_tier));
end;
$$;

revoke all on function promote_food(uuid, text) from public;
grant execute on function promote_food(uuid, text) to authenticated;

-- ----------------------------------------------------------------------------
-- Rate limit check (used by Edge Functions)
-- ----------------------------------------------------------------------------
create or replace function check_rate_limit(
  p_user_id uuid,
  p_action text,
  p_window_seconds integer,
  p_max_count integer
) returns boolean language plpgsql security definer as $$
declare
  v_window_start timestamptz;
  v_current_count integer;
begin
  v_window_start := date_trunc('second', now()) - (p_window_seconds || ' seconds')::interval;

  -- Clean old windows (opportunistic)
  delete from rate_limits
  where user_id = p_user_id and action = p_action and window_start < v_window_start;

  -- Count current window
  select coalesce(sum(count), 0) into v_current_count
  from rate_limits
  where user_id = p_user_id and action = p_action and window_start >= v_window_start;

  if v_current_count >= p_max_count then
    return false;
  end if;

  insert into rate_limits (user_id, action, window_start, count)
  values (p_user_id, p_action, date_trunc('minute', now()), 1)
  on conflict (user_id, action, window_start) do update
  set count = rate_limits.count + 1;

  return true;
end;
$$;

-- ----------------------------------------------------------------------------
-- Search foods (trigram + alias)
-- ----------------------------------------------------------------------------
create or replace function search_foods(
  p_query text,
  p_category text default null,
  p_limit integer default 20,
  p_offset integer default 0
) returns setof foods language plpgsql stable as $$
declare
  v_normalized text := lower(unaccent(p_query));
begin
  return query
  select distinct f.*
  from foods f
  left join food_aliases a on a.food_id = f.id
  where f.deleted_at is null
    and (
      (f.tier = 'verified')
      or (f.tier = 'community' and f.visibility = 'public' and f.flags < 3)
      or (f.contributor_id = auth.uid())
    )
    and (
      f.name_normalized % v_normalized
      or a.alias_normalized % v_normalized
      or f.name_normalized ilike '%' || v_normalized || '%'
    )
    and (p_category is null or f.category = p_category)
  order by
    case f.tier when 'verified' then 1 when 'community' then 2 else 3 end,
    similarity(f.name_normalized, v_normalized) desc,
    f.upvotes desc
  limit p_limit offset p_offset;
end;
$$;

grant execute on function search_foods(text, text, integer, integer) to authenticated;
```

---

## 7. Flutter project structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── atwater.dart           # kcal per gram of macro
│   │   ├── exchanges.dart         # exchange system grams
│   │   └── activity_multipliers.dart
│   ├── error/
│   │   ├── failures.dart          # Failure sealed class
│   │   └── exceptions.dart        # data-layer exceptions
│   ├── usecases/
│   │   ├── usecase.dart           # abstract UseCase<T, P>
│   │   └── no_params.dart
│   ├── di/
│   │   ├── injection.dart         # @InjectableInit()
│   │   └── injection.config.dart  # generated
│   ├── router/
│   │   ├── app_router.dart        # go_router config
│   │   └── route_names.dart
│   ├── supabase/
│   │   ├── supabase_client.dart   # singleton wrapper
│   │   └── supabase_extensions.dart
│   ├── secure_storage/
│   │   └── secure_storage_service.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── utils/
│       ├── tdee_calculator.dart
│       ├── macro_targets.dart
│       ├── unit_converter.dart
│       └── date_utils.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── auth_user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── auth_user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in_with_email.dart
│   │   │       ├── sign_up_with_email.dart
│   │   │       ├── sign_in_with_google.dart
│   │   │       ├── sign_in_with_apple.dart
│   │   │       ├── sign_out.dart
│   │   │       ├── get_current_user.dart
│   │   │       └── watch_auth_state.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── sign_in_page.dart
│   │       │   ├── sign_up_page.dart
│   │       │   └── forgot_password_page.dart
│   │       └── widgets/
│   │           └── social_sign_in_buttons.dart
│   ├── profile/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/ ...
│   ├── foods/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/ ...
│   ├── logging/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/ ...
│   ├── analytics/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/ ...
│   └── social/  # v2 — folder exists, implementation deferred
└── main.dart
```

---

## 8. Core utilities and constants

### Atwater factors

```dart
// lib/core/constants/atwater.dart
class Atwater {
  static const double kcalPerGramProtein = 4;
  static const double kcalPerGramCarbs = 4;
  static const double kcalPerGramFat = 9;

  static double calories({
    required double protein,
    required double carbs,
    required double fat,
  }) =>
      protein * kcalPerGramProtein +
      carbs * kcalPerGramCarbs +
      fat * kcalPerGramFat;
}
```

### Exchange system

```dart
// lib/core/constants/exchanges.dart
class ExchangeTable {
  static const double proteinGramsPerExchange = 7.0;
  static const double carbsGramsPerExchange = 15.0;
  static const double fatGramsPerExchange = 5.0;
  static const double fruitCarbsPerExchange = 15.0;
  static const double dairyCarbsPerExchange = 12.0;
  static const double dairyProteinPerExchange = 8.0;

  static double proteinToExchanges(double grams) =>
      grams / proteinGramsPerExchange;
  static double carbsToExchanges(double grams) =>
      grams / carbsGramsPerExchange;
  static double fatToExchanges(double grams) =>
      grams / fatGramsPerExchange;
}
```

### Activity multipliers (for TDEE)

```dart
// lib/core/constants/activity_multipliers.dart
enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  final double multiplier;
  const ActivityLevel(this.multiplier);
}
```

### TDEE calculator (Mifflin-St Jeor)

```dart
// lib/core/utils/tdee_calculator.dart
import '../constants/activity_multipliers.dart';

enum BiologicalSex { male, female }
enum Goal { deficit, maintain, surplus }

class TdeeCalculator {
  /// Mifflin-St Jeor BMR
  static double bmr({
    required BiologicalSex sex,
    required double weightKg,
    required double heightCm,
    required int ageYears,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * ageYears;
    return sex == BiologicalSex.male ? base + 5 : base - 161;
  }

  static double tdee({
    required double bmr,
    required ActivityLevel activity,
  }) =>
      bmr * activity.multiplier;

  static int targetCalories({
    required double tdee,
    required Goal goal,
  }) {
    switch (goal) {
      case Goal.deficit:
        return (tdee - 500).round(); // ~0.5kg/week loss
      case Goal.maintain:
        return tdee.round();
      case Goal.surplus:
        return (tdee + 300).round(); // lean bulk
    }
  }
}
```

### Macro target splitter

```dart
// lib/core/utils/macro_targets.dart
import '../constants/atwater.dart';

class MacroTargets {
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int calories;

  const MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.calories,
  });

  /// Protein = 1.8 g/kg bodyweight (hypertrophy-supporting default)
  /// Fat = 25% of calories
  /// Carbs = remainder
  factory MacroTargets.fromTarget({
    required int calories,
    required double bodyWeightKg,
  }) {
    final proteinG = bodyWeightKg * 1.8;
    final proteinKcal = proteinG * Atwater.kcalPerGramProtein;

    final fatKcal = calories * 0.25;
    final fatG = fatKcal / Atwater.kcalPerGramFat;

    final carbsKcal = calories - proteinKcal - fatKcal;
    final carbsG = (carbsKcal / Atwater.kcalPerGramCarbs).clamp(0, double.infinity);

    return MacroTargets(
      proteinG: proteinG,
      carbsG: carbsG.toDouble(),
      fatG: fatG,
      calories: calories,
    );
  }
}
```

### Failure sealed class

```dart
// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure(super.message);
}
```

### UseCase base

```dart
// lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}
```

---

## 9. Feature-by-feature build spec

Each feature follows the same structure. Below are entity definitions and key use cases per feature.

### Feature: auth

**Entities:**
```dart
class AuthUser extends Equatable {
  final String id;
  final String email;
  final DateTime createdAt;

  const AuthUser({required this.id, required this.email, required this.createdAt});

  @override
  List<Object?> get props => [id, email, createdAt];
}
```

**Repository interface:**
```dart
abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> signInWithEmail(String email, String password);
  Future<Either<Failure, AuthUser>> signUpWithEmail(String email, String password);
  Future<Either<Failure, AuthUser>> signInWithGoogle();
  Future<Either<Failure, AuthUser>> signInWithApple();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, AuthUser?>> getCurrentUser();
  Stream<AuthUser?> watchAuthState();
}
```

**BLoC states:**
```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(AuthUser user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}
```

### Feature: profile

**Entities:**
```dart
class Profile extends Equatable {
  final String id;
  final String displayName;
  final BiologicalSex? sex;
  final ActivityLevel? activityLevel;
  final Goal? goal;
  final double? targetProteinG;
  final double? targetCarbsG;
  final double? targetFatG;
  final int? targetCalories;
  final LogInputMode preferredLogMode;
  final int trustScore;
  final String locale;
  // ... etc
}

class HealthData extends Equatable {
  final String profileId;
  final double? bodyWeightKg;
  final double? heightCm;
  final DateTime? birthDate;
  // ... etc
}
```

**Use cases:**
- `GetProfile`
- `UpdateProfile`
- `UpdateHealthData`
- `ComputeTargets` — takes current profile + health data, writes computed targets back

### Feature: foods

**Entities:**
```dart
enum TrustTier { verified, community, personal }

enum FoodCategory {
  beef, chicken, pork, fish, dairy, eggs, carbs, fruit, vegetable,
  fats, oil, drink, snack, supplement, seasoning, prepared, other
}

class Food extends Equatable {
  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final FoodCategory category;
  final double referenceAmount;
  final String referenceUnit;
  final Macros macros;
  final List<Serving> servings;
  final List<String> aliases;
  final TrustTier tier;
  final String? contributorId;
  final int upvotes;
  final int flags;
}

class Macros extends Equatable {
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  double get calories => Atwater.calories(protein: protein, carbs: carbs, fat: fat);
}

class Serving extends Equatable {
  final String name;
  final double gramsEquivalent;
}
```

**Use cases:**
- `SearchFoods({String query, FoodCategory? category, int page})`
- `GetFoodById(String id)`
- `GetFoodByBarcode(String barcode)`
- `CreatePersonalFood(Food food)`
- `CreateCommunityFood(Food food)` — checks 7-day account age
- `UpvoteFood(String foodId)`
- `FlagFood(String foodId, String reason)`
- `GetRecentFoods({int limit})` — foods user has logged recently

### Feature: logging

**Entities:**
```dart
enum MealType { breakfast, lunch, dinner, snack }
enum LogInputMode { grams, portions, exchanges }

class MealEntry extends Equatable {
  final String id;
  final String userId;
  final String foodId;
  final FoodSnapshot snapshot;
  final double quantity;
  final String unit;
  final double gramsEquivalent;
  final MealType? mealType;
  final LogInputMode inputMode;
  final DateTime consumedAt;
}

class FoodSnapshot extends Equatable {
  final String foodName;
  final Macros macros;
}

class DailyLog extends Equatable {
  final DateTime date;
  final List<MealEntry> entries;
  final DailyMetrics? metrics;

  Macros get totalMacros => entries.fold(
        Macros(protein: 0, carbs: 0, fat: 0, fiber: 0),
        (acc, e) => Macros(
          protein: acc.protein + e.snapshot.macros.protein * (e.gramsEquivalent / 100),
          carbs: acc.carbs + e.snapshot.macros.carbs * (e.gramsEquivalent / 100),
          fat: acc.fat + e.snapshot.macros.fat * (e.gramsEquivalent / 100),
          fiber: acc.fiber + e.snapshot.macros.fiber * (e.gramsEquivalent / 100),
        ),
      );
}
```

**Use cases:**
- `LogMeal(MealEntryInput input)`
- `DeleteMealEntry(String id)`
- `UpdateMealEntry(String id, MealEntryInput input)`
- `GetDailyLog(DateTime date)`
- `CopyDay({DateTime from, DateTime to})` — "repeat yesterday"
- `SaveAsTemplate(List<MealEntry> entries, String templateName)`
- `ApplyTemplate(String templateId, MealType mealType)`

### Feature: analytics

**Entities:**
```dart
class WeeklyTrend extends Equatable {
  final DateTime weekStart;
  final List<DailySummary> days;
  final Macros averageDailyMacros;
  final int averageDailyCalories;
}

class DailySummary extends Equatable {
  final DateTime date;
  final Macros macros;
  final int calories;
  final int? exerciseBurn;
}
```

**Use cases:**
- `GetWeeklyTrend(DateTime weekStart)`
- `GetMonthlyTrend(DateTime monthStart)`
- `GetProteinAdherence({DateTime since, DateTime until})` — % of days hitting target
- `GetWeightTrend({DateTime since, DateTime until})`

---

## 10. Complete 6-month PR sequence

Each PR should be reviewable in ≤30 minutes, follow Conventional Commits, and be atomic.

### Month 1: Foundation (Weeks 1-4)

#### Week 1: Migrate stack (PRs 1-9)

- **PR 1** `chore/migrate-to-supabase-stack` — deps swap, remove Firestore/Firebase Auth/Provider/SharedPreferences, add Supabase/BLoC/dartz/get_it/injectable/freezed/go_router/flutter_secure_storage
- **PR 2** `feat/supabase-schema` — create Supabase project, write 3 migrations (schema/RLS/triggers), apply via CLI
- **PR 3** `feat/core-infrastructure` — `lib/core/` folder, failures, usecases, DI config, router skeleton, theme, constants, utils
- **PR 4** `feat/supabase-client` — Supabase singleton, secure storage wrapper, `.env` loading, init in `main.dart`
- **PR 5** `feat/auth-domain-data` — auth entity, repository interface, use cases, remote datasource, model, repo impl
- **PR 6** `feat/auth-presentation` — AuthBloc, sign-in/sign-up/forgot-password pages, social buttons, router wiring
- **PR 7** `feat/profile` — complete profile feature including onboarding flow
- **PR 8** `feat/fcm-setup` — FCM plumbing, token refresh, store token in profile
- **PR 9** `chore/week-1-wrap-up` — README, docs in `docs/`, GitHub issues for future work, tag `v0.1.0-alpha`

**Week 1 done criteria:** Auth + profile works end-to-end. Two test accounts confirmed isolated via RLS.

#### Week 2: Food database foundation (PRs 10-14)

- **PR 10** `feat/foods-domain` — Food/Macros/Serving entities, repository interface, use cases
- **PR 11** `feat/foods-data` — datasource with trigram search via `search_foods` RPC, models, repo impl
- **PR 12** `feat/foods-seed-data` — seed ~80 verified foods from brother's spreadsheet (label-verified)
- **PR 13** `feat/foods-search-ui` — FoodSearchBloc, search page with debounced input, tier badges, category filter
- **PR 14** `feat/foods-personal-add` — quick-add form for personal foods, food detail page

**Week 2 done criteria:** Can search the DB in Spanish and English, can add personal foods.

#### Week 3: Core logging loop (PRs 15-20)

- **PR 15** `feat/logging-domain` — MealEntry/FoodSnapshot/DailyLog entities, repo interface, use cases
- **PR 16** `feat/logging-data` — datasource, models, repo impl (with snapshot handling)
- **PR 17** `feat/logging-daily-view` — DailyLogBloc, daily page with protein-first rings, macro summary
- **PR 18** `feat/logging-log-sheet` — log-food bottom sheet with Recent/Templates/Search tabs
- **PR 19** `feat/logging-serving-picker` — serving picker with macro preview, quantity + unit selection
- **PR 20** `feat/logging-edit-delete` — edit meal entry, delete meal entry, undo

**Week 3 done criteria:** Full log-a-meal flow works. Start dogfooding.

#### Week 4: Retention features (PRs 21-25)

- **PR 21** `feat/templates-domain-data` — template entities, repo, use cases, datasource
- **PR 22** `feat/templates-ui` — save-as-template, templates list, apply-template flows
- **PR 23** `feat/logging-repeat-yesterday` — single-tap copy of yesterday's entries
- **PR 24** `feat/daily-metrics` — exercise burn entry, weight entry (encrypted), basal metabolism display
- **PR 25** `feat/recent-foods` — recent foods tab with frequency-based ordering

**Week 4 done criteria:** You and your brother are both using the app daily and prefer it to the spreadsheet.

### Month 2: Differentiators + hardening (Weeks 5-8)

#### Week 5: Exchange system (PRs 26-29)

- **PR 26** `feat/exchanges-constants-utils` — exchange tables, converter utilities
- **PR 27** `feat/exchanges-input-mode` — input mode toggle on serving picker
- **PR 28** `feat/exchanges-display` — show all three modes simultaneously on food detail and daily view
- **PR 29** `feat/named-servings` — named serving support in DB + UI (1 scoop, 1 slice, etc.)

#### Week 6: Polish (PRs 30-34)

- **PR 30** `feat/community-upvote-flag` — vote UI, flag reason modal
- **PR 31** `feat/trust-score-basic` — trust score calculation (contributor score × (upvotes - flags))
- **PR 32** `feat/analytics-charts` — fl_chart weekly protein trend, calories trend
- **PR 33** `feat/settings-export` — CSV export via Edge Function
- **PR 34** `feat/onboarding-polish` — onboarding flow improvements, empty states

#### Week 7: Bug-fix sprint (no new features)

- **PR 35-40** — based on dogfooding issues. No new features. Fix bugs, improve UX, improve error messages.

#### Week 8: Security review

- **PR 41** `test/rls-adversarial` — integration tests that attempt unauthorized access
- **PR 42** `chore/dependency-audit` — `flutter pub outdated --mode=security`, update all deps
- **PR 43** `feat/pgsodium-column-encryption` — verify encryption on health columns, rotate test keys
- **PR 44** `chore/security-review` — external review pass with trusted developer friend

### Month 3: Private beta (Weeks 9-12)

#### Week 9: Onboard private beta users (PRs 45-48)

- **PR 45** `feat/analytics-telemetry` — opt-in analytics (DAU, logs/user, retention)
- **PR 46** `feat/feedback-form` — in-app feedback mechanism
- **PR 47** `chore/private-beta-docs` — onboarding docs for beta users
- **PR 48** `feat/crash-reporting-optin` — Sentry or similar, PII-scrubbed, opt-in

**Onboard 3-5 trusted users.**

#### Week 10: Beta bug fixes (PRs 49-55)

- Based on beta user feedback. No new features.

#### Week 11: Barcode scanning (PRs 56-59)

- **PR 56** `feat/barcode-scanner` — `mobile_scanner` integration, camera permission flow
- **PR 57** `feat/barcode-lookup-local` — check local DB first
- **PR 58** `feat/barcode-openfoodfacts` — fallback to OpenFoodFacts API
- **PR 59** `feat/barcode-add-flow` — quick-add with barcode pre-filled

#### Week 12: Community tier goes live (PRs 60-63)

- **PR 60** `feat/community-tier-enable` — allow community submissions (with 7-day check)
- **PR 61** `feat/flag-review-queue` — admin web view of flagged foods
- **PR 62** `feat/community-food-banner` — visible warning banner on community entries
- **PR 63** `feat/admin-dashboard` — web-based admin (separate repo or `/admin` route)

### Month 4: Expansion + analytics (Weeks 13-16)

#### Week 13: Trust scoring refinement (PRs 64-66)

- **PR 64** `feat/trust-score-v2` — more sophisticated trust calculation
- **PR 65** `feat/trust-badge-display` — show trust indicators in search results
- **PR 66** `feat/trust-promotion-queue` — high-trust community foods auto-surface to admin review

#### Week 14: Analytics deepening (PRs 67-70)

- **PR 67** `feat/analytics-monthly-view` — monthly trend chart
- **PR 68** `feat/analytics-weight-tracking` — weight chart with encrypted data
- **PR 69** `feat/analytics-adherence` — % of days hitting protein target
- **PR 70** `feat/analytics-macro-distribution` — pie charts, weekly averages

#### Week 15: Localization polish (PRs 71-74)

- **PR 71** `feat/i18n-setup` — `flutter_localizations`, ARB files, es-CR + en
- **PR 72** `feat/i18n-strings` — externalize all user-facing strings
- **PR 73** `feat/i18n-food-aliases-en` — add English aliases to all verified foods
- **PR 74** `feat/i18n-regional-es` — general Spanish fallback

#### Week 16: Prep for app store submission (PRs 75-78)

- **PR 75** `chore/privacy-policy` — integrate privacy policy URL, ToS
- **PR 76** `chore/app-store-assets` — screenshots, descriptions, app icon variants
- **PR 77** `feat/account-deletion-ui` — user-facing "delete my account" in settings
- **PR 78** `feat/data-export-ui` — user-facing "export my data" in settings

### Month 5: Launch prep (Weeks 17-20)

#### Week 17: App store compliance (PRs 79-82)

- **PR 79** `feat/consent-flow` — first-run consent for health data (GDPR Art. 9)
- **PR 80** `feat/analytics-consent-banner` — cookie/analytics consent
- **PR 81** `chore/app-store-metadata` — finalize store listings
- **PR 82** `chore/appstore-privacy-labels` — Apple privacy nutrition labels

#### Week 18: iOS submission prep (PRs 83-85)

- **PR 83** `chore/ios-build-config` — release signing, entitlements
- **PR 84** `test/ios-device-matrix` — test on iOS 14+ devices
- **PR 85** `chore/ios-submit` — submit to App Store Connect

#### Week 19: Android submission prep (PRs 86-88)

- **PR 86** `chore/android-build-config` — release signing, ProGuard rules
- **PR 87** `test/android-device-matrix` — test on Android 8+ devices
- **PR 88** `chore/play-store-submit` — submit to Play Console

#### Week 20: Review cycle fixes (PRs 89-92)

- Respond to iOS/Android review feedback. Plan for 1-2 review cycles.

### Month 6: Soft launch + iterate (Weeks 21-24)

#### Week 21: Costa Rica soft launch

- **PR 93** `chore/feature-flags` — remote config via Supabase for feature gating
- **PR 94** `chore/region-restrict` — limit downloads to CR initially

#### Weeks 22-24: Monitor, fix, iterate

- PRs driven by real-world usage. No pre-planned list — respond to production signal.
- Expand regionally only after D30 retention proves out (target: >40%).

---

## 11. Testing strategy

### Test pyramid

- **Unit tests (most):** pure Dart code — use cases, utilities, model serialization. Fast, no dependencies.
- **BLoC tests:** `bloc_test` package, mock repositories with `mocktail`.
- **Widget tests:** key UI flows. Focus on state-dependent rendering.
- **Integration tests:** critical paths only (sign-in, log a meal, export data). Slow, use sparingly.

### Test patterns

**Use case test:**
```dart
void main() {
  late SignInWithEmail useCase;
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    useCase = SignInWithEmail(repo);
  });

  test('returns AuthUser on success', () async {
    when(() => repo.signInWithEmail(any(), any()))
        .thenAnswer((_) async => Right(testUser));

    final result = await useCase(SignInParams(email: 'a@b.c', password: 'x'));

    expect(result, Right(testUser));
  });
}
```

**BLoC test:**
```dart
blocTest<AuthBloc, AuthState>(
  'emits [loading, authenticated] on successful sign-in',
  build: () => AuthBloc(signInUseCase: mockSignIn, ...),
  act: (bloc) => bloc.add(AuthEvent.signInRequested(email: 'a@b.c', password: 'x')),
  expect: () => [
    const AuthState.loading(),
    AuthState.authenticated(testUser),
  ],
);
```

**RLS adversarial test (week 8):**
Spin up two Supabase clients with different JWTs. Confirm client A cannot read/write client B's data via direct queries.

---

## 12. Code patterns and conventions

### Conventional Commits (enforce strictly)

```
feat: add food search with trigram matching
fix: correct protein-per-exchange calculation
chore: upgrade supabase_flutter to 2.5.0
docs: update README with Supabase setup steps
test: add RLS adversarial tests
refactor: extract macro calculation to utility
```

### BLoC naming

- Events: past tense for user actions (`SignInRequested`), present for system (`AuthStateChanged`).
- States: descriptive nouns/adjectives (`Authenticated`, `Loading`, `Error`).
- Use `freezed` for union types.

### DI registration

```dart
@lazySingleton
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  AuthRepositoryImpl(this._remote);
}

@injectable
class SignInWithEmail implements UseCase<AuthUser, SignInParams> {
  final AuthRepository _repo;
  SignInWithEmail(this._repo);

  @override
  Future<Either<Failure, AuthUser>> call(SignInParams params) =>
      _repo.signInWithEmail(params.email, params.password);
}
```

### Error mapping (data layer)

```dart
Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
  try {
    return Right(await action());
  } on AuthException catch (e) {
    return Left(AuthFailure(e.message));
  } on PostgrestException catch (e) {
    return Left(ServerFailure(e.message));
  } on SocketException {
    return const Left(NetworkFailure('No internet connection'));
  } catch (e) {
    return Left(ServerFailure(e.toString()));
  }
}
```

### Snapshot pattern (meal entries)

When logging a meal, always fetch the current food first and embed its macros in the meal entry:

```dart
Future<Either<Failure, MealEntry>> logMeal(LogMealParams p) async {
  final food = await _foodRepo.getFoodById(p.foodId);
  return food.fold(
    (failure) => Left(failure),
    (food) async {
      final entry = MealEntry(
        // ...
        snapshot: FoodSnapshot(
          foodName: food.name,
          macros: food.macros,  // frozen at this moment
        ),
      );
      return _remote.insertMealEntry(entry);
    },
  );
}
```

---

## 13. Edge Functions

Edge Functions run with the service_role key and bypass RLS. Never expose this key to the client.

### delete_account

```typescript
// supabase/functions/delete_account/index.ts
import { serve } from 'https://deno.land/std/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js'

serve(async (req) => {
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return new Response('Unauthorized', { status: 401 })

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // Get user from JWT
  const { data: { user }, error } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', '')
  )
  if (error || !user) return new Response('Unauthorized', { status: 401 })

  // Audit log first (before we lose the ability to reference the user)
  await supabase.from('audit_log').insert({
    actor_id: user.id,
    action: 'delete_account',
    target_type: 'user',
    target_id: user.id,
  })

  // Cascade delete: profile delete cascades to all user data via FKs
  await supabase.from('profiles').delete().eq('id', user.id)

  // Finally, delete the auth user
  await supabase.auth.admin.deleteUser(user.id)

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'Content-Type': 'application/json' }
  })
})
```

### export_user_data

Returns a signed URL to a JSON blob in Supabase Storage containing all user data (profile, entries, templates, custom foods, votes).

### rate_limit_check

Called before mutations that need rate limiting (food creation, voting). Calls `check_rate_limit` RPC.

### admin_promote_food

Admin-only wrapper around `promote_food` RPC with additional validation.

### admin_resolve_flag

Admin-only flag resolution: mark food as deleted, demote tier, or dismiss flag.

### report_abuse

User-initiated abuse reports. Logs to `audit_log` and triggers admin review queue.

---

## 14. Seeding the food database

Source: your brother's `Meal_Calculator.xlsx` `IngredientDB` sheet has ~30 entries. Expand to ~80 verified foods before public launch.

### Cleaning the spreadsheet data

For each entry in the spreadsheet, verify against the actual product label:
- **Macros must be per 100g** (or per unit for discrete items). Spreadsheet may mix conventions.
- **Check the math:** `protein*4 + carbs*4 + fat*9` should equal stated calories ±5%. Some entries in the spreadsheet look off:
  - `Atun en agua` at 45 kcal for 9g protein seems light — verify against actual can label.
  - `Yogurt Griego` values vary by brand — pin to Dos Pinos specifically.
- **Add carbs data:** spreadsheet only tracks protein + calories. You need protein, carbs, fat, fiber explicitly.

### Seeding migration

Save as `supabase/migrations/0004_seed_verified_foods.sql`:

```sql
-- Run as service_role
insert into foods (
  name, brand, category,
  reference_amount, reference_unit,
  protein_g, carbs_g, fat_g, fiber_g,
  tier, visibility, locale
) values
  -- Beef
  ('Rib Eye', null, 'beef', 100, 'g', 24, 0, 16, 0, 'verified', 'public', 'es-CR'),
  ('Molida 85%', null, 'beef', 100, 'g', 22, 0, 12, 0, 'verified', 'public', 'es-CR'),
  -- ... etc for all ~80 foods

-- Add aliases for bilingual search
insert into food_aliases (food_id, alias, locale) values
  ((select id from foods where name = 'Rib Eye'), 'Ojo de Bife', 'es-CR'),
  ((select id from foods where name = 'Pollo - Pechuga'), 'Chicken Breast', 'en'),
  -- ... etc

-- Add named servings where applicable
insert into food_servings (food_id, name, grams_equivalent) values
  ((select id from foods where name = 'GNC Simply Perf Isolate Protein'), 'scoop', 28),
  -- ... etc
```

### Categories of foods to cover at launch

- **Beef:** rib eye, molida, new york, delmonico (8-10 cuts)
- **Chicken:** pechuga, muslo, ala (5-6 cuts)
- **Pork:** bacon, jamón, sausage, pierna, chuleta (6-8)
- **Fish:** atún, salmón, tilapia, pargo (4-6)
- **Dairy:** yogurt griego Dos Pinos, leche Delactomy, quesos (10-12)
- **Eggs:** huevo, clara (2-3)
- **Carbs:** arroz, tortilla harina, tortilla maíz, pasta, pan (8-10)
- **Fruit:** banano, manzana, sandía, mango (6-8)
- **Vegetables:** tomate, lechuga, espinaca, brócoli (6-8)
- **Fats:** aguacate, mantequilla, aceite oliva, aceite coco (4-6)
- **Snacks:** almendras, protein bar, chips (5-6)
- **Drinks:** whiskey, cerveza, café, té (3-4)
- **Supplements:** GNC, ON whey, BCAA (3-5)

Total target: 80-100 verified foods at launch.

---

## 15. Pre-launch checklist

Every item is a blocker for app store submission.

### Authentication & sessions
- [ ] Password complexity enforced
- [ ] Token refresh failures force re-auth
- [ ] Tokens in `flutter_secure_storage` (never SharedPreferences)
- [ ] Sign in with Apple working (iOS requirement)
- [ ] Google sign-in working via native flow
- [ ] Session list + remote sign-out in settings

### Authorization (RLS)
- [ ] RLS enabled on every table
- [ ] Adversarial RLS tests pass (two clients, one cannot access the other's data)
- [ ] `tier` column not writable by users
- [ ] `contributor_id` force-set by trigger
- [ ] Self-vote prevention trigger active
- [ ] Admin RPC functions check `is_admin`, not trust client input

### Data validation
- [ ] CHECK constraints on all macro columns
- [ ] CHECK constraints on enum-like text columns
- [ ] `calories` is generated column
- [ ] FK constraints with appropriate ON DELETE

### Encryption
- [ ] `pgsodium` column encryption on `profile_health` sensitive columns
- [ ] TLS-only (Supabase default, verified)
- [ ] `.env` in `.gitignore`, `.env.example` committed

### Rate limiting
- [ ] `check_rate_limit` called from all write Edge Functions
- [ ] Search pagination enforced (max 20 per page)
- [ ] `statement_timeout` set on roles

### Privacy
- [ ] Privacy policy drafted, reviewed (lawyer or reputable service)
- [ ] Terms of service drafted
- [ ] Explicit health data consent on first run (separate from ToS)
- [ ] "Export my data" works end-to-end
- [ ] "Delete my account" works end-to-end (hard delete ≤30 days)
- [ ] App store privacy labels match actual collection

### Client hardening
- [ ] No `print`/`debugPrint` in release
- [ ] Deep links reject unknown routes
- [ ] `android:allowBackup="false"` + iOS equivalent
- [ ] Certificate pinning (optional v1.1)

### Observability
- [ ] `audit_log` populated by triggers and Edge Functions
- [ ] Supabase dashboard alerts configured
- [ ] Uptime monitoring configured
- [ ] Crash reporting opt-in + PII-scrubbed (if enabled)

### App store assets
- [ ] Screenshots for all required device sizes (iPhone 6.7"/6.5"/5.5", iPad 12.9"/11", Android phone/tablet/7"/10")
- [ ] App icon, splash screen
- [ ] Store description (ES + EN)
- [ ] Privacy policy URL
- [ ] Support URL

---

## 16. Common pitfalls and debugging

### Flutter pub conflicts
- Use `flutter pub outdated --mode=null-safety` to find version mismatches
- Most Supabase conflicts are with `meta` or `http` — check transitive deps

### build_runner issues
- Delete `.dart_tool/build/` before clean build
- Run with `--delete-conflicting-outputs` when freezed/injectable files clash
- Commit generated files per OptiGasto convention (don't gitignore)

### Supabase RLS silently blocking queries
- If a query returns empty when you expected data, first suspect RLS
- Test in Supabase SQL editor with `set role authenticated; set request.jwt.claim.sub = '<uuid>';` then run the query
- `.select()` without matching rows ≠ error in Supabase client — it returns empty list

### OAuth redirect issues
- Android: custom scheme must be in `AndroidManifest.xml` intent-filter
- iOS: URL type in `Info.plist`
- Supabase dashboard: redirect URLs must include `io.supabase.calorietracker://login-callback/`
- Local dev: also add `http://localhost:3000/auth/callback` if testing web

### pgsodium column encryption gotchas
- Cannot create regular index on encrypted column
- Cannot use in WHERE clause directly — decrypt first (expensive)
- Keep only truly sensitive fields encrypted — everything else is a query-performance hit

### FCM + Supabase together
- Two backends = two sets of config — keep separate in `.env`
- FCM token should be stored in `profiles.fcm_token` and refreshed on app launch
- Background message handler must be top-level function (Flutter requirement)

---

## 17. Glossary and references

### Glossary

- **Atwater factors:** 4 kcal/g protein, 4 kcal/g carbs, 9 kcal/g fat. Foundational formula for calorie calculation.
- **BMR (Basal Metabolic Rate):** calories burned at rest. Calculated via Mifflin-St Jeor equation.
- **TDEE (Total Daily Energy Expenditure):** BMR × activity multiplier. Calories you burn per day.
- **Exchange (intercambio):** dietitian system where foods are grouped by macro profile. 1 protein exchange ≈ 7g protein.
- **Snapshot pattern:** storing a frozen copy of reference data at transaction time to protect historical accuracy.
- **RLS (Row-Level Security):** Postgres feature restricting row access per user. Supabase's primary auth model.
- **Trigram search:** fuzzy text matching using 3-character substrings. Enabled via `pg_trgm`.

### External references

- **Supabase docs:** https://supabase.com/docs
- **Clean Architecture in Flutter:** https://resocoder.com/flutter-clean-architecture-tdd/
- **BLoC library:** https://bloclibrary.dev
- **Mifflin-St Jeor equation:** https://www.calculator.net/bmr-calculator.html
- **Food exchange system:** https://www.diabeteseducator.org/living-with-diabetes/tips-and-tricks/exchange-lists-for-meal-planning
- **GDPR Article 9 (special category data):** https://gdpr-info.eu/art-9-gdpr/
- **OpenFoodFacts API:** https://world.openfoodfacts.org/data
- **OptiGasto repo (reference architecture):** your own repo — reference it when in doubt

### Internal docs

- `DESIGN.md` — high-level product + architecture
- `SECURITY.md` — threat model, encryption, compliance
- `MIGRATION_PLAN.md` — week-1 PR-level detail
- This doc (`TECHNICAL_PLAN.md`) — full 6-month reference

---

## Execution order when stuck

When you're unsure what to do next:

1. **Check this doc first.** If the answer is here, do that.
2. **Check `SECURITY.md`.** If the question is security-related.
3. **Check OptiGasto repo.** If the question is about a pattern you've solved before.
4. **Check the PR sequence.** Work strictly in order. Don't skip ahead.
5. **If genuinely blocked:** write a `BLOCKERS.md` in the repo with the specific question, move to the next PR, return when you have a way forward.

Do not over-plan. Do not re-design mid-execution. Trust the plan; adjust only if real production signal tells you to.
