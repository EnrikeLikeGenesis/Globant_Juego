import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mascota_virtual/game/crossy_road_logic.dart';

void main() {
  test('vehicles wait up to one second off screen before reappearing', () {
    final logic = CrossyRoadLogic(areaWidth: 400, random: Random(8));
    final rightMovingLane = logic.lanes.firstWhere(
      (lane) => lane.isRoad && lane.movesRight,
    );
    final leftMovingLane = logic.lanes.firstWhere(
      (lane) => lane.isRoad && !lane.movesRight,
    );
    final rightMovingCar = rightMovingLane.cars.first;
    final leftMovingCar = leftMovingLane.cars.first;
    rightMovingCar.x = logic.areaWidth + 1;
    leftMovingCar.x = -leftMovingLane.carWidth - 1;

    logic.update(0);

    expect(rightMovingCar.isRespawning, isTrue);
    expect(leftMovingCar.isRespawning, isTrue);
    expect(rightMovingCar.respawnDelay, inInclusiveRange(0, 1));
    expect(leftMovingCar.respawnDelay, inInclusiveRange(0, 1));

    logic.update(1.01);

    expect(rightMovingCar.isRespawning, isFalse);
    expect(rightMovingCar.x, -rightMovingLane.carWidth);
    expect(leftMovingCar.isRespawning, isFalse);
    expect(leftMovingCar.x, logic.areaWidth);
  });

  test('vehicle spawn positions vary with the random seed', () {
    final firstGame = CrossyRoadLogic(areaWidth: 400, random: Random(1));
    final secondGame = CrossyRoadLogic(areaWidth: 400, random: Random(2));
    final firstPositions = firstGame.lanes
        .where((lane) => lane.isRoad)
        .expand((lane) => lane.cars.map((car) => car.x))
        .toList();
    final secondPositions = secondGame.lanes
        .where((lane) => lane.isRoad)
        .expand((lane) => lane.cars.map((car) => car.x))
        .toList();

    expect(firstPositions, isNot(equals(secondPositions)));
  });

  test('grass checkpoints block retreat and advance the road repeatedly', () {
    final logic = CrossyRoadLogic(areaWidth: 400);

    void moveForwardWithoutTraffic() {
      if (logic.playerRow > 0) {
        logic.lanes[logic.playerRow - 1].cars.clear();
      }
      logic.moveForward();
    }

    for (var step = 0; step < 4; step++) {
      moveForwardWithoutTraffic();
    }
    expect(logic.playerRow, 4);
    expect(logic.canMoveBackward, isFalse);

    logic.moveBackward();
    expect(logic.playerRow, 4);

    for (var step = 0; step < 4; step++) {
      moveForwardWithoutTraffic();
    }
    expect(logic.scrollGeneration, 1);
    expect(logic.playerRow, 4);
    expect(logic.lanes.map((lane) => lane.row), List.generate(9, (i) => i));
    expect(logic.lanes[0].isRoad, isFalse);
    expect(logic.lanes[4].isRoad, isFalse);
    expect(logic.canMoveBackward, isFalse);

    for (var step = 0; step < 4; step++) {
      moveForwardWithoutTraffic();
    }
    expect(logic.scrollGeneration, 2);
    expect(logic.playerRow, 4);
    expect(logic.lanes[0].isRoad, isFalse);
    expect(logic.lanes[4].isRoad, isFalse);

    for (var step = 0; step < 4; step++) {
      moveForwardWithoutTraffic();
    }
    expect(logic.scrollGeneration, 3);
    final generatedRoads = logic.lanes.where(
      (lane) => lane.row > 0 && lane.row < 4,
    );
    expect(
      generatedRoads.every((lane) => lane.speed >= 58 && lane.speed <= 90),
      isTrue,
    );
    expect(generatedRoads.every((lane) => lane.cars.length == 1), isTrue);
    final playerLeft = (logic.areaWidth - CrossyRoadLogic.playerWidth) / 2;
    final playerRight = playerLeft + CrossyRoadLogic.playerWidth;
    expect(
      generatedRoads.every(
        (lane) => lane.cars.every(
          (car) =>
              car.x >= playerRight || car.x + lane.carWidth <= playerLeft,
        ),
      ),
      isTrue,
    );

    for (var section = 0; section < 4; section++) {
      for (var step = 0; step < 4; step++) {
        moveForwardWithoutTraffic();
      }
    }
    expect(logic.scrollGeneration, 7);
    expect(
      logic.lanes
          .where((lane) => lane.row > 0 && lane.row < 4)
          .every((lane) => lane.cars.length == 1),
      isTrue,
    );

    for (var step = 0; step < 4; step++) {
      moveForwardWithoutTraffic();
    }
    expect(logic.scrollGeneration, 8);
    final roadsAtSectionEight = logic.lanes.where(
      (lane) => lane.row > 0 && lane.row < 4,
    );
    expect(roadsAtSectionEight.every((lane) => lane.cars.length == 2), isTrue);
    expect(
      roadsAtSectionEight.every((lane) => lane.speed >= 68 && lane.speed <= 100),
      isTrue,
    );
  });
}