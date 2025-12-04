import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/cycle_provider.dart';
import '../providers/prediction_provider.dart';
import '../models/cycle_entry.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(cycleListProvider);
    final predictionsAsync = ref.watch(predictionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: cyclesAsync.when(
        data: (cycles) => predictionsAsync.when(
          data: (predictions) => _buildCalendar(cycles, predictions),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildCalendar(List<CycleEntry> cycles, predictions) {
    return Column(
      children: [
        // Calendar
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFD81B60),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, cycles, predictions);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, cycles, predictions, isToday: true);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(day, cycles, predictions, isSelected: true);
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD81B60),
              ),
            ),
          ),
        ),
        
        // Legend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildLegendItem('Period', Colors.red),
              _buildLegendItem('Fertile', Colors.green),
              _buildLegendItem('Ovulation', Colors.blue),
              _buildLegendItem('Predicted', Colors.red.withValues(alpha: 0.3)),
            ],
          ),
        ),
        
        const Divider(),
        
        // Cycle History Timeline
        Expanded(
          child: _buildCycleHistory(cycles),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, List<CycleEntry> cycles, predictions, {bool isToday = false, bool isSelected = false}) {
    Color? backgroundColor;
    Color? borderColor;
    bool isPredicted = false;

    // Check if day is in a period (actual)
    for (var cycle in cycles) {
      if (cycle.endDate != null) {
        if (day.isAfter(cycle.startDate.subtract(const Duration(days: 1))) &&
            day.isBefore(cycle.endDate!.add(const Duration(days: 1)))) {
          backgroundColor = Colors.red;
          break;
        }
      } else if (isSameDay(day, cycle.startDate)) {
        backgroundColor = Colors.red;
        break;
      }
    }

    // Check predictions if no actual data
    if (backgroundColor == null && predictions != null) {
      // Predicted period
      final predictedPeriodEnd = predictions.nextPeriod.add(const Duration(days: 5));
      if (day.isAfter(predictions.nextPeriod.subtract(const Duration(days: 1))) &&
          day.isBefore(predictedPeriodEnd.add(const Duration(days: 1)))) {
        backgroundColor = Colors.red.withValues(alpha: 0.3);
        isPredicted = true;
      }
      
      // Fertile window
      if (day.isAfter(predictions.fertileStart.subtract(const Duration(days: 1))) &&
          day.isBefore(predictions.fertileEnd.add(const Duration(days: 1)))) {
        backgroundColor = isPredicted ? backgroundColor : Colors.green.withValues(alpha: 0.5);
      }
      
      // Ovulation day
      if (isSameDay(day, predictions.ovulationDay)) {
        backgroundColor = Colors.blue;
      }
    }

    if (isSelected) {
      borderColor = const Color(0xFFD81B60);
    } else if (isToday) {
      borderColor = const Color(0xFFFF6B9D);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: backgroundColor != null ? Colors.white : Colors.black87,
            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCycleHistory(List<CycleEntry> cycles) {
    if (cycles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No cycle history yet.\nStart logging your periods!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cycles.length,
      itemBuilder: (context, index) {
        final cycle = cycles[index];
        final duration = cycle.endDate != null
            ? cycle.endDate!.difference(cycle.startDate).inDays + 1
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.water_drop,
                color: Color(0xFFD81B60),
              ),
            ),
            title: Text(
              DateFormat('MMM dd, yyyy').format(cycle.startDate),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cycle.endDate != null)
                  Text('Duration: $duration days')
                else
                  const Text('Ongoing'),
                if (cycle.flowLevel.isNotEmpty)
                  Text('Flow: ${cycle.flowLevel}'),
              ],
            ),
            trailing: cycle.endDate != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.pending, color: Colors.orange),
          ),
        );
      },
    );
  }
}
