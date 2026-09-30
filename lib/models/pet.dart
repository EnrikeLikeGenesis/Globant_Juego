import '../data/game_config.dart';
import 'game_stats.dart';

enum PetMood {
  idle,
  happy,
  sad,
  hungry,
  tired,
  sleeping,
  dirty,
  sick,
  eating,
  playing,
}

class Pet {
  String name;
  DateTime createdAt;
  bool isSleeping;
  GameStats stats;

  /// Actividad temporal (comiendo/jugando). No se guarda: solo dura unos segundos.
  PetMood? activity;

  Pet({
    this.name = 'Pompón',
    DateTime? createdAt,
    this.isSleeping = false,
    GameStats? stats,
  })  : createdAt = createdAt ?? DateTime.now(),
        stats = stats ?? GameStats();

  /// Estado visual actual de la mascota.
  PetMood get mood {
    if (isSleeping) return PetMood.sleeping;

    final current = activity;
    if (current != null) return current;

    const low = GameConfig.lowStatThreshold;
    if (stats.health < low) return PetMood.sick;
    if (stats.hunger < low || stats.thirst < low) return PetMood.hungry;
    if (stats.hygiene < low) return PetMood.dirty;
    if (stats.energy < low) return PetMood.tired;
    if (stats.happiness < low) return PetMood.sad;
    if (stats.happiness > GameConfig.happyThreshold) return PetMood.happy;
    return PetMood.idle;
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      name: json['name'] as String? ?? 'Pompón',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      isSleeping: json['isSleeping'] as bool? ?? false,
      stats: GameStats.fromJson(
        (json['stats'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'isSleeping': isSleeping,
        'stats': stats.toJson(),
      };
}