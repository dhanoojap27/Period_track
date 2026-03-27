import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 4)
class UserProfile {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int age;

  @HiveField(3)
  final double weight;

  @HiveField(4)
  final double height;

  @HiveField(5)
  final int cycleLength;

  @HiveField(6)
  final int periodLength;

  @HiveField(7)
  final DateTime lastPeriodStart;

  @HiveField(8)
  final List<String> healthConditions;

  @HiveField(9)
  final bool isCompleted;

  @HiveField(10)
  final DateTime createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.cycleLength,
    required this.periodLength,
    required this.lastPeriodStart,
    required this.healthConditions,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '',
      age: json['age'] as int,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      cycleLength: json['cycle_length'] as int,
      periodLength: json['period_length'] as int,
      lastPeriodStart: DateTime.parse(json['last_period_start'] as String),
      healthConditions: List<String>.from(json['health_conditions'] as List),
      isCompleted: json['is_completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'last_period_start': lastPeriodStart.toIso8601String(),
      'health_conditions': healthConditions,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'cycle_length': cycleLength,
      'period_length': periodLength,
      'last_period_start': lastPeriodStart.toIso8601String(),
      'health_conditions': healthConditions,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    int? age,
    double? weight,
    double? height,
    int? cycleLength,
    int? periodLength,
    DateTime? lastPeriodStart,
    List<String>? healthConditions,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      healthConditions: healthConditions ?? this.healthConditions,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
