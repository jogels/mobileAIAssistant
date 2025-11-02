import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'base_response.dart';

/// Service untuk menghandle API call terkait speech
class SpeechApiService {
  /// Mengirim text dari user ke API
  /// 
  /// [userText] adalah text yang dikenali dari voice recognition
  /// Returns BaseResponse dengan payload yang berisi response dari AI
  Future<BaseResponse<String>> sendUserMessage(String userText) async {
    try {
      // Membuat request payload dengan format BaseResponse
      final requestPayload = BaseResponse<String>(
        type: 'user_text_message',
        payload: userText,
      );

      // Konversi ke JSON
      final jsonBody = jsonEncode(requestPayload.toJson());
      
      // Logging request details
      // NOTE: Endpoint '/api/speech' mungkin perlu disesuaikan dengan endpoint yang ada di server Anda
      // Jika endpoint berbeda, ubah di sini atau konfirmasi dengan backend team
      final apiUrl = ApiConfig.getUrl('/api/speech');
      print('═══════════════════════════════════════════════════════════');
      print('📤 HTTP API Request');
      print('URL: $apiUrl');
      print('Method: POST');
      print('Headers: ${ApiConfig.defaultHeaders}');
      print('Request Payload:');
      print('  Type: ${requestPayload.type}');
      print('  Payload: "${requestPayload.payload}"');
      print('JSON Body: $jsonBody');
      print('═══════════════════════════════════════════════════════════');

      // Kirim request ke API
      // Endpoint bisa disesuaikan sesuai dengan API backend Anda
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      // Logging response details
      print('📥 HTTP API Response');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('═══════════════════════════════════════════════════════════');

      // Handle response
      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Parse response sebagai BaseResponse
        // Payload bisa berupa String langsung atau perlu dikonversi
        final baseResponse = BaseResponse<String>.fromJson(
          responseJson,
          (payload) {
            if (payload is String) {
              return payload;
            } else {
              return payload.toString();
            }
          },
        );
        
        print('✅ Response parsed successfully');
        print('  Response Type: ${baseResponse.type}');
        print('  Response Payload: "${baseResponse.payload}"');
        print('═══════════════════════════════════════════════════════════');

        return baseResponse;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error in sendUserMessage: $e');
      print('═══════════════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Helper method untuk mendapatkan response text dari API
  /// 
  /// Mengambil payload dari BaseResponse dan mengembalikan sebagai String
  Future<String> getAIResponse(String userText) async {
    try {
      final response = await sendUserMessage(userText);
      
      // Ambil hanya payload dari response
      return response.payload;
    } catch (e) {
      print('Error in getAIResponse: $e');
      // Return error message jika API gagal
      return 'Maaf, terjadi kesalahan saat menghubungi server. Silakan coba lagi.';
    }
  }
}

