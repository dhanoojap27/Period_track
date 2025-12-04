import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_settings.dart';
import '../models/cycle_entry.dart';
import '../models/predictions.dart';

class HiveService {
  static const String userSettingsBox = 'user_settings';
  static const String cyclesBox = 'cycles';
  static const String predictionsBox = 'predictions';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(UserSettingsAdapter());
    Hive.registerAdapter(CycleEntryAdapter());
    Hive.registerAdapter(PredictionsAdapter());
    
    // Open boxes
    await Hive.openBox<UserSettings>(userSettingsBox);
    await Hive.openBox<CycleEntry>(cyclesBox);
    await Hive.openBox<Predictions>(predictionsBox);
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
  }
}
