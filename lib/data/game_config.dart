/// Valores de balance del juego. Cambia aquí para ajustar la dificultad.
class GameConfig {
  GameConfig._(); // Evita crear instancias: solo usamos GameConfig.algo

  // ---- Límites ----
  static const double minStat = 0;
  static const double maxStat = 100;
  static const double initialStat = 80;

  // ---- Umbrales para decidir el estado de ánimo ----
  static const double lowStatThreshold = 30; // por debajo: necesita atención
  static const double happyThreshold = 70; // por encima: está feliz

  // ---- Pérdida de puntos POR HORA (también aplica offline) ----
  static const double hungerLossPerHour = 5;
  static const double thirstLossPerHour = 6;
  static const double energyLossPerHour = 3;
  static const double hygieneLossPerHour = 3;
  static const double happinessLossPerHour = 4;
  static const double sleepLossPerHour = 3;

  // Pérdida de salud por hora si está descuidada (lo usaremos en el paso 6)
  static const double healthLossPerHourIfNeglected = 5;

  // ---- Efecto de las acciones ----
  static const double feedHungerGain = 25;
  static const int feedCoinCost = 1;
  static const double waterThirstGain = 25;
  static const double bathHygieneGain = 100;
  static const double healAmount = 40;
  static const double playHappinessGain = 20;
  static const double playEnergyCost = 10;
  static const int playCoinReward = 3;
  static const double sleepEnergyGainPerHour = 20;

  // ---- Jugador ----
  static const int initialCoins = 10;
  static const int catchGameCoinsPerItem =
      2; // monedas por cada objeto atrapado
}
