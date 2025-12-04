import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/cycle_entry.dart';
import '../services/hive_service.dart';

class DataSeeder {
  static Future<void> seedUserData(String userId) async {
    final List<CycleEntry> entries = [];

    // Helper to create cycle
    void addCycle(int year, int month, int day, [int? endDay]) {
      final start = DateTime(year, month, day);
      final end = endDay != null ? DateTime(year, month, endDay) : start.add(const Duration(days: 4)); // Default 5 days
      entries.add(CycleEntry(
        startDate: start,
        endDate: end,
        flowLevel: 'Medium',
        symptoms: [],
        mood: [],
      ));
    }

    // Year 2024
    addCycle(2024, 1, 22); // Jan 22
    addCycle(2024, 2, 18); // Feb 18
    addCycle(2024, 3, 18, 23); // March 18-23
    addCycle(2024, 4, 14, 19); // April 14-19
    addCycle(2024, 5, 17); // May 17
    addCycle(2024, 6, 15); // June 15
    addCycle(2024, 7, 9); // July 9
    addCycle(2024, 8, 6); // August 6
    addCycle(2024, 9, 4, 8); // September 4-8
    addCycle(2024, 10, 26); // October 26
    // Nov missed?
    addCycle(2024, 12, 14); // Dec 14

    // Year 2025
    addCycle(2025, 1, 11, 15); // Jan 11-15
    addCycle(2025, 2, 6); // Feb 6
    addCycle(2025, 3, 5); // March 5
    addCycle(2025, 4, 27); // April 27
    addCycle(2025, 5, 22); // May 22
    addCycle(2025, 6, 19); // June 19
    addCycle(2025, 7, 13); // July 13
    addCycle(2025, 8, 6); // Aug 6
    // Sept missed?
    addCycle(2025, 10, 4); // Oct 4
    addCycle(2025, 10, 31); // Oct 31

    debugPrint('Seeding ${entries.length} cycles...');

    // Clear existing and add new
    final box = Hive.box<CycleEntry>(HiveService.cyclesBox);
    await box.clear();
    
    for (var entry in entries) {
      await HiveService.saveCycle(entry);
    }
    
    debugPrint('Seeding complete!');
  }
}
