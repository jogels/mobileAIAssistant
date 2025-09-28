import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/speech_message.dart';

class SpeechController extends GetxController {
  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  // Observable variables
  var isListening = false.obs;
  var isSpeaking = false.obs;
  var speechEnabled = false.obs;
  var recognizedText = ''.obs;
  var speechMessages = <SpeechMessage>[].obs;
  var isInitialized = false.obs;
  var currentLanguage = 'id_ID'.obs;
  var retryCount = 0.obs;
  var maxRetries = 3.obs;
  var isRetrying = false.obs;
  
  // Audio settings
  var speechRate = 0.5.obs;
  var speechVolume = 1.0.obs;
  var speechPitch = 1.0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
  }

  @override
  void onClose() {
    _flutterTts.stop();
    super.onClose();
  }

  Future<void> _initializeSpeech() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        Get.snackbar(
          'Izin Diperlukan',
          'Aplikasi memerlukan akses mikrofon untuk fitur speech-to-text',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Initialize speech to text with better error handling
      speechEnabled.value = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'listening') {
            isListening.value = true;
          } else if (status == 'notListening') {
            isListening.value = false;
          } else if (status == 'done') {
            isListening.value = false;
          }
        },
        onError: (error) {
          print('Speech error: $error');
          isListening.value = false;
          
          // Handle different types of errors
          String errorMessage = 'Terjadi kesalahan speech recognition';
          bool shouldRetry = false;
          
          switch (error.errorMsg) {
            case 'error_network':
              errorMessage = 'Koneksi internet bermasalah. Mencoba lagi...';
              shouldRetry = true;
              // Jika sudah retry beberapa kali, tampilkan fallback
              if (retryCount.value >= 2) {
                Future.delayed(const Duration(seconds: 1), () {
                  handleNetworkError();
                });
                shouldRetry = false; // Stop retry setelah 2 kali
              }
              break;
            case 'error_busy':
              errorMessage = 'Speech recognition sedang sibuk. Mencoba lagi...';
              shouldRetry = true;
              break;
            case 'error_no_match':
              errorMessage = 'Tidak ada suara yang terdeteksi. Coba berbicara lebih jelas.';
              break;
            case 'error_audio':
              errorMessage = 'Masalah dengan audio. Periksa mikrofon Anda.';
              break;
            case 'error_speech_timeout':
              errorMessage = 'Timeout speech recognition. Coba berbicara lebih jelas.';
              shouldRetry = true; // Retry untuk timeout
              break;
            case 'error_client':
              errorMessage = 'Masalah dengan klien speech recognition.';
              shouldRetry = true;
              break;
            case 'error_server':
              errorMessage = 'Server speech recognition bermasalah. Mencoba lagi...';
              shouldRetry = true;
              break;
            case 'error_7':
              errorMessage = 'Masalah dengan audio input. Periksa mikrofon dan coba lagi.';
              shouldRetry = true;
              break;
            default:
              errorMessage = 'Terjadi kesalahan: ${error.errorMsg}';
          }
          
          Get.snackbar(
            'Error Speech',
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
          
          // Auto retry untuk error yang bisa di-retry
          if (shouldRetry) {
            Future.delayed(const Duration(seconds: 2), () {
              retrySpeechRecognition();
            });
          } else {
            // Untuk error yang tidak bisa di-retry, reset counter
            retryCount.value = 0;
            
            // Jika error timeout, langsung gunakan simulasi
            if (error.errorMsg == 'error_speech_timeout') {
              Future.delayed(const Duration(seconds: 1), () {
                simulateSpeechRecognition();
              });
            }
          }
        },
        debugLogging: true, // Enable debug logging
      );

      // Initialize text to speech
      await _flutterTts.setLanguage(currentLanguage.value);
      await _flutterTts.setSpeechRate(speechRate.value);
      await _flutterTts.setVolume(speechVolume.value);
      await _flutterTts.setPitch(speechPitch.value);

      _flutterTts.setStartHandler(() {
        isSpeaking.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        isSpeaking.value = false;
      });

      _flutterTts.setErrorHandler((msg) {
        isSpeaking.value = false;
        Get.snackbar(
          'Error TTS',
          'Terjadi kesalahan: $msg',
          snackPosition: SnackPosition.BOTTOM,
        );
      });

      isInitialized.value = true;
      
      // Add welcome message
      _addSystemMessage('Halo! Saya siap untuk berbicara dengan Anda. Tekan tombol mikrofon untuk mulai berbicara.');
      
    } catch (e) {
      print('Error initializing speech: $e');
      Get.snackbar(
        'Error',
        'Gagal menginisialisasi fitur speech: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> startListening() async {
    if (!speechEnabled.value) {
      Get.snackbar(
        'Speech Tidak Tersedia',
        'Fitur speech-to-text tidak tersedia di perangkat ini',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Cek apakah sudah dalam proses listening
    if (isListening.value) {
      print('Already listening, ignoring request');
      return;
    }

    // Cek apakah ini emulator dan langsung gunakan simulasi
    // Disable untuk testing di device asli
    // if (await _isEmulator()) {
    //   print('Detected emulator, using simulation mode');
    //   simulateSpeechRecognition();
    //   return;
    // }

    try {
      recognizedText.value = '';
      
      // Stop any existing listening first
      await _speechToText.stop();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Cek ketersediaan speech recognition
      bool available = await _speechToText.initialize();
      if (!available) {
        Get.snackbar(
          'Speech Tidak Tersedia',
          'Speech recognition tidak tersedia di perangkat ini',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Cek apakah speech recognition tersedia
      if (!await _speechToText.hasPermission) {
        Get.snackbar(
          'Izin Diperlukan',
          'Aplikasi memerlukan izin mikrofon untuk speech recognition',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Cek apakah speech recognition tersedia di perangkat
      if (!speechEnabled.value) {
        Get.snackbar(
          'Speech Recognition Tidak Tersedia',
          'Speech recognition tidak tersedia di perangkat ini',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }


      await _speechToText.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          print('Speech result: ${result.recognizedWords}');
          print('Final result: ${result.finalResult}');
          print('Confidence: ${result.confidence}');
          
          // Jika ini hasil final, langsung proses
          if (result.finalResult) {
            print('Final speech result: ${result.recognizedWords}');
          }
        },
        localeId: 'id_ID', // Gunakan bahasa Indonesia
        listenFor: const Duration(seconds: 30), // Durasi sangat lama untuk hold button
        pauseFor: const Duration(seconds: 3),   // Pause lebih lama
        partialResults: true, // Aktifkan partial results untuk feedback real-time
        cancelOnError: false, // Jangan cancel otomatis jika error
        listenMode: ListenMode.dictation, // Dictation mode untuk input yang lebih panjang
        onSoundLevelChange: (level) {
          // Optional: untuk visual feedback
          print('Sound level: $level');
        },
      );
    } catch (e) {
      print('Error starting listening: $e');
      isListening.value = false;
      
      // Jika error, coba lagi atau beri feedback
      Get.snackbar(
        'Error',
        'Gagal memulai listening. Coba lagi atau periksa izin mikrofon.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      
      // Coba retry jika belum mencapai max retry
      if (retryCount.value < maxRetries.value) {
        Future.delayed(const Duration(seconds: 2), () {
          retrySpeechRecognition();
        });
      }
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      isListening.value = false;
      
      // Tunggu sebentar untuk memastikan speech recognition selesai
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (recognizedText.value.isNotEmpty && recognizedText.value.trim().length > 1) {
        print('Processing recognized text: ${recognizedText.value}');
        _addUserMessage(recognizedText.value);
        _processUserInput(recognizedText.value);
        recognizedText.value = ''; // Clear setelah diproses
      } else {
        // Jika tidak ada text yang terdeteksi, beri feedback yang lebih informatif
        Get.snackbar(
          'Tidak Ada Suara Terdeteksi',
          'Coba berbicara lebih jelas, dekat ke mikrofon, atau periksa koneksi internet',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          icon: const Icon(Icons.mic_off, color: Colors.orange),
        );
        recognizedText.value = ''; // Clear text kosong
        
        // Coba retry jika belum mencapai max retry
        if (retryCount.value < maxRetries.value) {
          Future.delayed(const Duration(seconds: 2), () {
            retrySpeechRecognition();
          });
        }
      }
    } catch (e) {
      print('Error stopping listening: $e');
      isListening.value = false;
      Get.snackbar(
        'Error',
        'Gagal menghentikan listening: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
      Get.snackbar(
        'Error',
        'Gagal berbicara: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    isSpeaking.value = false;
  }

  void _addUserMessage(String content) {
    final message = SpeechMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: SpeechMessageType.user,
      timestamp: DateTime.now(),
    );
    speechMessages.add(message);
  }

  void _addAIMessage(String content) {
    final message = SpeechMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: SpeechMessageType.ai,
      timestamp: DateTime.now(),
    );
    speechMessages.add(message);
    
    // Auto speak AI response
    speak(content);
  }

  void _addSystemMessage(String content) {
    final message = SpeechMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: SpeechMessageType.system,
      timestamp: DateTime.now(),
    );
    speechMessages.add(message);
  }

  void _processUserInput(String input) {
    // Simulasi AI response (nanti bisa diganti dengan API call)
    Timer(const Duration(seconds: 2), () {
      String response = _generateAIResponse(input);
      _addAIMessage(response);
    });
  }

  String _generateAIResponse(String input) {
    // Simulasi response AI berdasarkan input
    final lowerInput = input.toLowerCase();
    
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
      return 'Terima kasih atas pesan Anda: "$input". Saya memahami apa yang Anda katakan dan siap membantu lebih lanjut.';
    }
  }

  // Settings methods
  void updateSpeechRate(double rate) async {
    try {
      speechRate.value = rate;
      await _flutterTts.setSpeechRate(rate);
      print('Speech rate updated to: $rate');
    } catch (e) {
      print('Error updating speech rate: $e');
      Get.snackbar(
        'Error',
        'Gagal mengubah kecepatan bicara: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void updateSpeechVolume(double volume) async {
    try {
      speechVolume.value = volume;
      await _flutterTts.setVolume(volume);
      print('Speech volume updated to: $volume');
    } catch (e) {
      print('Error updating speech volume: $e');
      Get.snackbar(
        'Error',
        'Gagal mengubah volume: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void updateSpeechPitch(double pitch) async {
    try {
      speechPitch.value = pitch;
      await _flutterTts.setPitch(pitch);
      print('Speech pitch updated to: $pitch');
    } catch (e) {
      print('Error updating speech pitch: $e');
      Get.snackbar(
        'Error',
        'Gagal mengubah nada suara: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void updateLanguage(String language) async {
    try {
      currentLanguage.value = language;
      await _flutterTts.setLanguage(language);
      print('Language updated to: $language');
    } catch (e) {
      print('Error updating language: $e');
      Get.snackbar(
        'Error',
        'Gagal mengubah bahasa: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Method untuk test pengaturan suara
  Future<void> testVoiceSettings() async {
    try {
      await speak('Ini adalah test suara dengan pengaturan saat ini. Kecepatan: ${(speechRate.value * 100).round()}%, Volume: ${(speechVolume.value * 100).round()}%, Nada: ${speechPitch.value.toStringAsFixed(1)}');
    } catch (e) {
      print('Error testing voice settings: $e');
      Get.snackbar(
        'Error',
        'Gagal test suara: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void clearConversation() {
    speechMessages.clear();
    _addSystemMessage('Percakapan telah dihapus. Mari mulai percakapan baru!');
  }

  // Method untuk retry speech recognition
  Future<void> retrySpeechRecognition() async {
    if (isRetrying.value) return; // Prevent multiple retry
    
    if (retryCount.value < maxRetries.value) {
      isRetrying.value = true;
      retryCount.value++;
      print('Retrying speech recognition, attempt ${retryCount.value}');
      
      // Tunggu sebentar sebelum retry
      await Future.delayed(Duration(seconds: retryCount.value));
      
      // Coba lagi
      await startListening();
      isRetrying.value = false;
    } else {
      Get.snackbar(
        'Speech Recognition Gagal',
        'Telah mencoba ${maxRetries.value} kali. Menggunakan mode simulasi.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      retryCount.value = 0; // Reset counter
      isRetrying.value = false;
      // Stop semua retry dan gunakan simulasi
      isListening.value = false;
      
      // Gunakan simulasi untuk emulator
      Future.delayed(const Duration(seconds: 1), () {
        simulateSpeechRecognition();
      });
    }
  }

  // Method untuk reset retry counter
  void resetRetryCount() {
    retryCount.value = 0;
    isRetrying.value = false;
  }

  // Method untuk menangani error network
  void handleNetworkError() {
    Get.snackbar(
      'Koneksi Internet Bermasalah',
      'Speech recognition memerlukan koneksi internet yang stabil. Coba lagi nanti.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
      icon: const Icon(Icons.wifi_off, color: Colors.orange),
    );
  }


  // Method untuk simulasi speech recognition di emulator
  void simulateSpeechRecognition() {
    Get.snackbar(
      'Mode Simulasi',
      'Speech recognition tidak tersedia di emulator. Menggunakan mode simulasi.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      icon: const Icon(Icons.sim_card, color: Colors.blue),
    );
    
    // Simulasi speech recognition
    isListening.value = true;
    
    // Variasi text simulasi
    final simulationTexts = [
      'Hello, this is a simulation',
      'Halo, ini adalah simulasi',
      'How are you today?',
      'Apa kabar hari ini?',
      'Tell me about yourself',
      'Ceritakan tentang diri Anda',
      'What time is it?',
      'Jam berapa sekarang?',
    ];
    
    recognizedText.value = simulationTexts[DateTime.now().millisecondsSinceEpoch % simulationTexts.length];
    
    Future.delayed(const Duration(seconds: 2), () {
      isListening.value = false;
      if (recognizedText.value.isNotEmpty) {
        _addUserMessage(recognizedText.value);
        _processUserInput(recognizedText.value);
      }
    });
  }

  // Get available languages
  List<String> getAvailableLanguages() {
    return [
      'id_ID', // Indonesian
      'en_US', // English
      'en_GB', // English UK
      'es_ES', // Spanish
      'fr_FR', // French
      'de_DE', // German
      'ja_JP', // Japanese
      'ko_KR', // Korean
      'zh_CN', // Chinese
    ];
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'id_ID': return 'Bahasa Indonesia';
      case 'en_US': return 'English (US)';
      case 'en_GB': return 'English (UK)';
      case 'es_ES': return 'Español';
      case 'fr_FR': return 'Français';
      case 'de_DE': return 'Deutsch';
      case 'ja_JP': return '日本語';
      case 'ko_KR': return '한국어';
      case 'zh_CN': return '中文';
      default: return code;
    }
  }
}
