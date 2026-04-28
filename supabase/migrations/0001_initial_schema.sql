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
  body_weight_kg_encrypted bytea,
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
  name_normalized text not null,
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
  name text not null,
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
  weight_kg_encrypted bytea,
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
