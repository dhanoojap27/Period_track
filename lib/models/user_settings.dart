import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 0)
class UserSettings {
  @HiveField(0)
  final int cycleLength;
  @HiveField(1)
  final int periodLength;
  @HiveField(2)
  final DateTime lastPeriodStart;
  @HiveField(3)
  final int age;
  @HiveField(4)
  final double height;
  @HiveField(5)
  final double weight;

  UserSettings({
    required this.cycleLength,
    required this.periodLength,
    required this.lastPeriodStart,
    required this.age,
    required this.height,
    required this.weight,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      cycleLength: json['cycleLength'] as int,
      periodLength: json['periodLength'] as int,
      lastPeriodStart: DateTime.parse(json['lastPeriodStart'] as String),
      age: json['age'] as int,
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cycleLength': cycleLength,
      'periodLength': periodLength,
      'lastPeriodStart': lastPeriodStart.toIso8601String(),
      'age': age,
      'height': height,
      'weight': weight,
    };
  }

  UserSettings copyWith({
    int? cycleLength,
    int? periodLength,
    DateTime? lastPeriodStart,
    int? age,
    double? height,
    double? weight,
  }) {
    return UserSettings(
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }
}
