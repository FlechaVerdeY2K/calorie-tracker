import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FoodItem {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;

  FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'],
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein_g'] as num).toDouble(),
      carbs: (json['carbohydrates_total_g'] as num).toDouble(),
      fat: (json['fat_total_g'] as num).toDouble(),
      servingSize: (json['serving_size_g'] as num).toDouble(),
    );
  }
}

class FoodService {
  final String _apiKey = dotenv.env['CALORIE_NINJAS_API_KEY'] ?? '';
  static const _baseUrl = 'https://api.calorieninjas.com/v1/nutrition';

  Future<List<FoodItem>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl?query=${Uri.encodeComponent(query)}'),
      headers: {'X-Api-Key': _apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((e) => FoodItem.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch nutrition data');
    }
  }
}