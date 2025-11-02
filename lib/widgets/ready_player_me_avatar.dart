import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ReadyPlayerMeAvatar extends StatelessWidget {
  final bool isAnimating;
  final double size;
  final String? glbUrl;
  final String? animationName; // tidak dipakai oleh wrapper saat ini
  final String? rpmApiKey; // tidak dipakai oleh wrapper saat ini

  const ReadyPlayerMeAvatar({
    super.key,
    this.isAnimating = false,
    this.size = 60.0,
    this.glbUrl,
    this.animationName,
    this.rpmApiKey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: ModelViewer(
          src: glbUrl ?? 'https://models.readyplayer.me/68e0f3dd96f1fb90a498da22.glb',
          alt: 'Ready Player Me Avatar',
          ar: false,
          autoRotate: isAnimating,
          animationName: animationName ?? 'Idle',
          cameraControls: false,
          disableZoom: true,
          disablePan: true,
          disableTap: true,
          interactionPrompt: InteractionPrompt.none,
          loading: Loading.eager,
          cameraOrbit: '0deg 75deg 1.5m',
          fieldOfView: '30deg',
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
