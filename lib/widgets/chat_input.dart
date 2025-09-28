import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isLoading;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.isLoading = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty && !widget.isLoading) {
      widget.onSendMessage(message);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: "Tulis pesan Anda...",
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Send button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade500,
                    Colors.purple.shade500,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: widget.isLoading ? null : _sendMessage,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                            .rotate(duration: 1000.ms)
                        : Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ).animate(target: _controller.text.isNotEmpty ? 1 : 0)
                            .scale(duration: 200.ms, curve: Curves.easeInOut),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
