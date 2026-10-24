import 'package:flutter/material.dart';

class CategoryIcons {
  static const Map<String, IconData> map = {
    'shopping_cart': Icons.shopping_cart,
    'directions_car': Icons.directions_car,
    'restaurant': Icons.restaurant,
    'receipt_long': Icons.receipt_long,
    'shopping_bag': Icons.shopping_bag,
    'local_cafe': Icons.local_cafe,
    'fitness_center': Icons.fitness_center,
    'flight': Icons.flight,
    'medical_services': Icons.medical_services,
    'home': Icons.home,
    'movie': Icons.movie,
    'school': Icons.school,
    'pets': Icons.pets,
    'phone_android': Icons.phone_android,
    'subscriptions': Icons.subscriptions,
    'work': Icons.work,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,
  };

  static IconData get(String key) => map[key] ?? Icons.category;
  static List<String> get availableKeys => map.keys.where((k) => k != 'category').toList();
}

class ExpenseCategory {
  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final bool isDefault;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.isDefault = false,
  });

  IconData get icon => CategoryIcons.get(iconKey);
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'isDefault': isDefault,
      };

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    // Backwards compatibility if old iconCodePoint exists
    String key = json['iconKey'] as String? ?? 'category';
    if (json['iconCodePoint'] != null && json['iconKey'] == null) {
      final code = json['iconCodePoint'] as int;
      if (code == 0xe59c) key = 'shopping_cart';
      else if (code == 0xe1d5) key = 'directions_car';
      else if (code == 0xe532) key = 'restaurant';
      else if (code == 0xef64) key = 'receipt_long';
      else if (code == 0xe59f) key = 'shopping_bag';
      else if (code == 0xe3e7) key = 'more_horiz';
    }

    return ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconKey: key,
      colorValue: json['colorValue'] as int? ?? 0xFF10B981,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  ExpenseCategory copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
  }) {
    return ExpenseCategory(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault,
    );
  }

  static List<ExpenseCategory> get defaultCategories => const [
        ExpenseCategory(
          id: 'grocery',
          name: 'Grocery',
          iconKey: 'shopping_cart',
          colorValue: 0xFF10B981, // Emerald Green
          isDefault: true,
        ),
        ExpenseCategory(
          id: 'travel',
          name: 'Travel',
          iconKey: 'directions_car',
          colorValue: 0xFF3B82F6, // Blue
          isDefault: true,
        ),
        ExpenseCategory(
          id: 'food',
          name: 'Food',
          iconKey: 'restaurant',
          colorValue: 0xFFF59E0B, // Amber
          isDefault: true,
        ),
        ExpenseCategory(
          id: 'bills',
          name: 'Bills',
          iconKey: 'receipt_long',
          colorValue: 0xFFEF4444, // Red
          isDefault: true,
        ),
        ExpenseCategory(
          id: 'shopping',
          name: 'Shopping',
          iconKey: 'shopping_bag',
          colorValue: 0xFF8B5CF6, // Purple
          isDefault: true,
        ),
        ExpenseCategory(
          id: 'other',
          name: 'Other',
          iconKey: 'more_horiz',
          colorValue: 0xFF6B7280, // Slate Gray
          isDefault: true,
        ),
      ];
}
