# Full App Redesign — Design Spec
**Date:** 2026-04-18  
**Approach:** Full Rebuild (Approach A) — new theme system + all screens rebuilt + new navigation, ships together.

---

## 1. Design System

### Style
**Flat Design Mobile (Touch-First)** — bold color blocking, no shadows, high contrast, energetic fitness feel.  
Source: UI/UX Pro Max — "health fitness calorie tracker nutrition mobile modern motivational"

### Color Tokens

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `primary` | `#059669` | `#10B981` | Buttons, active tab, ring eaten arc, header bg |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | Text/icons on primary |
| `accent` | `#EA580C` | `#FB923C` | Calories eaten, carbs macro |
| `protein` | `#3B82F6` | `#60A5FA` | Protein macro bar/chip |
| `fat` | `#EF4444` | `#F87171` | Fat macro, destructive actions |
| `exercise` | `#059669` | `#10B981` | Exercise/burned entries (same as primary) |
| `surface` | `#FFFFFF` | `#1E293B` | Cards, sheets, bottom nav |
| `background` | `#F0F9F6` | `#0F172A` | Page background |
| `onSurface` | `#0F172A` | `#F1F5F9` | Primary text |
| `muted` | `#6B7280` | `#94A3B8` | Secondary text, labels |
| `border` | `#E5E7EB` | `#334155` | Dividers, card borders |
| `destructive` | `#EF4444` | `#F87171` | Sign out, delete |

All tokens defined in `lib/theme/app_colors.dart` as static constants with light/dark variants. Never use raw hex in screens or widgets.

### Typography — Barlow + Barlow Condensed
Add to `pubspec.yaml` via `google_fonts` package.

| Style | Font | Weight | Size | Usage |
|-------|------|--------|------|-------|
| `displayLarge` | Barlow Condensed | 900 | 28px | Big calorie numbers |
| `headlineMedium` | Barlow | 700 | 20px | Screen titles, greeting |
| `titleMedium` | Barlow | 600 | 16px | Section headers |
| `bodyMedium` | Barlow | 400 | 14px | List items, descriptions |
| `labelSmall` | Barlow | 500 | 12px | Macro labels (uppercase) |

Defined in `lib/theme/app_typography.dart`.

### Spacing (8dp grid)
`4 · 8 · 12 · 16 · 20 · 24 · 32 · 48`  
- Page horizontal padding: `20px`  
- Card internal padding: `16px`  
- Section gap: `24px`  
- Item gap: `12px`  

### Shape
- Cards / floating panels: `BorderRadius.circular(16)`  
- Chips / tags: `BorderRadius.circular(12)`  
- Pills / toggles: `BorderRadius.circular(50)`  
- Bottom sheet: `BorderRadius.vertical(top: Radius.circular(24))`  

---

## 2. New File Structure

```
lib/
├── theme/
│   ├── app_colors.dart        ← all color tokens (light + dark)
│   ├── app_typography.dart    ← Barlow text styles
│   └── app_theme.dart         ← ThemeData light + dark, wires colors + typography
├── widgets/
│   ├── calorie_ring.dart      ← reusable donut ring (SVG-style CustomPainter)
│   ├── macro_bar.dart         ← labeled progress bar (label + bar + value)
│   ├── log_entry_tile.dart    ← meal/exercise list item (swipeable)
│   └── app_bottom_nav.dart    ← bottom nav with center FAB cutout
├── screens/
│   ├── auth_screen.dart       ← rebuilt
│   ├── home_screen.dart       ← rebuilt (was dashboard_screen.dart)
│   ├── diary_screen.dart      ← rebuilt (was inline in dashboard)
│   ├── log_entry_screen.dart  ← rebuilt as bottom sheet
│   ├── history_screen.dart    ← rebuilt
│   └── profile_screen.dart    ← rebuilt (absorbs settings_screen.dart)
└── services/                  ← unchanged
```

`settings_screen.dart` is deleted — settings live in Profile.  
`food_database_screen.dart` is kept but accessed from within the Log Entry flow, not as a standalone tab.

---

## 3. Navigation

**Pattern:** Center FAB tab bar — 4 tabs + elevated center "+" button.

```
Home  |  Diary  |  [+]  |  History  |  Profile
```

- `[+]` opens `LogEntryScreen` as a modal bottom sheet (`showModalBottomSheet` with `isScrollControlled: true`).
- All tab switches use `IndexedStack` to preserve scroll/state per tab.
- Back navigation restores scroll position and filter state.
- Bottom nav stays visible from all top-level screens. Hides only inside `LogEntryScreen` sheet.

### Route Map
The center "+" is an overlay FAB, not a real tab index. Four real tab indices:

| Destination | How to reach |
|-------------|-------------|
| Home | Tab index 0 |
| Diary | Tab index 1 · also "View full diary →" from Home |
| Log Entry | Center "+" FAB overlay (modal sheet, no tab index) |
| History | Tab index 2 |
| Profile | Tab index 3 |
| Food Database | Search within Log Entry sheet → "Browse all" |
| Profile Edit | "Edit ›" button on Profile screen (pushed route) |

---

## 4. Screens

### 4.1 Auth Screen
- Full-screen green gradient hero (`#059669` → `#065F46`)
- App logo (🥗) + app name + tagline: *"Know what you eat. Own your goals."*
- White bottom sheet (`BorderRadius.vertical(top: 24)`) slides up with:
  - Email field
  - Password field (with show/hide toggle)
  - "Sign In" full-width primary button
  - Divider "or continue with"
  - Google + Apple social buttons (side by side, outlined)
  - "Don't have an account? Sign up" text toggle
- Sign Up mode: adds Confirm Password field, swaps button label.
- No changes to `AuthService` logic.

### 4.2 Home Screen
**Header (green):**
- Left: date (`Friday, Apr 18 · Goal: 3,260`) + greeting (`Good morning, Edgar 👋`)
- Right: notification bell icon

**Floating summary card** (overlaps header by 10px, `elevation` via shadow):
- Left: mini donut ring (68×68) — green arc = eaten %, orange arc = burned %
- Right column: Remaining (green, bold) · Eaten · Burned · Goal

**Macro bars section** (below card, padding 20px):
- Three rows: PROTEIN (blue) · CARBS (orange) · FAT (red)
- Each: label + `current / goal g` right-aligned + progress bar

**Today's Log preview:**
- Section title "Today's Log"
- Up to 3 most recent entries (food = `#f9fafb` bg, exercise = `#ECFDF5` bg + green text)
- "View full diary →" tappable link → navigates to Diary tab

### 4.3 Diary Screen
**Header (green):**
- "Diary" title left + 📅 calendar icon right (opens `showDatePicker`)
- Horizontally scrollable date strip (7 visible days, current day highlighted white pill)
  - Strip scrolls infinitely into the past (no label, ‹ › arrows as visual affordance)
  - Swiping left/right on the date strip OR the main content changes the selected day

**Content (scrollable):**

> **Note on Snacks:** New meal type. Add `'snack'` as a valid `type` value in the Firestore `logs` collection alongside existing `'food'` and `'exercise'`. Existing entries without a meal slot default to Lunch.

- Grouped by meal: **Breakfast · Lunch · Dinner · Snacks · Exercise**
- Each group header: meal name (uppercase) + total calories for group + "**+ Add**" right-aligned
- Each entry: `LogEntryTile` — food name, macro breakdown (`P Xg · C Xg · F Xg`), calorie right-aligned
  - Exercise entries: green background, calorie shown as `−Xcal`
  - Swipe left on entry to reveal delete action (red, requires confirmation)
- Empty group: placeholder text "Tap + Add to log [meal name]"
- Tapping "**+ Add**" on a group opens `LogEntryScreen` sheet pre-selected to that meal slot

### 4.4 Log Entry Screen (Bottom Sheet)
- Modal bottom sheet, `isScrollControlled: true`, drag handle at top
- Title: "Log Food or Exercise"
- **Food / Exercise toggle** (segmented, default Food)

**Food mode:**
- Search field (🔍 prefix, "Search food or scan barcode…")
- Results list: food name + macros detail + calorie right-aligned + green "+" circular add button
- Tapping a result: opens quantity selector (inline expand, not new screen) — input grams/servings, shows live macro preview
- Footer link: "+ Create custom food" → opens `FoodDatabaseScreen` modal

**Exercise mode:**
- Search field ("Search exercise…")
- Results: exercise name + duration input + calories burned estimate
- Same CalorieNinjas API, type='exercise'

### 4.5 History Screen
**Header (green):** "History" title + "Last 7 days" subtitle

**7-day bar chart** (`fl_chart` BarChart):
- Green bars = calories eaten, orange bars = calories burned
- Today highlighted (full opacity), past days slightly muted
- Day labels (M T W T F S S) below bars
- Legend: green dot "Eaten" · orange dot "Burned"

**Weekly stats row** (3 cards):
- Avg daily calories · Deficit days · Surplus days

**Daily rows list:**
- Each row: day name + net calories (green if deficit `−X`, red if surplus `+X`)
- Tappable row → navigates to that day in Diary tab

### 4.6 Profile Screen — View Mode
**Header (green):**
- Avatar circle (initials or photo) + display name + email

**Floating stats card** (3 items, no BMR):
- Cal goal (green) · Protein goal (blue) · Day streak 🔥 (orange)

  > **Streak calculation:** Count consecutive days (ending today) where the `logs` Firestore collection has at least one entry for the user. Calculated in `CalorieService` at load time, cached in memory for the session.

**Body Stats section:**
- "Edit ›" button top-right → enters Edit Mode
- Rows (read-only): Weight · Height · Age · Gender

**Goals section:**
- Calorie goal `›` (tappable, inline edit)
- Protein goal `›` (tappable, inline edit)

**Settings section:**
- Daily reminder toggle (ON/OFF + time)
- Dark mode (System / Light / Dark selector)
- Sign out (red text, confirmation dialog before action)

### 4.7 Profile Screen — Edit Mode
- Pushed as a new screen (not modal) with "Edit Profile" title, Cancel + Save in AppBar
- **Single Imperial / Metric toggle** at top — switching converts all fields instantly
  - Imperial: weight in lbs, height in ft + in (two fields)
  - Metric: weight in kg, height in m (one field)
  - Inline conversion hint shown (e.g. `= 83.9 kg`) updates as user types
  - Preference persisted to `SharedPreferences` key `unit_system`
- Editable fields: Weight · Height · Age · Gender (Male/Female segmented)
- On Save: recalculates BMR (Mifflin-St Jeor), updates Firestore profile doc, pops back to view

---

## 5. Unit Conversion Logic

```dart
// Weight
double lbsToKg(double lbs) => lbs * 0.453592;
double kgToLbs(double kg) => kg * 2.20462;

// Height
double feetInchesToMeters(int feet, int inches) => (feet * 12 + inches) * 0.0254;
(int feet, int inches) metersToFeetInches(double m) {
  final totalInches = (m / 0.0254).round();
  return (totalInches ~/ 12, totalInches % 12);
}
```

- Conversions run on toggle tap, not on every keystroke.
- Values rounded: kg to 1 decimal, lbs to whole number, m to 2 decimals.
- If user edits after toggle, the new value is taken as-is in the current unit.

---

## 6. Theme Wiring

`main.dart` passes `ThemeData` from `AppTheme.light()` and `AppTheme.dark()` to `MaterialApp`:

```dart
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system, // overridden by user preference
  ...
)
```

`ThemeMode` preference stored in `SharedPreferences` key `theme_mode`, read at startup and managed by a `ThemeNotifier` (ChangeNotifier, added to existing Provider setup).

---

## 7. Deleted / Merged Files

| Old file | Fate |
|----------|------|
| `screens/settings_screen.dart` | Deleted — settings merged into Profile |
| `screens/dashboard_screen.dart` | Renamed → `screens/home_screen.dart` |

`food_database_screen.dart` kept but no longer a top-level route — accessed from Log Entry sheet.

---

## 8. Out of Scope

- No changes to `services/` (auth, calorie, food, notification services)
- No changes to Firestore data model
- No changes to Firebase configuration
- Friends feed (currently in dashboard) deferred — not included in redesigned Home screen (data still exists, can be added later)

---

## 9. Pre-Delivery Checklist (from UI/UX Pro Max)

- [ ] No emojis used as structural icons (use `Icons.*` or vector alternatives)
- [ ] All touch targets ≥ 44×44pt
- [ ] Primary text contrast ≥ 4.5:1 in both light and dark
- [ ] Safe areas respected for header, bottom nav, FAB
- [ ] Scroll content not hidden behind fixed bottom nav
- [ ] Animations 150–300ms, respect `prefers-reduced-motion` (via `MediaQuery.disableAnimations`)
- [ ] Form fields have labels (not placeholder-only)
- [ ] Swipe-to-delete requires confirmation
- [ ] Unit preference and theme mode persist across app restarts
