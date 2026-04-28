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
-- Normalize food and alias names
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
-- Force contributor_id to auth.uid() on food insert
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
-- Rate limit check
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

  delete from rate_limits
  where user_id = p_user_id and action = p_action and window_start < v_window_start;

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
-- Search foods
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
