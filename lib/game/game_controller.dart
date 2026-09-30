import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../data/food_catalog.dart';
import '../data/game_config.dart';
import '../screens/store_screen.dart';
import '../services/time_service.dart';
import '../models/pet.dart';
import '../models/player.dart';
import '../services/storage_service.dart';

enum RoomType { livingRoom, bathroom, bedroom }

class GameController extends ChangeNotifier {
  static const int _bathScrubAreaCount = 16;

  final StorageService _storage;
  final Set<int> _bathScrubbedAreas = {};
  final List<Offset> _bathSoapBubbles = [];
  final Set<int> _bathRinsedBubbles = {};

  Player player = Player();
  Pet pet = Pet();

  Timer? _activityTimer;
  Timer? _roomTimer;
  Timer? _statsTimer;
  final TimeService _timeService = TimeService();
  RoomType currentRoom = RoomType.livingRoom;

  GameController(this._storage);

  /// Carga la partida guardada y aplica el tiempo transcurrido (offline).
  Future<void> load() async {
    final saved = await _storage.load();
    if (saved != null) {
      player = saved.player;
      pet = saved.pet;
      _timeService.applyOfflineTime(pet, player.lastPlayed);
      player.lastPlayed = DateTime.now();
      await _storage.save(player, pet);
    }
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => applyElapsedTime(),
    );
    notifyListeners();
  }

  /// Vuelve a aplicar el tiempo transcurrido (por ejemplo, al volver de
  /// segundo plano). Se llama desde main.dart con WidgetsBindingObserver.
  void applyElapsedTime() {
    _timeService.applyOfflineTime(pet, player.lastPlayed);
    _saveAndNotify();
  }

  FoodItem? _getFoodItem(String name) {
    for (final item in foodCatalog) {
      if (item.name == name) return item;
    }
    return null;
  }

  bool buyFood(String foodName) {
    final item = _getFoodItem(foodName);
    if (item == null) return false;
    if (player.coins < item.price) return false;

    player.coins -= item.price;
    player.inventory[foodName] = (player.inventory[foodName] ?? 0) + 1;
    _saveAndNotify();
    return true;
  }

  bool feedFood(String foodName) {
    final food = _getFoodItem(foodName);
    if (food == null) return false;

    final current = player.inventory[foodName] ?? 0;
    if (current <= 0) return false;

    player.inventory[foodName] = current - 1;
    if ((player.inventory[foodName] ?? 0) <= 0) {
      player.inventory.remove(foodName);
    }

    pet.stats.change(
      hunger: food.hunger,
      thirst: food.thirst,
      happiness: food.happiness,
    );
    _showActivity(PetMood.eating);
    _saveAndNotify();
    return true;
  }

  void showFoodMenu(BuildContext context) {
    final foods = player.inventory.entries.toList();

    if (foods.isEmpty) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'No tienes comida',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Compra comida en la tienda para alimentar a tu mascota.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const StoreScreen(),
                              ),
                            );
                          },
                          child: const Text('Ir a la tienda'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elegir comida',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...foods.map((entry) {
                  final name = entry.key;
                  final quantity = entry.value;
                  final item = _getFoodItem(name);

                  return ListTile(
                    leading: const Icon(Icons.restaurant_menu),
                    title: Text(name),
                    subtitle: item == null
                        ? null
                        : Text('Efecto: ${item.effectSummary}'),
                    trailing: Text('x$quantity'),
                    onTap: () {
                      Navigator.of(context).pop();
                      final fed = feedFood(name);
                      if (!fed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No puedes usar esa comida ahora.'),
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void enterRoom(
    RoomType room, {
    Duration? duration = const Duration(seconds: 2),
  }) {
    currentRoom = room;
    _roomTimer?.cancel();
    if (duration != null) {
      _roomTimer = Timer(duration, () {
        currentRoom = RoomType.livingRoom;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void bathe() {
    _bathScrubbedAreas.clear();
    _bathSoapBubbles.clear();
    _bathRinsedBubbles.clear();
    enterRoom(RoomType.bathroom, duration: null);
  }

  int get bathScrubProgress =>
      (_bathScrubbedAreas.length * 100 / _bathScrubAreaCount).round();

  Set<int> get bathScrubbedAreas => Set.unmodifiable(_bathScrubbedAreas);
  List<Offset> get bathSoapBubbles => List.unmodifiable(_bathSoapBubbles);
  Set<int> get bathRinsedBubbles => Set.unmodifiable(_bathRinsedBubbles);

  int get bathRinseProgress {
    if (bathScrubProgress < 100 || _bathSoapBubbles.isEmpty) return 0;
    return (_bathRinsedBubbles.length * 100 / _bathSoapBubbles.length).round();
  }

  void scrubPetArea(int areaIndex) {
    if (currentRoom != RoomType.bathroom ||
        areaIndex < 0 ||
        areaIndex >= _bathScrubAreaCount) {
      return;
    }
    if (_bathScrubbedAreas.add(areaIndex)) notifyListeners();
  }

  void addBathSoapBubble(Offset position) {
    if (currentRoom != RoomType.bathroom ||
        bathScrubProgress >= 100 ||
        position.dx < 0 ||
        position.dx > 1 ||
        position.dy < 0 ||
        position.dy > 1) {
      return;
    }
    _bathSoapBubbles.add(position);
    notifyListeners();
  }

  void rinseBathBubblesAt(Offset position) {
    if (currentRoom != RoomType.bathroom || bathScrubProgress < 100) return;

    var changed = false;
    for (var index = 0; index < _bathSoapBubbles.length; index++) {
      if ((_bathSoapBubbles[index] - position).distance <= 0.1) {
        changed = _bathRinsedBubbles.add(index) || changed;
      }
    }
    if (changed) notifyListeners();
  }

  bool rinsePet() {
    if (currentRoom != RoomType.bathroom ||
        bathScrubProgress < 100 ||
        bathRinseProgress < 100) {
      return false;
    }

    pet.stats.change(hygiene: GameConfig.bathHygieneGain);
    _bathScrubbedAreas.clear();
    _bathSoapBubbles.clear();
    _bathRinsedBubbles.clear();
    _saveAndNotify();
    return true;
  }

  void lowerStatsForTesting() {
    pet.stats.change(
      hunger: -10,
      thirst: -10,
      energy: -10,
      hygiene: -10,
      happiness: -10,
      health: -10,
      sleep: -10,
    );
    _saveAndNotify();
  }

  bool startMiniGame() {
    if (pet.stats.energy < GameConfig.playEnergyCost) return false;

    pet.stats.change(
      happiness: GameConfig.playHappinessGain,
      energy: -GameConfig.playEnergyCost,
    );
    _showActivity(PetMood.playing);
    _saveAndNotify();
    return true;
  }

  void play() {
    // No dejamos jugar si la mascota está demasiado cansada.
    if (pet.stats.energy < GameConfig.playEnergyCost) return;

    pet.stats.change(
      happiness: GameConfig.playHappinessGain,
      energy: -GameConfig.playEnergyCost,
    );
    player.coins += GameConfig.playCoinReward;
    _showActivity(PetMood.playing);
    _saveAndNotify();
  }

  void sleep() {
    pet.isSleeping = true;
    pet.stats.change(energy: GameConfig.sleepEnergyGainPerHour, happiness: 5);
    pet.activity = null;
    enterRoom(RoomType.bedroom);
    _saveAndNotify();
  }

  /// Suma monedas (usado por los minijuegos) y guarda.
  void addCoins(int amount) {
    player.coins += amount;
    _saveAndNotify();
  }

  /// Muestra una expresión temporal (comiendo/jugando) por 1.5 segundos.
  void _showActivity(PetMood mood) {
    _activityTimer?.cancel();
    pet.activity = mood;
    _activityTimer = Timer(const Duration(milliseconds: 1500), () {
      pet.activity = null;
      notifyListeners();
    });
  }

  /// Borra todo y empieza de cero (solo para pruebas).
  Future<void> resetGame() async {
    await _storage.clear();
    player = Player();
    pet = Pet();
    notifyListeners();
  }

  void _saveAndNotify() {
    player.lastPlayed = DateTime.now();
    _storage.save(player, pet);
    notifyListeners();
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    _roomTimer?.cancel();
    _statsTimer?.cancel();
    super.dispose();
  }
}
