import 'package:hive/hive.dart';

part 'predictions.g.dart';

@HiveType(typeId: 2)
class Predictions {
  @HiveField(0)
  final DateTime nextPeriod;
  @HiveField(1)
  final DateTime ovulationDay;
  @HiveField(2)
  final DateTime fertileStart;
  @HiveField(3)
  final DateTime fertileEnd;
  @HiveField(4)
  final int confidenceDays; // ± days (e.g., 2 means ±2 days)
  @HiveField(5)
  final double predictedCycleLength; // Predicted cycle length
  @HiveField(6)
  final String trend; // 'stable', 'lengthening', 'shortening'

  Predictions({
    required this.nextPeriod,
    required this.ovulationDay,
    required this.fertileStart,
    required this.fertileEnd,
    this.confidenceDays = 2,
    this.predictedCycleLength = 28.0,
    this.trend = 'stable',
  });

  factory Predictions.fromJson(Map<String, dynamic> json) {
    return Predictions(
      nextPeriod: DateTime.parse(json['nextPeriod'] as String),
      ovulationDay: DateTime.parse(json['ovulationDay'] as String),
      fertileStart: DateTime.parse(json['fertileStart'] as String),
      fertileEnd: DateTime.parse(json['fertileEnd'] as String),
      confidenceDays: json['confidenceDays'] as int? ?? 2,
      predictedCycleLength: (json['predictedCycleLength'] as num?)?.toDouble() ?? 28.0,
      trend: json['trend'] as String? ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nextPeriod': nextPeriod.toIso8601String(),
      'ovulationDay': ovulationDay.toIso8601String(),
      'fertileStart': fertileStart.toIso8601String(),
      'fertileEnd': fertileEnd.toIso8601String(),
      'confidenceDays': confidenceDays,
      'predictedCycleLength': predictedCycleLength,
      'trend': trend,
    };
  }

  Predictions copyWith({
    DateTime? nextPeriod,
    DateTime? ovulationDay,
    DateTime? fertileStart,
    DateTime? fertileEnd,
    int? confidenceDays,
    double? predictedCycleLength,
    String? trend,
  }) {
    return Predictions(
      nextPeriod: nextPeriod ?? this.nextPeriod,
      ovulationDay: ovulationDay ?? this.ovulationDay,
      fertileStart: fertileStart ?? this.fertileStart,
      fertileEnd: fertileEnd ?? this.fertileEnd,
      confidenceDays: confidenceDays ?? this.confidenceDays,
      predictedCycleLength: predictedCycleLength ?? this.predictedCycleLength,
      trend: trend ?? this.trend,
    );
  }
}
