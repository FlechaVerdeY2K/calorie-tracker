import 'package:calorie_tracker/services/auth_service.dart';
import 'package:calorie_tracker/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/food_service.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key, this.initialMealSlot = 'lunch'});

  final String initialMealSlot;

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final _searchController = TextEditingController();
  final _gramsController = TextEditingController();
  final _manualCaloriesController = TextEditingController();
  final _exerciseNameController = TextEditingController();
  final _exerciseCaloriesController = TextEditingController();
  final _foodService = FoodService();

  late String _mealSlot;
  String _mode = 'food';
  bool _searching = false;
  bool _saving = false;
  List<FoodItem> _results = [];
  FoodItem? _selected;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;

  static const _mealSlots = ['breakfast', 'lunch', 'dinner', 'snack'];

  @override
  void initState() {
    super.initState();
    _mealSlot = widget.initialMealSlot;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _gramsController.dispose();
    _manualCaloriesController.dispose();
    _exerciseNameController.dispose();
    _exerciseCaloriesController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await _foodService.search(q);
      setState(() => _results = results);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Search failed')));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _select(FoodItem item) {
    setState(() {
      _selected = item;
      _gramsController.text = item.servingSize.toStringAsFixed(0);
      _manualCaloriesController.text = item.calories.toStringAsFixed(0);
      _protein = item.protein;
      _carbs = item.carbs;
      _fat = item.fat;
      _results = [];
      _searchController.clear();
    });
  }

  void _onGramsChanged(String value) {
    if (_selected == null) return;
    final grams = double.tryParse(value);
    if (grams == null || grams <= 0) return;
    final ratio = grams / _selected!.servingSize;
    setState(() {
      _manualCaloriesController.text =
          (_selected!.calories * ratio).toStringAsFixed(0);
      _protein = _selected!.protein * ratio;
      _carbs = _selected!.carbs * ratio;
      _fat = _selected!.fat * ratio;
    });
  }

  Future<void> _saveFood() async {
    final name = _selected?.name ?? _searchController.text.trim();
    final calories = double.tryParse(_manualCaloriesController.text.trim());
    if (name.isEmpty || calories == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a food first')));
      return;
    }
    setState(() => _saving = true);
    final uid = context.read<AuthService>().currentUser!.uid;
    await FirebaseFirestore.instance.collection('logs').add({
      'uid': uid,
      'name': name,
      'calories': calories,
      'protein': _protein,
      'carbs': _carbs,
      'fat': _fat,
      'grams': double.tryParse(_gramsController.text) ?? 0,
      'type': 'meal',
      'mealSlot': _mealSlot,
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveExercise() async {
    final name = _exerciseNameController.text.trim();
    final calories = double.tryParse(_exerciseCaloriesController.text.trim());
    if (name.isEmpty || calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fill in exercise name and calories')));
      return;
    }
    setState(() => _saving = true);
    final uid = context.read<AuthService>().currentUser!.uid;
    await FirebaseFirestore.instance.collection('logs').add({
      'uid': uid,
      'name': name,
      'calories': calories,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'type': 'exercise',
      'mealSlot': 'exercise',
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text('Log Food or Exercise',
                style: textTheme.headlineMedium),
          ),
          const SizedBox(height: 16),
          // Mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'food',
                    label: Text('Food'),
                    icon: Icon(Icons.restaurant_rounded)),
                ButtonSegment(
                    value: 'exercise',
                    label: Text('Exercise'),
                    icon: Icon(Icons.fitness_center_rounded)),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() {
                _mode = v.first;
                _results = [];
                _selected = null;
                _searchController.clear();
                _gramsController.clear();
                _manualCaloriesController.clear();
                _exerciseNameController.clear();
                _exerciseCaloriesController.clear();
              }),
            ),
          ),
          const SizedBox(height: 16),
          if (_mode == 'food') ...[
            // Meal slot chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _mealSlots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final slot = _mealSlots[i];
                  final active = slot == _mealSlot;
                  return ChoiceChip(
                    label: Text(_capitalize(slot)),
                    selected: active,
                    onSelected: (_) => setState(() => _mealSlot = slot),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search food or scan barcode\u2026',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                onSubmitted: (_) => _search(),
                textInputAction: TextInputAction.search,
              ),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final item = _results[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name),
                      subtitle: Text(
                          'P ${item.protein.toStringAsFixed(1)}g  '
                          'C ${item.carbs.toStringAsFixed(1)}g  '
                          'F ${item.fat.toStringAsFixed(1)}g'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.calories.toStringAsFixed(0)} cal',
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: colorScheme.primary,
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                      onTap: () => _select(item),
                    );
                  },
                ),
              ),
            ],
            if (_selected != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selected!.name, style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _gramsController,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              suffixText: 'g',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _onGramsChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _manualCaloriesController,
                            decoration: const InputDecoration(
                              labelText: 'Calories',
                              suffixText: 'kcal',
                            ),
                            keyboardType: TextInputType.number,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MacroChip(
                            label: 'PROTEIN',
                            value: _protein,
                            color: AppColors.protein),
                        _MacroChip(
                            label: 'CARBS',
                            value: _carbs,
                            color: AppColors.lightAccent),
                        _MacroChip(
                            label: 'FAT',
                            value: _fat,
                            color: AppColors.fat),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton(
                onPressed: _saving ? null : _saveFood,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add to Diary'),
              ),
            ),
          ] else ...[
            // Exercise mode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _exerciseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Exercise name',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _exerciseCaloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories burned',
                      suffixText: 'kcal',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _saveExercise,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Log Exercise'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _MacroChip extends StatelessWidget {
  const _MacroChip(
      {required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}g',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color)),
      ],
    );
  }
}
