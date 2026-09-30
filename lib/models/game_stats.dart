import '../data/game_config.dart';
import '../utils/helpers.dart';

class GameStats {
  double hunger; // 100 = sin hambre
  double thirst; // 100 = sin sed
  double energy;
  double hygiene;
  double happiness;
  double health;
  double sleep; // 100 = descansada

  GameStats({
    this.hunger = GameConfig.initialStat,
    this.thirst = GameConfig.initialStat,
    this.energy = GameConfig.initialStat,
    this.hygiene = GameConfig.initialStat,
    this.happiness = GameConfig.initialStat,
    this.health = GameConfig.initialStat,
    this.sleep = GameConfig.initialStat,
  });

  /// Suma (o resta, con negativos) a cada estadística sin salirse de 0-100.
  /// Ejemplo: stats.change(hunger: 25, energy: -10);
  void change({
    double hunger = 0,
    double thirst = 0,
    double energy = 0,
    double hygiene = 0,
    double happiness = 0,
    double health = 0,
    double sleep = 0,
  }) {
    this.hunger = clampStat(this.hunger + hunger);
    this.thirst = clampStat(this.thirst + thirst);
    this.energy = clampStat(this.energy + energy);
    this.hygiene = clampStat(this.hygiene + hygiene);
    this.happiness = clampStat(this.happiness + happiness);
    this.health = clampStat(this.health + health);
    this.sleep = clampStat(this.sleep + sleep);
  }

  factory GameStats.fromJson(Map<String, dynamic> json) {
    double read(String key) =>
        clampStat((json[key] as num?)?.toDouble() ?? GameConfig.initialStat);

    return GameStats(
      hunger: read('hunger'),
      thirst: read('thirst'),
      energy: read('energy'),
      hygiene: read('hygiene'),
      happiness: read('happiness'),
      health: read('health'),
      sleep: read('sleep'),
    );
  }

  Map<String, dynamic> toJson() => {
        'hunger': hunger,
        'thirst': thirst,
        'energy': energy,
        'hygiene': hygiene,
        'happiness': happiness,
        'health': health,
        'sleep': sleep,
      };
}