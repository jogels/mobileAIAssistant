import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIAvatar extends StatelessWidget {
  final bool isAnimating;
  final double size;

  const AIAvatar({
    super.key,
    this.isAnimating = false,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle dengan animasi
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
          ).animate(target: isAnimating ? 1 : 0)
            .scale(duration: 600.ms, curve: Curves.easeInOut)
            .then()
            .scale(duration: 600.ms, curve: Curves.easeInOut, begin: const Offset(1.0, 1.0), end: const Offset(0.8, 0.8)),
          
          // Icon AI
          Icon(
            Icons.smart_toy,
            color: Colors.white,
            size: size * 0.4,
          ).animate(target: isAnimating ? 1 : 0)
            .shimmer(duration: 1000.ms, color: Colors.white.withOpacity(0.5))
            .then()
            .shimmer(duration: 1000.ms, color: Colors.white.withOpacity(0.5)),
          
          // Pulsing ring effect
          if (isAnimating)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
              .scale(duration: 1500.ms, curve: Curves.easeOut, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
              .fadeOut(duration: 1500.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}
