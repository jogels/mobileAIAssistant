import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ready_player_me_controller.dart';

class AvatarSelector extends StatelessWidget {
  const AvatarSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller sudah diinisialisasi di main.dart
    final controller = Get.find<ReadyPlayerMeController>();
    
    return Obx(() => Column(
      children: [
        // Avatar Selection
        if (controller.avatars.isNotEmpty) ...[
          Text(
            'Pilih Avatar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.avatars.length,
              itemBuilder: (context, index) {
                final avatar = controller.avatars[index];
                final isSelected = controller.selectedAvatar.value?.id == avatar.id;
                
                return GestureDetector(
                  onTap: () => controller.selectAvatar(avatar),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          size: 40,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          avatar.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Animation Selection
        if (controller.animations.isNotEmpty) ...[
          Text(
            'Pilih Animasi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.animations.length,
              itemBuilder: (context, index) {
                final animation = controller.animations[index];
                final isSelected = controller.selectedAnimation.value?.id == animation.id;
                
                return GestureDetector(
                  onTap: () => controller.selectAnimation(animation),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 24,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          animation.name,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        
        // Loading State
        if (controller.isLoading.value)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        
        // Error State
        if (controller.error.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              controller.error.value,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    ));
  }
}
