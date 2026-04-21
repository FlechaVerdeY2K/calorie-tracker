# Security & Privacy Document

**Status:** Draft v0.1
**Last updated:** 2026-04-20
**Privacy posture:** GDPR-grade from day 1 (strict)
**Target:** Public app store launch within 6 months

This document covers the threat model, row-level security policies, encryption choices, privacy compliance requirements, and the pre-launch security checklist. It is reviewable independently of `DESIGN.md` and should stay in sync when either changes.

## Threat model

Users trust this app with their body weight, eating habits, and daily caloric intake — all of which qualify as **health data** under major privacy regimes. Several classes of attackers/risks matter:

### 1. Malicious food contributors

**Goal:** Pollute the shared database with incorrect macros to either make the app unusable or deliberately harm users who rely on the data (someone trying to lose weight logs a food that claims to be 100 kcal but is actually 500).

**Mitigations:**

- Community-tier foods gated behind 7-day account age.
- DB-level CHECK constraints on physical plausibility (protein ≤ 100g per 100g, etc.).
- Hard cap of 20 new foods per user per day, 5 per hour (Edge Function rate limiting).
- 3 flags auto-hides a food from search pending admin review.
- Verified tier requires manual admin promotion — upvotes only sort the review queue, they do not auto-promote.
- Community-tier foods display a visible "⚠️ Community entry — verify before logging" banner.

### 2. Sybil attack on trust signals

**Goal:** Create many fake accounts to upvote self-submitted foods into verified tier, or flag competitor/honest submissions into oblivion.

**Mitigations:**

- Users cannot vote on their own submissions (DB trigger).
- One vote per user per food (UNIQUE constraint on `food_votes`).
- Votes from accounts <7 days old don't count toward promotion queue ranking.
- Promotion to verified is **always manual** by admin. No purely algorithmic path.
- Suspicious voting patterns logged to `audit_log` for review.

### 3. Health data exfiltration

**Goal:** Extract body weight, eating habits, and other sensitive personal data from other users.

**Mitigations:**

- Row-level security on every table (no table is readable without it).
- `profile_health` table stores weight/height/DOB with column-level encryption via `pgsodium`.
- All PII columns require `auth.uid()` match for SELECT.
- API tokens stored in iOS Keychain / Android Keystore via `flutter_secure_storage`.
- TLS-only connections enforced (Supabase default).

### 4. Privilege escalation

**Goal:** Regular user elevates to admin or modifies own records in disallowed ways (changing a personal food into verified tier, changing contributor_id on someone else's food, etc.).

**Mitigations:**

- `tier` column is never writable by RLS policy — only via SECURITY DEFINER RPC `promote_food()` that checks admin JWT claim.
- `contributor_id` is force-set to `auth.uid()` by INSERT trigger regardless of client input.
- `superseded_by` not writable by users at all.
- Admin actions logged to append-only `audit_log`.

### 5. Denial of service

**Goal:** Make the app unusable for other users via expensive queries, storage exhaustion, or auth endpoint spam.

**Mitigations:**

- Postgres `statement_timeout = '5s'` on the `anon` and `authenticated` roles.
- Trigram indexes keep search fast at scale.
- Pagination enforced (max 20 results per search page, cursor-based).
- Supabase's built-in auth rate limiting (not tunable, but present).
- Per-user `rate_limits` table for custom limits on food creation, voting, etc.

### 6. Account compromise

**Goal:** Attacker gains access to a user's account via credential stuffing, phishing, or token theft.

**Mitigations:**

- Enforce strong passwords (minimum length, common-password dictionary check on signup).
- Rate-limited auth endpoints.
- Optional biometric app lock (v1.1 — add to build plan).
- Secure token storage (Keychain/Keystore).
- Proper token refresh handling — on refresh failure, force re-authentication rather than silent retry with stale token.
- Session list + remote sign-out in settings (uses Supabase's session management).

### 7. Data loss / history corruption

**Goal:** Not necessarily an attacker — could be an edit propagating incorrectly, but the outcome is the same: users lose trust.

**Mitigations:**

- `meal_entries` stores denormalized snapshot of macros at log time. Food edits never modify historical logs.
- Food edits are non-destructive: new row with `superseded_by` pointing back.
- Soft-delete (not hard-delete) for personal foods — `deleted_at` column.
- Daily DB backups (Supabase default on paid tier — confirm before launch).

## Row-Level Security policies

RLS is enabled on **every** user-data table. Policies below are the complete set.

### profiles

```sql
alter table profiles enable row level security;

create policy "profiles_select_own" on profiles
  for select using (auth.uid() = id);

create policy "profiles_insert_own" on profiles
  for insert with check (auth.uid() = id);

create policy "profiles_update_own" on profiles
  for update using (auth.uid() = id)
  with check (
    auth.uid() = id
    and trust_score = (select trust_score from profiles where id = auth.uid())
    -- user cannot change their own trust_score
  );

-- NO delete policy. Deletion goes through the `delete_account()` Edge Function
-- which handles cascade of personal data and auth.users deletion atomically.
```

### profile_health (encrypted sensitive data)

```sql
alter table profile_health enable row level security;

create policy "profile_health_select_own" on profile_health
  for select using (auth.uid() = profile_id);

create policy "profile_health_upsert_own" on profile_health
  for insert with check (auth.uid() = profile_id);

create policy "profile_health_update_own" on profile_health
  for update using (auth.uid() = profile_id)
  with check (auth.uid() = profile_id);

-- NO delete policy. Cascades via profile deletion.
```

### foods

```sql
alter table foods enable row level security;

-- Readable: all verified, all non-flagged public community, your own personal, your own (even if flagged)
create policy "foods_select_public" on foods for select using (
  (tier = 'verified' and deleted_at is null)
  or (tier = 'community' and visibility = 'public' and flags < 3 and deleted_at is null)
  or (contributor_id = auth.uid())
);

-- Writable: only community or personal, only if 7+ days old for community
create policy "foods_insert_own" on foods for insert with check (
  contributor_id = auth.uid()
  and tier in ('community', 'personal')
  and superseded_by is null
  and (
    tier = 'personal'
    or (select created_at from auth.users where id = auth.uid()) < now() - interval '7 days'
  )
);

-- Updatable: only your own personal foods, and you cannot change tier/contributor_id
create policy "foods_update_own_personal" on foods for update using (
  contributor_id = auth.uid() and tier = 'personal'
) with check (
  contributor_id = auth.uid() and tier = 'personal'
);

-- No public delete policy. Personal foods can be soft-deleted via the app
-- (which does an UPDATE setting deleted_at). Admin deletion goes through RPC.
```

### meal_entries

```sql
alter table meal_entries enable row level security;

create policy "meals_select_own" on meal_entries
  for select using (user_id = auth.uid());

create policy "meals_insert_own" on meal_entries
  for insert with check (user_id = auth.uid());

create policy "meals_update_own" on meal_entries
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "meals_delete_own" on meal_entries
  for delete using (user_id = auth.uid());
```

### food_votes

```sql
alter table food_votes enable row level security;

create policy "votes_select_own" on food_votes
  for select using (user_id = auth.uid());

create policy "votes_insert_own" on food_votes for insert with check (
  user_id = auth.uid()
  -- self-vote blocked by trigger
  -- account age check is also in trigger (promotion queue weighting)
);

create policy "votes_delete_own" on food_votes
  for delete using (user_id = auth.uid());
```

### meal_templates + meal_template_items

```sql
alter table meal_templates enable row level security;
create policy "templates_all_own" on meal_templates for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

alter table meal_template_items enable row level security;
create policy "template_items_all_own" on meal_template_items for all
  using ((select user_id from meal_templates where id = template_id) = auth.uid())
  with check ((select user_id from meal_templates where id = template_id) = auth.uid());
```

### daily_metrics

```sql
alter table daily_metrics enable row level security;
create policy "metrics_all_own" on daily_metrics for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
```

### audit_log (admin-only, append-only)

```sql
alter table audit_log enable row level security;

-- No select for regular users
create policy "audit_log_admin_select" on audit_log for select using (
  (auth.jwt() ->> 'role') = 'admin'
);

-- No direct insert — only via SECURITY DEFINER functions
-- No update policy — append-only
-- No delete policy — append-only
```

## Triggers and security-critical functions

### Prevent self-voting on foods

```sql
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
```

### Force contributor_id on insert

```sql
create or replace function force_contributor_id() returns trigger
language plpgsql security definer as $$
begin
  new.contributor_id := auth.uid();
  return new;
end;
$$;

create trigger foods_force_contributor before insert on foods
  for each row execute function force_contributor_id();
```

### Macro physical plausibility (defense in depth — RLS handles auth, this handles physics)

```sql
alter table foods add constraint macros_nonneg check (
  protein_g >= 0 and carbs_g >= 0 and fat_g >= 0 and fiber_g >= 0
);

alter table foods add constraint macros_physical check (
  case when reference_unit = 'g' and reference_amount = 100 then
    protein_g + carbs_g + fat_g <= 100
  else true end
  -- Per-100g foods cannot have >100g of macros. Per-unit foods can be any size.
);

alter table foods add constraint macros_per100_bounds check (
  case when reference_unit = 'g' and reference_amount = 100 then
    protein_g <= 100 and carbs_g <= 100 and fat_g <= 100
  else true end
);
```

### Promote food to verified tier (admin-only)

```sql
create or replace function promote_food(food_id uuid, new_tier text)
returns void
language plpgsql security definer as $$
begin
  if (auth.jwt() ->> 'role') != 'admin' then
    raise exception 'admin privileges required';
  end if;

  if new_tier not in ('verified', 'community') then
    raise exception 'invalid tier';
  end if;

  update foods set tier = new_tier, updated_at = now() where id = food_id;

  insert into audit_log (actor_id, action, target_type, target_id, metadata)
  values (auth.uid(), 'promote_food', 'food', food_id,
          jsonb_build_object('new_tier', new_tier));
end;
$$;

revoke all on function promote_food(uuid, text) from public;
grant execute on function promote_food(uuid, text) to authenticated;
-- The internal auth check is what actually enforces admin-only.
```

## Encryption

### At rest (disk)

Supabase provides disk-level encryption by default. This is table stakes but insufficient for health data.

### Column-level (sensitive health data)

Strict posture — `pgsodium` column-level encryption on:

- `profile_health.body_weight_kg`
- `profile_health.height_cm`
- `profile_health.birth_date`

Keys managed by Supabase Vault. App sees decrypted values via a view that RLS-restricts to `auth.uid() = profile_id`.

Why these specifically: these three columns together approximate BMI, age, and weight trajectory — enough for re-identification in combination with other data, and sensitive enough that a breach of the underlying Postgres dump would be a notifiable incident.

### In transit

- TLS 1.2+ enforced by Supabase.
- Certificate pinning on the Flutter client (v1.1 — note in build plan).

## Rate limiting

Supabase auth endpoints are rate-limited by default. For everything else we maintain our own `rate_limits` table and enforce via Edge Functions or triggers.

```sql
create table rate_limits (
  user_id uuid not null references profiles(id) on delete cascade,
  action text not null,
  window_start timestamptz not null,
  count integer not null default 1,
  primary key (user_id, action, window_start)
);
```

Enforced limits:

| Action | Limit |
|---|---|
| Food creation (community tier) | 20/day, 5/hour |
| Food creation (personal tier) | 100/day |
| Vote (upvote or flag) | 100/day |
| Meal log | 200/day (generous, for edge cases) |
| Search queries | 300/hour |
| Account creation (per IP) | 3/day (Supabase level) |

## Privacy compliance (GDPR-grade, day 1)

### Article 9 special category data

Body weight, BMI, and eating habits likely qualify as "data concerning health" under GDPR Article 9. This means:

- Explicit consent required on first run (not bundled with ToS acceptance — separate checkbox for "processing of health data").
- Legal basis documented: explicit consent for processing health data.
- Data minimization: don't collect what we don't need. No photos of meals. No location. No device identifiers beyond what FCM requires.

### User rights

All of these must work **from day 1**, not bolted on later:

- **Right of access:** "Export all my data" button in settings. Generates JSON + CSV download. Includes: profile, meal entries, templates, custom foods, votes.
- **Right to rectification:** Edit profile, edit custom foods, edit meal entries.
- **Right to erasure:** "Delete my account" button. Triggers `delete_account()` Edge Function. Completes within 30 days (GDPR requirement). Hard-deletes personal data. Community foods the user contributed remain (de-identified: `contributor_id` set to NULL) to preserve database integrity — this is compatible with GDPR as long as users are informed of it in the privacy policy.
- **Right to portability:** Same as access — export is in machine-readable JSON.
- **Right to object:** User can disable all analytics/telemetry.

### Required documents before launch

- **Privacy Policy** — specific, not boilerplate. Must enumerate: what data, why, legal basis, retention periods, third parties (Supabase, FCM), user rights, contact for data protection inquiries.
- **Terms of Service** — standard, but should include community food contribution rules.
- **Cookie/tracking disclosure** — if any analytics are added, needs a consent banner in EU/UK.

These are not optional and not a "week 23" task — they need to be drafted by week 17 at the latest. Recommend using a lawyer or a reputable template service (iubenda, Termly) rather than writing from scratch.

### Data residency

Supabase hosts by region. For EU compliance, health data for EU users should be stored in an EU region. Initial launch in Costa Rica can use US-East, but EU expansion requires adding EU region — budget for this.

## Client-side security

### Token storage

```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  # NOT shared_preferences for any sensitive data
```

```dart
// lib/core/secure_storage.dart
final _storage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
```

### Session handling

- On app launch, validate session with Supabase before showing any authenticated screen.
- On token refresh failure: clear tokens, force re-auth, never silently retry with stale token.
- On app backgrounding for >15 minutes (configurable): require biometric unlock (v1.1).
- Remote session list in settings: show active sessions, allow revocation.

### Input validation

**Client-side validation is UX, not security.** Every validation must also be enforced at the DB or Edge Function level. The Flutter app's validators are purely for user feedback.

### Logging

- Never log tokens, passwords, or encrypted column values.
- Production builds use `kDebugMode` guards around all `print`/`debugPrint`.
- Crash reporting (if added) must be opt-in and must scrub PII.

### Deep links

`go_router` configuration must reject unknown routes rather than navigate to them. Any deep link with auth-sensitive params requires re-auth.

## Edge Functions (server-side boundaries)

Operations that require the `service_role` key, bypass RLS, or need cross-table atomicity run as Supabase Edge Functions. **The service_role key is NEVER exposed to the client** — these functions run in Supabase's environment.

Required Edge Functions at launch:

| Function | Purpose |
|---|---|
| `delete_account` | Hard-delete user data across all tables + auth.users |
| `export_user_data` | Generate full data export (JSON/CSV), upload to Storage, return signed URL |
| `rate_limit_check` | Server-side rate limit enforcement for food creation |
| `admin_promote_food` | Admin-only food tier promotion |
| `admin_resolve_flag` | Admin-only flag resolution + food status update |
| `report_abuse` | User-initiated abuse reports (logged, triggers admin review) |

## Logging and observability

### audit_log

Append-only table capturing all admin actions and security-relevant events:

```sql
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
```

Events logged:

- Food tier promotions/demotions
- Account deletions
- Flag resolutions
- Admin role grants/revokes
- Failed auth attempts (aggregated, not per-attempt PII)
- Rate limit violations
- Policy violations caught by triggers

### Monitoring

Before launch, set up:

- Supabase dashboard alerts on: >10 failed auth/minute, statement_timeout trips, RLS policy denials spiking.
- Weekly review of `audit_log` for anomalous patterns.
- Uptime monitoring (any free service — Pingdom, UptimeRobot).

## Pre-launch security checklist

Complete before submitting to app stores. **Every item is a blocker.**

### Authentication
- [ ] Password complexity enforced (min length, common-password block).
- [ ] Token refresh failures force re-auth (no silent stale-token usage).
- [ ] Tokens stored in `flutter_secure_storage`, never in `shared_preferences`.
- [ ] Sign in with Apple implemented (iOS app store requirement).
- [ ] Test: locked-out account path (too many failed attempts).
- [ ] Test: expired token path (force refresh, force re-auth on refresh fail).

### Authorization
- [ ] RLS enabled on every user-data table.
- [ ] RLS policies tested with adversarial queries (try to read another user's data, try to write to another user's rows).
- [ ] `tier` column not writable via RLS — only via `promote_food()` RPC.
- [ ] `contributor_id` force-set by trigger regardless of client input.
- [ ] `superseded_by` not writable by users.
- [ ] Self-vote prevention trigger tested.
- [ ] Admin RPC functions check JWT role claim, not trust user input.

### Data validation
- [ ] CHECK constraints on all macro columns (non-negative, physical plausibility).
- [ ] CHECK constraints on enum-like text columns (`tier`, `goal`, `activity_level`, `meal_type`).
- [ ] Generated column for `calories` — no stored calorie column.
- [ ] Foreign key constraints with appropriate ON DELETE behavior.

### Encryption
- [ ] `pgsodium` column encryption on `profile_health` sensitive columns.
- [ ] TLS-only connections verified.
- [ ] No plaintext secrets in client code or repo (use `flutter_dotenv` + `.env` in `.gitignore`).

### Rate limiting
- [ ] `rate_limits` table enforced via Edge Functions for food creation.
- [ ] Search pagination (max 20 per page, cursor-based).
- [ ] `statement_timeout` set on `anon` and `authenticated` roles.

### Privacy
- [ ] Privacy policy drafted and reviewed by lawyer or reputable template service.
- [ ] Terms of service drafted.
- [ ] Explicit health data consent on first run (separate from ToS).
- [ ] "Export my data" Edge Function works end-to-end.
- [ ] "Delete my account" Edge Function works end-to-end (hard delete, ≤30 days).
- [ ] Data residency decision documented (initial: US-East OK for CR launch; EU region required before EU marketing).
- [ ] App store privacy labels match actual data collection.

### Client hardening
- [ ] No `print`/`debugPrint` in release builds (wrapped in `kDebugMode`).
- [ ] Crash reporting opt-in and PII-scrubbed (or deferred past launch).
- [ ] Deep link handling rejects unknown routes.
- [ ] `android:allowBackup="false"` and iOS equivalent to prevent OS backup of app data.

### Observability
- [ ] `audit_log` populated by all relevant triggers and Edge Functions.
- [ ] Supabase dashboard alerts configured.
- [ ] Uptime monitoring configured.

### Review
- [ ] External security review by a trusted party (not you, not brother). Can be a developer friend — fresh eyes matter more than certifications for the first pass.
- [ ] Penetration test attempt: try to read another user's data from a second account.
- [ ] Load test: simulate 100 concurrent users logging meals, confirm search stays <500ms.

## Post-launch security practices

- Monthly review of `audit_log`.
- Quarterly RLS policy audit (test with adversarial queries).
- Annual external security review.
- Incident response plan: who's contacted if a breach is detected, within what timeframe (GDPR requires notification of authorities within 72 hours of awareness).
- Dependency audit: `flutter pub outdated --mode=security` weekly.
- Subscribe to Supabase security advisories.
