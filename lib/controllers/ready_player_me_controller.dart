import 'package:get/get.dart';
import '../models/ready_player_me_avatar.dart';
import '../services/ready_player_me_service.dart';

class ReadyPlayerMeController extends GetxController {
  // Observable variables
  final RxList<ReadyPlayerMeAvatar> avatars = <ReadyPlayerMeAvatar>[].obs;
  final RxList<ReadyPlayerMeAnimation> animations = <ReadyPlayerMeAnimation>[].obs;
  final Rx<ReadyPlayerMeAvatar?> selectedAvatar = Rx<ReadyPlayerMeAvatar?>(null);
  final Rx<ReadyPlayerMeAnimation?> selectedAnimation = Rx<ReadyPlayerMeAnimation?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAvatars();
    loadAnimations();
  }

  // Load daftar avatar
  Future<void> loadAvatars() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // Menggunakan data lokal tanpa API call
      final avatarsData = ReadyPlayerMeService.getAvatars();
      avatars.value = avatarsData
          .map((data) => ReadyPlayerMeAvatar.fromJson(data))
          .toList();
      
      // Pilih avatar pertama sebagai default
      if (avatars.isNotEmpty) {
        selectedAvatar.value = avatars.first;
      }
    } catch (e) {
      error.value = 'Failed to load avatars: $e';
      print('Error loading avatars: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load daftar animasi
  Future<void> loadAnimations() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      // Menggunakan data lokal tanpa API call
      final animationsData = ReadyPlayerMeService.getAnimations();
      animations.value = animationsData
          .map((data) => ReadyPlayerMeAnimation.fromJson(data))
          .toList();
      
      // Pilih animasi idle sebagai default
      final idleAnimation = animations.firstWhereOrNull(
        (anim) => anim.category.toLowerCase() == 'idle',
      );
      selectedAnimation.value = idleAnimation ?? animations.firstOrNull;
    } catch (e) {
      error.value = 'Failed to load animations: $e';
      print('Error loading animations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Pilih avatar
  void selectAvatar(ReadyPlayerMeAvatar avatar) {
    selectedAvatar.value = avatar;
  }

  // Pilih animasi
  void selectAnimation(ReadyPlayerMeAnimation animation) {
    selectedAnimation.value = animation;
  }

  // Dapatkan URL GLB untuk avatar yang dipilih
  String? getSelectedAvatarGLBUrl() {
    return selectedAvatar.value?.glbUrl;
  }

  // Dapatkan URL GLB untuk animasi yang dipilih
  String? getSelectedAnimationGLBUrl() {
    return selectedAnimation.value?.glbUrl;
  }

  // Dapatkan nama animasi yang dipilih
  String getSelectedAnimationName() {
    return selectedAnimation.value?.name ?? 'Idle';
  }

  // Refresh data
  @override
  Future<void> refresh() async {
    await Future.wait([
      loadAvatars(),
      loadAnimations(),
    ]);
  }

  // Clear error
  void clearError() {
    error.value = '';
  }
}
