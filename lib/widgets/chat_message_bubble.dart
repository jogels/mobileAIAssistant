import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_message.dart';
import 'ai_avatar.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser && showAvatar) ...[
            AIAvatar(
              size: 32,
              isAnimating: false,
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Colors.blue.shade500
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(message.isUser ? 18 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white 
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ).animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
                
                const SizedBox(height: 4),
                
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey.shade600,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return "Baru saja";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes}m yang lalu";
    } else if (difference.inDays < 1) {
      return "${difference.inHours}h yang lalu";
    } else {
      return "${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
    }
  }
}
