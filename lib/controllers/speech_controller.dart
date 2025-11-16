import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/speech_message.dart';
import '../api/speech_api_service.dart';
import '../api/websocket_service.dart';

class SpeechController extends GetxController {
  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechApiService _apiService = SpeechApiService();
  final WebSocketService _wsService = WebSocketService();
  
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
  var isLoading = false.obs; // Loading state untuk API call
  var useWebSocket = true.obs; // Opsi untuk menggunakan WebSocket atau HTTP
  var isWsConnected = false.obs; // Status koneksi WebSocket
  
  // Untuk accumulate streaming chunks dari llm_text_chunk
  String _accumulatedResponse = '';
  String? _currentAIMessageId; // ID pesan AI yang sedang di-build dari chunks
  Timer? _streamingTimeoutTimer; // Timer untuk detect akhir streaming
  
  // Audio settings
  var speechRate = 0.5.obs;
  var speechVolume = 1.0.obs;
  var speechPitch = 1.0.obs;

  StreamSubscription? _wsMessageSubscription;
  StreamSubscription? _wsConnectionSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeSpeech();
    _initializeWebSocket();
  }

  @override
  void onClose() {
    _flutterTts.stop();
    _streamingTimeoutTimer?.cancel();
    _wsMessageSubscription?.cancel();
    _wsConnectionSubscription?.cancel();
    _wsService.dispose();
    super.onClose();
  }

  /// Initialize WebSocket connection
  Future<void> _initializeWebSocket() async {
    try {
      // Listen untuk koneksi WebSocket
      _wsConnectionSubscription = _wsService.connectionStream.listen((connected) {
        isWsConnected.value = connected;
        if (!connected) {
          Get.snackbar(
            'WebSocket',
            'Koneksi WebSocket terputus. Menggunakan HTTP API.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
          );
        }
      });

      // Listen untuk pesan dari WebSocket
      _wsMessageSubscription = _wsService.messageStream.listen((response) {
        // Filter: hanya proses response dengan type "llm_text_chunk"
        if (response.type == 'llm_text_chunk') {
          print('✅ Received llm_text_chunk response');
          // Ambil payload dari response
          final chunk = response.payload;
          
          // Accumulate chunks untuk streaming response
          _accumulatedResponse += chunk;
          
          // Cancel timeout timer jika ada (masih ada chunks yang datang)
          _streamingTimeoutTimer?.cancel();
          
          // Update atau buat pesan AI dengan accumulated text
          if (_currentAIMessageId == null) {
            // Buat pesan AI baru untuk response pertama
            final message = SpeechMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: _accumulatedResponse,
              type: SpeechMessageType.ai,
              timestamp: DateTime.now(),
            );
            _currentAIMessageId = message.id;
            speechMessages.add(message);
            isLoading.value = false; // Set loading false saat chunk pertama datang
          } else {
            // Update pesan yang sudah ada dengan accumulated text
            final index = speechMessages.indexWhere((m) => m.id == _currentAIMessageId);
            if (index != -1) {
              final existingMessage = speechMessages[index];
              speechMessages[index] = SpeechMessage(
                id: existingMessage.id,
                content: _accumulatedResponse,
                type: existingMessage.type,
                timestamp: existingMessage.timestamp,
              );
            }
          }
          
          // Set timeout untuk detect akhir streaming (jika tidak ada signal done)
          // Jika tidak ada chunks baru dalam 1 detik, anggap streaming selesai dan langsung speak
          _streamingTimeoutTimer = Timer(const Duration(seconds: 1), () {
            if (_accumulatedResponse.isNotEmpty && _currentAIMessageId != null) {
              print('⏱️ Streaming timeout - Assuming response complete');
              print('🔊 Speaking AI response: "$_accumulatedResponse"');
              speak(_accumulatedResponse);
              _accumulatedResponse = '';
              _currentAIMessageId = null;
            }
          });
        } else if (response.type == 'llm_text_done' || response.type == 'llm_response_complete' || response.type == 'done') {
          // Response selesai, cancel timeout dan langsung speak
          _streamingTimeoutTimer?.cancel();
          print('✅ Received final response signal: ${response.type}');
          if (_accumulatedResponse.isNotEmpty && _currentAIMessageId != null) {
            // Langsung speak accumulated response setelah selesai
            print('🔊 Speaking AI response: "$_accumulatedResponse"');
            speak(_accumulatedResponse);
          }
          _accumulatedResponse = '';
          _currentAIMessageId = null;
          isLoading.value = false;
        } else {
          print('⏭️ Skipping response with type: ${response.type} (only showing llm_text_chunk)');
          // Tidak proses response dengan type selain "llm_text_chunk"
        }
      });

      // Connect ke WebSocket
      await _wsService.connect();
      print('WebSocket initialized');
    } catch (e) {
      print('Error initializing WebSocket: $e');
      useWebSocket.value = false; // Fallback ke HTTP jika WebSocket gagal
      Get.snackbar(
        'WebSocket',
        'Gagal terhubung ke WebSocket. Menggunakan HTTP API.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    }
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
          
          switch (error.errorMsg) {
            case 'error_network':
              errorMessage = 'Koneksi internet bermasalah. Periksa koneksi internet Anda.';
              // Tampilkan network error handler jika sudah beberapa kali
              if (retryCount.value >= 2) {
                Future.delayed(const Duration(seconds: 1), () {
                  handleNetworkError();
                });
              }
              break;
            case 'error_busy':
              errorMessage = 'Speech recognition sedang sibuk. Silakan coba lagi.';
              break;
            case 'error_no_match':
              errorMessage = 'Tidak ada suara yang terdeteksi. Coba berbicara lebih jelas.';
              break;
            case 'error_audio':
              errorMessage = 'Masalah dengan audio. Periksa mikrofon Anda.';
              break;
            case 'error_speech_timeout':
              errorMessage = 'Timeout speech recognition. Coba berbicara lebih jelas.';
              break;
            case 'error_client':
              errorMessage = 'Masalah dengan klien speech recognition.';
              break;
            case 'error_server':
              errorMessage = 'Server speech recognition bermasalah. Silakan coba lagi.';
              break;
            case 'error_7':
              errorMessage = 'Masalah dengan audio input. Periksa mikrofon dan coba lagi.';
              break;
            default:
              errorMessage = 'Terjadi kesalahan: ${error.errorMsg}';
          }
          
          Get.snackbar(
            'Error Speech',
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
          );
          
          // DISABLE AUTO-RETRY - User harus klik button sendiri untuk retry
          // Reset counter dan state agar siap untuk rekam berikutnya
          retryCount.value = 0;
          isListening.value = false;
          isRetrying.value = false;
          
          // Jangan auto-retry atau auto-simulasi
          // Biarkan user yang memutuskan kapan akan rekam lagi
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
      // Reset state sebelum mulai listening baru
      recognizedText.value = '';
      isListening.value = false; // Reset state
      
      // Stop dan cancel any existing listening first
      try {
        await _speechToText.stop();
      } catch (e) {
        print('Warning: Error stopping previous listening: $e');
        // Continue anyway, mungkin tidak ada listening aktif
      }
      
      try {
        await _speechToText.cancel();
      } catch (e) {
        print('Warning: Error canceling previous listening: $e');
        // Continue anyway
      }
      
      // Tunggu lebih lama untuk memastikan state benar-benar reset
      await Future.delayed(const Duration(milliseconds: 300));
      
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


      // Set listening state sebelum memulai
      isListening.value = true;
      
      await _speechToText.listen(
        onResult: (result) {
          recognizedText.value = result.recognizedWords;
          print('Speech result: ${result.recognizedWords}');
          print('Final result: ${result.finalResult}');
          print('Confidence: ${result.confidence}');
          
          // Simpan text terakhir yang terdeteksi
          if (result.recognizedWords.isNotEmpty) {
            recognizedText.value = result.recognizedWords;
          }
          
          // Jika ini hasil final, langsung proses (optional - bisa diaktifkan jika ingin auto-process)
          // if (result.finalResult) {
          //   print('Final speech result: ${result.recognizedWords}');
          // }
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
      
      print('✅ Speech recognition started successfully');
    } catch (e) {
      print('Error starting listening: $e');
      isListening.value = false;
      
      // Jika error, beri feedback dan reset state
      Get.snackbar(
        'Error',
        'Gagal memulai listening. Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      
      // DISABLE AUTO-RETRY - User harus klik button sendiri untuk retry
      // Reset counter agar siap untuk percobaan berikutnya
      retryCount.value = 0;
      isRetrying.value = false;
    }
  }

  Future<void> stopListening() async {
    try {
      // Simpan text yang terdeteksi sebelum stop (untuk memastikan kita dapat text terakhir)
      final detectedText = recognizedText.value;
      
      // Stop listening
      if (isListening.value) {
        try {
          await _speechToText.stop();
          print('✅ Speech recognition stopped');
        } catch (e) {
          print('⚠️ Error stopping speech recognition: $e');
          // Try cancel as fallback
          try {
            await _speechToText.cancel();
          } catch (e2) {
            print('⚠️ Error canceling speech recognition: $e2');
          }
        }
      }
      
      // Reset state
      isListening.value = false;
      
      // Tunggu sebentar untuk memastikan speech recognition selesai dan mendapatkan final result
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Gunakan text terakhir yang tersimpan atau yang ada di recognizedText
      final finalText = recognizedText.value.isNotEmpty 
          ? recognizedText.value 
          : detectedText;
      
      print('Final text to process: "$finalText"');
      
      if (finalText.isNotEmpty && finalText.trim().length > 1) {
        final textToProcess = finalText.trim();
        print('Processing recognized text: "$textToProcess"');
        
        // Tambahkan pesan user
        _addUserMessage(textToProcess);
        
        // Proses dan kirim ke API/WebSocket
        await _processUserInput(textToProcess);
        
        // Clear setelah diproses
        recognizedText.value = '';
        
        // Reset retry count setelah berhasil
        retryCount.value = 0;
        isRetrying.value = false;
      } else {
        print('No text detected or text too short');
        // Jika tidak ada text yang terdeteksi, beri feedback yang lebih informatif
        Get.snackbar(
          'Tidak Ada Suara Terdeteksi',
          'Coba berbicara lebih jelas atau dekat ke mikrofon',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade800,
          icon: const Icon(Icons.mic_off, color: Colors.orange),
        );
        recognizedText.value = ''; // Clear text kosong
        
        // DISABLE AUTO-RETRY - User harus klik button sendiri untuk rekam lagi
        // Reset counter agar siap untuk percobaan berikutnya
        retryCount.value = 0;
        isRetrying.value = false;
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

  Future<void> _processUserInput(String input) async {
    if (input.trim().isEmpty) {
      print('Warning: Empty input, skipping API call');
      return;
    }

    try {
      // Reset accumulated response untuk request baru
      _streamingTimeoutTimer?.cancel(); // Cancel timeout timer jika ada
      _accumulatedResponse = '';
      _currentAIMessageId = null;
      
      isLoading.value = true;
      print('=== Processing User Input ===');
      print('Input text: "$input"');
      print('WebSocket enabled: ${useWebSocket.value}');
      print('WebSocket connected: ${_wsService.isConnected}');
      
      // Gunakan WebSocket jika tersedia dan terhubung, otherwise gunakan HTTP
      if (useWebSocket.value && _wsService.isConnected) {
        print('→ Using WebSocket to send message');
        try {
          _wsService.sendUserTextMessage(input);
          print('✓ Message sent via WebSocket successfully');
          // Response akan diterima melalui stream dan di-handle di _initializeWebSocket
          // isLoading akan di-set ke false di handler stream
        } catch (e) {
          print('✗ Error sending via WebSocket: $e');
          // Fallback ke HTTP jika WebSocket gagal
          await _sendViaHttp(input);
        }
      } else {
        print('→ Using HTTP API to send message');
        await _sendViaHttp(input);
      }
    } catch (e) {
      print('✗ Error processing user input: $e');
      print('Stack trace: ${StackTrace.current}');
      isLoading.value = false;
      
      // Fallback ke response lokal jika API gagal
      String fallbackResponse = _generateAIResponse(input);
      _addAIMessage(fallbackResponse);
      
      Get.snackbar(
        'Warning',
        'Gagal menghubungi server. Menggunakan response lokal.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
    }
  }

  /// Helper method untuk mengirim via HTTP API
  Future<void> _sendViaHttp(String input) async {
    try {
      // Menggunakan sendUserMessage untuk mendapatkan BaseResponse dengan type
      final baseResponse = await _apiService.sendUserMessage(input);
      
      // Filter: hanya proses response dengan type "llm_text_chunk"
      if (baseResponse.type == 'llm_text_chunk') {
        print('✅ Received llm_text_chunk response from HTTP API');
        final aiResponse = baseResponse.payload;
        print('✓ HTTP API response received: "$aiResponse"');
        _addAIMessage(aiResponse);
        
        // Langsung speak response setelah diterima
        print('🔊 Speaking AI response from HTTP API: "$aiResponse"');
        speak(aiResponse);
        
        isLoading.value = false;
      } else {
        print('⏭️ Skipping HTTP response with type: ${baseResponse.type} (only showing llm_text_chunk)');
        // Tunggu response yang benar dengan type "llm_text_chunk"
        // Jika tidak ada, set loading ke false dan beri feedback
        isLoading.value = false;
        Get.snackbar(
          'Info',
          'Menunggu response dari server...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('✗ HTTP API error: $e');
      throw e; // Re-throw untuk ditangani di _processUserInput
    }
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
      // Jangan masuk ke mode simulasi - biarkan user retry manual
      Get.snackbar(
        'Speech Recognition Gagal',
        'Telah mencoba beberapa kali. Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
      );
      retryCount.value = 0; // Reset counter
      isRetrying.value = false;
      isListening.value = false;
      
      // JANGAN gunakan simulasi otomatis - biarkan user yang memutuskan
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
  // DISABLED - Tidak digunakan lagi untuk mencegah auto-trigger
  // void simulateSpeechRecognition() {
  //   // Method ini di-disable untuk mencegah auto-trigger listening
  //   // Jika diperlukan, bisa dipanggil secara manual
  // }

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
