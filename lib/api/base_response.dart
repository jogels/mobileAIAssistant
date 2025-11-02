/// Base response model untuk API
/// 
/// Model ini digunakan sebagai struktur standar untuk semua response dari API
/// yang memiliki format:
/// {
///   "type": "...",
///   "payload": {...}
/// }
class BaseResponse<T> {
  final String type;
  final T payload;

  BaseResponse({
    required this.type,
    required this.payload,
  });

  /// Factory constructor untuk membuat BaseResponse dari JSON
  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return BaseResponse<T>(
      type: json['type'] as String,
      payload: fromJsonT != null
          ? fromJsonT(json['payload'])
          : json['payload'] as T,
    );
  }

  /// Method untuk mengkonversi BaseResponse ke JSON
  Map<String, dynamic> toJson([Map<String, dynamic> Function(T)? toJsonT]) {
    return {
      'type': type,
      'payload': toJsonT != null ? toJsonT(payload) : payload,
    };
  }

  @override
  String toString() {
    return 'BaseResponse(type: $type, payload: $payload)';
  }
}

