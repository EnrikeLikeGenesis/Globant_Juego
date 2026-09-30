import '../data/game_config.dart';
import '../models/pet.dart';

class TimeService {
  /// Aplica el desgaste de las estadísticas según las horas transcurridas
  /// desde [lastPlayed] hasta ahora. Modifica [pet] directamente.
  void applyOfflineTime(Pet pet, DateTime lastPlayed) {
    final now = DateTime.now();
    final elapsed = now.difference(lastPlayed);
    if (elapsed.isNegative) return; // reloj del dispositivo cambiado, ignorar

    final hours = elapsed.inSeconds / 3600;
    if (hours <= 0) return;

    // Si estaba durmiendo, en vez de perder energía la recupera.
    if (pet.isSleeping) {
      pet.stats.change(energy: GameConfig.sleepEnergyGainPerHour * hours);
      // Dormir despierta a la mascota sola al llegar a energía completa.
      if (pet.stats.energy >= GameConfig.maxStat) {
        pet.isSleeping = false;
      }
    } else {
      pet.stats.change(
        hunger: -GameConfig.hungerLossPerHour * hours,
        thirst: -GameConfig.thirstLossPerHour * hours,
        energy: -GameConfig.energyLossPerHour * hours,
        hygiene: -GameConfig.hygieneLossPerHour * hours,
        happiness: -GameConfig.happinessLossPerHour * hours,
        sleep: -GameConfig.sleepLossPerHour * hours,
      );
    }

    // Si alguna estadística vital está muy baja, la salud se resiente.
    final neglected =
        pet.stats.hunger < GameConfig.lowStatThreshold ||
        pet.stats.thirst < GameConfig.lowStatThreshold ||
        pet.stats.hygiene < GameConfig.lowStatThreshold;
    if (neglected) {
      pet.stats.change(
        health: -GameConfig.healthLossPerHourIfNeglected * hours,
      );
    }
  }
}
