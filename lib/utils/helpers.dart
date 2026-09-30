import '../data/game_config.dart';

/// Limita una estadística para que siempre quede entre 0 y 100.
double clampStat(double value) {
  return value.clamp(GameConfig.minStat, GameConfig.maxStat).toDouble();
}