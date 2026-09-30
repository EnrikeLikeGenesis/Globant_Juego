import 'dart:math';

import '../data/game_config.dart';

class Player {
  int coins;
  int experience;
  int level;
  DateTime lastPlayed;
  Map<String, int> highScores; // ej: {'catch': 120}
  Map<String, int> inventory; // ej: {'manzana': 2, 'pollo': 1}

  Player({
    this.coins = GameConfig.initialCoins,
    this.experience = 0,
    this.level = 1,
    DateTime? lastPlayed,
    Map<String, int>? highScores,
    Map<String, int>? inventory,
  })  : lastPlayed = lastPlayed ?? DateTime.now(),
        highScores = highScores ?? {},
        inventory = inventory ?? {};

  factory Player.fromJson(Map<String, dynamic> json) {
    final inventoryMap = (json['inventory'] as Map? ?? {})
        .map((key, value) => MapEntry(key.toString(), (value as num).toInt()));

    return Player(
      // max(0, ...) garantiza que las monedas nunca sean negativas
      coins: max(0, (json['coins'] as num?)?.toInt() ?? GameConfig.initialCoins),
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      lastPlayed: DateTime.tryParse(json['lastPlayed'] as String? ?? ''),
      highScores: Map<String, int>.from(json['highScores'] as Map? ?? {}),
      inventory: Map<String, int>.from(inventoryMap),
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'experience': experience,
        'level': level,
        'lastPlayed': lastPlayed.toIso8601String(),
        'highScores': highScores,
        'inventory': inventory,
      };
}