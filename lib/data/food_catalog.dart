import 'package:flutter/material.dart';

class FoodItem {
  final String name;
  final int price;
  final double hunger;
  final double thirst;
  final double happiness;
  final String description;
  final String emoji;
  final IconData icon;
  final Color color;

  const FoodItem({
    required this.name,
    required this.price,
    required this.hunger,
    required this.thirst,
    required this.happiness,
    required this.description,
    required this.emoji,
    required this.icon,
    required this.color,
  });

  String get effectSummary {
    final hungerText = _formatStat(hunger, 'hambre');
    final thirstText = _formatStat(thirst, 'sed');
    final happinessText = _formatStat(happiness, 'felicidad');
    return '$hungerText · $thirstText · $happinessText';
  }

  String _formatStat(double value, String label) {
    final sign = value >= 0 ? '+' : '';
    return '$sign${value.toInt()} $label';
  }
}

const List<FoodItem> foodCatalog = [
  FoodItem(
    name: 'Manzana',
    price: 3,
    hunger: 18,
    thirst: 4,
    happiness: 8,
    description: 'Un snack fresco que animará a tu mascota.',
    emoji: '🍎',
    icon: Icons.apple,
    color: Color(0xFFFFD6A5),
  ),
  FoodItem(
    name: 'Sopa',
    price: 5,
    hunger: 26,
    thirst: 10,
    happiness: 4,
    description: 'Calentita y muy reconfortante.',
    emoji: '🍲',
    icon: Icons.restaurant,
    color: Color(0xFFFFC2A1),
  ),
  FoodItem(
    name: 'Bebida',
    price: 4,
    hunger: -6,
    thirst: 22,
    happiness: 6,
    description: 'Ideal para reponer la sed sin gastar mucho.',
    emoji: '🥤',
    icon: Icons.local_drink,
    color: Color(0xFFB6E3FF),
  ),
  FoodItem(
    name: 'Galleta',
    price: 2,
    hunger: 10,
    thirst: -6,
    happiness: 12,
    description: 'Pequeña, sabrosa y que le pone feliz.',
    emoji: '🍪',
    icon: Icons.cookie,
    color: Color(0xFFD9C7A2),
  ),
];
