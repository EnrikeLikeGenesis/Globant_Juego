import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/game_config.dart';
import 'package:flutter/scheduler.dart';
import '../game/catch_game_logic.dart';
import '../game/game_controller.dart';

class CatchGameScreen extends StatefulWidget {
  const CatchGameScreen({super.key});

  @override
  State<CatchGameScreen> createState() => _CatchGameScreenState();
}

class _CatchGameScreenState extends State<CatchGameScreen>
    with SingleTickerProviderStateMixin {
  CatchGameLogic? _logic;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    final logic = _logic;
    if (logic == null) return;

    final dt = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;

    logic.update(dt);

    if (logic.isGameOver && !_rewarded) {
      _rewarded = true;
      _ticker.stop();
      _giveReward(logic.score);
    }

    setState(() {}); // redibuja con las nuevas posiciones
  }

  void _giveReward(int score) {
    final caughtItems = score ~/ 10;
    final coins = caughtItems * GameConfig.catchGameCoinsPerItem;
    if (coins > 0) {
      context.read<GameController>().addCoins(coins);
    }
  }

  void _startGame(double width, double height) {
    final game = context.read<GameController>();
    if (!game.startMiniGame()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu mascota está demasiado cansada para jugar.')),
      );
      Navigator.of(context).pop();
      return;
    }

    _rewarded = false;
    _lastTick = Duration.zero;
    _logic = CatchGameLogic(areaWidth: width, areaHeight: height)..start();
    _ticker.stop();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atrapa objetos')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Primer frame: todavía no hay juego, lo iniciamos una vez que
          // conocemos el tamaño real del área.
          if (_logic == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startGame(width, height);
            });
            return const Center(child: CircularProgressIndicator());
          }

          final logic = _logic!;

          return GestureDetector(
            onPanUpdate: (details) {
              logic.moveBasketTo(details.localPosition.dx - logic.basketWidth / 2);
            },
            child: Stack(
              children: [
                // ---- HUD: tiempo, vidas y puntaje ----
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⏱ ${logic.timeLeft.ceil()}s',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        '❤️ ${logic.lives}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        '⭐ ${logic.score}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),

                // ---- Objetos cayendo ----
                for (final item in logic.items)
                  Positioned(
                    left: item.x,
                    top: item.y,
                    child: Text(
                      item.type == FallingItemType.clock ? '⏰' : '🍎',
                      style: TextStyle(fontSize: item.size),
                    ),
                  ),

                // ---- Cesta ----
                Positioned(
                  left: logic.basketX,
                  bottom: 0,
                  child: Container(
                    width: logic.basketWidth,
                    height: logic.basketHeight,
                    decoration: BoxDecoration(
                      color: Colors.brown.shade300,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                        bottom: Radius.circular(16),
                      ),
                    ),
                  ),
                ),

                // ---- Pantalla de Game Over ----
                if (logic.isGameOver)
                  Container(
                    color: Colors.black54,
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            logic.lives == 0 ? '¡Sin vidas!' : '¡Tiempo!',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Puntaje: ${logic.score}',
                              style: const TextStyle(fontSize: 20, color: Colors.white)),
                          Text(
                            'Monedas ganadas: ${(logic.score ~/ 10) * GameConfig.catchGameCoinsPerItem}',
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _startGame(width, height),
                            child: const Text('Jugar de nuevo'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Volver',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}