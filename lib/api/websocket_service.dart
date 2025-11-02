import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'api_config.dart';
import 'base_response.dart';

/// Service untuk menghandle WebSocket connection
class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  final _connectionController = StreamController<bool>.broadcast();
  final _messageController = StreamController<BaseResponse<String>>.broadcast();

  /// Stream untuk status koneksi
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Stream untuk menerima pesan dari WebSocket
  Stream<BaseResponse<String>> get messageStream => _messageController.stream;

  /// Status koneksi saat ini
  bool get isConnected => _isConnected;

  /// Connect ke WebSocket server
  Future<void> connect([String? path]) async {
    if (_isConnected) {
      print('WebSocket sudah terhubung');
      return;
    }

    try {
      final urlString = ApiConfig.getWebSocketUrl(path);
      
      // Memastikan URL benar-benar menggunakan ws:// atau wss://
      String finalUrl = urlString;
      if (!finalUrl.startsWith('ws://') && !finalUrl.startsWith('wss://')) {
        // Jika tidak dimulai dengan ws://, ganti http:// atau https:// menjadi ws:// atau wss://
        finalUrl = finalUrl.replaceFirst(RegExp(r'^https?://'), 'ws://');
      }
      
      // Parse dan validate URI
      // Pastikan URL benar-benar valid sebelum parsing
      if (!finalUrl.startsWith('ws://') && !finalUrl.startsWith('wss://')) {
        throw Exception('Invalid WebSocket URL: URL must start with ws:// or wss://');
      }
      
      // Buat URI dengan port yang eksplisit jika tidak ada
      // Ngrok biasanya menggunakan port default (80 untuk ws, 443 untuk wss)
      Uri uri;
      try {
        uri = Uri.parse(finalUrl);
        
        // Jika port adalah 0 atau tidak ada, set port default
        if (uri.port == 0) {
          final defaultPort = uri.scheme == 'wss' ? 443 : 80;
          uri = Uri(
            scheme: uri.scheme,
            host: uri.host,
            port: defaultPort,
            path: uri.path.isEmpty ? '/' : uri.path,
            query: uri.query,
            fragment: uri.fragment,
          );
        }
      } catch (e) {
        throw Exception('Failed to parse WebSocket URI: $e');
      }
      
      // Validasi URI yang sudah di-parse
      if (uri.scheme != 'ws' && uri.scheme != 'wss') {
        throw Exception('Invalid URI scheme: ${uri.scheme}. Expected ws:// or wss://');
      }
      
      if (uri.host.isEmpty) {
        throw Exception('Invalid URI: host is empty');
      }
      
      print('═══════════════════════════════════════════════════════════');
      print('🔌 Connecting to WebSocket');
      print('Original URL: $urlString');
      print('Final URL: $finalUrl');
      print('Parsed URI:');
      print('  Scheme: ${uri.scheme}');
      print('  Host: ${uri.host}');
      print('  Port: ${uri.port} (default: ${uri.scheme == "ws" ? 80 : 443})');
      print('  Path: ${uri.path.isEmpty ? "/" : uri.path}');
      print('  Query: ${uri.query.isEmpty ? "(none)" : uri.query}');
      print('  Fragment: ${uri.fragment.isEmpty ? "(none)" : uri.fragment}');
      print('Full URI String: $uri');
      print('═══════════════════════════════════════════════════════════');

      // Menggunakan WebSocket.connect() dengan custom headers untuk ngrok
      // Ngrok memerlukan header khusus untuk bypass browser warning
      print('Connecting WebSocket with ngrok headers...');
      
      // Coba dengan wss:// terlebih dahulu (secure WebSocket yang lebih stabil dengan ngrok)
      WebSocket? webSocket;
      Exception? lastError;
      
      // Coba wss:// dulu
      if (uri.scheme == 'wss' || finalUrl.startsWith('wss://')) {
        try {
          print('Trying secure WebSocket (wss://)...');
          webSocket = await WebSocket.connect(
            uri.toString(),
            headers: {
              'ngrok-skip-browser-warning': 'true',
            },
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('WebSocket secure connection timeout');
            },
          );
          print('✅ WebSocket connected successfully using wss:// with ngrok headers');
        } catch (e) {
          print('⚠️ Error with wss://: $e');
          lastError = e is Exception ? e : Exception(e.toString());
          
          // Fallback ke ws:// jika wss:// gagal
          try {
            print('Trying non-secure WebSocket (ws://) as fallback...');
            final wsUri = Uri(
              scheme: 'ws',
              host: uri.host,
              port: 80,
              path: uri.path.isEmpty ? '/' : uri.path,
            );
            
            webSocket = await WebSocket.connect(
              wsUri.toString(),
              headers: {
                'ngrok-skip-browser-warning': 'true',
              },
            ).timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('WebSocket connection timeout');
              },
            );
            print('✅ WebSocket connected successfully using ws:// with ngrok headers');
          } catch (e2) {
            print('⚠️ Error with ws://: $e2');
            lastError = e2 is Exception ? e2 : Exception(e2.toString());
          }
        }
      } else {
        // Jika sudah ws://, langsung coba
        try {
          print('Trying WebSocket (ws://)...');
          webSocket = await WebSocket.connect(
            uri.toString(),
            headers: {
              'ngrok-skip-browser-warning': 'true',
            },
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('WebSocket connection timeout');
            },
          );
          print('✅ WebSocket connected successfully using ws:// with ngrok headers');
        } catch (e) {
          print('⚠️ Error with ws://: $e');
          lastError = e is Exception ? e : Exception(e.toString());
        }
      }
      
      // Jika WebSocket.connect() berhasil
      if (webSocket != null) {
        _channel = IOWebSocketChannel(webSocket);
      } else {
        // Fallback: coba dengan IOWebSocketChannel jika WebSocket.connect() gagal
        print('Trying IOWebSocketChannel.connect() as fallback...');
        try {
          _channel = IOWebSocketChannel.connect(uri);
          print('✅ WebSocket connected using IOWebSocketChannel.connect()');
        } catch (e) {
          print('❌ IOWebSocketChannel.connect() also failed: $e');
          throw lastError ?? Exception('All WebSocket connection methods failed');
        }
      }

      // Listen untuk pesan
      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      _isConnected = true;
      _connectionController.add(true);
      print('✅ WebSocket connected successfully');
      print('═══════════════════════════════════════════════════════════');
    } catch (e) {
      print('❌ Error connecting to WebSocket: $e');
      print('═══════════════════════════════════════════════════════════');
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Disconnect dari WebSocket server
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      _handleDisconnection();
      print('WebSocket disconnected');
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  /// Mengirim pesan ke WebSocket server
  void sendMessage(String type, String payload) {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket tidak terhubung');
    }

    try {
      final message = BaseResponse<String>(
        type: type,
        payload: payload,
      );

      final jsonMessage = jsonEncode(message.toJson());
      
      // Logging detail untuk WebSocket message
      print('═══════════════════════════════════════════════════════════');
      print('📤 WebSocket Message Sent');
      print('Message Type: $type');
      print('Message Payload: "$payload"');
      print('JSON Message: $jsonMessage');
      print('═══════════════════════════════════════════════════════════');
      
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      print('❌ Error sending WebSocket message: $e');
      print('═══════════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Mengirim pesan user text ke WebSocket
  void sendUserTextMessage(String userText) {
    sendMessage('user_text_message', userText);
  }

  /// Handle pesan yang diterima dari WebSocket
  void _handleMessage(dynamic message) {
    try {
      String messageStr;
      
      if (message is String) {
        messageStr = message;
      } else {
        messageStr = utf8.decode(message);
      }

      print('═══════════════════════════════════════════════════════════');
      print('📥 WebSocket Message Received');
      print('Raw Message: $messageStr');
      
      final jsonData = jsonDecode(messageStr) as Map<String, dynamic>;
      final baseResponse = BaseResponse<String>.fromJson(
        jsonData,
        (payload) {
          if (payload is String) {
            return payload;
          } else {
            return payload.toString();
          }
        },
      );

      print('✅ Message parsed successfully');
      print('  Response Type: ${baseResponse.type}');
      print('  Response Payload: "${baseResponse.payload}"');
      print('═══════════════════════════════════════════════════════════');
      
      _messageController.add(baseResponse);
    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
      print('Raw message: $message');
      print('═══════════════════════════════════════════════════════════');
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _messageController.close();
  }
}

