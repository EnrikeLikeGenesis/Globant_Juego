import 'package:flutter_test/flutter_test.dart';
import 'package:mascota_virtual/game/game_controller.dart';
import 'package:mascota_virtual/models/pet.dart';
import 'package:mascota_virtual/models/player.dart';
import 'package:mascota_virtual/services/storage_service.dart';

void main() {
  test('one scrub and rinse fills hygiene to 100', () {
    final game = GameController(_MemoryStorage());
    game.pet.stats.hygiene = 4;
    game.bathe();

    for (var area = 0; area < 16; area++) {
      final position = Offset((area % 4 + 0.3) / 4, (area ~/ 4 + 0.6) / 4);
      game.addBathSoapBubble(position);
      game.scrubPetArea(area);
    }

    expect(game.bathScrubProgress, 100);
    expect(game.bathRinseProgress, 0);
    expect(game.rinsePet(), isFalse);

    for (var index = 0; index < 15; index++) {
      game.rinseBathBubblesAt(game.bathSoapBubbles[index]);
    }
    expect(game.bathRinseProgress, lessThan(100));
    expect(game.rinsePet(), isFalse);

    game.rinseBathBubblesAt(game.bathSoapBubbles.last);
    expect(game.bathRinseProgress, 100);
    expect(game.rinsePet(), isTrue);
    expect(game.pet.stats.hygiene, 100);
    expect(game.bathScrubProgress, 0);
    expect(game.bathRinseProgress, 0);
  });
}

class _MemoryStorage extends StorageService {
  @override
  Future<void> save(Player player, Pet pet) async {}
}
