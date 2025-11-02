class ReadyPlayerMeAvatar {
  final String id;
  final String name;
  final String glbUrl;
  final String? thumbnailUrl;
  final List<String> availableAnimations;
  final Map<String, dynamic> metadata;

  ReadyPlayerMeAvatar({
    required this.id,
    required this.name,
    required this.glbUrl,
    this.thumbnailUrl,
    this.availableAnimations = const [],
    this.metadata = const {},
  });

  factory ReadyPlayerMeAvatar.fromJson(Map<String, dynamic> json) {
    return ReadyPlayerMeAvatar(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Avatar',
      glbUrl: json['glbUrl'] ?? json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail'],
      availableAnimations: List<String>.from(json['availableAnimations'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'glbUrl': glbUrl,
      'thumbnailUrl': thumbnailUrl,
      'availableAnimations': availableAnimations,
      'metadata': metadata,
    };
  }
}

class ReadyPlayerMeAnimation {
  final String id;
  final String name;
  final String glbUrl;
  final String? thumbnailUrl;
  final String category;
  final Map<String, dynamic> metadata;

  ReadyPlayerMeAnimation({
    required this.id,
    required this.name,
    required this.glbUrl,
    this.thumbnailUrl,
    this.category = 'idle',
    this.metadata = const {},
  });

  factory ReadyPlayerMeAnimation.fromJson(Map<String, dynamic> json) {
    return ReadyPlayerMeAnimation(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Animation',
      glbUrl: json['glbUrl'] ?? json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail'],
      category: json['category'] ?? 'idle',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'glbUrl': glbUrl,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'metadata': metadata,
    };
  }
}
