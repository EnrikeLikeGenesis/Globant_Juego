import 'package:flutter/material.dart';

import '../models/pet.dart';

class PetWidget extends StatefulWidget {
  final PetMood mood;
  final double hygiene;
  final Set<int> scrubbedAreas;
  final List<Offset> soapBubbles;
  final Set<int> rinsedBubbles;

  const PetWidget({
    super.key,
    required this.mood,
    required this.hygiene,
    this.scrubbedAreas = const {},
    this.soapBubbles = const [],
    this.rinsedBubbles = const {},
  });

  @override
  State<PetWidget> createState() => _PetWidgetState();
}

class _PetWidgetState extends State<PetWidget>
    with SingleTickerProviderStateMixin {
  static const _normalSprites = [
    'assets/images/buho1.png',
    'assets/images/buho2.png',
    'assets/images/buho3.png',
    'assets/images/buho4.png',
    'assets/images/buho5.png',
  ];

  // Si después agregas un set de sprites tristes, solo tienes que reemplazar este array.
  static const _sadSprites = [
    'assets/images/buho1.png',
    'assets/images/buho2.png',
    'assets/images/buho3.png',
    'assets/images/buho4.png',
    'assets/images/buho5.png',
  ];

  static const _frameDurations = [
    Duration(milliseconds: 2000),
    Duration(milliseconds: 250),
    Duration(milliseconds: 250),
    Duration(milliseconds: 250),
    Duration(milliseconds: 2000),
  ];

  static const _cycleDuration = Duration(milliseconds: 4750);

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _cycleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<String> get _activeSprites {
    return widget.mood == PetMood.sad ? _sadSprites : _normalSprites;
  }

  int _frameIndexForCurrentTime() {
    final sprites = _activeSprites;
    final elapsed = (_animationController.value * _cycleDuration.inMilliseconds)
        .clamp(0, _cycleDuration.inMilliseconds.toDouble());

    var accumulated = 0;
    for (var i = 0; i < sprites.length; i++) {
      final frameDuration = _frameDurations[i].inMilliseconds;
      if (elapsed < accumulated + frameDuration) {
        return i;
      }
      accumulated += frameDuration;
    }

    return sprites.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final sprites = _activeSprites;
        final frame = _frameIndexForCurrentTime();
        return SizedBox(
          width: 160,
          height: 160,
          child: Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(sprites[frame], fit: BoxFit.contain),
                  CustomPaint(
                    painter: _DirtPainter(widget.hygiene, widget.scrubbedAreas),
                  ),
                  for (
                    var index = 0;
                    index < widget.soapBubbles.length;
                    index++
                  )
                    if (!widget.rinsedBubbles.contains(index))
                      Positioned(
                        left: widget.soapBubbles[index].dx * 140 - 14,
                        top: widget.soapBubbles[index].dy * 140 - 14,
                        child: Image.asset(
                          'assets/images/bubbles.png',
                          width: 28,
                          height: 28,
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DirtPainter extends CustomPainter {
  final double hygiene;
  final Set<int> scrubbedAreas;

  const _DirtPainter(this.hygiene, this.scrubbedAreas);

  static const _marks = [
    _DirtMark(0.27, 0.51, 13, 9, 0.02),
    _DirtMark(0.72, 0.52, 12, 9, 0.09),
    _DirtMark(0.37, 0.69, 10, 13, 0.16),
    _DirtMark(0.64, 0.7, 13, 9, 0.24),
    _DirtMark(0.25, 0.67, 9, 12, 0.32),
    _DirtMark(0.76, 0.65, 10, 13, 0.42),
    _DirtMark(0.45, 0.79, 13, 9, 0.52),
    _DirtMark(0.56, 0.36, 9, 9, 0.62),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dirtiness = ((100 - hygiene) / 100).clamp(0.0, 1.0);
    for (final mark in _marks) {
      final column = (mark.x * 4).floor();
      final row = (mark.y * 4).floor();
      if (scrubbedAreas.contains(row * 4 + column)) continue;

      final visibility = ((dirtiness - mark.threshold) / 0.14).clamp(0.0, 1.0);
      if (visibility == 0) continue;

      final paint = Paint()
        ..color = Color.fromRGBO(75, 43, 25, 0.3 + visibility * 0.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * mark.x, size.height * mark.y),
          width: mark.radiusX * 2,
          height: mark.radiusY * 2,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DirtPainter oldDelegate) {
    return oldDelegate.hygiene != hygiene ||
        oldDelegate.scrubbedAreas.length != scrubbedAreas.length ||
        !oldDelegate.scrubbedAreas.containsAll(scrubbedAreas);
  }
}

class _DirtMark {
  final double x;
  final double y;
  final double radiusX;
  final double radiusY;
  final double threshold;

  const _DirtMark(this.x, this.y, this.radiusX, this.radiusY, this.threshold);
}
