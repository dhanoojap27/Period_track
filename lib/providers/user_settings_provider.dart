import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_settings.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';

final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, AsyncValue<UserSettings?>>((ref) {
  final user = ref.watch(authProvider);
  return UserSettingsNotifier(user);
});

class UserSettingsNotifier extends StateNotifier<AsyncValue<UserSettings?>> {
  final User? _user;
  final SyncService _syncService = SyncService();

  UserSettingsNotifier(this._user) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Use authenticated user ID if available, otherwise use demo_user for testing
      final userId = _user?.uid ?? 'demo_user';
      final settings = await _syncService.loadUserSettings(userId);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveSettings(UserSettings settings) async {
    state = const AsyncValue.loading();
    try {
      // Use authenticated user ID if available, otherwise use demo_user for testing
      final userId = _user?.uid ?? 'demo_user';
      await _syncService.syncUserSettings(settings, userId);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Re-throw so the UI can show the error
    }
  }
  
  Future<void> updateSettings(UserSettings settings) async {
      await saveSettings(settings);
  }
}
