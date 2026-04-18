# Full App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current single-dashboard calorie tracker UI with the approved four-tab redesign, new theme system, bottom-sheet logging flow, and consolidated profile/settings experience without breaking auth, Firebase data access, or reminders.

**Architecture:** Introduce a design-system layer (`theme/`, reusable `widgets/`, focused models/helpers) and rebuild the app shell around an `IndexedStack` root with a center FAB that opens the logging flow as a modal sheet. Keep Firebase as the source of truth, but add narrowly scoped compatibility helpers in `CalorieService` and `FoodService` so the new Home, Diary, History, and Profile screens can render richer state without a Firestore migration.

**Tech Stack:** Flutter, Material 3, Provider, Firebase Auth, Cloud Firestore, SharedPreferences, `fl_chart`, `flutter_local_notifications`, `google_fonts`, `http`, `flutter_test`

---

## File Structure

- Modify: `pubspec.yaml` — add `google_fonts`; keep existing Firebase/chart/preferences packages.
- Modify: `lib/main.dart` — bootstrap `MultiProvider`, wire `AppTheme.light()` / `AppTheme.dark()`, and send signed-in users to the new shell instead of `DashboardScreen`.
- Create: `lib/models/unit_system.dart` — `metric` / `imperial` enum plus persistence key helpers.
- Create: `lib/models/log_entry_record.dart` — normalized log model that treats legacy Firestore `type: 'meal'` docs as food entries.
- Create: `lib/models/daily_summary.dart` — reusable totals for Home, Diary, and History.
- Create: `lib/state/theme_notifier.dart` — load/save `theme_mode` from `SharedPreferences`.
- Create: `lib/state/unit_system_notifier.dart` — load/save `unit_system` from `SharedPreferences`.
- Create: `lib/theme/app_colors.dart` — static light/dark token tables.
- Create: `lib/theme/app_typography.dart` — Barlow / Barlow Condensed text theme.
- Create: `lib/theme/app_theme.dart` — shared `ThemeData` factory methods and input/button styling.
- Create: `lib/utils/unit_conversions.dart` — lbs/kg and ft/in/m conversions with the rounding rules from the spec.
- Create: `lib/utils/log_grouping.dart` — meal-slot grouping, “default to lunch”, and history aggregation helpers.
- Create: `lib/widgets/app_bottom_nav.dart` — four-tab navigation with center FAB gap.
- Create: `lib/widgets/calorie_ring.dart` — custom-painted eaten/burned donut.
- Create: `lib/widgets/macro_bar.dart` — labeled progress row with clamp-safe values.
- Create: `lib/widgets/log_entry_tile.dart` — shared diary/home tile with delete affordance hooks.
- Create: `lib/screens/app_shell.dart` — `IndexedStack` host for Home / Diary / History / Profile plus FAB launcher.
- Create: `lib/screens/home_screen.dart` — redesigned dashboard replacement.
- Create: `lib/screens/diary_screen.dart` — grouped-by-meal daily log.
- Create: `lib/screens/profile_edit_screen.dart` — pushed edit route with unit toggle and conversion hints.
- Modify: `lib/screens/auth_screen.dart` — hero + bottom-sheet auth redesign with unchanged `AuthService` behavior.
- Modify: `lib/screens/log_entry_screen.dart` — bottom-sheet-friendly food/exercise flow with quantity preview and meal preselection.
- Modify: `lib/screens/history_screen.dart` — redesigned 7-day analytics and diary deep links.
- Modify: `lib/screens/profile_screen.dart` — view mode, inline settings, edit navigation, sign out.
- Modify: `lib/screens/food_database_screen.dart` — support modal use from the log-entry flow and optional “return selected food” behavior.
- Modify: `lib/services/calorie_service.dart` — add normalized day queries, streak calculation, and delete helpers required by the new screens.
- Modify: `lib/services/food_service.dart` — add exercise search mapping and reusable quantity-scaling helpers.
- Delete: `lib/screens/settings_screen.dart` — settings move into Profile.
- Delete: `lib/screens/dashboard_screen.dart` after `home_screen.dart` is fully wired.
- Create tests:
  - `test/utils/unit_conversions_test.dart`
  - `test/utils/log_grouping_test.dart`
  - `test/state/theme_notifier_test.dart`
  - `test/state/unit_system_notifier_test.dart`
  - `test/widgets/app_bottom_nav_test.dart`
  - `test/widgets/auth_screen_test.dart`
  - `test/widgets/home_screen_widgets_test.dart`
  - `test/widgets/log_entry_screen_test.dart`
  - `test/widgets/profile_edit_screen_test.dart`
  - Replace `test/widget_test.dart` with an app-shell smoke test that matches the real app.

## Resolved Assumptions

- Legacy log documents currently use `type: 'meal'`, not `type: 'food'`. Keep backward compatibility by treating `'meal'` as the stored food type and adding an optional `mealSlot` field (`breakfast`, `lunch`, `dinner`, `snack`) for new entries. When `mealSlot` is absent, the UI must default the entry to Lunch.
- The spec’s “no service changes” note conflicts with the required streak, diary grouping, and exercise search behavior. This plan allows surgical updates to `CalorieService` and `FoodService`, but keeps Firebase collections and auth configuration intact.
- The design spec mentions emoji branding, but the pre-delivery checklist forbids emoji as structural icons. Use Material icons or a future asset instead of emoji in the implemented UI.

### Task 1: Preferences, Conversions, and Bootstrap

**Files:**
- Create: `lib/models/unit_system.dart`
- Create: `lib/state/theme_notifier.dart`
- Create: `lib/state/unit_system_notifier.dart`
- Create: `lib/utils/unit_conversions.dart`
- Modify: `lib/main.dart`
- Modify: `pubspec.yaml`
- Test: `test/utils/unit_conversions_test.dart`
- Test: `test/state/theme_notifier_test.dart`
- Test: `test/state/unit_system_notifier_test.dart`

- [ ] **Step 1: Write the failing unit tests for conversions and persisted preferences**

```dart
// test/utils/unit_conversions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_tracker/utils/unit_conversions.dart';

void main() {
  test('lbsToKg and kgToLbs follow spec rounding', () {
    expect(lbsToKg(185), closeTo(83.9145, 0.0001));
    expect(roundKilograms(lbsToKg(185)), 83.9);
    expect(roundPounds(kgToLbs(83.9)), 185);
  });

  test('feet/inches conversions round-trip cleanly', () {
    final meters = feetInchesToMeters(5, 11);
    final (feet, inches) = metersToFeetInches(meters);

    expect(roundMeters(meters), 1.80);
    expect(feet, 5);
    expect(inches, 11);
  });
}
```

```dart
// test/state/theme_notifier_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_tracker/state/theme_notifier.dart';

void main() {
  test('ThemeNotifier loads and saves theme mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

    final notifier = ThemeNotifier();
    await notifier.load();

    expect(notifier.themeMode, ThemeMode.dark);

    await notifier.setThemeMode(ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });
}
```

```dart
// test/state/unit_system_notifier_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_tracker/models/unit_system.dart';
import 'package:calorie_tracker/state/unit_system_notifier.dart';

void main() {
  test('UnitSystemNotifier defaults to metric and persists updates', () async {
    SharedPreferences.setMockInitialValues({});

    final notifier = UnitSystemNotifier();
    await notifier.load();
    expect(notifier.unitSystem, UnitSystem.metric);

    await notifier.setUnitSystem(UnitSystem.imperial);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('unit_system'), 'imperial');
  });
}
```

- [ ] **Step 2: Run the tests to verify the missing files fail**

Run: `flutter test test/utils/unit_conversions_test.dart test/state/theme_notifier_test.dart test/state/unit_system_notifier_test.dart -r compact`
Expected: FAIL with import errors for the new models, utils, and notifiers.

- [ ] **Step 3: Implement the preferences and conversion layer**

```dart
// lib/models/unit_system.dart
enum UnitSystem { metric, imperial }

extension UnitSystemStorage on UnitSystem {
  String get storageValue => switch (this) {
        UnitSystem.metric => 'metric',
        UnitSystem.imperial => 'imperial',
      };

  static UnitSystem fromStorage(String? value) {
    return value == 'imperial' ? UnitSystem.imperial : UnitSystem.metric;
  }
}
```

```dart
// lib/utils/unit_conversions.dart
double lbsToKg(double lbs) => lbs * 0.453592;
double kgToLbs(double kg) => kg * 2.20462;

double feetInchesToMeters(int feet, int inches) =>
    (feet * 12 + inches) * 0.0254;

(int feet, int inches) metersToFeetInches(double meters) {
  final totalInches = (meters / 0.0254).round();
  return (totalInches ~/ 12, totalInches % 12);
}

double roundKilograms(double value) => double.parse(value.toStringAsFixed(1));
double roundMeters(double value) => double.parse(value.toStringAsFixed(2));
int roundPounds(double value) => value.round();
```

```dart
// lib/state/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theme_mode');
    _themeMode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString('theme_mode', value);
  }
}
```

```dart
// lib/state/unit_system_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_tracker/models/unit_system.dart';

class UnitSystemNotifier extends ChangeNotifier {
  UnitSystem _unitSystem = UnitSystem.metric;

  UnitSystem get unitSystem => _unitSystem;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _unitSystem = UnitSystemStorage.fromStorage(prefs.getString('unit_system'));
    notifyListeners();
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    _unitSystem = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('unit_system', value.storageValue);
  }
}
```

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();

  final themeNotifier = ThemeNotifier();
  final unitSystemNotifier = UnitSystemNotifier();
  await Future.wait([themeNotifier.load(), unitSystemNotifier.load()]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider.value(value: unitSystemNotifier),
      ],
      child: const MyApp(),
    ),
  );
}
```

- [ ] **Step 4: Re-run the preference and conversion tests**

Run: `flutter test test/utils/unit_conversions_test.dart test/state/theme_notifier_test.dart test/state/unit_system_notifier_test.dart -r compact`
Expected: PASS for all three test files.

- [ ] **Step 5: Commit the foundation layer**

```bash
git add pubspec.yaml lib/main.dart lib/models/unit_system.dart lib/state/theme_notifier.dart lib/state/unit_system_notifier.dart lib/utils/unit_conversions.dart test/utils/unit_conversions_test.dart test/state/theme_notifier_test.dart test/state/unit_system_notifier_test.dart
git commit -m "feat: add redesign preferences foundation"
```

### Task 2: Theme System and Top-Level Shell

**Files:**
- Create: `lib/theme/app_colors.dart`
- Create: `lib/theme/app_typography.dart`
- Create: `lib/theme/app_theme.dart`
- Create: `lib/widgets/app_bottom_nav.dart`
- Create: `lib/screens/app_shell.dart`
- Modify: `lib/main.dart`
- Test: `test/widgets/app_bottom_nav_test.dart`

- [ ] **Step 1: Write the shell widget test**

```dart
// test/widgets/app_bottom_nav_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_tracker/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('bottom nav renders four destinations and center add action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: AppBottomNav(
            currentIndex: 1,
            onTap: (_) {},
            onAddPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the shell test to confirm the missing widget fails**

Run: `flutter test test/widgets/app_bottom_nav_test.dart -r compact`
Expected: FAIL with import errors for `AppBottomNav`.

- [ ] **Step 3: Build the theme files and shell scaffold**

```dart
// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const lightPrimary = Color(0xFF059669);
  static const darkPrimary = Color(0xFF10B981);
  static const lightAccent = Color(0xFFEA580C);
  static const darkAccent = Color(0xFFFB923C);
  static const protein = Color(0xFF3B82F6);
  static const fat = Color(0xFFEF4444);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF1E293B);
  static const lightBackground = Color(0xFFF0F9F6);
  static const darkBackground = Color(0xFF0F172A);
  static const lightBorder = Color(0xFFE5E7EB);
  static const darkBorder = Color(0xFF334155);
}
```

```dart
// lib/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.barlowCondensed(fontSize: 28, fontWeight: FontWeight.w900),
      headlineMedium: GoogleFonts.barlow(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w400),
      labelSmall: GoogleFonts.barlow(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.1),
    );
  }
}
```

```dart
// lib/widgets/app_bottom_nav.dart
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        children: [
          _NavItem(label: 'Home', icon: Icons.home_rounded, selected: currentIndex == 0, onTap: () => onTap(0)),
          _NavItem(label: 'Diary', icon: Icons.menu_book_rounded, selected: currentIndex == 1, onTap: () => onTap(1)),
          const Spacer(),
          _NavItem(label: 'History', icon: Icons.bar_chart_rounded, selected: currentIndex == 2, onTap: () => onTap(2)),
          _NavItem(label: 'Profile', icon: Icons.person_rounded, selected: currentIndex == 3, onTap: () => onTap(3)),
        ],
      ),
    );
  }
}
```

```dart
// lib/screens/app_shell.dart
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  DateTime _selectedDiaryDate = DateTime.now();

  Future<void> _openLogEntrySheet({String? mealSlot}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => LogEntryScreen(initialMealSlot: mealSlot),
    );
  }

  void _openDiaryDay(DateTime date) {
    setState(() {
      _selectedDiaryDate = date;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onViewFullDiary: () => setState(() => _currentIndex = 1)),
      DiaryScreen(selectedDate: _selectedDiaryDate),
      HistoryScreen(onOpenDay: _openDiaryDay),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _openLogEntrySheet,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onAddPressed: _openLogEntrySheet,
      ),
    );
  }
}
```

- [ ] **Step 4: Wire `MaterialApp` to the new theme and signed-in shell**

```dart
// lib/main.dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      title: 'Calorie Tracker',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeNotifier.themeMode,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return auth.currentUser != null ? const AppShell() : const AuthScreen();
  }
}
```

- [ ] **Step 5: Verify the shell test and commit**

Run: `flutter test test/widgets/app_bottom_nav_test.dart -r compact`
Expected: PASS.

```bash
git add lib/main.dart lib/theme/app_colors.dart lib/theme/app_typography.dart lib/theme/app_theme.dart lib/widgets/app_bottom_nav.dart lib/screens/app_shell.dart test/widgets/app_bottom_nav_test.dart
git commit -m "feat: add redesigned app shell"
```

### Task 3: Rebuild the Auth Screen

**Files:**
- Modify: `lib/screens/auth_screen.dart`
- Test: `test/widgets/auth_screen_test.dart`

- [ ] **Step 1: Write the auth layout test**

```dart
// test/widgets/auth_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:calorie_tracker/screens/auth_screen.dart';
import 'package:calorie_tracker/services/auth_service.dart';

void main() {
  testWidgets('auth screen shows hero, form, and social actions', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: AuthService(),
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    expect(find.text('Know what you eat. Own your goals.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the auth widget test**

Run: `flutter test test/widgets/auth_screen_test.dart -r compact`
Expected: FAIL because the old auth screen does not render the new copy/layout.

- [ ] **Step 3: Implement the redesigned auth screen without changing `AuthService` behavior**

```dart
// lib/screens/auth_screen.dart
return Scaffold(
  body: DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF059669), Color(0xFF065F46)],
      ),
    ),
    child: SafeArea(
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.spa_rounded, size: 72, color: Colors.white),
          const SizedBox(height: 16),
          Text('Calorie Tracker', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Know what you eat. Own your goals.', style: TextStyle(color: Colors.white70)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                TextField(decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                  ),
                )),
                if (!_isLogin) ...[
                  const SizedBox(height: 12),
                  TextField(decoration: const InputDecoration(labelText: 'Confirm Password')),
                ],
                const SizedBox(height: 20),
                FilledButton(onPressed: _submit, child: Text(_isLogin ? 'Sign In' : 'Create Account')),
                const SizedBox(height: 16),
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('or continue with')), Expanded(child: Divider())]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: auth.signInWithGoogle, icon: const Icon(Icons.g_mobiledata), label: const Text('Google'))),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton.icon(onPressed: auth.signInWithApple, icon: const Icon(Icons.apple), label: const Text('Apple'))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
```

- [ ] **Step 4: Re-run the auth widget test**

Run: `flutter test test/widgets/auth_screen_test.dart -r compact`
Expected: PASS.

- [ ] **Step 5: Commit the auth redesign**

```bash
git add lib/screens/auth_screen.dart test/widgets/auth_screen_test.dart
git commit -m "feat: redesign auth screen"
```

### Task 4: Shared Models, Home Widgets, and the New Home Screen

**Files:**
- Create: `lib/models/log_entry_record.dart`
- Create: `lib/models/daily_summary.dart`
- Create: `lib/widgets/calorie_ring.dart`
- Create: `lib/widgets/macro_bar.dart`
- Create: `lib/widgets/log_entry_tile.dart`
- Create: `lib/screens/home_screen.dart`
- Modify: `lib/services/calorie_service.dart`
- Test: `test/widgets/home_screen_widgets_test.dart`

- [ ] **Step 1: Write failing widget tests for the reusable summary pieces**

```dart
// test/widgets/home_screen_widgets_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_tracker/widgets/macro_bar.dart';
import 'package:calorie_tracker/widgets/log_entry_tile.dart';

void main() {
  testWidgets('MacroBar shows label and current/goal copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MacroBar(
            label: 'PROTEIN',
            current: 120,
            goal: 180,
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('PROTEIN'), findsOneWidget);
    expect(find.text('120 / 180 g'), findsOneWidget);
  });

  testWidgets('LogEntryTile renders delete affordance host content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LogEntryTile(
            title: 'Greek Yogurt',
            subtitle: 'P 18g · C 8g · F 4g',
            caloriesLabel: '220 cal',
          ),
        ),
      ),
    );

    expect(find.text('Greek Yogurt'), findsOneWidget);
    expect(find.text('220 cal'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the shared-widget tests**

Run: `flutter test test/widgets/home_screen_widgets_test.dart -r compact`
Expected: FAIL because the new models/widgets do not exist yet.

- [ ] **Step 3: Add normalized log models and summary widgets**

```dart
// lib/models/log_entry_record.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LogEntryRecord {
  const LogEntryRecord({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    required this.type,
    required this.mealSlot,
  });

  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;
  final String type;
  final String mealSlot;

  bool get isExercise => type == 'exercise';

  factory LogEntryRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final rawType = (data['type'] as String? ?? 'meal').toLowerCase();
    return LogEntryRecord(
      id: id,
      name: data['name'] as String? ?? 'Untitled',
      calories: (data['calories'] as num? ?? 0).toDouble(),
      protein: (data['protein'] as num? ?? 0).toDouble(),
      carbs: (data['carbs'] as num? ?? 0).toDouble(),
      fat: (data['fat'] as num? ?? 0).toDouble(),
      loggedAt: (data['timestamp'] as Timestamp).toDate(),
      type: rawType == 'food' ? 'meal' : rawType,
      mealSlot: (data['mealSlot'] as String? ?? 'lunch').toLowerCase(),
    );
  }
}
```

```dart
// lib/models/daily_summary.dart
class DailySummary {
  const DailySummary({
    required this.date,
    required this.goal,
    required this.eaten,
    required this.burned,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinGoal,
    required this.carbGoal,
    required this.fatGoal,
    required this.entries,
  });

  final DateTime date;
  final double goal;
  final double eaten;
  final double burned;
  final double protein;
  final double carbs;
  final double fat;
  final double proteinGoal;
  final double carbGoal;
  final double fatGoal;
  final List<LogEntryRecord> entries;

  double get remaining => goal - eaten + burned;
  double get net => eaten - burned;

  String get weekdayLabel => ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];
  String get netLabel => '${net <= 0 ? '-' : '+'}${net.abs().toStringAsFixed(0)}';

  factory DailySummary.empty(DateTime date) {
    return DailySummary(
      date: date,
      goal: 0,
      eaten: 0,
      burned: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      proteinGoal: 0,
      carbGoal: 0,
      fatGoal: 0,
      entries: const [],
    );
  }

  DailySummary copyWith({
    double? goal,
    double? eaten,
    double? burned,
    double? protein,
    double? carbs,
    double? fat,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    List<LogEntryRecord>? entries,
  }) {
    return DailySummary(
      date: date,
      goal: goal ?? this.goal,
      eaten: eaten ?? this.eaten,
      burned: burned ?? this.burned,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      entries: entries ?? this.entries,
    );
  }
}
```

```dart
// lib/widgets/macro_bar.dart
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  final String label;
  final double current;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            Text('${current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} g'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress, color: color, minHeight: 10),
      ],
    );
  }
}
```

```dart
// lib/widgets/log_entry_tile.dart
class LogEntryTile extends StatelessWidget {
  const LogEntryTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.caloriesLabel,
    this.backgroundColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String caloriesLabel;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        onTap: onTap,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(caloriesLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
```

- [ ] **Step 4: Replace `DashboardScreen` with the new Home screen backed by `CalorieService` summaries**

```dart
// lib/services/calorie_service.dart
Stream<DailySummary> watchDailySummary(String uid, DateTime day) {
  return watchEntriesForDay(uid, day).map((entries) {
    final eaten = entries.where((entry) => !entry.isExercise).fold<double>(0, (sum, entry) => sum + entry.calories);
    final burned = entries.where((entry) => entry.isExercise).fold<double>(0, (sum, entry) => sum + entry.calories);
    final protein = entries.where((entry) => !entry.isExercise).fold<double>(0, (sum, entry) => sum + entry.protein);
    final carbs = entries.where((entry) => !entry.isExercise).fold<double>(0, (sum, entry) => sum + entry.carbs);
    final fat = entries.where((entry) => !entry.isExercise).fold<double>(0, (sum, entry) => sum + entry.fat);

    return DailySummary.empty(day).copyWith(
      goal: 3260,
      eaten: eaten,
      burned: burned,
      protein: protein,
      carbs: carbs,
      fat: fat,
      proteinGoal: 180,
      carbGoal: 325,
      fatGoal: 80,
      entries: entries,
    );
  });
}
```

```dart
// lib/screens/home_screen.dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onViewFullDiary});

  final VoidCallback onViewFullDiary;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser!.uid;

    return StreamBuilder<DailySummary>(
      stream: CalorieService().watchDailySummary(uid, DateTime.now()),
      builder: (context, summarySnap) {
        final summary = summarySnap.data ?? DailySummary.empty(DateTime.now());

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.lightPrimary,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Friday, Apr 18 · Goal: ${summary.goal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text('Good morning, Edgar', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList.list(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CalorieRing(eaten: summary.eaten, burned: summary.burned, goal: summary.goal, size: 68),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Remaining ${summary.remaining.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium),
                                Text('Eaten ${summary.eaten.toStringAsFixed(0)}'),
                                Text('Burned ${summary.burned.toStringAsFixed(0)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  MacroBar(label: 'PROTEIN', current: summary.protein, goal: summary.proteinGoal, color: AppColors.protein),
                  const SizedBox(height: 12),
                  MacroBar(label: 'CARBS', current: summary.carbs, goal: summary.carbGoal, color: AppColors.lightAccent),
                  const SizedBox(height: 12),
                  MacroBar(label: 'FAT', current: summary.fat, goal: summary.fatGoal, color: AppColors.fat),
                  const SizedBox(height: 24),
                  TextButton(onPressed: onViewFullDiary, child: const Text('View full diary →')),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 5: Verify the shared widgets and commit**

Run: `flutter test test/widgets/home_screen_widgets_test.dart -r compact`
Expected: PASS.

```bash
git add lib/models/log_entry_record.dart lib/models/daily_summary.dart lib/widgets/calorie_ring.dart lib/widgets/macro_bar.dart lib/widgets/log_entry_tile.dart lib/screens/home_screen.dart lib/services/calorie_service.dart test/widgets/home_screen_widgets_test.dart
git commit -m "feat: add redesigned home screen"
```

### Task 5: Diary Grouping, Date Navigation, and Delete Flow

**Files:**
- Create: `lib/utils/log_grouping.dart`
- Create: `lib/screens/diary_screen.dart`
- Modify: `lib/services/calorie_service.dart`
- Modify: `lib/widgets/log_entry_tile.dart`
- Test: `test/utils/log_grouping_test.dart`

- [ ] **Step 1: Write the grouping test for meal sections and lunch fallback**

```dart
// test/utils/log_grouping_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_tracker/models/log_entry_record.dart';
import 'package:calorie_tracker/utils/log_grouping.dart';

void main() {
  test('groupDiaryEntries buckets meals and defaults missing slot to lunch', () {
    final entries = [
      LogEntryRecord(id: '1', name: 'Oats', calories: 300, protein: 10, carbs: 45, fat: 5, loggedAt: DateTime(2026, 4, 18, 8), type: 'meal', mealSlot: 'breakfast'),
      LogEntryRecord(id: '2', name: 'Trail Mix', calories: 200, protein: 6, carbs: 14, fat: 12, loggedAt: DateTime(2026, 4, 18, 15), type: 'meal', mealSlot: ''),
      LogEntryRecord(id: '3', name: 'Cycling', calories: 350, protein: 0, carbs: 0, fat: 0, loggedAt: DateTime(2026, 4, 18, 18), type: 'exercise', mealSlot: 'exercise'),
    ];

    final grouped = groupDiaryEntries(entries);

    expect(grouped['Breakfast']!.length, 1);
    expect(grouped['Lunch']!.length, 1);
    expect(grouped['Snacks']!, isEmpty);
    expect(grouped['Exercise']!.length, 1);
  });
}
```

- [ ] **Step 2: Run the grouping test**

Run: `flutter test test/utils/log_grouping_test.dart -r compact`
Expected: FAIL because the grouping helper does not exist.

- [ ] **Step 3: Implement grouping helpers and delete support**

```dart
// lib/utils/log_grouping.dart
import 'package:calorie_tracker/models/log_entry_record.dart';

Map<String, List<LogEntryRecord>> groupDiaryEntries(List<LogEntryRecord> entries) {
  final grouped = {
    'Breakfast': <LogEntryRecord>[],
    'Lunch': <LogEntryRecord>[],
    'Dinner': <LogEntryRecord>[],
    'Snacks': <LogEntryRecord>[],
    'Exercise': <LogEntryRecord>[],
  };

  for (final entry in entries) {
    if (entry.isExercise) {
      grouped['Exercise']!.add(entry);
      continue;
    }

    final slot = entry.mealSlot.isEmpty ? 'lunch' : entry.mealSlot;
    if (slot == 'breakfast') {
      grouped['Breakfast']!.add(entry);
    } else if (slot == 'dinner') {
      grouped['Dinner']!.add(entry);
    } else if (slot == 'snack') {
      grouped['Snacks']!.add(entry);
    } else {
      grouped['Lunch']!.add(entry);
    }
  }

  return grouped;
}
```

```dart
// lib/services/calorie_service.dart
Stream<List<LogEntryRecord>> watchEntriesForDay(String uid, DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));

  return _db
      .collection('logs')
      .where('uid', isEqualTo: uid)
      .where('timestamp', isGreaterThanOrEqualTo: start)
      .where('timestamp', isLessThan: end)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => LogEntryRecord.fromFirestore(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt)));
}

Future<void> deleteLogEntry(String id) {
  return _db.collection('logs').doc(id).delete();
}
```

- [ ] **Step 4: Build the diary screen with date strip, grouped sections, and confirmed delete**

```dart
// lib/screens/diary_screen.dart
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key, required this.selectedDate});

  final DateTime selectedDate;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  late DateTime _selectedDate = widget.selectedDate;

  @override
  void didUpdateWidget(covariant DiaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _selectedDate = widget.selectedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;

    return StreamBuilder<List<LogEntryRecord>>(
      stream: CalorieService().watchEntriesForDay(uid, _selectedDate),
      builder: (context, snapshot) {
        final grouped = groupDiaryEntries(snapshot.data ?? const []);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.lightPrimary,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  children: [
                    Text('Diary', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_month, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList.list(
                children: grouped.entries.map((section) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(section.key.toUpperCase(), style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          TextButton(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => LogEntryScreen(initialMealSlot: section.key.toLowerCase()),
                            ),
                            child: const Text('+ Add'),
                          ),
                        ],
                      ),
                      if (section.value.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text('Tap + Add to log ${section.key.toLowerCase()}'),
                        )
                      else
                        ...section.value.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LogEntryTile(
                                title: entry.name,
                                subtitle: 'P ${entry.protein.toStringAsFixed(0)}g · C ${entry.carbs.toStringAsFixed(0)}g · F ${entry.fat.toStringAsFixed(0)}g',
                                caloriesLabel: entry.isExercise ? '-${entry.calories.toStringAsFixed(0)} cal' : '${entry.calories.toStringAsFixed(0)} cal',
                                backgroundColor: entry.isExercise ? const Color(0xFFECFDF5) : null,
                                onTap: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete entry?'),
                                      content: Text('Remove ${entry.name} from your diary?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await CalorieService().deleteLogEntry(entry.id);
                                  }
                                },
                              ),
                            )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 5: Verify grouping and commit**

Run: `flutter test test/utils/log_grouping_test.dart -r compact`
Expected: PASS.

```bash
git add lib/utils/log_grouping.dart lib/screens/diary_screen.dart lib/services/calorie_service.dart lib/widgets/log_entry_tile.dart test/utils/log_grouping_test.dart
git commit -m "feat: add diary redesign"
```

### Task 6: Bottom-Sheet Log Entry Flow and Food Database Integration

**Files:**
- Modify: `lib/screens/log_entry_screen.dart`
- Modify: `lib/screens/food_database_screen.dart`
- Modify: `lib/services/food_service.dart`
- Test: `test/widgets/log_entry_screen_test.dart`

- [ ] **Step 1: Write the bottom-sheet flow test**

```dart
// test/widgets/log_entry_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_tracker/screens/log_entry_screen.dart';

void main() {
  testWidgets('log entry screen starts in food mode and exposes exercise toggle', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LogEntryScreen(initialMealSlot: 'breakfast'))));

    expect(find.text('Log Food or Exercise'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Exercise'), findsOneWidget);
    expect(find.text('Search food or scan barcode…'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the log-entry widget test**

Run: `flutter test test/widgets/log_entry_screen_test.dart -r compact`
Expected: FAIL because the current screen is a full page with the old layout and copy.

- [ ] **Step 3: Extend the food service for reusable quantity scaling and exercise search**

```dart
// lib/services/food_service.dart
class ExerciseItem {
  const ExerciseItem({
    required this.name,
    required this.durationMinutes,
    required this.caloriesBurned,
  });

  final String name;
  final int durationMinutes;
  final double caloriesBurned;
}

extension FoodItemScaling on FoodItem {
  FoodItem scaledTo(double grams) {
    final ratio = servingSize == 0 ? 0.0 : grams / servingSize;
    return FoodItem(
      name: name,
      calories: calories * ratio,
      protein: protein * ratio,
      carbs: carbs * ratio,
      fat: fat * ratio,
      servingSize: grams,
    );
  }
}

Future<List<ExerciseItem>> searchExercises(String query) async {
  final response = await http.get(
    Uri.parse('https://api.calorieninjas.com/v1/exercises?query=${Uri.encodeComponent(query)}'),
    headers: {'X-Api-Key': _apiKey},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to fetch exercise data');
  }

  final data = json.decode(response.body) as Map<String, dynamic>;
  final items = data['items'] as List<dynamic>;
  return items.map((item) {
    final duration = (item['duration_minutes'] as num).round();
    final caloriesPerHour = (item['calories_per_hour'] as num).toDouble();
    return ExerciseItem(
      name: item['name'] as String,
      durationMinutes: duration,
      caloriesBurned: caloriesPerHour * (duration / 60),
    );
  }).toList();
}
```

- [ ] **Step 4: Rebuild the log-entry screen as a modal-friendly flow**

```dart
// lib/screens/log_entry_screen.dart
class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({
    super.key,
    this.initialMealSlot,
  });

  final String? initialMealSlot;

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  String _mode = 'food';
  String _mealSlot = 'lunch';

  @override
  void initState() {
    super.initState();
    _mealSlot = switch (widget.initialMealSlot) {
      'breakfast' => 'breakfast',
      'dinner' => 'dinner',
      'snacks' => 'snack',
      'snack' => 'snack',
      _ => 'lunch',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 20),
            const Text('Log Food or Exercise'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'food', label: Text('Food')),
                ButtonSegment(value: 'exercise', label: Text('Exercise')),
              ],
              selected: {_mode},
              onSelectionChanged: (value) => setState(() => _mode = value.first),
            ),
            if (_mode == 'food') _FoodSearchPane(mealSlot: _mealSlot) else const _ExerciseSearchPane(),
          ],
        ),
      ),
    );
  }
}
```

```dart
// save payload in food mode
await FirebaseFirestore.instance.collection('logs').add({
  'uid': user.uid,
  'email': user.email,
  'name': scaledFood.name,
  'calories': scaledFood.calories,
  'protein': scaledFood.protein,
  'carbs': scaledFood.carbs,
  'fat': scaledFood.fat,
  'grams': scaledFood.servingSize,
  'type': 'meal',
  'mealSlot': _mealSlot,
  'timestamp': DateTime.now(),
});
```

- [ ] **Step 5: Verify the new flow and commit**

Run: `flutter test test/widgets/log_entry_screen_test.dart -r compact`
Expected: PASS.

```bash
git add lib/screens/log_entry_screen.dart lib/screens/food_database_screen.dart lib/services/food_service.dart test/widgets/log_entry_screen_test.dart
git commit -m "feat: rebuild log entry flow"
```

### Task 7: History Analytics Redesign

**Files:**
- Modify: `lib/services/calorie_service.dart`
- Modify: `lib/screens/history_screen.dart`
- Test: `test/utils/log_grouping_test.dart`

- [ ] **Step 1: Add the failing history aggregate test beside the grouping helpers**

```dart
// append to test/utils/log_grouping_test.dart
test('buildWeeklyHistory produces averages and deficit counts', () {
  final result = buildWeeklyHistory([
    DailySummary.empty(DateTime(2026, 4, 12)).copyWith(goal: 2200, eaten: 2000, burned: 200),
    DailySummary.empty(DateTime(2026, 4, 13)).copyWith(goal: 2200, eaten: 2600, burned: 100),
  ]);

  expect(result.avgDailyCalories, 2300);
  expect(result.deficitDays, 1);
  expect(result.surplusDays, 1);
});
```

- [ ] **Step 2: Run the helper test**

Run: `flutter test test/utils/log_grouping_test.dart -r compact`
Expected: FAIL because the weekly summary helper does not exist yet.

- [ ] **Step 3: Implement weekly summary support in the service/helper layer**

```dart
// lib/utils/log_grouping.dart
class WeeklyHistory {
  const WeeklyHistory({
    required this.avgDailyCalories,
    required this.deficitDays,
    required this.surplusDays,
  });

  final int avgDailyCalories;
  final int deficitDays;
  final int surplusDays;
}

List<DailySummary> buildDailySummaries(DateTime anchor, List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
  final byDay = <DateTime, List<LogEntryRecord>>{};
  for (var offset = 6; offset >= 0; offset -= 1) {
    final date = DateTime(anchor.year, anchor.month, anchor.day).subtract(Duration(days: offset));
    byDay[date] = [];
  }

  for (final doc in docs) {
    final entry = LogEntryRecord.fromFirestore(doc.id, doc.data());
    final bucket = DateTime(entry.loggedAt.year, entry.loggedAt.month, entry.loggedAt.day);
    byDay[bucket]?.add(entry);
  }

  return byDay.entries.map((entry) {
    final records = entry.value;
    final eaten = records.where((item) => !item.isExercise).fold<double>(0, (sum, item) => sum + item.calories);
    final burned = records.where((item) => item.isExercise).fold<double>(0, (sum, item) => sum + item.calories);
    return DailySummary.empty(entry.key).copyWith(eaten: eaten, burned: burned, entries: records);
  }).toList();
}

WeeklyHistory buildWeeklyHistory(List<DailySummary> days) {
  if (days.isEmpty) {
    return const WeeklyHistory(avgDailyCalories: 0, deficitDays: 0, surplusDays: 0);
  }

  final average = days.fold<double>(0, (sum, day) => sum + day.eaten) / days.length;
  final deficitDays = days.where((day) => day.net <= 0).length;
  final surplusDays = days.where((day) => day.net > 0).length;

  return WeeklyHistory(
    avgDailyCalories: average.round(),
    deficitDays: deficitDays,
    surplusDays: surplusDays,
  );
}
```

```dart
// lib/services/calorie_service.dart
Stream<List<DailySummary>> watchLast7Days(String uid, DateTime anchor) {
  final start = DateTime(anchor.year, anchor.month, anchor.day).subtract(const Duration(days: 6));
  final end = DateTime(anchor.year, anchor.month, anchor.day).add(const Duration(days: 1));

  return _db
      .collection('logs')
      .where('uid', isEqualTo: uid)
      .where('timestamp', isGreaterThanOrEqualTo: start)
      .where('timestamp', isLessThan: end)
      .snapshots()
      .map((snap) => buildDailySummaries(anchor, snap.docs));
}
```

```dart
// lib/screens/history_screen.dart
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.onOpenDay});

  final ValueChanged<DateTime> onOpenDay;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;

    return StreamBuilder<List<DailySummary>>(
      stream: CalorieService().watchLast7Days(uid, DateTime.now()),
      builder: (context, snapshot) {
        final days = snapshot.data ?? [];
        final weekly = buildWeeklyHistory(days);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.lightPrimary,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('History', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('Last 7 days', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: BarChart(
                  BarChartData(
                    barGroups: List.generate(days.length, (index) {
                      final day = days[index];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(toY: day.eaten, color: AppColors.lightPrimary),
                          BarChartRodData(toY: day.burned, color: AppColors.lightAccent),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Avg ${weekly.avgDailyCalories}')))),
                    Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Deficit ${weekly.deficitDays}')))),
                    Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Surplus ${weekly.surplusDays}')))),
                  ],
                ),
              ),
            ),
            SliverList.list(
              children: days.map((day) => ListTile(
                title: Text(day.weekdayLabel),
                trailing: Text(day.netLabel, style: TextStyle(color: day.net <= 0 ? Colors.green : Colors.red)),
                onTap: () => onOpenDay(day.date),
              )).toList(),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 4: Re-run the helper test**

Run: `flutter test test/utils/log_grouping_test.dart -r compact`
Expected: PASS with the new weekly history helper.

- [ ] **Step 5: Commit the history rebuild**

```bash
git add lib/services/calorie_service.dart lib/screens/history_screen.dart test/utils/log_grouping_test.dart
git commit -m "feat: redesign history screen"
```

### Task 8: Profile View, Edit Route, Theme Toggle, and Reminders

**Files:**
- Modify: `lib/screens/profile_screen.dart`
- Create: `lib/screens/profile_edit_screen.dart`
- Modify: `lib/services/calorie_service.dart`
- Modify: `lib/services/notification_service.dart`
- Test: `test/widgets/profile_edit_screen_test.dart`

- [ ] **Step 1: Write the profile edit test**

```dart
// test/widgets/profile_edit_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_tracker/models/unit_system.dart';
import 'package:calorie_tracker/screens/profile_edit_screen.dart';
import 'package:calorie_tracker/state/unit_system_notifier.dart';

void main() {
  testWidgets('profile edit screen switches between metric and imperial inputs', (tester) async {
    SharedPreferences.setMockInitialValues({'unit_system': 'metric'});
    final unitNotifier = UnitSystemNotifier();
    await unitNotifier.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: unitNotifier,
        child: const MaterialApp(home: ProfileEditScreen()),
      ),
    );

    expect(find.text('kg'), findsOneWidget);
    await tester.tap(find.text('Imperial'));
    await tester.pumpAndSettle();
    expect(find.text('lbs'), findsOneWidget);
    expect(find.text('ft'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the profile edit test**

Run: `flutter test test/widgets/profile_edit_screen_test.dart -r compact`
Expected: FAIL because the edit route does not exist yet.

- [ ] **Step 3: Add streak support and the dedicated edit screen**

```dart
// lib/services/calorie_service.dart
Future<int> loadLoggingStreak(String uid) async {
  var streak = 0;
  var cursor = DateTime.now();

  while (true) {
    final entries = await watchEntriesForDay(uid, cursor).first;
    if (entries.isEmpty) break;
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}
```

```dart
// lib/screens/profile_edit_screen.dart
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('profiles').doc(uid).set({
      'weight': _resolvedWeightKg,
      'height': _resolvedHeightCm,
      'age': int.parse(_ageController.text),
      'gender': _gender,
      'bmr': _calculatedBmr,
    }, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final unitSystem = context.watch<UnitSystemNotifier>().unitSystem;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<UnitSystem>(
            segments: const [
              ButtonSegment(value: UnitSystem.metric, label: Text('Metric')),
              ButtonSegment(value: UnitSystem.imperial, label: Text('Imperial')),
            ],
            selected: {unitSystem},
            onSelectionChanged: (value) => context.read<UnitSystemNotifier>().setUnitSystem(value.first),
          ),
          if (unitSystem == UnitSystem.metric) ...[
            _MetricFields(),
          ] else ...[
            _ImperialFields(),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Fold settings into the profile screen**

```dart
// lib/screens/profile_screen.dart
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeNotifier>().themeMode;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('profiles').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final remindersEnabled = data['remindersEnabled'] as bool? ?? false;
        final reminderTime = data['reminderTime'] as String? ?? '12:00';

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.lightPrimary,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['displayName'] as String? ?? 'Your Profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                    Text(data['email'] as String? ?? '', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList.list(
                children: [
                  Card(
                    child: ListTile(
                      title: Text('Cal goal ${(data['calorieGoal'] ?? 0)}'),
                      subtitle: Text('Protein goal ${(data['recommendedProtein'] ?? 0)} · Streak ${(data['streak'] ?? 0)}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Body Stats'),
                    trailing: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
                      child: const Text('Edit ›'),
                    ),
                  ),
                  ListTile(title: const Text('Weight'), trailing: Text('${data['weight'] ?? '--'}')),
                  ListTile(title: const Text('Height'), trailing: Text('${data['height'] ?? '--'}')),
                  ListTile(title: const Text('Age'), trailing: Text('${data['age'] ?? '--'}')),
                  ListTile(title: const Text('Gender'), trailing: Text('${data['gender'] ?? '--'}')),
                  SwitchListTile(
                    value: remindersEnabled,
                    onChanged: (value) async {
                      final parts = reminderTime.split(':');
                      if (value) {
                        await NotificationService().scheduleDaily(int.parse(parts[0]), int.parse(parts[1]), "Don't forget to log your meals today!");
                      } else {
                        await NotificationService().cancelAll();
                      }
                      await FirebaseFirestore.instance.collection('profiles').doc(uid).set({
                        'remindersEnabled': value,
                        'reminderTime': reminderTime,
                      }, SetOptions(merge: true));
                    },
                    title: const Text('Daily reminder'),
                  ),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('System')),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (value) => context.read<ThemeNotifier>().setThemeMode(value.first),
                  ),
                  ListTile(
                    title: const Text('Sign out', style: TextStyle(color: Colors.red)),
                    onTap: () => _confirmSignOut(context),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 5: Verify the edit route and commit**

Run: `flutter test test/widgets/profile_edit_screen_test.dart -r compact`
Expected: PASS.

```bash
git add lib/screens/profile_screen.dart lib/screens/profile_edit_screen.dart lib/services/calorie_service.dart lib/services/notification_service.dart test/widgets/profile_edit_screen_test.dart
git commit -m "feat: redesign profile and settings"
```

### Task 9: Cleanup, Smoke Tests, and Final Verification

**Files:**
- Delete: `lib/screens/settings_screen.dart`
- Delete: `lib/screens/dashboard_screen.dart`
- Modify: `test/widget_test.dart`
- Modify: `lib/screens/app_shell.dart`
- Modify: any touched imports after the file deletions

- [ ] **Step 1: Replace the default smoke test with an app-shell smoke test**

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calorie_tracker/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('app shell navigation keeps the redesigned tabs visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Placeholder(),
          bottomNavigationBar: AppBottomNav(
            currentIndex: 0,
            onTap: (_) {},
            onAddPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Remove obsolete screens and import references**

```dart
// lib/screens/app_shell.dart
final screens = [
  HomeScreen(onViewFullDiary: () => setState(() => _currentIndex = 1)),
  DiaryScreen(selectedDate: _selectedDiaryDate),
  HistoryScreen(onOpenDay: _openDiaryDay),
  const ProfileScreen(),
];
```

```text
Delete these files:
- lib/screens/settings_screen.dart
- lib/screens/dashboard_screen.dart
```

- [ ] **Step 3: Run the targeted verification suite**

Run: `flutter test test/utils/unit_conversions_test.dart test/utils/log_grouping_test.dart test/state/theme_notifier_test.dart test/state/unit_system_notifier_test.dart test/widgets/app_bottom_nav_test.dart test/widgets/auth_screen_test.dart test/widgets/home_screen_widgets_test.dart test/widgets/log_entry_screen_test.dart test/widgets/profile_edit_screen_test.dart test/widget_test.dart -r compact`
Expected: PASS across the redesign test suite.

- [ ] **Step 4: Run analyzer and a manual sanity check**

Run: `flutter analyze`
Expected: PASS with no errors.

Run: `flutter run`
Expected: App boots, auth screen appears for signed-out users, signed-in users see Home/Diary/History/Profile tabs, center FAB opens the modal log-entry sheet, theme mode persists after restart, and deleting a diary item requires confirmation.

- [ ] **Step 5: Commit the cleanup pass**

```bash
git add lib/screens/app_shell.dart lib/screens/home_screen.dart lib/screens/diary_screen.dart lib/screens/history_screen.dart lib/screens/profile_screen.dart lib/screens/profile_edit_screen.dart lib/screens/log_entry_screen.dart lib/screens/food_database_screen.dart lib/services/calorie_service.dart lib/services/food_service.dart lib/widgets/app_bottom_nav.dart lib/widgets/calorie_ring.dart lib/widgets/macro_bar.dart lib/widgets/log_entry_tile.dart test/widget_test.dart
git add -u lib/screens/settings_screen.dart lib/screens/dashboard_screen.dart
git commit -m "chore: finalize redesigned app flow"
```
