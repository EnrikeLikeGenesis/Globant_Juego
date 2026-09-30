import 'dart:math';

class TrafficCar {
  double x;
  final int style;
  bool isRespawning = false;
  double respawnDelay = 0;

  TrafficCar({required this.x, required this.style});
}

class TrafficLane {
  int row;
  final bool isRoad;
  final bool movesRight;
  final double speed;
  final double carWidth;
  final List<TrafficCar> cars;

  TrafficLane({
    required this.row,
    required this.isRoad,
    required this.movesRight,
    required this.speed,
    required this.carWidth,
    required this.cars,
  });
}

class CrossyRoadLogic {
  static const int rowCount = 9;
  static const int startingRow = rowCount - 1;
  static const double playerWidth = 38;
  static const double speedIncreasePerSection = 2;
  static const double maxSpeedIncrease = 64;
  static const int sectionsPerExtraVehicle = 8;
  static const int maxExtraVehicles = 2;

  final double areaWidth;
  final List<TrafficLane> lanes = [];
  final Random _random;

  int playerRow = startingRow;
  int score = 0;
  int _furthestRowReached = startingRow;
  int _checkpointRow = startingRow;
  int scrollGeneration = 0;
  bool isGameOver = false;

  bool get canMoveBackward => !isGameOver && playerRow < _checkpointRow;

  CrossyRoadLogic({required this.areaWidth, Random? random})
    : _random = random ?? Random() {
    final carWidth = min(62.0, areaWidth * 0.19);

    for (var row = 0; row < rowCount; row++) {
      final isRoad = row != 0 && row != 4 && row != startingRow;
      if (!isRoad) {
        lanes.add(_createGrassLane(row, carWidth));
        continue;
      }

      lanes.add(_createRoadLane(row));
    }
  }

  TrafficLane _createRoadLane(int row) {
    final carWidth = min(62.0, areaWidth * 0.19);
    final baseCarCount = areaWidth > 520 ? 2 : 1;
    final extraCars = min(
      scrollGeneration ~/ sectionsPerExtraVehicle,
      maxExtraVehicles,
    );
    final carPositions = _carStartingPositions(
      baseCarCount + extraCars,
      carWidth,
    );
    return TrafficLane(
      row: row,
      isRoad: true,
      movesRight: (row + scrollGeneration).isEven,
      speed: 52 +
          _random.nextDouble() * 32 +
          min(
            scrollGeneration * speedIncreasePerSection,
            maxSpeedIncrease,
          ),
      carWidth: carWidth,
      cars: [
        for (var index = 0; index < carPositions.length; index++)
          TrafficCar(
            x: carPositions[index],
            style: _random.nextInt(4),
          ),
      ],
    );
  }

  List<double> _carStartingPositions(int requestedCount, double carWidth) {
    final maxX = max(0.0, areaWidth - carWidth);
    final playerLeft = (areaWidth - playerWidth) / 2;
    final playerRight = playerLeft + playerWidth;
    final safePositions = <double>[];

    for (var x = 0.0; x <= maxX; x += carWidth + 8) {
      if (x + carWidth <= playerLeft || x >= playerRight) {
        safePositions.add(x);
      }
    }

    if (safePositions.isEmpty) return [0];

    safePositions.shuffle(_random);
    final carCount = min(requestedCount, safePositions.length);
    return safePositions.take(carCount).toList();
  }

  TrafficLane _createGrassLane(int row, double carWidth) {
    return TrafficLane(
      row: row,
      isRoad: false,
      movesRight: false,
      speed: 0,
      carWidth: carWidth,
      cars: [],
    );
  }

  void moveForward() {
    if (isGameOver) return;
    if (playerRow > 0) {
      playerRow--;
      if (playerRow < _furthestRowReached) {
        score++;
        _furthestRowReached = playerRow;
      }
      if (!lanes[playerRow].isRoad) {
        _checkpointRow = playerRow;
      }
      if (playerRow == 0) {
        _advanceSection();
      }
      _checkCollision();
    }
  }

  void moveBackward() {
    if (!canMoveBackward) return;
    playerRow++;
    _checkCollision();
  }

  void _advanceSection() {
    lanes.removeWhere((lane) => lane.row > 4);
    for (final lane in lanes) {
      lane.row += 4;
    }
    scrollGeneration++;
    lanes.add(_createGrassLane(0, min(62.0, areaWidth * 0.19)));
    for (var row = 1; row < 4; row++) {
      lanes.add(_createRoadLane(row));
    }
    lanes.sort((first, second) => first.row.compareTo(second.row));
    playerRow = 4;
    _checkpointRow = playerRow;
    _furthestRowReached = playerRow;
  }

  void update(double dt) {
    if (isGameOver) return;

    for (final lane in lanes.where((lane) => lane.isRoad)) {
      for (final car in lane.cars) {
        if (car.isRespawning) {
          car.respawnDelay -= dt;
          if (car.respawnDelay <= 0) {
            car.isRespawning = false;
            car.x = lane.movesRight ? -lane.carWidth : areaWidth;
          }
          continue;
        }

        car.x += (lane.movesRight ? 1 : -1) * lane.speed * dt;
        if (lane.movesRight && car.x > areaWidth) {
          car.isRespawning = true;
          car.respawnDelay = _random.nextDouble();
        } else if (!lane.movesRight && car.x < -lane.carWidth) {
          car.isRespawning = true;
          car.respawnDelay = _random.nextDouble();
        }
      }
    }

    _checkCollision();
  }

  void _checkCollision() {
    final lane = lanes[playerRow];
    if (!lane.isRoad) return;

    final playerLeft = (areaWidth - playerWidth) / 2;
    final playerRight = playerLeft + playerWidth;
    if (lane.cars.any(
      (car) => car.x < playerRight && car.x + lane.carWidth > playerLeft,
    )) {
      isGameOver = true;
    }
  }
}
