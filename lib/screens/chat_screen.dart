import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/ai_avatar.dart';
import '../widgets/chat_sidebar.dart';
import 'speech_screen.dart';
import 'animation_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find<ChatController>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AIAvatar(size: 32, isAnimating: false),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Erico GPT",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() => Text(
                  controller.isLoading.value ? "Mengetik..." : "Online",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: controller.isLoading.value 
                        ? Colors.orange 
                        : Colors.green,
                  ),
                )),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const SpeechScreen()),
            icon: const Icon(Icons.mic),
            tooltip: "Percakapan Suara",
          ),
          IconButton(
            onPressed: () => Get.to(() => const AnimationScreen()),
            icon: const Icon(Icons.animation),
            tooltip: "Animation Screen",
          ),
          IconButton(
            onPressed: () => controller.toggleSidebar(),
            icon: const Icon(Icons.menu),
            tooltip: "Riwayat Chat",
          ),
          IconButton(
            onPressed: () => controller.createNewSession(),
            icon: const Icon(Icons.add),
            tooltip: "Chat Baru",
          ),
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Row(
        children: [
          // Sidebar
          Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: controller.isSidebarOpen.value ? 280 : 0,
            child: controller.isSidebarOpen.value 
                ? const ChatSidebar()
                : const SizedBox.shrink(),
          )),
          
          // Main chat area
          Expanded(
            child: Column(
              children: [
                // Chat messages
                Expanded(
                  child: Obx(() {
                    final session = controller.currentSession.value;
                    if (session == null || session.messages.isEmpty) {
                      return _buildEmptyState(context, controller);
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: session.messages.length,
                      itemBuilder: (context, index) {
                        final message = session.messages.reversed.toList()[index];
                        return ChatMessageBubble(
                          message: message,
                          showAvatar: !message.isUser,
                        );
                      },
                    );
                  }),
                ),
                
                // Loading indicator
                Obx(() {
                  if (controller.isLoading.value) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const AIAvatar(size: 32, isAnimating: true),
                          const SizedBox(width: 12),
                          Text(
                            "AI sedang mengetik...",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                
                // Input field
                ChatInput(
                  onSendMessage: (message) => controller.sendMessage(message),
                  isLoading: controller.isLoading.value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ChatController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AIAvatar(size: 80, isAnimating: true),
          const SizedBox(height: 24),
          Text(
            "Halo! Saya AI Assistant Anda",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Mulai percakapan dengan mengetik pesan di bawah",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                _buildSuggestionChip(
                  context,
                  "Apa yang bisa Anda bantu?",
                  () => controller.sendMessage("Apa yang bisa Anda bantu?"),
                ),
                const SizedBox(height: 8),
                _buildSuggestionChip(
                  context,
                  "Buatkan rencana harian",
                  () => controller.sendMessage("Buatkan rencana harian"),
                ),
                const SizedBox(height: 8),
                _buildSuggestionChip(
                  context,
                  "Jelaskan konsep AI",
                  () => controller.sendMessage("Jelaskan konsep AI"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
