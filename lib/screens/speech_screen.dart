import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/speech_controller.dart';
import '../models/speech_message.dart';
import '../widgets/ai_avatar.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final SpeechController speechController = Get.put(SpeechController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AIAvatar(size: 28, isAnimating: false),
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
      body: Obx(() => Column(
        children: [
          // Status indicator
          _buildStatusIndicator(context),
          
          // Messages list
          Expanded(
            child: speechController.speechMessages.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: speechController.speechMessages.length,
                    itemBuilder: (context, index) {
                      final message = speechController.speechMessages.reversed.toList()[index];
                      return _buildSpeechMessageBubble(context, message);
                    },
                  ),
          ),
          
          // Voice input area
          _buildVoiceInputArea(context),
        ],
      )),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Obx(() => Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: speechController.isListening.value 
                      ? Colors.orange 
                      : speechController.isSpeaking.value 
                          ? Colors.blue 
                          : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  speechController.isListening.value 
                      ? "Mendengarkan suara Anda..." 
                      : speechController.isSpeaking.value 
                          ? "AI sedang berbicara..." 
                          : "Siap untuk mendengarkan",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (speechController.recognizedText.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Mendeteksi: ${speechController.recognizedText.value}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      )),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AIAvatar(size: 100, isAnimating: true),
            const SizedBox(height: 24),
            Text(
              "Percakapan Suara",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tekan dan tahan tombol mikrofon untuk berbicara",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildSuggestionChip(
                    context,
                    "Halo, apa kabar?",
                    () => _addDemoMessage("Halo, apa kabar?"),
                  ),
                  const SizedBox(height: 8),
                  _buildSuggestionChip(
                    context,
                    "Ceritakan tentang diri Anda",
                    () => _addDemoMessage("Ceritakan tentang diri Anda"),
                  ),
                  const SizedBox(height: 8),
                  _buildSuggestionChip(
                    context,
                    "Jam berapa sekarang?",
                    () => _addDemoMessage("Jam berapa sekarang?"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechMessageBubble(BuildContext context, SpeechMessage message) {
    final isUser = message.type == SpeechMessageType.user;
    final isSystem = message.type == SpeechMessageType.system;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            AIAvatar(
              size: 32,
              isAnimating: !isSystem && speechController.isSpeaking.value,
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.blue.shade500
                        : isSystem
                            ? Colors.grey.shade200
                            : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isUser 
                              ? Colors.white 
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      if (!isUser && !isSystem) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Obx(() => IconButton(
                              onPressed: () => speechController.isSpeaking.value 
                                  ? speechController.stopSpeaking() 
                                  : speechController.speak(message.content),
                              icon: Icon(
                                speechController.isSpeaking.value ? Icons.stop : Icons.play_arrow,
                                size: 16,
                                color: Colors.blue,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            )),
                            const SizedBox(width: 8),
                            Text(
                              "Tekan untuk mendengarkan",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
                
                const SizedBox(height: 4),
                
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic,
                color: Colors.grey.shade600,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceInputArea(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(16),
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
                child: Container(
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
                ),
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
            if (speechController.isSpeaking.value)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: IconButton(
                  onPressed: () => speechController.stopSpeaking(),
                  icon: const Icon(Icons.stop),
                  tooltip: "Berhenti berbicara",
                ),
              ),
            
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
    ));
  }

  Widget _buildSuggestionChip(BuildContext context, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
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

  void _addDemoMessage(String content) {
    // Simulasi menambah pesan user dan AI response
    final userMessage = SpeechMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: SpeechMessageType.user,
      timestamp: DateTime.now(),
    );
    speechController.speechMessages.add(userMessage);
    
    // Add AI response after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final aiResponse = _getAIResponse(content);
      final aiMessage = SpeechMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: aiResponse,
        type: SpeechMessageType.ai,
        timestamp: DateTime.now(),
      );
      speechController.speechMessages.add(aiMessage);
      speechController.speak(aiResponse);
    });
  }

  String _getAIResponse(String userMessage) {
    final lowerInput = userMessage.toLowerCase();
    
    if (lowerInput.contains('halo') || lowerInput.contains('hai')) {
      return 'Halo! Senang bisa berbicara dengan Anda. Ada yang bisa saya bantu?';
    } else if (lowerInput.contains('nama')) {
      return 'Saya adalah Erico GPT, asisten AI Anda. Saya siap membantu Anda kapan saja.';
    } else if (lowerInput.contains('terima kasih')) {
      return 'Sama-sama! Saya senang bisa membantu Anda.';
    } else if (lowerInput.contains('jam')) {
      final now = DateTime.now();
      return 'Sekarang jam ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
    } else if (lowerInput.contains('cuaca')) {
      return 'Maaf, saya tidak bisa mengakses informasi cuaca saat ini. Tapi Anda bisa mengecek aplikasi cuaca di perangkat Anda.';
    } else {
      return 'Terima kasih atas pesan Anda: "$userMessage". Saya memahami apa yang Anda katakan dan siap membantu lebih lanjut.';
    }
  }

  void _handleStartListening() async {
    try {
      // Reset retry count sebelum memulai
      speechController.resetRetryCount();
      await speechController.startListening();
    } catch (e) {
      print('Error in _handleStartListening: $e');
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
      await speechController.stopListening();
    } catch (e) {
      print('Error in _handleStopListening: $e');
      speechController.isListening.value = false;
    }
  }


  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return "Baru saja";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m yang lalu";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}h yang lalu";
    } else {
      return "${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
    }
  }

}
