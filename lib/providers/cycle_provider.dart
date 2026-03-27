import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cycle_entry.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';

final cycleListProvider = StateNotifierProvider<CycleListNotifier, AsyncValue<List<CycleEntry>>>((ref) {
  final user = ref.watch(authProvider);
  return CycleListNotifier(user);
});

class CycleListNotifier extends StateNotifier<AsyncValue<List<CycleEntry>>> {
  final User? _user;
  final SyncService _syncService = SyncService();

  CycleListNotifier(this._user) : super(const AsyncValue.loading()) {
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    if (_user == null) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }
    try {
      final cycles = await _syncService.loadCycles(_user.id);
      if (mounted) state = AsyncValue.data(cycles);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCycle(CycleEntry cycle) async {
    if (_user == null) return;
    try {
      await _syncService.syncCycleEntry(cycle, _user.id);
      
      // Reload to ensure consistency
      if (mounted) await _loadCycles();
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateCycle(CycleEntry cycle) async {
    if (_user == null) return;
    try {
      await _syncService.syncCycleEntry(cycle, _user.id);
      
      if (mounted) await _loadCycles();
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCycle(DateTime startDate) async {
    if (_user == null) return;
    try {
      await _syncService.deleteCycleEntry(startDate, _user.id);
      
      if (mounted) await _loadCycles();
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }
}
