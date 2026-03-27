import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/chat_service.dart';
import '../services/hive_service.dart';
import 'auth_provider.dart';
import 'cycle_provider.dart';
import 'prediction_provider.dart';
import 'user_settings_provider.dart';

// Chat service provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService();
  service.initialize();
  return service;
});

// Chat messages state
class ChatState {
  final List<ChatMessage> messages;
  final ChatMode currentMode;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.currentMode = ChatMode.assistant,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatMode? currentMode,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      currentMode: currentMode ?? this.currentMode,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<ChatMessage> get messagesForCurrentMode {
    return messages.where((m) => m.chatMode == currentMode.name).toList();
  }
}

// Chat notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final ChatService _chatService;
  final _uuid = const Uuid();

  ChatNotifier(this._ref, this._chatService) : super(const ChatState()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await HiveService.getChatMessages();
      state = state.copyWith(messages: messages);
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
    }
  }

  Future<void> _saveMessages() async {
    try {
      await HiveService.saveChatMessages(state.messages);
    } catch (e) {
      debugPrint('Error saving chat messages: $e');
    }
  }

  void setMode(ChatMode mode) {
    if (state.currentMode != mode) {
      state = state.copyWith(currentMode: mode, error: null);
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
      chatMode: state.currentMode.name,
    );

    // Add user message immediately
    final updatedMessages = [...state.messages, userMessage];
    state = state.copyWith(messages: updatedMessages, isLoading: true, error: null);
    await _saveMessages();

    try {
      // Get context data
      final cyclesAsync = _ref.read(cycleListProvider);
      final cycles = cyclesAsync.hasValue ? cyclesAsync.value : null;
      final predictions = _ref.read(predictionProvider).valueOrNull;
      final settings = _ref.read(userSettingsProvider).valueOrNull;
      
      // Get user profile for name
      final user = _ref.read(authProvider);
      UserProfile? userProfile;
      if (user != null) {
        userProfile = HiveService.getUserProfile(user.id);
      }

      // Send to AI
      final response = await _chatService.sendMessage(
        message: content,
        mode: state.currentMode,
        chatHistory: state.messagesForCurrentMode,
        cycles: cycles,
        predictions: predictions,
        settings: settings,
        userProfile: userProfile,
      );

      // Add AI response
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
        chatMode: state.currentMode.name,
      );

      final finalMessages = [...state.messages, aiMessage];
      state = state.copyWith(messages: finalMessages, isLoading: false);
      await _saveMessages();
    } catch (e) {
      debugPrint('Error in chat: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get response. Please try again.',
      );
    }
  }

  Future<void> clearChat() async {
    final filteredMessages = state.messages
        .where((m) => m.chatMode != state.currentMode.name)
        .toList();
    state = state.copyWith(messages: filteredMessages);
    await _saveMessages();
    _chatService.clearSessions();
  }

  Future<void> clearAllChats() async {
    state = state.copyWith(messages: []);
    await HiveService.clearChatMessages();
    _chatService.clearSessions();
  }
}

// Main chat provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(ref, chatService);
});
