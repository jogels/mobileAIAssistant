import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_session.dart';

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find<ChatController>();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Riwayat Chat",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.toggleSidebar(),
                  icon: const Icon(Icons.close),
                  tooltip: "Tutup",
                ),
              ],
            ),
          ),
          
          // New chat button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.createNewSession(),
                icon: const Icon(Icons.add),
                label: const Text("Chat Baru"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          
          // Chat sessions list
          Expanded(
            child: Obx(() {
              if (controller.chatSessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada chat",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.chatSessions.length,
                itemBuilder: (context, index) {
                  final session = controller.chatSessions[index];
                  final isActive = controller.currentSession.value?.id == session.id;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => controller.switchToSession(session),
                        onLongPress: () => _showDeleteDialog(context, controller, session),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isActive 
                                ? Border.all(color: Colors.blue.withOpacity(0.3))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 16,
                                color: isActive 
                                    ? Colors.blue.shade600
                                    : Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session.title,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: isActive 
                                            ? FontWeight.w600 
                                            : FontWeight.normal,
                                        color: isActive 
                                            ? Colors.blue.shade600
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatDate(session.updatedAt),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ChatController controller, ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Chat"),
        content: Text("Apakah Anda yakin ingin menghapus chat '${session.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              controller.deleteSession(session);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return "Hari ini";
    } else if (difference.inDays == 1) {
      return "Kemarin";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} hari yang lalu";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
