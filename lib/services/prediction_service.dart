import 'dart:math';
import '../models/cycle_entry.dart';
import '../models/predictions.dart';
import '../models/user_settings.dart';

class PredictionService {
  static Predictions calculatePredictions(
    List<CycleEntry> cycles,
    UserSettings settings,
  ) {
    if (cycles.isEmpty) {
      return _calculateFromDate(settings.lastPeriodStart, settings.cycleLength.toDouble());
    }

    // Sort cycles by date descending (newest first)
    cycles.sort((a, b) => b.startDate.compareTo(a.startDate));

    // 1. Calculate historical cycle lengths
    List<int> cycleLengths = [];
    for (int i = 0; i < cycles.length - 1; i++) {
      final current = cycles[i].startDate;
      final previous = cycles[i + 1].startDate;
      final diff = current.difference(previous).inDays;
      cycleLengths.add(diff);
    }

    // 2. Outlier Detection & Filtering
    List<Point<int>> validCycles = [];
    
    for (int i = 0; i < cycleLengths.length; i++) {
      int length = cycleLengths[i];
      // Filter out missed periods (> 45 days) and spotting (< 15 days)
      if (length > 45 || length < 15) continue;
      
      // X axis: index (0 is most recent), Y axis: length
      validCycles.add(Point(i, length));
    }

    if (validCycles.isEmpty) {
      return _calculateFromDate(cycles.first.startDate, settings.cycleLength.toDouble());
    }

    // 3. Enhanced Prediction with Weighted Moving Average
    final result = _enhancedPrediction(validCycles, cycles.first.startDate);
    
    return Predictions(
      nextPeriod: result['nextPeriod'],
      ovulationDay: result['ovulationDay'],
      fertileStart: result['fertileStart'],
      fertileEnd: result['fertileEnd'],
      confidenceDays: result['confidenceDays'],
      predictedCycleLength: result['predictedCycleLength'],
      trend: result['trend'],
    );
  }

  static Map<String, dynamic> _enhancedPrediction(List<Point<int>> validCycles, DateTime lastPeriod) {
    // Use last 6-8 cycles for prediction (more recent = more weight)
    final recentCycles = validCycles.take(min(8, validCycles.length)).toList();
    
    // 1. Weighted Moving Average (recent cycles have more weight)
    double weightedSum = 0;
    double totalWeight = 0;
    for (int i = 0; i < recentCycles.length; i++) {
      // Weight decreases exponentially: 1.0, 0.8, 0.64, 0.51, ...
      double weight = pow(0.8, i).toDouble();
      weightedSum += recentCycles[i].y * weight;
      totalWeight += weight;
    }
    double weightedAvg = weightedSum / totalWeight;
    
    // 2. Linear Regression for trend detection
    double slope = 0;
    if (recentCycles.length >= 3) {
      slope = _calculateSlope(recentCycles);
    }
    
    // 3. Combine weighted average with trend
    double predictedLength = weightedAvg + (slope * -1); // -1 because we predict for next cycle
    
    // 4. Calculate confidence interval based on variance
    double variance = _calculateVariance(recentCycles.map((p) => p.y.toDouble()).toList());
    double stdDev = sqrt(variance);
    int confidenceDays = (stdDev * 1.5).round().clamp(1, 5); // 1.5 std dev ≈ 87% confidence
    
    // 5. Detect trend
    String trend = 'stable';
    if (slope.abs() > 0.3) {
      trend = slope > 0 ? 'lengthening' : 'shortening';
    }
    
    // Clamp prediction to reasonable bounds
    predictedLength = predictedLength.clamp(21.0, 40.0);
    
    // Calculate dates
    final nextPeriod = lastPeriod.add(Duration(days: predictedLength.round()));
    final ovulationDay = nextPeriod.subtract(const Duration(days: 14));
    final fertileStart = ovulationDay.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDay;
    
    return {
      'nextPeriod': nextPeriod,
      'ovulationDay': ovulationDay,
      'fertileStart': fertileStart,
      'fertileEnd': fertileEnd,
      'confidenceDays': confidenceDays,
      'predictedCycleLength': predictedLength,
      'trend': trend,
    };
  }

  static double _calculateSlope(List<Point<int>> points) {
    int n = points.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumXX = 0;

    for (var p in points) {
      sumX += p.x;
      sumY += p.y;
      sumXY += p.x * p.y;
      sumXX += p.x * p.x;
    }

    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }

  static double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    double mean = values.reduce((a, b) => a + b) / values.length;
    double sumSquaredDiff = values.fold(0, (sum, val) => sum + pow(val - mean, 2));
    return sumSquaredDiff / values.length;
  }

  static Predictions _calculateFromDate(DateTime lastPeriod, double cycleLength) {
    final nextPeriod = lastPeriod.add(Duration(days: cycleLength.round()));
    final ovulationDay = nextPeriod.subtract(const Duration(days: 14));
    final fertileStart = ovulationDay.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDay;

    return Predictions(
      nextPeriod: nextPeriod,
      ovulationDay: ovulationDay,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      confidenceDays: 3,
      predictedCycleLength: cycleLength,
      trend: 'stable',
    );
  }
}

