import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_settings.dart';
import '../models/cycle_entry.dart';
import '../models/predictions.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class HiveService {
  static const String userSettingsBox = 'user_settings';
  static const String cyclesBox = 'cycles';
  static const String predictionsBox = 'predictions';
  static const String chatMessagesBox = 'chat_messages';
  static const String userProfileBox = 'user_profile';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(UserSettingsAdapter());
    Hive.registerAdapter(CycleEntryAdapter());
    Hive.registerAdapter(PredictionsAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    
    // Open boxes
    await Hive.openBox<UserSettings>(userSettingsBox);
    await Hive.openBox<CycleEntry>(cyclesBox);
    await Hive.openBox<Predictions>(predictionsBox);
    await Hive.openBox<ChatMessage>(chatMessagesBox);
    await Hive.openBox<UserProfile>(userProfileBox);
  }

  // User Settings
  static Future<void> saveUserSettings(UserSettings settings) async {
    final box = Hive.box<UserSettings>(userSettingsBox);
    await box.put('current', settings);
  }

  static UserSettings? getUserSettings() {
    final box = Hive.box<UserSettings>(userSettingsBox);
    return box.get('current');
  }

  // Cycles
  static Future<void> saveCycle(CycleEntry cycle) async {
    final box = Hive.box<CycleEntry>(cyclesBox);
    await box.put(cycle.startDate.toIso8601String(), cycle);
  }

  static Future<void> deleteCycle(String key) async {
    final box = Hive.box<CycleEntry>(cyclesBox);
    await box.delete(key);
  }

  static List<CycleEntry> getAllCycles() {
    final box = Hive.box<CycleEntry>(cyclesBox);
    return box.values.toList();
  }

  // Predictions
  static Future<void> savePredictions(Predictions predictions) async {
    final box = Hive.box<Predictions>(predictionsBox);
    await box.put('current', predictions);
  }

  static Predictions? getPredictions() {
    final box = Hive.box<Predictions>(predictionsBox);
    return box.get('current');
  }

  static Future<void> clearAll() async {
    await Hive.box<UserSettings>(userSettingsBox).clear();
    await Hive.box<CycleEntry>(cyclesBox).clear();
    await Hive.box<Predictions>(predictionsBox).clear();
    await Hive.box<ChatMessage>(chatMessagesBox).clear();
    await Hive.box<UserProfile>(userProfileBox).clear();
  }

  // User Profile
  static Future<void> saveUserProfile(UserProfile profile) async {
    final box = Hive.box<UserProfile>(userProfileBox);
    await box.put(profile.userId, profile);
  }

  static UserProfile? getUserProfile(String userId) {
    final box = Hive.box<UserProfile>(userProfileBox);
    return box.get(userId);
  }

  static Future<void> deleteUserProfile(String userId) async {
    final box = Hive.box<UserProfile>(userProfileBox);
    await box.delete(userId);
  }

  // Chat Messages
  static Future<List<ChatMessage>> getChatMessages() async {
    final box = Hive.box<ChatMessage>(chatMessagesBox);
    return box.values.toList();
  }

  static Future<void> saveChatMessages(List<ChatMessage> messages) async {
    final box = Hive.box<ChatMessage>(chatMessagesBox);
    await box.clear();
    for (var i = 0; i < messages.length; i++) {
      await box.put(messages[i].id, messages[i]);
    }
  }

  static Future<void> clearChatMessages() async {
    final box = Hive.box<ChatMessage>(chatMessagesBox);
    await box.clear();
  }
}
