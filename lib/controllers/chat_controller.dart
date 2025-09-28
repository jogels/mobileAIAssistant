import 'package:get/get.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatController extends GetxController {
  // Observable variables
  var currentSession = Rxn<ChatSession>();
  var chatSessions = <ChatSession>[].obs;
  var isLoading = false.obs;
  var isSidebarOpen = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
  }

  void _initializeChat() {
    // Buat session baru untuk memulai chat
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Chat Baru",
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    currentSession.value = newSession;
    chatSessions.add(newSession);
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Tambahkan pesan user
    currentSession.value?.messages.add(userMessage);
    currentSession.refresh();

    // Simulasi response AI (nanti bisa diganti dengan API call)
    _simulateAIResponse(content);
  }

  void _simulateAIResponse(String userMessage) {
    isLoading.value = true;
    
    // Simulasi delay AI response
    Future.delayed(const Duration(seconds: 2), () {
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "Ini adalah response simulasi AI untuk: '$userMessage'. Fitur ini akan diintegrasikan dengan API AI yang sesungguhnya.",
        isUser: false,
        timestamp: DateTime.now(),
      );

      currentSession.value?.messages.add(aiMessage);
      currentSession.refresh();
      isLoading.value = false;
    });
  }

  void createNewSession() {
    final newSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "Chat Baru",
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    currentSession.value = newSession;
    chatSessions.add(newSession);
    isSidebarOpen.value = false;
  }

  void switchToSession(ChatSession session) {
    currentSession.value = session;
    isSidebarOpen.value = false;
  }

  void deleteSession(ChatSession session) {
    chatSessions.remove(session);
    if (currentSession.value?.id == session.id) {
      if (chatSessions.isNotEmpty) {
        currentSession.value = chatSessions.first;
      } else {
        createNewSession();
      }
    }
  }

  void toggleSidebar() {
    isSidebarOpen.value = !isSidebarOpen.value;
  }
}
