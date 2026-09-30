import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class StatBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value; // 0-100

  const StatBar({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  Color _colorForValue(double value) {
    return AppColors.forStat(value);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForValue(value);
    final progress = (value.clamp(0, 100) / 100).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, size: 18, color: color),
                ),
              ),
              Positioned(
                bottom: 2,
                child: Text(
                  '${value.round()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}