import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_settings.dart';
import '../models/cycle_entry.dart';
import '../models/predictions.dart';
import '../supabase_config.dart';
import 'hive_service.dart';

class SyncService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || 
           result.contains(ConnectivityResult.wifi);
  }

  // Sync User Settings
  Future<void> syncUserSettings(UserSettings settings, String userId) async {
    // Save to Hive first (offline support)
    await HiveService.saveUserSettings(settings);
    debugPrint('✅ User settings saved to Hive');
    
    // Try to sync to Supabase if online
    if (await isOnline()) {
      try {
        final data = {
          'user_id': userId,
          ...settings.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        debugPrint('🔄 Syncing to Supabase: $data');
        
        await SupabaseConfig.client
            .from('user_settings')
            .upsert(data);
        debugPrint('✅ User settings synced to Supabase');
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to sync user settings to Supabase: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    } else {
      debugPrint('📴 Offline - saved to Hive only');
    }
  }

  Future<UserSettings?> loadUserSettings(String userId) async {
    // Try to load from Supabase if online
    if (await isOnline()) {
      try {
        final response = await SupabaseConfig.client
            .from('user_settings')
            .select()
            .eq('user_id', userId)
            .single();
        
        if (response != null) {
          final settings = UserSettings.fromJson(response);
          await HiveService.saveUserSettings(settings);
          return settings;
        }
      } catch (e) {
        debugPrint('Failed to load user settings from Supabase: $e');
      }
    }
    
    // Fallback to Hive
    return HiveService.getUserSettings();
  }

  // Sync Cycle Entry
  Future<void> syncCycleEntry(CycleEntry cycle, String userId) async {
    // Save to Hive first
    await HiveService.saveCycle(cycle);
    debugPrint('✅ Cycle saved to Hive: ${cycle.startDate}');
    
    // Try to sync to Supabase if online
    if (await isOnline()) {
      try {
        final data = {
          'user_id': userId,
          ...cycle.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        debugPrint('🔄 Syncing cycle to Supabase: $data');
        
        await SupabaseConfig.client
            .from('cycles')
            .upsert(data);
        debugPrint('✅ Cycle synced to Supabase');
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to sync cycle to Supabase: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    } else {
      debugPrint('📴 Offline - cycle saved to Hive only');
    }
  }

  Future<List<CycleEntry>> loadCycles(String userId) async {
    // Try to load from Supabase if online
    if (await isOnline()) {
      try {
        final response = await SupabaseConfig.client
            .from('cycles')
            .select()
            .eq('user_id', userId)
            .order('startDate', ascending: false);
        
        final cycles = (response as List)
            .map((data) => CycleEntry.fromJson(data))
            .toList();
        
        // Update Hive cache
        for (var cycle in cycles) {
          await HiveService.saveCycle(cycle);
        }
        
        debugPrint('✅ Loaded ${cycles.length} cycles from Supabase');
        return cycles;
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to load cycles from Supabase: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    
    // Fallback to Hive
    final cycles = HiveService.getAllCycles();
    debugPrint('📴 Loaded ${cycles.length} cycles from Hive (offline)');
    return cycles;
  }

  Future<void> deleteCycleEntry(DateTime startDate, String userId) async {
    final key = startDate.toIso8601String();
    
    // Delete from Hive
    await HiveService.deleteCycle(key);
    debugPrint('✅ Cycle deleted from Hive: $key');
    
    // Try to delete from Supabase if online
    if (await isOnline()) {
      try {
        await SupabaseConfig.client
            .from('cycles')
            .delete()
            .eq('user_id', userId)
            .eq('startDate', key);
        debugPrint('✅ Cycle deleted from Supabase');
      } catch (e, stackTrace) {
        debugPrint('❌ Failed to delete cycle from Supabase: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  // Sync Predictions
  Future<void> syncPredictions(Predictions predictions, String userId) async {
    // Save to Hive first
    await HiveService.savePredictions(predictions);
    
    // Try to sync to Supabase if online
    if (await isOnline()) {
      try {
        await SupabaseConfig.client
            .from('predictions')
            .upsert({
              'user_id': userId,
              ...predictions.toJson(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      } catch (e) {
        debugPrint('Failed to sync predictions to Supabase: $e');
      }
    }
  }

  Future<Predictions?> loadPredictions(String userId) async {
    // Try to load from Supabase if online
    if (await isOnline()) {
      try {
        final response = await SupabaseConfig.client
            .from('predictions')
            .select()
            .eq('user_id', userId)
            .single();
        
        if (response != null) {
          final predictions = Predictions.fromJson(response);
          await HiveService.savePredictions(predictions);
          return predictions;
        }
      } catch (e) {
        debugPrint('Failed to load predictions from Supabase: $e');
      }
    }
    
    // Fallback to Hive
    return HiveService.getPredictions();
  }

  // Sync all data when coming back online
  Future<void> syncAll(String userId) async {
    if (!await isOnline()) return;
    
    try {
      // Sync user settings
      final settings = HiveService.getUserSettings();
      if (settings != null) {
        await syncUserSettings(settings, userId);
      }
      
      // Sync cycles
      final cycles = HiveService.getAllCycles();
      for (var cycle in cycles) {
        await syncCycleEntry(cycle, userId);
      }
      
      // Sync predictions
      final predictions = HiveService.getPredictions();
      if (predictions != null) {
        await syncPredictions(predictions, userId);
      }
    } catch (e) {
      debugPrint('Failed to sync all data: $e');
    }
  }
}
