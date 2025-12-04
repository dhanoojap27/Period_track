import 'package:hive/hive.dart';

part 'cycle_entry.g.dart';

@HiveType(typeId: 1)
class CycleEntry {
  @HiveField(0)
  final DateTime startDate;
  @HiveField(1)
  final DateTime? endDate;
  @HiveField(2)
  final List<String> symptoms;
  @HiveField(3)
  final List<String> mood;
  @HiveField(4)
  final String flowLevel;

  CycleEntry({
    required this.startDate,
    this.endDate,
    required this.symptoms,
    required this.mood,
    required this.flowLevel,
  });

  factory CycleEntry.fromJson(Map<String, dynamic> json) {
    return CycleEntry(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      symptoms: List<String>.from(json['symptoms'] as List),
      mood: List<String>.from(json['mood'] as List),
      flowLevel: json['flowLevel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'symptoms': symptoms,
      'mood': mood,
      'flowLevel': flowLevel,
    };
  }

  CycleEntry copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? symptoms,
    List<String>? mood,
    String? flowLevel,
  }) {
    return CycleEntry(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      symptoms: symptoms ?? this.symptoms,
      mood: mood ?? this.mood,
      flowLevel: flowLevel ?? this.flowLevel,
    );
  }
}
