import 'package:calorie_tracker/models/unit_system.dart';
import 'package:calorie_tracker/services/auth_service.dart';
import 'package:calorie_tracker/services/calorie_service.dart';
import 'package:calorie_tracker/state/theme_notifier.dart';
import 'package:calorie_tracker/state/unit_system_notifier.dart';
import 'package:calorie_tracker/theme/app_colors.dart';
import 'package:calorie_tracker/utils/unit_conversions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Profile view screen
// ---------------------------------------------------------------------------

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser!.uid;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<_ProfileData>(
      future: _loadProfile(uid),
      builder: (context, snap) {
        final data = snap.data;
        return _ProfileView(uid: uid, data: data, textTheme: textTheme);
      },
    );
  }

  static Future<_ProfileData> _loadProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .get();
    final streak = await CalorieService().getStreak(uid);
    final d = doc.data() ?? {};
    return _ProfileData(
      weight: (d['weight'] as num?)?.toDouble() ?? 0,
      heightCm: (d['height'] as num?)?.toDouble() ?? 0,
      age: (d['age'] as num?)?.toInt() ?? 0,
      gender: d['gender'] as String? ?? 'male',
      calorieGoal: (d['calorieGoal'] as num?)?.toDouble() ?? 3260,
      proteinGoal: (d['proteinGoal'] as num?)?.toDouble() ?? 180,
      streak: streak,
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView(
      {required this.uid, required this.data, required this.textTheme});

  final String uid;
  final _ProfileData? data;
  final TextTheme textTheme;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late _ProfileData? _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  @override
  void didUpdateWidget(_ProfileView old) {
    super.didUpdateWidget(old);
    if (widget.data != null) _data = widget.data;
  }

  Future<void> _editGoal(BuildContext context, String label, double current,
      Function(double) onSave) async {
    final ctrl = TextEditingController(text: current.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration:
              InputDecoration(labelText: label, suffixText: 'kcal'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.trim());
                if (v != null) Navigator.pop(ctx, v);
              },
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      await onSave(result);
      setState(() {
        _data = _data?.copyWith(
          calorieGoal: label.contains('Calorie') ? result : null,
          proteinGoal: label.contains('Protein') ? result : null,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final themeNotifier = context.watch<ThemeNotifier>();
    final colorScheme = Theme.of(context).colorScheme;
    final data = _data;
    final user = auth.currentUser;
    final displayName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? '';
    final initials = displayName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Column(
      children: [
        // Green header
        Container(
          color: AppColors.lightPrimary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      initials,
                      style: widget.textTheme.headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: widget.textTheme.titleMedium
                                ?.copyWith(color: Colors.white)),
                        Text(email,
                            style: widget.textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // Stats card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'Cal Goal',
                        value: data != null
                            ? '${data.calorieGoal.toStringAsFixed(0)}'
                            : '--',
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'Protein',
                        value: data != null
                            ? '${data.proteinGoal.toStringAsFixed(0)}g'
                            : '--',
                        color: AppColors.protein,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'Streak',
                        value: data != null ? '${data.streak}' : '--',
                        color: AppColors.lightAccent,
                        suffix: ' days',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Body Stats
              _SectionHeader(
                title: 'Body Stats',
                action: TextButton(
                  onPressed: data == null
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _ProfileEditScreen(
                                  uid: widget.uid, data: data),
                            ),
                          );
                          if (context.mounted) setState(() => _data = null);
                          // Re-fetch after edit
                          final fresh = await ProfileScreen._loadProfile(
                              widget.uid);
                          if (context.mounted) {
                            setState(() => _data = fresh);
                          }
                        },
                  child: const Text('Edit \u203a'),
                ),
              ),
              const SizedBox(height: 8),
              if (data == null)
                const Center(child: CircularProgressIndicator())
              else
                _BodyStatsCard(data: data),
              const SizedBox(height: 24),
              // Goals
              const _SectionHeader(title: 'Goals'),
              const SizedBox(height: 8),
              _GoalRow(
                label: 'Calorie goal',
                value: data != null
                    ? '${data.calorieGoal.toStringAsFixed(0)} kcal'
                    : '--',
                onTap: data == null
                    ? null
                    : () => _editGoal(
                          context,
                          'Calorie goal',
                          data.calorieGoal,
                          (v) => FirebaseFirestore.instance
                              .collection('profiles')
                              .doc(widget.uid)
                              .set({'calorieGoal': v},
                                  SetOptions(merge: true)),
                        ),
              ),
              _GoalRow(
                label: 'Protein goal',
                value: data != null
                    ? '${data.proteinGoal.toStringAsFixed(0)} g'
                    : '--',
                onTap: data == null
                    ? null
                    : () => _editGoal(
                          context,
                          'Protein goal',
                          data.proteinGoal,
                          (v) => FirebaseFirestore.instance
                              .collection('profiles')
                              .doc(widget.uid)
                              .set({'proteinGoal': v},
                                  SetOptions(merge: true)),
                        ),
              ),
              const SizedBox(height: 24),
              // Settings
              const _SectionHeader(title: 'Settings'),
              const SizedBox(height: 8),
              // Dark mode
              _SettingsRow(
                label: 'Appearance',
                trailing: DropdownButton<ThemeMode>(
                  value: themeNotifier.themeMode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(
                        value: ThemeMode.dark, child: Text('Dark')),
                  ],
                  onChanged: (m) {
                    if (m != null) themeNotifier.setThemeMode(m);
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Sign out
              TextButton(
                onPressed: () => _confirmSignOut(context, auth),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.fat,
                  minimumSize: const Size.fromHeight(48),
                  alignment: Alignment.centerLeft,
                ),
                child: const Text('Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(
      BuildContext context, AuthService auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the sign in screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) await auth.signOut();
  }
}

// ---------------------------------------------------------------------------
// Profile edit screen (pushed)
// ---------------------------------------------------------------------------

class _ProfileEditScreen extends StatefulWidget {
  const _ProfileEditScreen({required this.uid, required this.data});

  final String uid;
  final _ProfileData data;

  @override
  State<_ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<_ProfileEditScreen> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _feetCtrl;
  late final TextEditingController _inchesCtrl;
  late final TextEditingController _heightCmCtrl;
  late final TextEditingController _ageCtrl;
  late String _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _gender = d.gender;
    _ageCtrl = TextEditingController(text: d.age > 0 ? '${d.age}' : '');

    final (ft, inch) = metersToFeetInches(d.heightCm / 100);
    _feetCtrl = TextEditingController(text: '$ft');
    _inchesCtrl = TextEditingController(text: '$inch');
    _heightCmCtrl =
        TextEditingController(text: d.heightCm > 0 ? d.heightCm.toStringAsFixed(0) : '');

    _weightCtrl =
        TextEditingController(text: d.weight > 0 ? d.weight.toStringAsFixed(1) : '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _feetCtrl.dispose();
    _inchesCtrl.dispose();
    _heightCmCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _onUnitToggle(UnitSystem newUnit, UnitSystem old) {
    if (newUnit == old) return;
    if (newUnit == UnitSystem.imperial) {
      // metric → imperial
      final kg = double.tryParse(_weightCtrl.text) ?? 0;
      _weightCtrl.text = roundPounds(kgToLbs(kg)).toString();
      final cm = double.tryParse(_heightCmCtrl.text) ?? 0;
      final (ft, inch) = metersToFeetInches(cm / 100);
      _feetCtrl.text = '$ft';
      _inchesCtrl.text = '$inch';
    } else {
      // imperial → metric
      final lbs = double.tryParse(_weightCtrl.text) ?? 0;
      _weightCtrl.text = roundKilograms(lbsToKg(lbs)).toString();
      final ft = int.tryParse(_feetCtrl.text) ?? 0;
      final inch = int.tryParse(_inchesCtrl.text) ?? 0;
      final cm = feetInchesToMeters(ft, inch) * 100;
      _heightCmCtrl.text = cm.toStringAsFixed(0);
    }
  }

  double _weightKg(UnitSystem unit) {
    final v = double.tryParse(_weightCtrl.text) ?? 0;
    return unit == UnitSystem.imperial ? lbsToKg(v) : v;
  }

  double _heightCm(UnitSystem unit) {
    if (unit == UnitSystem.imperial) {
      final ft = int.tryParse(_feetCtrl.text) ?? 0;
      final inch = int.tryParse(_inchesCtrl.text) ?? 0;
      return feetInchesToMeters(ft, inch) * 100;
    }
    return double.tryParse(_heightCmCtrl.text) ?? 0;
  }

  Future<void> _save(UnitSystem unit) async {
    final age = int.tryParse(_ageCtrl.text.trim());
    final wkg = _weightKg(unit);
    final hcm = _heightCm(unit);

    if (wkg <= 0 || hcm <= 0 || age == null || age <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in all fields')));
      return;
    }

    double bmr;
    if (_gender == 'male') {
      bmr = (10 * wkg) + (6.25 * hcm) - (5 * age) + 5;
    } else {
      bmr = (10 * wkg) + (6.25 * hcm) - (5 * age) - 161;
    }

    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('profiles')
        .doc(widget.uid)
        .set({
      'weight': wkg,
      'height': hcm,
      'age': age,
      'gender': _gender,
      'bmr': bmr,
      'recommendedProtein': wkg * 2.2,
    }, SetOptions(merge: true));

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final unitNotifier = context.watch<UnitSystemNotifier>();
    final unit = unitNotifier.unitSystem;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        leadingWidth: 72,
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _save(unit),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Unit toggle
          Row(
            children: [
              Text('Units', style: textTheme.titleMedium),
              const Spacer(),
              SegmentedButton<UnitSystem>(
                segments: const [
                  ButtonSegment(
                      value: UnitSystem.metric, label: Text('Metric')),
                  ButtonSegment(
                      value: UnitSystem.imperial,
                      label: Text('Imperial')),
                ],
                selected: {unit},
                onSelectionChanged: (v) {
                  final newUnit = v.first;
                  _onUnitToggle(newUnit, unit);
                  unitNotifier.setUnitSystem(newUnit);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gender
          Text('Gender', style: textTheme.labelSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'male', label: Text('Male')),
              ButtonSegment(value: 'female', label: Text('Female')),
            ],
            selected: {_gender},
            onSelectionChanged: (v) => setState(() => _gender = v.first),
          ),
          const SizedBox(height: 20),
          // Weight
          TextField(
            controller: _weightCtrl,
            decoration: InputDecoration(
              labelText: 'Weight',
              suffixText: unit == UnitSystem.metric ? 'kg' : 'lbs',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          // Height
          if (unit == UnitSystem.metric)
            TextField(
              controller: _heightCmCtrl,
              decoration: const InputDecoration(
                labelText: 'Height',
                suffixText: 'cm',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feetCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Height (ft)',
                      suffixText: 'ft',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _inchesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Inches',
                      suffixText: 'in',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Age
          TextField(
            controller: _ageCtrl,
            decoration: const InputDecoration(
              labelText: 'Age',
              suffixText: 'years',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label,
      required this.value,
      required this.color,
      this.suffix = ''});

  final String label;
  final String value;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55))),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              text: value,
              style: textTheme.displayLarge?.copyWith(color: color),
              children: suffix.isNotEmpty
                  ? [
                      TextSpan(
                          text: suffix,
                          style: textTheme.labelSmall
                              ?.copyWith(color: color))
                    ]
                  : [],
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyStatsCard extends StatelessWidget {
  const _BodyStatsCard({required this.data});

  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    final unit =
        context.read<UnitSystemNotifier>().unitSystem;
    final isImperial = unit == UnitSystem.imperial;

    final weightLabel = isImperial
        ? '${roundPounds(kgToLbs(data.weight))} lbs'
        : '${data.weight.toStringAsFixed(1)} kg';

    String heightLabel;
    if (isImperial) {
      final (ft, inch) = metersToFeetInches(data.heightCm / 100);
      heightLabel = '$ft\' $inch"';
    } else {
      heightLabel = '${data.heightCm.toStringAsFixed(0)} cm';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _BodyRow(label: 'Weight', value: data.weight > 0 ? weightLabel : '--'),
            _BodyRow(label: 'Height', value: data.heightCm > 0 ? heightLabel : '--'),
            _BodyRow(label: 'Age', value: data.age > 0 ? '${data.age} yrs' : '--'),
            _BodyRow(
                label: 'Gender',
                value: data.gender.isEmpty
                    ? '--'
                    : data.gender[0].toUpperCase() + data.gender.substring(1),
                isLast: true),
          ],
        ),
      ),
    );
  }
}

class _BodyRow extends StatelessWidget {
  const _BodyRow(
      {required this.label, required this.value, this.isLast = false});

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(label,
                  style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6))),
              const Spacer(),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.08)),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow(
      {required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Text(label, style: textTheme.bodyMedium),
            const Spacer(),
            Text(value,
                style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55))),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                size: 18,
                color: colorScheme.onSurface.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label, style: textTheme.bodyMedium),
        const Spacer(),
        trailing,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _ProfileData {
  const _ProfileData({
    required this.weight,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.calorieGoal,
    required this.proteinGoal,
    required this.streak,
  });

  final double weight;
  final double heightCm;
  final int age;
  final String gender;
  final double calorieGoal;
  final double proteinGoal;
  final int streak;

  _ProfileData copyWith({
    double? calorieGoal,
    double? proteinGoal,
  }) {
    return _ProfileData(
      weight: weight,
      heightCm: heightCm,
      age: age,
      gender: gender,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      streak: streak,
    );
  }
}
