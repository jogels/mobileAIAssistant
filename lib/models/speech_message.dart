enum SpeechMessageType {
  user,
  ai,
  system,
}

class SpeechMessage {
  final String id;
  final String content;
  final SpeechMessageType type;
  final DateTime timestamp;
  final bool isAudioAvailable;
  final String? audioPath;
  final Duration? audioDuration;

  SpeechMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isAudioAvailable = false,
    this.audioPath,
    this.audioDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'isAudioAvailable': isAudioAvailable,
      'audioPath': audioPath,
      'audioDuration': audioDuration?.inMilliseconds,
    };
  }

  factory SpeechMessage.fromJson(Map<String, dynamic> json) {
    return SpeechMessage(
      id: json['id'],
      content: json['content'],
      type: SpeechMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SpeechMessageType.user,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isAudioAvailable: json['isAudioAvailable'] ?? false,
      audioPath: json['audioPath'],
      audioDuration: json['audioDuration'] != null 
          ? Duration(milliseconds: json['audioDuration'])
          : null,
    );
  }
}
