import 'dart:math';

enum FallingItemType { apple, clock }

/// Un objeto que cae. (x, y) es la esquina superior izquierda.
class FallingItem {
  double x;
  double y;
  final double size;
  final FallingItemType type;

  FallingItem({
    required this.x,
    required this.y,
    this.size = 32,
    this.type = FallingItemType.apple,
  });
}

/// Toda la lógica del minijuego "Atrapa objetos", sin nada de UI.
/// La pantalla solo llama a estos métodos y dibuja lo que hay en [items].
class CatchGameLogic {
  final double areaWidth;
  final double areaHeight;
  final double basketWidth;
  final double basketHeight;
  final Duration gameDuration;

  static const int initialLives = 3;
  static const int clockBonusSeconds = 10;
  static const double difficultyStartsAfter = 20;

  final Random _random;

  double basketX;
  final List<FallingItem> items = [];

  int score = 0;
  int lives = initialLives;
  double timeLeft;
  bool isRunning = false;
  bool isGameOver = false;

  double _elapsedTime = 0;
  double _fallSpeed = 120;
  double _spawnTimer = 0;
  double _spawnInterval = 1.0;
  double _clockSpawnTimer = 0;

  double get fallSpeed => _fallSpeed;
  double get spawnInterval => _spawnInterval;

  CatchGameLogic({
    required this.areaWidth,
    required this.areaHeight,
    this.basketWidth = 70,
    this.basketHeight = 40,
    this.gameDuration = const Duration(seconds: 30),
    Random? random,
  })  : basketX = (areaWidth - 70) / 2,
        timeLeft = gameDuration.inSeconds.toDouble(),
        _random = random ?? Random();

  void start() {
    isRunning = true;
    isGameOver = false;
    score = 0;
    lives = initialLives;
    items.clear();
    timeLeft = gameDuration.inSeconds.toDouble();
    _elapsedTime = 0;
    _fallSpeed = 120;
    _spawnInterval = 1.0;
    _spawnTimer = 0;
    _clockSpawnTimer = _nextClockSpawnInterval();
  }

  /// Mueve la cesta a una posición X, sin salirse del área de juego.
  void moveBasketTo(double x) {
    basketX = x.clamp(0, areaWidth - basketWidth);
  }

  /// Se llama en cada frame (por ejemplo, desde un Ticker).
  /// [dt] es el tiempo transcurrido en segundos desde el frame anterior.
  void update(double dt) {
    if (!isRunning) return;

    timeLeft -= dt;
    if (timeLeft <= 0) {
      timeLeft = 0;
      isRunning = false;
      isGameOver = true;
      return;
    }

    _elapsedTime += dt;
    final difficultyTime = max(0.0, _elapsedTime - difficultyStartsAfter);
    _fallSpeed = min(240.0, 120 + difficultyTime * 0.8);
    _spawnInterval = max(0.4, 1.0 - difficultyTime * 0.01);

    _spawnTimer += dt;
    while (_spawnTimer >= _spawnInterval) {
      _spawnTimer -= _spawnInterval;
      _spawnItem(FallingItemType.apple);
    }

    _clockSpawnTimer -= dt;
    final hasClock = items.any((item) => item.type == FallingItemType.clock);
    if (_clockSpawnTimer <= 0 && !hasClock) {
      _spawnItem(FallingItemType.clock);
      _clockSpawnTimer = _nextClockSpawnInterval();
    }

    final basketTop = areaHeight - basketHeight;

    for (final item in items) {
      item.y += _fallSpeed * dt;
    }

    // Revisar colisiones y quitar objetos atrapados o que se salieron.
    items.removeWhere((item) {
      final reachedBasketLevel = item.y + item.size >= basketTop;
      if (!reachedBasketLevel) return false;

      final caught = item.x + item.size >= basketX &&
          item.x <= basketX + basketWidth;
      if (caught) {
        if (item.type == FallingItemType.apple) {
          score += 10;
        } else {
          timeLeft += clockBonusSeconds;
        }
      } else if (item.type == FallingItemType.apple) {
        lives--;
        if (lives <= 0) {
          lives = 0;
          isRunning = false;
          isGameOver = true;
        }
      }
      return true; // se quita, haya sido atrapado o no
    });
  }

  double _nextClockSpawnInterval() => 8 + _random.nextDouble() * 4;

  void _spawnItem(FallingItemType type) {
    final size = 32.0;
    items.add(
      FallingItem(
        x: _random.nextDouble() * (areaWidth - size),
        y: -size,
        size: size,
        type: type,
      ),
    );
  }
}