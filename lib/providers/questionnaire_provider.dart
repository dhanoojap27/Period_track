import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import '../models/cycle_entry.dart';
import '../services/hive_service.dart';
import '../supabase_config.dart';
import 'auth_provider.dart';
import 'user_settings_provider.dart';
import 'cycle_provider.dart';

// Questionnaire state
class QuestionnaireState {
  final int currentStep;
  final String? name;
  final int? age;
  final double? weight;
  final double? height;
  final int? cycleLength;
  final int? periodLength;
  final DateTime? lastPeriodStart;
  final List<String> healthConditions;
  final bool isLoading;
  final bool isCompleted;
  final String? error;

  const QuestionnaireState({
    this.currentStep = 0,
    this.name,
    this.age,
    this.weight,
    this.height,
    this.cycleLength,
    this.periodLength,
    this.lastPeriodStart,
    this.healthConditions = const [],
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
  });

  QuestionnaireState copyWith({
    int? currentStep,
    String? name,
    int? age,
    double? weight,
    double? height,
    int? cycleLength,
    int? periodLength,
    DateTime? lastPeriodStart,
    List<String>? healthConditions,
    bool? isLoading,
    bool? isCompleted,
    String? error,
  }) {
    return QuestionnaireState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      healthConditions: healthConditions ?? this.healthConditions,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error,
    );
  }

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return name != null && name!.trim().isNotEmpty;
      case 1:
        return age != null && age! >= 10 && age! <= 100;
      case 2:
        return weight != null && weight! > 0;
      case 3:
        return height != null && height! > 0;
      case 4:
        return cycleLength != null && cycleLength! >= 21 && cycleLength! <= 45;
      case 5:
        return periodLength != null && periodLength! >= 1 && periodLength! <= 15;
      case 6:
        return lastPeriodStart != null;
      case 7:
        return true; // Health conditions are optional
      default:
        return false;
    }
  }

  double get progress => (currentStep + 1) / 8;
}

// Questionnaire notifier
class QuestionnaireNotifier extends StateNotifier<QuestionnaireState> {
  final Ref _ref;

  QuestionnaireNotifier(this._ref) : super(const QuestionnaireState());

  void nextStep() {
    if (state.currentStep < 7) {
      state = state.copyWith(currentStep: state.currentStep + 1, error: null);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1, error: null);
    }
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setAge(int age) {
    state = state.copyWith(age: age);
  }

  void setWeight(double weight) {
    state = state.copyWith(weight: weight);
  }

  void setHeight(double height) {
    state = state.copyWith(height: height);
  }

  void setCycleLength(int length) {
    state = state.copyWith(cycleLength: length);
  }

  void setPeriodLength(int length) {
    state = state.copyWith(periodLength: length);
  }

  void setLastPeriodStart(DateTime date) {
    state = state.copyWith(lastPeriodStart: date);
  }

  void toggleHealthCondition(String condition) {
    final currentConditions = List<String>.from(state.healthConditions);
    if (currentConditions.contains(condition)) {
      currentConditions.remove(condition);
    } else {
      currentConditions.add(condition);
    }
    state = state.copyWith(healthConditions: currentConditions);
  }

  Future<bool> submitQuestionnaire() async {
    if (!state.canProceed) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _ref.read(authProvider)?.id;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return false;
      }

      final profile = UserProfile(
        userId: userId,
        name: state.name!,
        age: state.age!,
        weight: state.weight!,
        height: state.height!,
        cycleLength: state.cycleLength!,
        periodLength: state.periodLength!,
        lastPeriodStart: state.lastPeriodStart!,
        healthConditions: state.healthConditions,
        isCompleted: true,
        createdAt: DateTime.now(),
      );

      // Save UserProfile to local storage
      await HiveService.saveUserProfile(profile);

      // Create and save UserSettings for predictions
      final settings = UserSettings(
        cycleLength: state.cycleLength!,
        periodLength: state.periodLength!,
        lastPeriodStart: state.lastPeriodStart!,
        age: state.age!,
        height: state.height!,
        weight: state.weight!,
      );
      
      // Save UserSettings so predictions work
      await _ref.read(userSettingsProvider.notifier).saveSettings(settings);
      debugPrint('UserSettings saved for predictions');

      // Create initial cycle entry from last period data for predictions
      final endDate = state.lastPeriodStart!.add(Duration(days: state.periodLength! - 1));
      final initialCycle = CycleEntry(
        startDate: state.lastPeriodStart!,
        endDate: endDate,
        symptoms: [],
        mood: [],
        flowLevel: 'medium',
      );
      
      // Save initial cycle for predictions
      await _ref.read(cycleListProvider.notifier).addCycle(initialCycle);
      debugPrint('Initial cycle entry created for predictions');

      // Save UserProfile to Supabase if online
      try {
        await SupabaseConfig.client
            .from('user_profiles')
            .upsert(profile.toSupabaseJson());
        debugPrint('Profile saved to Supabase');
      } catch (e) {
        debugPrint('Could not save to Supabase: $e');
        // Continue anyway - data is saved locally
      }

      state = state.copyWith(isLoading: false, isCompleted: true);
      return true;
    } catch (e) {
      debugPrint('Error saving questionnaire: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save profile. Please try again.',
      );
      return false;
    }
  }

  Future<void> checkIfCompleted() async {
    try {
      final userId = _ref.read(authProvider)?.id;
      if (userId == null) return;

      // Check local storage first
      final localProfile = HiveService.getUserProfile(userId);
      if (localProfile != null && localProfile.isCompleted) {
        state = state.copyWith(isCompleted: true);
        return;
      }

      // Check Supabase
      try {
        final response = await SupabaseConfig.client
            .from('user_profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          final profile = UserProfile.fromJson(response);
          await HiveService.saveUserProfile(profile);
          state = state.copyWith(isCompleted: profile.isCompleted);
        }
      } catch (e) {
        debugPrint('Could not check Supabase: $e');
      }
    } catch (e) {
      debugPrint('Error checking questionnaire status: $e');
    }
  }

  void reset() {
    state = const QuestionnaireState();
  }
}

// Provider
final questionnaireProvider =
    StateNotifierProvider<QuestionnaireNotifier, QuestionnaireState>((ref) {
  return QuestionnaireNotifier(ref);
});

// Health conditions list
final healthConditionsList = [
  'PCOS',
  'Endometriosis',
  'Irregular periods',
  'Heavy bleeding',
  'Severe cramps',
  'Thyroid issues',
  'Diabetes',
  'None of the above',
];
