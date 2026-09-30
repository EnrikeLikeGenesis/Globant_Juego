import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mascota_virtual/game/catch_game_logic.dart';

void main() {
  test('clocks spawn every eight to twelve seconds, one at a time', () {
    final logic = CatchGameLogic(
      areaWidth: 300,
      areaHeight: 100000,
      random: Random(17),
    )..start();
    logic.timeLeft = 1000;

    logic.update(7.99);
    expect(
      logic.items.where((item) => item.type == FallingItemType.clock),
      isEmpty,
    );

    logic.update(4.02);
    var clocks = logic.items
        .where((item) => item.type == FallingItemType.clock)
        .toList();
    expect(clocks, hasLength(1));

    logic.update(12.01);
    clocks = logic.items
        .where((item) => item.type == FallingItemType.clock)
        .toList();
    expect(clocks, hasLength(1));

    logic.items.remove(clocks.single);
    logic.update(0);
    expect(
      logic.items.where((item) => item.type == FallingItemType.clock),
      hasLength(1),
    );
  });

  test('catching a clock adds ten seconds without changing lives or score', () {
    final logic = CatchGameLogic(
      areaWidth: 300,
      areaHeight: 300,
      random: Random(1),
    )..start();
    logic.timeLeft = 12;
    logic.items.add(
      FallingItem(
        x: logic.basketX,
        y: 300 - logic.basketHeight - 32,
        type: FallingItemType.clock,
      ),
    );

    logic.update(0);

    expect(logic.timeLeft, 22);
    expect(logic.lives, 3);
    expect(logic.score, 0);
  });

  test('only three missed apples end the game; missed clocks cost no life', () {
    final logic = CatchGameLogic(
      areaWidth: 300,
      areaHeight: 300,
      random: Random(2),
    )..start();
    final missedItemY = 300 - logic.basketHeight - 32;

    logic.items.add(
      FallingItem(
        x: 0,
        y: missedItemY,
        type: FallingItemType.clock,
      ),
    );
    logic.items.add(FallingItem(x: 0, y: missedItemY));
    logic.update(0);
    expect(logic.lives, 2);
    expect(logic.isGameOver, isFalse);

    for (var miss = 0; miss < 2; miss++) {
      logic.items.add(FallingItem(x: 0, y: missedItemY));
      logic.update(0);
    }

    expect(logic.lives, 0);
    expect(logic.isGameOver, isTrue);
  });

  test('spawning continues and difficulty rises after twenty seconds', () {
    final logic = CatchGameLogic(
      areaWidth: 300,
      areaHeight: 100000,
      random: Random(42),
    )..start();
    logic.timeLeft = 1000;

    logic.update(19);
    expect(logic.fallSpeed, 120);
    expect(logic.spawnInterval, 1);

    logic.update(16);
    expect(logic.fallSpeed, closeTo(132, 0.001));
    expect(logic.spawnInterval, closeTo(0.85, 0.001));
    expect(logic.items, isNotEmpty);
    expect(
      logic.items.any((item) => item.type == FallingItemType.clock),
      isTrue,
    );
  });
}