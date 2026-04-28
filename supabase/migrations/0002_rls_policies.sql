-- ============================================================================
-- Row-Level Security Policies
-- Migration: 0002_rls_policies.sql
-- ============================================================================

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
    and trust_score = (select trust_score from profiles where id = auth.uid())
    and is_admin = (select is_admin from profiles where id = auth.uid())
  );

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
create policy "foods_select_public" on foods for select using (
  (tier = 'verified' and deleted_at is null)
  or (tier = 'community' and visibility = 'public' and flags < 3 and deleted_at is null)
  or (contributor_id = auth.uid())
);

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

create policy "foods_update_own_personal" on foods for update using (
  contributor_id = auth.uid() and tier = 'personal'
) with check (
  contributor_id = auth.uid()
  and tier = 'personal'
);

-- ----------------------------------------------------------------------------
-- Food aliases and servings
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
-- Rate limits
-- ----------------------------------------------------------------------------
create policy "rate_limits_select_own" on rate_limits
  for select using (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- Audit log
-- ----------------------------------------------------------------------------
create policy "audit_log_admin_select" on audit_log for select using (
  exists (select 1 from profiles where id = auth.uid() and is_admin = true)
);

-- ----------------------------------------------------------------------------
-- Statement timeouts
-- ----------------------------------------------------------------------------
alter role anon set statement_timeout = '5s';
alter role authenticated set statement_timeout = '5s';
