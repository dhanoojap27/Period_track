import 'package:flutter_test/flutter_test.dart';
import 'package:mensuration_tracker/models/user_settings.dart';
import 'package:mensuration_tracker/models/cycle_entry.dart';
import 'package:mensuration_tracker/models/predictions.dart';

void main() {
  group('UserSettings', () {
    test('fromJson and toJson work correctly', () {
      final settings = UserSettings(
        cycleLength: 28,
        periodLength: 5,
        lastPeriodStart: DateTime(2023, 10, 1),
        age: 25,
        height: 165.5,
        weight: 60.0,
      );

      final json = settings.toJson();
      final fromJson = UserSettings.fromJson(json);

      expect(fromJson.cycleLength, settings.cycleLength);
      expect(fromJson.periodLength, settings.periodLength);
      expect(fromJson.lastPeriodStart, settings.lastPeriodStart);
      expect(fromJson.age, settings.age);
      expect(fromJson.height, settings.height);
      expect(fromJson.weight, settings.weight);
    });

    test('copyWith works correctly', () {
      final settings = UserSettings(
        cycleLength: 28,
        periodLength: 5,
        lastPeriodStart: DateTime(2023, 10, 1),
        age: 25,
        height: 165.5,
        weight: 60.0,
      );

      final newSettings = settings.copyWith(cycleLength: 30);
      expect(newSettings.cycleLength, 30);
      expect(newSettings.periodLength, 5);
    });
  });

  group('CycleEntry', () {
    test('fromJson and toJson work correctly', () {
      final entry = CycleEntry(
        startDate: DateTime(2023, 10, 1),
        endDate: DateTime(2023, 10, 5),
        symptoms: ['Cramps', 'Headache'],
        mood: ['Happy'],
        flowLevel: 'Medium',
      );

      final json = entry.toJson();
      final fromJson = CycleEntry.fromJson(json);

      expect(fromJson.startDate, entry.startDate);
      expect(fromJson.endDate, entry.endDate);
      expect(fromJson.symptoms, entry.symptoms);
      expect(fromJson.mood, entry.mood);
      expect(fromJson.flowLevel, entry.flowLevel);
    });
  });

  group('Predictions', () {
    test('fromJson and toJson work correctly', () {
      final predictions = Predictions(
        nextPeriod: DateTime(2023, 11, 1),
        ovulationDay: DateTime(2023, 10, 15),
        fertileStart: DateTime(2023, 10, 12),
        fertileEnd: DateTime(2023, 10, 16),
      );

      final json = predictions.toJson();
      final fromJson = Predictions.fromJson(json);

      expect(fromJson.nextPeriod, predictions.nextPeriod);
      expect(fromJson.ovulationDay, predictions.ovulationDay);
      expect(fromJson.fertileStart, predictions.fertileStart);
      expect(fromJson.fertileEnd, predictions.fertileEnd);
    });
  });
}
