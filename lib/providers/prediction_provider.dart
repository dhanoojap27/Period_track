import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/predictions.dart';
import '../models/cycle_entry.dart';
import '../models/user_settings.dart';
import '../services/sync_service.dart';
import '../services/prediction_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

final predictionProvider = StateNotifierProvider<PredictionNotifier, AsyncValue<Predictions?>>((ref) {
  final user = ref.watch(authProvider);
  return PredictionNotifier(user);
});

class PredictionNotifier extends StateNotifier<AsyncValue<Predictions?>> {
  final User? _user;
  final SyncService _syncService = SyncService();

  PredictionNotifier(this._user) : super(const AsyncValue.loading()) {
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    if (_user == null) {
      if (mounted) state = const AsyncValue.data(null);
      return;
    }
    try {
      final predictions = await _syncService.loadPredictions(_user.id);
      if (mounted) state = AsyncValue.data(predictions);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> calculateAndSavePredictions(
    List<CycleEntry> cycles,
    UserSettings settings,
  ) async {
    if (_user == null) return;
    
    try {
      final predictions = PredictionService.calculatePredictions(cycles, settings);
      
      await _syncService.syncPredictions(predictions, _user.id);
      if (mounted) state = AsyncValue.data(predictions);
      
      // Schedule Notifications
      await _scheduleReminders(predictions);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> _scheduleReminders(Predictions predictions) async {
    if (kIsWeb) return; // Skip notifications on web
    await NotificationService.cancelAllNotifications();

    // Period Reminder (2 days before)
    final periodReminderDate = predictions.nextPeriod.subtract(const Duration(days: 2));
    if (periodReminderDate.isAfter(DateTime.now())) {
      await NotificationService.scheduleNotification(
        id: 1,
        title: 'Period Coming Soon',
        body: 'Your period is predicted to start in 2 days.',
        scheduledDate: periodReminderDate,
      );
    }

    // Fertile Window Reminder
    if (predictions.fertileStart.isAfter(DateTime.now())) {
      await NotificationService.scheduleNotification(
        id: 2,
        title: 'Fertile Window Starting',
        body: 'Your fertile window starts today.',
        scheduledDate: predictions.fertileStart,
      );
    }

    // Ovulation Reminder
    if (predictions.ovulationDay.isAfter(DateTime.now())) {
      await NotificationService.scheduleNotification(
        id: 3,
        title: 'Ovulation Day',
        body: 'Today is your predicted ovulation day.',
        scheduledDate: predictions.ovulationDay,
      );
    }
  }

  Future<void> savePredictions(Predictions predictions) async {
    if (_user == null) return;
    if (mounted) state = const AsyncValue.loading();
    try {
      await _syncService.syncPredictions(predictions, _user.id);
      if (mounted) state = AsyncValue.data(predictions);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> updatePredictions(Predictions predictions) async {
      await savePredictions(predictions);
  }
}
