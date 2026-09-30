import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet.dart';
import '../models/player.dart';

/// Lo que se guarda y se carga: jugador + mascota.
class SaveData {
  final Player player;
  final Pet pet;

  SaveData(this.player, this.pet);
}

class StorageService {
  static const _saveKey = 'game_save';

  Future<void> save(Player player, Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'player': player.toJson(),
      'pet': pet.toJson(),
    };
    await prefs.setString(_saveKey, jsonEncode(data));
  }

  /// Devuelve null si no hay partida guardada o si está dañada.
  Future<SaveData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(_saveKey);
    if (text == null) return null;

    try {
      final data = jsonDecode(text) as Map<String, dynamic>;
      return SaveData(
        Player.fromJson((data['player'] as Map<String, dynamic>?) ?? {}),
        Pet.fromJson((data['pet'] as Map<String, dynamic>?) ?? {}),
      );
    } catch (_) {
      return null;
    }
  }

  /// Borra la partida (útil para pruebas).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }
}