import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../data/game_config.dart';
import '../game/crossy_road_logic.dart';
import '../game/game_controller.dart';

class CrossyRoadScreen extends StatefulWidget {
  const CrossyRoadScreen({super.key});

  @override
  State<CrossyRoadScreen> createState() => _CrossyRoadScreenState();
}

class _CrossyRoadScreenState extends State<CrossyRoadScreen>
    with SingleTickerProviderStateMixin {
  CrossyRoadLogic? _logic;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool _rewarded = false;
  bool _lastMoveWasForward = false;
  int _hopKey = 0;
  double _verticalDragDistance = 0;

  static const _carColors = [
    Color(0xFFE85D4A),
    Color(0xFF4C9BE8),
    Color(0xFFF2BD4B),
    Color(0xFF51B59A),
  ];

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
      final coins = logic.score * GameConfig.catchGameCoinsPerItem;
      if (coins > 0) context.read<GameController>().addCoins(coins);
    }

    if (mounted) setState(() {});
  }

  void _startGame(double width) {
    final game = context.read<GameController>();
    if (!game.startMiniGame()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu mascota está demasiado cansada para jugar.'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    _rewarded = false;
    _lastTick = Duration.zero;
    _logic = CrossyRoadLogic(areaWidth: width);
    _ticker
      ..stop()
      ..start();
  }

  void _moveForward() {
    final logic = _logic;
    if (logic == null) return;

    logic.moveForward();
    setState(() {
      _lastMoveWasForward = true;
      _hopKey++;
    });
  }

  void _moveBackward() {
    final logic = _logic;
    if (logic == null) return;

    logic.moveBackward();
    setState(() {
      _lastMoveWasForward = false;
      _hopKey++;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cruza la calle')),
      backgroundColor: const Color(0xFFEAF0E2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_logic == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _startGame(constraints.maxWidth - 32);
              });
              return const Center(child: CircularProgressIndicator());
            }

            final logic = _logic!;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DISTANCIA',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${logic.score}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, boardConstraints) {
                        final rowHeight =
                            boardConstraints.maxHeight /
                            CrossyRoadLogic.rowCount;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragStart: (_) {
                              _verticalDragDistance = 0;
                            },
                            onVerticalDragUpdate: (details) {
                              _verticalDragDistance += details.delta.dy;
                            },
                            onVerticalDragEnd: (_) {
                              if (_verticalDragDistance <= -24) {
                                _moveForward();
                              } else if (_verticalDragDistance >= 24) {
                                _moveBackward();
                              }
                              _verticalDragDistance = 0;
                            },
                            child: Stack(
                              children: [
                                for (final lane in logic.lanes)
                                  _buildLane(lane, rowHeight),
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 420),
                                  curve: Curves.easeInOutCubic,
                                  left: (boardConstraints.maxWidth - 50) / 2,
                                  top:
                                      logic.playerRow * rowHeight +
                                      (rowHeight - 50) / 2,
                                  width: 50,
                                  height: 50,
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(_hopKey),
                                    tween: Tween(begin: 0, end: math.pi),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          0,
                                          -math.sin(value) * 16,
                                        ),
                                        child: child,
                                      );
                                    },
                                    child: Image.asset(
                                      _lastMoveWasForward
                                          ? 'assets/images/buhoespalda.png'
                                          : 'assets/images/buho5.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                if (logic.isGameOver) _buildGameOver(logic),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: logic.canMoveBackward
                              ? _moveBackward
                              : null,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          label: const Text('test_atras'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF647A52),
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: logic.isGameOver ? null : _moveForward,
                          icon: const Icon(Icons.keyboard_arrow_up),
                          label: const Text('test_adelante'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF287C5D),
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLane(TrafficLane lane, double rowHeight) {
    final top = lane.row * rowHeight;
    if (!lane.isRoad) {
      return AnimatedPositioned(
        key: ObjectKey(lane),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        top: top,
        left: 0,
        right: 0,
        height: rowHeight,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF83B95D),
            border: Border(
              bottom: BorderSide(color: Color(0xFF75A950), width: 2),
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.grass,
                size: 20,
                color: Colors.white.withOpacity(0.35),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedPositioned(
      key: ObjectKey(lane),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      top: top,
      left: 0,
      right: 0,
      height: rowHeight,
      child: Container(
        color: const Color(0xFF454A4A),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5,
                  (_) => Container(
                    width: 22,
                    height: 2,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ),
            ),
            for (var index = 0; index < lane.cars.length; index++)
              Positioned(
                left: lane.cars[index].x,
                top: (rowHeight - 34) / 2,
                width: lane.carWidth,
                height: 34,
                child: _buildVehicle(lane, lane.cars[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicle(TrafficLane lane, TrafficCar car) {
    final color = _carColors[car.style];
    final frontLeft = lane.movesRight ? null : 5.0;
    final frontRight = lane.movesRight ? 5.0 : null;
    final rearLeft = lane.movesRight ? 5.0 : null;
    final rearRight = lane.movesRight ? null : 5.0;

    return Stack(
      children: [
        Positioned(
          left: 7,
          right: 7,
          top: 8,
          bottom: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(color, Colors.white, 0.2)!, color],
              ),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white70, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 15,
          top: 10,
          bottom: 13,
          width: 11,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFBFE8EE),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white70, width: 1),
            ),
          ),
        ),
        Positioned(
          right: 15,
          top: 10,
          bottom: 13,
          width: 11,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFBFE8EE),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white70, width: 1),
            ),
          ),
        ),
        Positioned(
          left: frontLeft,
          right: frontRight,
          top: 15,
          child: const _VehicleLight(color: Color(0xFFFFF2A6)),
        ),
        Positioned(
          left: rearLeft,
          right: rearRight,
          top: 15,
          child: const _VehicleLight(color: Color(0xFFFF796A)),
        ),
        Positioned(left: 12, bottom: 2, child: _VehicleWheel()),
        Positioned(right: 12, bottom: 2, child: _VehicleWheel()),
      ],
    );
  }

  Widget _buildGameOver(CrossyRoadLogic logic) {
    final coins = logic.score * GameConfig.catchGameCoinsPerItem;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¡Cuidado con el tráfico!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Distancia: ${logic.score}'),
                Text('Monedas ganadas: $coins'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      _startGame(MediaQuery.sizeOf(context).width - 32),
                  icon: const Icon(Icons.replay),
                  label: const Text('Jugar de nuevo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleLight extends StatelessWidget {
  final Color color;

  const _VehicleLight({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4,
      height: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _VehicleWheel extends StatelessWidget {
  const _VehicleWheel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF202526),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white30, width: 1),
      ),
    );
  }
}
