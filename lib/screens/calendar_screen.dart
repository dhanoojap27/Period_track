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
  
  // For range selection (start and end date)
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isSelectingRange = false;

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(cycleListProvider);
    final predictionsAsync = ref.watch(predictionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectingRange)
            TextButton(
              onPressed: _cancelRangeSelection,
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddPeriodDialog(),
              tooltip: 'Add Period',
            ),
        ],
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
      floatingActionButton: _isSelectingRange && _rangeStart != null
          ? FloatingActionButton.extended(
              onPressed: _saveRangeSelection,
              backgroundColor: const Color(0xFFFF6B9D),
              icon: const Icon(Icons.check),
              label: Text(_rangeEnd != null 
                  ? 'Save Period (${_rangeEnd!.difference(_rangeStart!).inDays + 1} days)' 
                  : 'Save Single Day'),
            )
          : null,
    );
  }

  Widget _buildCalendar(List<CycleEntry> cycles, predictions) {
    return Column(
      children: [
        // Range selection hint
        if (_isSelectingRange)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFFFE4E9),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFD81B60)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _rangeStart == null
                        ? 'Tap a date to set period START date'
                        : 'Tap another date to set period END date (or tap same date for single day)',
                    style: const TextStyle(
                      color: Color(0xFFD81B60),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
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
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rangeSelectionMode: _isSelectingRange ? RangeSelectionMode.enforced : RangeSelectionMode.disabled,
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
                  
              if (_isSelectingRange) {
                _handleRangeSelection(selectedDay);
              } else {
                setState(() {
                  _selectedDay = selectedDay;
                });
                _showDayOptions(selectedDay, cycles);
              }
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
              rangeStartDecoration: const BoxDecoration(
                color: Color(0xFFD81B60),
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: Color(0xFFD81B60),
                shape: BoxShape.circle,
              ),
              withinRangeDecoration: BoxDecoration(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                shape: BoxShape.rectangle,
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
              rangeStartBuilder: (context, day, focusedDay) {
                return _buildRangeMarker(day, 'Start', Colors.red);
              },
              rangeEndBuilder: (context, day, focusedDay) {
                return _buildRangeMarker(day, 'End', Colors.red);
              },
              withinRangeBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                );
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

  Widget _buildRangeMarker(DateTime day, String label, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRangeSelection(DateTime selectedDay) {
    setState(() {
      if (_rangeStart == null) {
        // First selection - set start date
        _rangeStart = selectedDay;
        _rangeEnd = null;
      } else {
        // Second selection - set end date
        if (selectedDay.isBefore(_rangeStart!)) {
          // If selected date is before start, swap them
          _rangeEnd = _rangeStart;
          _rangeStart = selectedDay;
        } else {
          _rangeEnd = selectedDay;
        }
      }
    });
  }

  void _cancelRangeSelection() {
    setState(() {
      _isSelectingRange = false;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _saveRangeSelection() async {
    if (_rangeStart == null) return;

    final cycle = CycleEntry(
      startDate: _rangeStart!,
      endDate: _rangeEnd,
      flowLevel: 'medium',
      symptoms: [],
      mood: [],
    );

    await ref.read(cycleListProvider.notifier).addCycle(cycle);

    if (mounted) {
      final days = _rangeEnd != null 
          ? _rangeEnd!.difference(_rangeStart!).inDays + 1 
          : 1;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Period saved: $days day${days > 1 ? 's' : ''} (${DateFormat('MMM dd').format(_rangeStart!)} - ${DateFormat('MMM dd').format(_rangeEnd ?? _rangeStart!)})'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Reset selection mode
    setState(() {
      _isSelectingRange = false;
      _rangeStart = null;
      _rangeEnd = null;
    });
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
            'No cycle history yet.\nStart logging your periods!\n\nTap the + button or select a date on the calendar to add a period.',
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
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditPeriodDialog(cycle);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(cycle);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDayOptions(DateTime selectedDay, List<CycleEntry> cycles) {
    // Check if there's already a period on this day
    CycleEntry? existingCycle;
    for (var cycle in cycles) {
      if (cycle.endDate != null) {
        if (selectedDay.isAfter(cycle.startDate.subtract(const Duration(days: 1))) &&
            selectedDay.isBefore(cycle.endDate!.add(const Duration(days: 1)))) {
          existingCycle = cycle;
          break;
        }
      } else if (isSameDay(selectedDay, cycle.startDate)) {
        existingCycle = cycle;
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(selectedDay),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD81B60),
                ),
              ),
              const SizedBox(height: 20),
              if (existingCycle != null) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFFFF6B9D)),
                  title: const Text('Edit Period'),
                  subtitle: Text('Started: ${DateFormat('MMM d').format(existingCycle.startDate)}'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditPeriodDialog(existingCycle!);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Period', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(existingCycle!);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.date_range, color: Color(0xFFFF6B9D)),
                  title: const Text('Select Period Range (Start & End)'),
                  subtitle: const Text('Tap two dates on calendar'),
                  onTap: () {
                    Navigator.pop(context);
                    _startRangeSelection(selectedDay);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle, color: Color(0xFFFF6B9D)),
                  title: const Text('Add Period with Dialog'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddPeriodDialog(startDate: selectedDay);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.water_drop, color: Color(0xFFD81B60)),
                  title: const Text('Log Single Day Period'),
                  onTap: () {
                    Navigator.pop(context);
                    _addSingleDayPeriod(selectedDay);
                  },
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _startRangeSelection(DateTime startDate) {
    setState(() {
      _isSelectingRange = true;
      _rangeStart = startDate;
      _rangeEnd = null;
    });
  }

  void _showAddPeriodDialog({DateTime? startDate}) {
    DateTime selectedStart = startDate ?? DateTime.now();
    DateTime? selectedEnd;
    String flowLevel = 'medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Period'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Date
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Color(0xFFFF6B9D)),
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedStart)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            selectedStart = date;
                          });
                        }
                      },
                    ),
                    // End Date
                    ListTile(
                      leading: const Icon(Icons.event_available, color: Color(0xFFFF6B9D)),
                      title: const Text('End Date'),
                      subtitle: Text(selectedEnd != null
                          ? DateFormat('MMM dd, yyyy').format(selectedEnd!)
                          : 'Not set (ongoing)'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedEnd ?? selectedStart.add(const Duration(days: 4)),
                          firstDate: selectedStart,
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            selectedEnd = date;
                          });
                        }
                      },
                    ),
                    // Flow Level
                    const SizedBox(height: 16),
                    const Text('Flow Level', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'light', label: Text('Light')),
                        ButtonSegment(value: 'medium', label: Text('Medium')),
                        ButtonSegment(value: 'heavy', label: Text('Heavy')),
                      ],
                      selected: {flowLevel},
                      onSelectionChanged: (value) {
                        setState(() {
                          flowLevel = value.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addPeriod(selectedStart, selectedEnd, flowLevel);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPeriodDialog(CycleEntry cycle) {
    DateTime selectedStart = cycle.startDate;
    DateTime? selectedEnd = cycle.endDate;
    String flowLevel = cycle.flowLevel.isNotEmpty ? cycle.flowLevel : 'medium';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Period'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Date
                    ListTile(
                      leading: const Icon(Icons.calendar_today, color: Color(0xFFFF6B9D)),
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedStart)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            selectedStart = date;
                          });
                        }
                      },
                    ),
                    // End Date
                    ListTile(
                      leading: const Icon(Icons.event_available, color: Color(0xFFFF6B9D)),
                      title: const Text('End Date'),
                      subtitle: Text(selectedEnd != null
                          ? DateFormat('MMM dd, yyyy').format(selectedEnd!)
                          : 'Not set (ongoing)'),
                      trailing: selectedEnd != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                setState(() {
                                  selectedEnd = null;
                                });
                              },
                            )
                          : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedEnd ?? selectedStart.add(const Duration(days: 4)),
                          firstDate: selectedStart,
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            selectedEnd = date;
                          });
                        }
                      },
                    ),
                    // Flow Level
                    const SizedBox(height: 16),
                    const Text('Flow Level', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'light', label: Text('Light')),
                        ButtonSegment(value: 'medium', label: Text('Medium')),
                        ButtonSegment(value: 'heavy', label: Text('Heavy')),
                      ],
                      selected: {flowLevel},
                      onSelectionChanged: (value) {
                        setState(() {
                          flowLevel = value.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updatePeriod(cycle, selectedStart, selectedEnd, flowLevel);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(CycleEntry cycle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Period?'),
          content: Text(
            'Are you sure you want to delete the period starting on ${DateFormat('MMM dd, yyyy').format(cycle.startDate)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePeriod(cycle);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPeriod(DateTime startDate, DateTime? endDate, String flowLevel) async {
    final cycle = CycleEntry(
      startDate: startDate,
      endDate: endDate,
      flowLevel: flowLevel,
      symptoms: [],
      mood: [],
    );

    await ref.read(cycleListProvider.notifier).addCycle(cycle);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Period added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _addSingleDayPeriod(DateTime date) async {
    final cycle = CycleEntry(
      startDate: date,
      endDate: date,
      flowLevel: 'medium',
      symptoms: [],
      mood: [],
    );

    await ref.read(cycleListProvider.notifier).addCycle(cycle);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Period logged for ${DateFormat('MMM dd').format(date)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updatePeriod(CycleEntry oldCycle, DateTime startDate, DateTime? endDate, String flowLevel) async {
    // Delete old cycle and add updated one
    await ref.read(cycleListProvider.notifier).deleteCycle(oldCycle.startDate);
    
    final updatedCycle = CycleEntry(
      startDate: startDate,
      endDate: endDate,
      flowLevel: flowLevel,
      symptoms: oldCycle.symptoms,
      mood: oldCycle.mood,
    );

    await ref.read(cycleListProvider.notifier).addCycle(updatedCycle);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Period updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deletePeriod(CycleEntry cycle) async {
    await ref.read(cycleListProvider.notifier).deleteCycle(cycle.startDate);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Period deleted'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
