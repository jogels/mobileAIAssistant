import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'ai_avatar.dart';
import '../controllers/ready_player_me_controller.dart';

class Simple3DAvatar extends StatefulWidget {
  final bool isAnimating;
  final double size;

  const Simple3DAvatar({
    super.key,
    this.isAnimating = false,
    this.size = 60.0,
  });

  @override
  State<Simple3DAvatar> createState() => _Simple3DAvatarState();
}

class _Simple3DAvatarState extends State<Simple3DAvatar> {
  late ReadyPlayerMeController _readyPlayerMeController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _readyPlayerMeController = Get.find<ReadyPlayerMeController>();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // 3D Model Placeholder dengan Icon
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(widget.size / 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.face,
                    size: widget.size * 0.4,
                    color: Colors.white,
                  ),
                  if (widget.size > 50) ...[
                    const SizedBox(height: 4),
                    Text(
                      '3D Avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.size * 0.12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Animasi overlay
          if (widget.isAnimating)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size / 2),
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
