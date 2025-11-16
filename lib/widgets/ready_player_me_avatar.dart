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
    // Gunakan OverflowBox untuk memberikan ruang ekstra agar tidak terpotong
    // Avatar biasanya lebih tinggi dari lebar, jadi berikan lebih banyak ruang vertikal
    return SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        maxWidth: size * 1.3, // 30% lebih besar untuk mencegah clipping horizontal
        maxHeight: size * 1.8, // 80% lebih besar vertikal untuk mencegah clipping kepala dan kaki
        alignment: Alignment.center,
        child: SizedBox(
          width: size * 1.3,
          height: size * 1.8,
          child: ModelViewer(
            src: glbUrl ?? 'https://models.readyplayer.me/6919bd4d28f4be8b0cf728e1.glb',
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
            cameraOrbit: '0deg 75deg 2.5m', // Jarak 2.5m dan sudut 75deg untuk melihat full body tanpa terlalu dekat
            fieldOfView: '50deg', // Field of view sedang untuk melihat lebih banyak area tanpa distorsi
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
