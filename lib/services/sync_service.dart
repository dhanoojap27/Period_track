import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_settings.dart';
import '../models/cycle_entry.dart';
import '../models/predictions.dart';
import 'hive_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    
    // Try to sync to Firestore if online
    if (await isOnline()) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .set(settings.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to sync user settings to Firestore: $e');
      }
    }
  }

  Future<UserSettings?> loadUserSettings(String userId) async {
    // Try to load from Firestore if online
    if (await isOnline()) {
      try {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists && doc.data() != null) {
          final settings = UserSettings.fromJson(doc.data()!);
          await HiveService.saveUserSettings(settings);
          return settings;
        }
      } catch (e) {
        debugPrint('Failed to load user settings from Firestore: $e');
      }
    }
    
    // Fallback to Hive
    return HiveService.getUserSettings();
  }

  // Sync Cycle Entry
  Future<void> syncCycleEntry(CycleEntry cycle, String userId) async {
    // Save to Hive first
    await HiveService.saveCycle(cycle);
    
    // Try to sync to Firestore if online
    if (await isOnline()) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cycles')
            .doc(cycle.startDate.toIso8601String())
            .set(cycle.toJson());
      } catch (e) {
        debugPrint('Failed to sync cycle to Firestore: $e');
      }
    }
  }

  Future<List<CycleEntry>> loadCycles(String userId) async {
    // Try to load from Firestore if online
    if (await isOnline()) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('cycles')
            .orderBy('startDate', descending: true)
            .get();
        
        final cycles = snapshot.docs
            .map((doc) => CycleEntry.fromJson(doc.data()))
            .toList();
        
        // Update Hive cache
        for (var cycle in cycles) {
          await HiveService.saveCycle(cycle);
        }
        
        return cycles;
      } catch (e) {
        debugPrint('Failed to load cycles from Firestore: $e');
      }
    }
    
    // Fallback to Hive
    return HiveService.getAllCycles();
  }

  Future<void> deleteCycleEntry(DateTime startDate, String userId) async {
    final key = startDate.toIso8601String();
    
    // Delete from Hive
    await HiveService.deleteCycle(key);
    
    // Try to delete from Firestore if online
    if (await isOnline()) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cycles')
            .doc(key)
            .delete();
      } catch (e) {
        debugPrint('Failed to delete cycle from Firestore: $e');
      }
    }
  }

  // Sync Predictions
  Future<void> syncPredictions(Predictions predictions, String userId) async {
    // Save to Hive first
    await HiveService.savePredictions(predictions);
    
    // Try to sync to Firestore if online
    if (await isOnline()) {
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('predictions')
            .doc('current')
            .set(predictions.toJson());
      } catch (e) {
        debugPrint('Failed to sync predictions to Firestore: $e');
      }
    }
  }

  Future<Predictions?> loadPredictions(String userId) async {
    // Try to load from Firestore if online
    if (await isOnline()) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('predictions')
            .doc('current')
            .get();
        
        if (doc.exists && doc.data() != null) {
          final predictions = Predictions.fromJson(doc.data()!);
          await HiveService.savePredictions(predictions);
          return predictions;
        }
      } catch (e) {
        debugPrint('Failed to load predictions from Firestore: $e');
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
