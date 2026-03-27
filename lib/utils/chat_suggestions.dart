import '../models/chat_message.dart';

class ChatSuggestion {
  final String text;
  final String icon;

  const ChatSuggestion({
    required this.text,
    required this.icon,
  });
}

class ChatSuggestions {
  static const List<ChatSuggestion> assistantSuggestions = [
    ChatSuggestion(
      text: 'When is my next period?',
      icon: '📅',
    ),
    ChatSuggestion(
      text: 'Explain my cycle pattern',
      icon: '📊',
    ),
    ChatSuggestion(
      text: 'How to track symptoms?',
      icon: '📝',
    ),
    ChatSuggestion(
      text: 'What is my fertile window?',
      icon: '🌸',
    ),
    ChatSuggestion(
      text: 'Tips for period cramps',
      icon: '💆',
    ),
    ChatSuggestion(
      text: 'How accurate are predictions?',
      icon: '🎯',
    ),
  ];

  static const List<ChatSuggestion> doctorSuggestions = [
    ChatSuggestion(
      text: 'Is my cycle length normal?',
      icon: '⏱️',
    ),
    ChatSuggestion(
      text: 'What could cause irregular periods?',
      icon: '🔍',
    ),
    ChatSuggestion(
      text: 'When should I see a doctor?',
      icon: '👩‍⚕️',
    ),
    ChatSuggestion(
      text: 'Common causes of heavy bleeding',
      icon: '🩸',
    ),
    ChatSuggestion(
      text: 'Understanding PMS symptoms',
      icon: '😌',
    ),
    ChatSuggestion(
      text: 'Fertility basics explained',
      icon: '🥚',
    ),
  ];

  static List<ChatSuggestion> getSuggestions(ChatMode mode) {
    return mode == ChatMode.doctor ? doctorSuggestions : assistantSuggestions;
  }
}
