/// Konfigurasi untuk API
class ApiConfig {
  /// Base URL untuk API
  static const String baseUrl = 'https://c12c43e93230.ngrok-free.app';

  /// WebSocket URL
  /// WebSocket endpoint dengan path /ws
  static const String wsUrl = 'ws://a95ba217a444.ngrok-free.app/ws';
  
  /// Fallback ke wss:// (secure) jika ws:// tidak tersedia
  static const String wsUrlFallback = 'wss://a95ba217a444.ngrok-free.app/ws';

  /// Helper method untuk mendapatkan full URL dari endpoint
  static String getUrl(String endpoint) {
    // Menghapus leading slash jika ada untuk menghindari double slash
    final cleanEndpoint = endpoint.startsWith('/') 
        ? endpoint.substring(1) 
        : endpoint;
    return '$baseUrl/$cleanEndpoint';
  }

  /// Helper method untuk mendapatkan WebSocket URL dengan path
  static String getWebSocketUrl([String? path]) {
    // Pastikan base URL tidak memiliki karakter tambahan
    String cleanWsUrl = wsUrl.trim();
    
    if (path != null && path.isNotEmpty) {
      final cleanPath = path.startsWith('/') 
          ? path.substring(1).trim() 
          : path.trim();
      // Hapus trailing slash jika ada
      final finalPath = cleanPath.endsWith('/') 
          ? cleanPath.substring(0, cleanPath.length - 1)
          : cleanPath;
      return '$cleanWsUrl/$finalPath';
    }
    
    // Pastikan tidak ada trailing slash
    return cleanWsUrl.endsWith('/') 
        ? cleanWsUrl.substring(0, cleanWsUrl.length - 1)
        : cleanWsUrl;
  }

  /// Headers default untuk request API
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Header untuk ngrok (skip browser warning)
        'ngrok-skip-browser-warning': 'true',
      };
}

