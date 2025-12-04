import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/cycle_entry.dart';
import '../providers/cycle_provider.dart';

class LogPeriodScreen extends ConsumerStatefulWidget {
  const LogPeriodScreen({super.key});

  @override
  ConsumerState<LogPeriodScreen> createState() => _LogPeriodScreenState();
}

class _LogPeriodScreenState extends ConsumerState<LogPeriodScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _flowLevel = 'Medium';
  final Set<String> _selectedSymptoms = {};
  double _moodValue = 5.0;
  bool _isSaving = false;

  final List<String> _flowLevels = ['Light', 'Medium', 'Heavy'];
  final List<String> _symptoms = ['Cramps', 'Mood Swings', 'Acne', 'Cravings', 'Headache', 'Fatigue'];
  final Map<double, String> _moodLabels = {
    1: '😢',
    3: '😐',
    5: '🙂',
    7: '😊',
    10: '😄',
  };

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B9D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _savePeriod() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final entry = CycleEntry(
      startDate: _startDate!,
      endDate: _endDate,
      symptoms: _selectedSymptoms.toList(),
      mood: [_moodLabels[_moodValue] ?? '🙂'],
      flowLevel: _flowLevel,
    );

    try {
      await ref.read(cycleListProvider.notifier).addCycle(entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Period logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        setState(() {
          _startDate = null;
          _endDate = null;
          _flowLevel = 'Medium';
          _selectedSymptoms.clear();
          _moodValue = 5.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Period'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            _buildSectionTitle('Period Dates'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateCard(
                    'Start Date',
                    _startDate,
                    () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateCard(
                    'End Date',
                    _endDate,
                    () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Flow Level
            _buildSectionTitle('Flow Level'),
            const SizedBox(height: 12),
            _buildFlowLevelSelector(),
            const SizedBox(height: 24),

            // Symptoms
            _buildSectionTitle('Symptoms'),
            const SizedBox(height: 12),
            _buildSymptomsSelector(),
            const SizedBox(height: 24),

            // Mood
            _buildSectionTitle('Mood'),
            const SizedBox(height: 12),
            _buildMoodSlider(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _savePeriod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B9D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Period',
                        style: TextStyle(
                          fontSize: 18,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFD81B60),
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE4E9), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Select',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: date != null ? Colors.black87 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowLevelSelector() {
    return Row(
      children: _flowLevels.map((level) {
        final isSelected = _flowLevel == level;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _flowLevel = level),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF6B9D) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF6B9D) : const Color(0xFFFFE4E9),
                    width: 2,
                  ),
                ),
                child: Text(
                  level,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSymptomsSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _symptoms.map((symptom) {
        final isSelected = _selectedSymptoms.contains(symptom);
        return FilterChip(
          label: Text(symptom),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSymptoms.add(symptom);
              } else {
                _selectedSymptoms.remove(symptom);
              }
            });
          },
          selectedColor: const Color(0xFFFF6B9D),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFFFF6B9D) : const Color(0xFFFFE4E9),
            width: 2,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMoodSlider() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE4E9), width: 2),
      ),
      child: Column(
        children: [
          Text(
            _moodLabels[_moodValue] ?? '🙂',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _moodValue,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: const Color(0xFFFF6B9D),
            inactiveColor: const Color(0xFFFFE4E9),
            onChanged: (value) {
              setState(() {
                _moodValue = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('😢', style: TextStyle(fontSize: 20, color: Colors.black54)),
              Text('😄', style: TextStyle(fontSize: 20, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
