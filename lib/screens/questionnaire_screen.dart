import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/questionnaire_provider.dart';
import '../main.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  ConsumerState<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _cycleLengthController = TextEditingController();
  final _periodLengthController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _cycleLengthController.dispose();
    _periodLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionnaireProvider);

    // Update controllers when state changes
    if (_nameController.text != (state.name ?? '')) {
      _nameController.text = state.name ?? '';
    }
    if (_ageController.text != (state.age?.toString() ?? '')) {
      _ageController.text = state.age?.toString() ?? '';
    }
    if (_weightController.text != (state.weight?.toString() ?? '')) {
      _weightController.text = state.weight?.toString() ?? '';
    }
    if (_heightController.text != (state.height?.toString() ?? '')) {
      _heightController.text = state.height?.toString() ?? '';
    }
    if (_cycleLengthController.text != (state.cycleLength?.toString() ?? '')) {
      _cycleLengthController.text = state.cycleLength?.toString() ?? '';
    }
    if (_periodLengthController.text != (state.periodLength?.toString() ?? '')) {
      _periodLengthController.text = state.periodLength?.toString() ?? '';
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF0F5),
              Color(0xFFFFE4E9),
              Color(0xFFFFC0CB),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(state),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentStep(state),
                ),
              ),
              _buildNavigationButtons(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(QuestionnaireState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${state.currentStep + 1} of 8',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF880E4F),
                ),
              ),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF880E4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[400]!),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(QuestionnaireState state) {
    switch (state.currentStep) {
      case 0:
        return _buildNameStep(state);
      case 1:
        return _buildAgeStep(state);
      case 2:
        return _buildWeightStep(state);
      case 3:
        return _buildHeightStep(state);
      case 4:
        return _buildCycleLengthStep(state);
      case 5:
        return _buildPeriodLengthStep(state);
      case 6:
        return _buildLastPeriodStep(state);
      case 7:
        return _buildHealthConditionsStep(state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep(QuestionnaireState state) {
    return _buildStepContent(
      icon: Icons.person,
      title: 'What is your name?',
      subtitle: 'Let us know how to address you',
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.person_outline, color: Colors.pink[400]),
            ),
            onChanged: (value) {
              ref.read(questionnaireProvider.notifier).setName(value);
            },
          ),
          const SizedBox(height: 16),
          if (state.name != null && state.name!.trim().isEmpty)
            Text(
              'Please enter your name',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildAgeStep(QuestionnaireState state) {
    return _buildStepContent(
      icon: Icons.cake,
      title: 'How old are you?',
      subtitle: 'This helps us provide age-appropriate health insights',
      child: Column(
        children: [
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Age (years)',
              hintText: 'Enter your age',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixText: 'years',
            ),
            onChanged: (value) {
              final age = int.tryParse(value);
              if (age != null) {
                ref.read(questionnaireProvider.notifier).setAge(age);
              }
            },
          ),
          const SizedBox(height: 16),
          if (state.age != null && (state.age! < 10 || state.age! > 100))
            Text(
              'Please enter a valid age between 10 and 100',
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildWeightStep(QuestionnaireState state) {
    return _buildStepContent(
      icon: Icons.monitor_weight,
      title: 'What is your weight?',
      subtitle: 'This helps us calculate health metrics',
      child: TextField(
        controller: _weightController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Weight',
          hintText: 'Enter your weight',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixText: 'kg',
        ),
        onChanged: (value) {
          final weight = double.tryParse(value);
          if (weight != null) {
            ref.read(questionnaireProvider.notifier).setWeight(weight);
          }
        },
      ),
    );
  }

  Widget _buildHeightStep(QuestionnaireState state) {
    return _buildStepContent(
      icon: Icons.height,
      title: 'What is your height?',
      subtitle: 'This helps us calculate your BMI',
      child: TextField(
        controller: _heightController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Height',
          hintText: 'Enter your height',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          suffixText: 'cm',
        ),
        onChanged: (value) {
          final height = double.tryParse(value);
          if (height != null) {
            ref.read(questionnaireProvider.notifier).setHeight(height);
          }
        },
      ),
    );
  }

  Widget _buildCycleLengthStep(QuestionnaireState state) {
    return _buildStepContent(
      icon: Icons.calendar_today,
      title: 'Average cycle length',
      subtitle: 'How many days is your typical menstrual cycle? (21-45 days)',
      child: Column(
        children: [
          TextField(
            controller: _cycleLengthController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cycle Length',
              hintText: 'e.g., 28',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixText: 'days',
            ),
            onChanged: (value) {
              final length = int.tryParse(value);
              if (length != null) {
                ref.read(questionnaireProvider.notifier).setCycleLength(length);
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Typical range: 21-35 days (average is 28)',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodLengthStep(QuestionnaireState state) {
    return _buildStepContent(
      icon: Icons.water_drop,
      title: 'Average period length',
      subtitle: 'How many days does your period typically last? (1-15 days)',
      child: Column(
        children: [
          TextField(
            controller: _periodLengthController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Period Length',
              hintText: 'e.g., 5',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixText: 'days',
            ),
            onChanged: (value) {
              final length = int.tryParse(value);
              if (length != null) {
                ref.read(questionnaireProvider.notifier).setPeriodLength(length);
              }
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Typical range: 3-7 days',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLastPeriodStep(QuestionnaireState state) {
    return _buildStepContent(
      icon: Icons.event,
      title: 'When did your last period start?',
      subtitle: 'This helps us predict your next cycle',
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: state.lastPeriodStart ?? DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 90)),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            ref.read(questionnaireProvider.notifier).setLastPeriodStart(date);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.pink[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.lastPeriodStart != null
                      ? DateFormat('MMMM d, yyyy').format(state.lastPeriodStart!)
                      : 'Select a date',
                  style: TextStyle(
                    fontSize: 16,
                    color: state.lastPeriodStart != null
                        ? Colors.black87
                        : Colors.grey[500],
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthConditionsStep(QuestionnaireState state) {
    return _buildStepContent(
      icon: Icons.health_and_safety,
      title: 'Any health conditions?',
      subtitle: 'Select all that apply (optional)',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: healthConditionsList.map((condition) {
          final isSelected = state.healthConditions.contains(condition);
          return FilterChip(
            label: Text(condition),
            selected: isSelected,
            onSelected: (_) {
              ref.read(questionnaireProvider.notifier).toggleHealthCondition(condition);
            },
            selectedColor: Colors.pink[100],
            checkmarkColor: Colors.pink[700],
            backgroundColor: Colors.white,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepContent({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.pink[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: Colors.pink[700]),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF880E4F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        child,
      ],
    );
  }

  Widget _buildNavigationButtons(QuestionnaireState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(questionnaireProvider.notifier).previousStep();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.pink[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.pink[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: state.canProceed
                    ? () async {
                        if (state.currentStep < 7) {
                          ref.read(questionnaireProvider.notifier).nextStep();
                        } else {
                          final success = await ref
                              .read(questionnaireProvider.notifier)
                              .submitQuestionnaire();
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile saved successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Navigate directly to home page
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const MainScaffold()),
                              (route) => false,
                            );
                          }
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        state.currentStep < 7 ? 'Next' : 'Complete',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
