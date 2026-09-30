import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_controller.dart';
import 'minigames_screen.dart';
import 'store_screen.dart';
import '../utils/app_colors.dart';
import '../widgets/action_button.dart';
import '../widgets/pet_widget.dart';
import '../widgets/stat_bar.dart';

Color _backgroundForRoom(RoomType room) {
  switch (room) {
    case RoomType.bathroom:
      return const Color(0xFFBFE4FF);
    case RoomType.bedroom:
      return const Color(0xFFE3D9FF);
    case RoomType.livingRoom:
      return AppColors.background;
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final stats = game.pet.stats;

    return Scaffold(
      backgroundColor: _backgroundForRoom(game.currentRoom),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---- Estadísticas en círculos arriba ----
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatBar(
                      icon: Icons.restaurant,
                      label: 'Hambre',
                      value: stats.hunger,
                    ),
                    StatBar(
                      icon: Icons.water_drop,
                      label: 'Sed',
                      value: stats.thirst,
                    ),
                    StatBar(
                      icon: Icons.bolt,
                      label: 'Energía',
                      value: stats.energy,
                    ),
                    StatBar(
                      icon: Icons.bathtub,
                      label: 'Higiene',
                      value: stats.hygiene,
                    ),
                    StatBar(
                      icon: Icons.sentiment_satisfied,
                      label: 'Felicidad',
                      value: stats.happiness,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: game.lowerStatsForTesting,
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: const Text('Test'),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${game.player.coins}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ---- Mascota en el centro ----
              if (game.currentRoom == RoomType.bathroom)
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const Text(
                        'Sala de cuidado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(child: _BathScene(game: game)),
                    ],
                  ),
                )
              else
                Expanded(
                  flex: 3,
                  child: Center(
                    child: PetWidget(
                      mood: game.pet.mood,
                      hygiene: stats.hygiene,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ---- Botones de acción ----
              if (game.currentRoom == RoomType.bathroom)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          game.enterRoom(RoomType.livingRoom, duration: null),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                    Draggable<String>(
                      data: 'sponge',
                      feedback: _Sponge(),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: _Sponge(),
                      ),
                      child: _Sponge(),
                    ),
                    Draggable<String>(
                      data: 'rinse',
                      feedback: _Shower(),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: _Shower(),
                      ),
                      child: _Shower(),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ActionButton(
                      icon: Icons.restaurant,
                      label: 'Alimentar',
                      onPressed: () => game.showFoodMenu(context),
                    ),
                    ActionButton(
                      icon: Icons.bathtub,
                      label: 'Cuidar',
                      onPressed: game.bathe,
                    ),
                    ActionButton(
                      icon: Icons.sports_esports,
                      label: 'Jugar',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MinigamesScreen(),
                        ),
                      ),
                    ),
                    ActionButton(
                      icon: Icons.bedtime,
                      label: 'Dormir',
                      onPressed: game.sleep,
                    ),
                    ActionButton(
                      icon: Icons.store,
                      label: 'Tienda',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StoreScreen()),
                      ),
                    ),
                    ActionButton(
                      icon: Icons.palette,
                      label: 'Personalizar',
                      onPressed: null,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BathScene extends StatefulWidget {
  final GameController game;

  const _BathScene({required this.game});

  @override
  State<_BathScene> createState() => _BathSceneState();
}

class _BathSceneState extends State<_BathScene> {
  final _sceneKey = GlobalKey();
  Offset? _toolPosition;
  String? _activeTool;
  DateTime? _lastBubbleAt;

  void _handleToolMove(DragTargetDetails<String> details) {
    final renderObject = _sceneKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final position = renderObject.globalToLocal(
      details.offset + const Offset(44, 44),
    );
    final center = renderObject.size.center(Offset.zero);
    final petPosition = position - center;
    if (petPosition.dx.abs() > 70 || petPosition.dy.abs() > 70) return;

    final bubblePosition = Offset(
      (petPosition.dx + 70) / 140,
      (petPosition.dy + 70) / 140,
    );
    if (details.data == 'sponge') {
      final now = DateTime.now();
      if (_lastBubbleAt == null ||
          now.difference(_lastBubbleAt!) >= const Duration(milliseconds: 250)) {
        final column = ((petPosition.dx + 70) / 140 * 4).floor().clamp(0, 3);
        final row = ((petPosition.dy + 70) / 140 * 4).floor().clamp(0, 3);
        widget.game.addBathSoapBubble(bubblePosition);
        widget.game.scrubPetArea(row * 4 + column);
        _lastBubbleAt = now;
      }
    } else if (details.data == 'rinse') {
      widget.game.rinseBathBubblesAt(bubblePosition);
    }

    if (_toolPosition == null ||
        (_toolPosition! - position).distance > 5 ||
        _activeTool != details.data) {
      setState(() {
        _toolPosition = position;
        _activeTool = details.data;
      });
    }
  }

  void _handleToolDrop(DragTargetDetails<String> details) {
    if (details.data == 'rinse') widget.game.rinsePet();
    setState(() {
      _toolPosition = null;
      _activeTool = null;
      _lastBubbleAt = null;
    });
  }

  void _handleToolLeave(String? data) {
    setState(() {
      _toolPosition = null;
      _activeTool = null;
      _lastBubbleAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onMove: _handleToolMove,
      onAcceptWithDetails: _handleToolDrop,
      onLeave: _handleToolLeave,
      builder: (context, candidateData, rejectedData) {
        final progress = widget.game.bathScrubProgress;
        final isReadyToRinse = progress == 100;
        final rinseProgress = widget.game.bathRinseProgress;
        return Stack(
          key: _sceneKey,
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isReadyToRinse
                      ? Colors.cyanAccent
                      : Colors.white.withOpacity(0.7),
                  width: isReadyToRinse ? 4 : 2,
                ),
                boxShadow: isReadyToRinse
                    ? [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.8),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ]
                    : const [],
              ),
              child: PetWidget(
                mood: widget.game.pet.mood,
                hygiene: widget.game.pet.stats.hygiene,
                scrubbedAreas: widget.game.bathScrubbedAreas,
                soapBubbles: widget.game.bathSoapBubbles,
                rinsedBubbles: widget.game.bathRinsedBubbles,
              ),
            ),
            if (_toolPosition != null)
              Positioned(
                left: _toolPosition!.dx - 23,
                top: _toolPosition!.dy - 20,
                child: _activeTool == 'sponge'
                    ? const _SoapBubbles()
                    : const _WaterSpray(),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Text(
                progress < 100
                    ? 'Limpieza: $progress%'
                    : 'Enjuague: $rinseProgress%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isReadyToRinse ? Colors.teal.shade900 : Colors.black87,
                  fontWeight: FontWeight.w700,
                  shadows: const [Shadow(color: Colors.white, blurRadius: 6)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Sponge extends StatelessWidget {
  const _Sponge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🧽', style: TextStyle(fontSize: 38)),
            Text('Esponja', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Shower extends StatelessWidget {
  const _Shower();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shower, size: 38, color: Colors.lightBlue),
            Text('Enjuagar', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SoapBubbles extends StatelessWidget {
  const _SoapBubbles();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Image(
        image: AssetImage('assets/images/bubbles.png'),
        width: 46,
        height: 38,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _WaterSpray extends StatelessWidget {
  const _WaterSpray();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Icon(Icons.water_drop, color: Colors.lightBlue, size: 30),
    );
  }
}
