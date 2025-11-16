// Tidak perlu import untuk data lokal

class ReadyPlayerMeService {
  // URL avatar Ready Player Me yang Anda berikan
  static const String _defaultAvatarUrl = 'https://models.readyplayer.me/6919bd4d28f4be8b0cf728e1.glb';
  
  // URL test yang lebih sederhana untuk debugging
  static const String _testAvatarUrl = 'https://rrrtwkyhqdtdondioqdc.supabase.co/storage/v1/object/public/animations/F_Standing_Idle_001.glb';
  
  // Daftar avatar yang tersedia (hardcoded untuk demo)
  static List<Map<String, dynamic>> getAvatars() {
    return [
      {
        'id': 'default_avatar',
        'name': 'Default Avatar',
        'glbUrl': _defaultAvatarUrl,
        'thumbnailUrl': null,
        'availableAnimations': ['idle', 'wave', 'dance'],
      },
      {
        'id': 'fallback_avatar',
        'name': 'Fallback Avatar',
        'glbUrl': _testAvatarUrl,
        'thumbnailUrl': null,
        'availableAnimations': ['idle'],
      },
      {
        'id': 'test_avatar',
        'name': 'Test Avatar',
        'glbUrl': _testAvatarUrl,
        'thumbnailUrl': null,
        'availableAnimations': ['idle'],
      },
    ];
  }
  
  // Daftar animasi yang tersedia
  static List<Map<String, dynamic>> getAnimations() {
    return [
      {
        'id': 'idle',
        'name': 'Idle',
        'glbUrl': _defaultAvatarUrl,
        'category': 'idle',
        'thumbnailUrl': null,
      },
      {
        'id': 'wave',
        'name': 'Wave',
        'glbUrl': _defaultAvatarUrl,
        'category': 'gesture',
        'thumbnailUrl': null,
      },
      {
        'id': 'dance',
        'name': 'Dance',
        'glbUrl': _defaultAvatarUrl,
        'category': 'dance',
        'thumbnailUrl': null,
      },
    ];
  }
  
  // Mendapatkan URL avatar GLB berdasarkan ID
  static String? getAvatarGLBUrl(String avatarId) {
    final avatars = getAvatars();
    try {
      final avatar = avatars.firstWhere((a) => a['id'] == avatarId);
      return avatar['glbUrl'];
    } catch (e) {
      return null;
    }
  }
  
  // Mendapatkan URL animasi GLB
  static String? getAnimationGLBUrl(String animationId) {
    final animations = getAnimations();
    try {
      final animation = animations.firstWhere((a) => a['id'] == animationId);
      return animation['glbUrl'];
    } catch (e) {
      return null;
    }
  }
}
