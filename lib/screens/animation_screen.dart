import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/speech_controller.dart';
import '../widgets/ready_player_me_avatar.dart';
import '../widgets/simple_3d_avatar.dart';

class AnimationScreen extends StatefulWidget {
  const AnimationScreen({super.key});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  late final SpeechController speechController;

  @override
  void initState() {
    super.initState();
    // Gunakan instance yang sudah ada atau buat baru jika belum ada
    try {
      speechController = Get.find<SpeechController>();
    } catch (e) {
      speechController = Get.put(SpeechController());
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Simple3DAvatar(size: 28, isAnimating: false),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Erico GPT Voice",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(() => Text(
                    speechController.isSpeaking.value 
                        ? "Sedang berbicara..." 
                        : speechController.isListening.value 
                            ? "Mendengarkan..." 
                            : "Siap Mendengarkan",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: speechController.isSpeaking.value 
                          ? Colors.blue 
                          : speechController.isListening.value 
                              ? Colors.orange 
                              : Colors.green,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showSettingsDialog(context),
            icon: const Icon(Icons.settings_voice),
            tooltip: "Pengaturan Suara",
          ),
          IconButton(
            onPressed: () => speechController.clearConversation(),
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Hapus Percakapan",
          ),
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Column(
        children: [
          // Avatar besar memenuhi area antara AppBar dan voice button
          Expanded(
            child: _buildAvatarWithFallback(context),
          ),
          
          // Voice input area di bawah
          _buildVoiceInputArea(context),
        ],
      ),
    );
  }

  // Container full screen untuk webview dengan avatar ukuran tetap di tengah
  Widget _buildAvatarWithFallback(BuildContext context) {
    // Ukuran avatar tetap
    const double fixedAvatarSize = 300.0;
    
    return Stack(
      clipBehavior: Clip.none, // Tidak clip agar OverflowBox bisa bekerja dengan baik
      children: [
        // Webview full screen dengan avatar di tengah
        _SafeAvatarWidget(
          speechController: speechController,
          size: fixedAvatarSize,
          isFullScreen: true,
        ),
        
        // Status indicator minimal di bawah avatar
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Obx(() => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: speechController.isListening.value 
                          ? Colors.orange 
                          : speechController.isSpeaking.value 
                              ? Colors.blue 
                              : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    speechController.isListening.value 
                        ? "Mendengarkan..." 
                        : speechController.isSpeaking.value 
                            ? "Berbicara..." 
                            : "Siap",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )),
            ),
          ),
        ),
        
        // Loading indicator saat API dipanggil (minimal)
        Obx(() => speechController.isLoading.value
            ? Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memproses...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }


  Widget _buildVoiceInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Voice button - centered
            Center(
              child: GestureDetector(
                onTapDown: (_) => _handleStartListening(),
                onTapUp: (_) => _handleStopListening(),
                onTapCancel: () => _handleStopListening(),
                child: Obx(() => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: speechController.isListening.value
                          ? [Colors.red.shade500, Colors.red.shade700]
                          : [Colors.blue.shade500, Colors.blue.shade700],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (speechController.isListening.value ? Colors.red : Colors.blue).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    speechController.isListening.value ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 36,
                  ),
                )),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Center(
              child: Column(
                children: [
                  Obx(() => Text(
                    speechController.isListening.value 
                        ? "Lepas untuk mengirim" 
                        : "Tekan dan tahan untuk berbicara",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    speechController.isListening.value 
                        ? "Berbicara sekarang..." 
                        : speechController.retryCount.value > 0
                            ? "Mencoba lagi... (${speechController.retryCount.value}/${speechController.maxRetries.value})"
                            : "AI akan membalas dengan suara",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: speechController.retryCount.value > 0 
                          ? Colors.orange 
                          : Theme.of(context).hintColor,
                    ),
                  )),
                ],
              ),
            ),
            
            // Stop speaking button
            Obx(() => speechController.isSpeaking.value
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: IconButton(
                    onPressed: () => speechController.stopSpeaking(),
                    icon: const Icon(Icons.stop),
                    tooltip: "Berhenti berbicara",
                  ),
                )
              : const SizedBox.shrink()),
            
            // Retry button (only when needed)
            Obx(() => speechController.retryCount.value > 0
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () {
                        speechController.resetRetryCount();
                        speechController.startListening();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Coba Lagi"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pengaturan Suara"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => ListTile(
              title: const Text("Kecepatan Bicara"),
              subtitle: Slider(
                value: speechController.speechRate.value,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (value) => speechController.updateSpeechRate(value),
              ),
              trailing: Text("${(speechController.speechRate.value * 100).round()}%"),
            )),
            Obx(() => ListTile(
              title: const Text("Volume"),
              subtitle: Slider(
                value: speechController.speechVolume.value,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) => speechController.updateSpeechVolume(value),
              ),
              trailing: Text("${(speechController.speechVolume.value * 100).round()}%"),
            )),
            Obx(() => ListTile(
              title: const Text("Nada Suara"),
              subtitle: Slider(
                value: speechController.speechPitch.value,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) => speechController.updateSpeechPitch(value),
              ),
              trailing: Text(speechController.speechPitch.value.toStringAsFixed(1)),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => speechController.testVoiceSettings(),
            child: const Text("Test Suara"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _handleStartListening() async {
    try {
      // Pastikan state listening sudah di-reset
      if (speechController.isListening.value) {
        print('Still listening from previous session, stopping first...');
        await speechController.stopListening();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Reset retry count sebelum memulai
      speechController.resetRetryCount();
      
      // Clear recognized text
      speechController.recognizedText.value = '';
      
      // Start listening
      await speechController.startListening();
    } catch (e) {
      print('Error in _handleStartListening: $e');
      // Pastikan state di-reset jika error
      speechController.isListening.value = false;
      
      // Simple error handling without manual input
      Get.snackbar(
        'Error',
        'Gagal memulai speech recognition. Coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _handleStopListening() async {
    try {
      // Pastikan ada sesuatu yang di-listening sebelum stop
      if (!speechController.isListening.value) {
        print('Not currently listening, nothing to stop');
        return;
      }
      
      await speechController.stopListening();
      
      // Pastikan state di-reset setelah stop
      if (speechController.isListening.value) {
        speechController.isListening.value = false;
      }
    } catch (e) {
      print('Error in _handleStopListening: $e');
      // Pastikan state di-reset jika error
      speechController.isListening.value = false;
    }
  }
}

// Widget terpisah untuk menangani error dengan lebih baik
class _SafeAvatarWidget extends StatefulWidget {
  final SpeechController speechController;
  final double size;
  final bool isFullScreen;

  const _SafeAvatarWidget({
    required this.speechController,
    this.size = 250.0,
    this.isFullScreen = false,
  });

  @override
  State<_SafeAvatarWidget> createState() => _SafeAvatarWidgetState();
}

class _SafeAvatarWidgetState extends State<_SafeAvatarWidget> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Setup error handler untuk menangkap error dari ModelViewer
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final stackTrace = details.stack?.toString() ?? '';
      if (stackTrace.contains('ModelViewer') || 
          stackTrace.contains('ReadyPlayerMeAvatar')) {
        print('Error detected in ModelViewer: ${details.exception}');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      } else {
        // Biarkan error lain ditangani oleh original handler
        if (originalOnError != null) {
          originalOnError(details);
        } else {
          FlutterError.presentError(details);
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // Fallback jika ada error
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.face,
          size: widget.size * 0.4,
          color: Colors.white,
        ),
      );
    }

    // Jika isFullScreen, container full screen dengan avatar di tengah
    if (widget.isFullScreen) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        clipBehavior: Clip.none, // Tidak clip agar OverflowBox bisa bekerja
        child: Center(
          child: _hasError
              ? Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.face,
                    size: widget.size * 0.4,
                    color: Colors.white,
                  ),
                )
              : _ReactiveAvatar(
                  speechController: widget.speechController,
                  size: widget.size,
                ),
        ),
      );
    }
    
    // Jika tidak full screen, container sesuai ukuran avatar
    return Container(
      width: widget.size,
      height: widget.size,
      clipBehavior: Clip.none, // Tidak clip agar OverflowBox bisa bekerja
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // ReadyPlayerMeAvatar dengan error handling
          _hasError
            ? Container(
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
                ),
                child: Icon(
                  Icons.face,
                  size: widget.size * 0.4,
                  color: Colors.white,
                ),
              )
            : _ReactiveAvatar(
                speechController: widget.speechController,
                size: widget.size,
              ),
          // Fallback loading indicator
          Obx(() => (widget.speechController.isSpeaking.value || 
                     widget.speechController.isListening.value)
            ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.purple.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

// Widget terpisah untuk menangani reactive isAnimating
// Tidak menggunakan Obx untuk ModelViewer karena terlalu berat
class _ReactiveAvatar extends StatefulWidget {
  final SpeechController speechController;
  final double size;

  const _ReactiveAvatar({
    required this.speechController,
    this.size = 250.0,
  });

  @override
  State<_ReactiveAvatar> createState() => _ReactiveAvatarState();
}

class _ReactiveAvatarState extends State<_ReactiveAvatar> {
  bool _isAnimating = false;
  late StreamSubscription _speakingSubscription;
  late StreamSubscription _listeningSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to changes
    _speakingSubscription = widget.speechController.isSpeaking.listen((value) {
      _updateAnimating();
    });
    _listeningSubscription = widget.speechController.isListening.listen((value) {
      _updateAnimating();
    });
    _updateAnimating();
  }

  @override
  void dispose() {
    _speakingSubscription.cancel();
    _listeningSubscription.cancel();
    super.dispose();
  }

  void _updateAnimating() {
    final newValue = widget.speechController.isSpeaking.value || 
                     widget.speechController.isListening.value;
    if (_isAnimating != newValue && mounted) {
      setState(() {
        _isAnimating = newValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReadyPlayerMeAvatar(
      size: widget.size,
      isAnimating: _isAnimating,
      rpmApiKey: 'sk_live_idJ1TNyOuuz28VfxFSveg-jOfTFm5aYHvoWj',
      glbUrl: 'https://models.readyplayer.me/6919bd4d28f4be8b0cf728e1.glb',
      animationName: 'Idle',
    );
  }
}

