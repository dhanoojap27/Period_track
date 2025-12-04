import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/cycle_provider.dart';
import '../models/cycle_entry.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cycleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.white,
      ),
      body: cyclesAsync.when(
        data: (cycles) => _buildInsights(context, cycles),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInsights(BuildContext context, List<CycleEntry> cycles) {
    if (cycles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No data yet.\nStart logging your periods to see insights!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }

    final completedCycles = cycles.where((c) => c.endDate != null).toList();
    final avgCycleLength = _calculateAverageCycleLength(completedCycles);
    final avgPeriodLength = _calculateAveragePeriodLength(completedCycles);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Avg Cycle',
                  avgCycleLength > 0 ? '${avgCycleLength.toStringAsFixed(0)} days' : 'N/A',
                  Icons.calendar_today,
                  const Color(0xFFFF6B9D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Period',
                  avgPeriodLength > 0 ? '${avgPeriodLength.toStringAsFixed(0)} days' : 'N/A',
                  Icons.water_drop,
                  const Color(0xFFFDA085),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cycle Length Graph
          _buildSectionTitle('Cycle Length Trend'),
          const SizedBox(height: 12),
          _buildCycleLengthChart(completedCycles),
          const SizedBox(height: 24),

          // Period History Chart
          _buildSectionTitle('Period Duration History'),
          const SizedBox(height: 12),
          _buildPeriodHistoryChart(completedCycles),
          const SizedBox(height: 24),

          // Health Suggestions
          _buildSectionTitle('Health Insights'),
          const SizedBox(height: 12),
          _buildHealthSuggestions(avgCycleLength, avgPeriodLength),
        ],
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleLengthChart(List<CycleEntry> completedCycles) {
    if (completedCycles.length < 2) {
      return _buildNoDataCard('Need at least 2 complete cycles');
    }

    final cycleLengths = <FlSpot>[];
    for (int i = 0; i < completedCycles.length - 1; i++) {
      final current = completedCycles[i];
      final next = completedCycles[i + 1];
      final length = current.startDate.difference(next.startDate).inDays.abs();
      cycleLengths.add(FlSpot(i.toDouble(), length.toDouble()));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'C${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: cycleLengths,
              isCurved: true,
              color: const Color(0xFFFF6B9D),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.2),
              ),
            ),
          ],
          minY: 20,
          maxY: 40,
        ),
      ),
    );
  }

  Widget _buildPeriodHistoryChart(List<CycleEntry> completedCycles) {
    if (completedCycles.isEmpty) {
      return _buildNoDataCard('No completed periods yet');
    }

    final periodLengths = completedCycles.take(10).map((cycle) {
      final length = cycle.endDate!.difference(cycle.startDate).inDays + 1;
      return length.toDouble();
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= periodLengths.length) return const Text('');
                  return Text(
                    '${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: periodLengths.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: const Color(0xFFFDA085),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHealthSuggestions(double avgCycleLength, double avgPeriodLength) {
    final suggestions = <Map<String, dynamic>>[];

    if (avgCycleLength > 0) {
      if (avgCycleLength >= 21 && avgCycleLength <= 35) {
        suggestions.add({
          'icon': Icons.check_circle,
          'color': Colors.green,
          'title': 'Normal Cycle Length',
          'description': 'Your average cycle length is within the healthy range (21-35 days).',
        });
      } else {
        suggestions.add({
          'icon': Icons.warning,
          'color': Colors.orange,
          'title': 'Irregular Cycle',
          'description': 'Your cycle length is outside the typical range. Consider consulting a healthcare provider.',
        });
      }
    }

    if (avgPeriodLength > 0) {
      if (avgPeriodLength >= 3 && avgPeriodLength <= 7) {
        suggestions.add({
          'icon': Icons.check_circle,
          'color': Colors.green,
          'title': 'Normal Period Duration',
          'description': 'Your period duration is within the healthy range (3-7 days).',
        });
      } else if (avgPeriodLength < 3) {
        suggestions.add({
          'icon': Icons.info,
          'color': Colors.blue,
          'title': 'Short Period',
          'description': 'Your periods are shorter than average. This can be normal, but track any changes.',
        });
      } else {
        suggestions.add({
          'icon': Icons.warning,
          'color': Colors.orange,
          'title': 'Long Period',
          'description': 'Your periods are longer than average. Consider discussing with a healthcare provider.',
        });
      }
    }

    suggestions.add({
      'icon': Icons.favorite,
      'color': const Color(0xFFFF6B9D),
      'title': 'Stay Hydrated',
      'description': 'Drink plenty of water throughout your cycle to help reduce bloating and cramps.',
    });

    return Column(
      children: suggestions.map((suggestion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: suggestion['color'].withValues(alpha: 0.3), width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(suggestion['icon'], color: suggestion['color'], size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: suggestion['color'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      suggestion['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  double _calculateAverageCycleLength(List<CycleEntry> completedCycles) {
    if (completedCycles.length < 2) return 0;

    int totalLength = 0;
    for (int i = 0; i < completedCycles.length - 1; i++) {
      final current = completedCycles[i];
      final next = completedCycles[i + 1];
      totalLength += current.startDate.difference(next.startDate).inDays.abs();
    }

    return totalLength / (completedCycles.length - 1);
  }

  double _calculateAveragePeriodLength(List<CycleEntry> completedCycles) {
    if (completedCycles.isEmpty) return 0;

    int totalLength = 0;
    for (var cycle in completedCycles) {
      totalLength += cycle.endDate!.difference(cycle.startDate).inDays + 1;
    }

    return totalLength / completedCycles.length;
  }
}
