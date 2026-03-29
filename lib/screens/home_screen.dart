import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/predictions.dart';
import '../models/user_settings.dart';
import '../providers/prediction_provider.dart';
import '../providers/user_settings_provider.dart';
import '../providers/cycle_provider.dart';
import 'log_period_screen.dart';
import 'chat_screen.dart';
import 'delivery/delivery_home_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger prediction calculation on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePredictions();
    });
  }

  void _updatePredictions() async {
    final cycles = ref.read(cycleListProvider).valueOrNull ?? [];
    var settings = ref.read(userSettingsProvider).valueOrNull;
    
    debugPrint('🔄 Updating predictions: ${cycles.length} cycles, settings: ${settings != null}');
    
    // Create default settings if none exist
    if (settings == null && cycles.isNotEmpty) {
      debugPrint('📝 Creating default settings from first cycle');
      settings = UserSettings(
        cycleLength: 28,
        periodLength: 5,
        lastPeriodStart: cycles.first.startDate,
        age: 25,
        height: 160,
        weight: 60,
      );
      await ref.read(userSettingsProvider.notifier).saveSettings(settings);
    }
    
    if (settings != null && cycles.isNotEmpty) {
      debugPrint('✅ Calculating predictions with ${cycles.length} cycles');
      ref.read(predictionProvider.notifier).calculateAndSavePredictions(cycles, settings);
    } else {
      debugPrint('⚠️ Cannot calculate predictions - cycles: ${cycles.length}, settings: ${settings != null}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictionsAsync = ref.watch(predictionProvider);
    final settingsAsync = ref.watch(userSettingsProvider);

    // Listen to changes to re-trigger predictions
    ref.listen(cycleListProvider, (previous, next) {
      if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
        _updatePredictions();
      }
    });
    ref.listen(userSettingsProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _updatePredictions();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF0F5), // Lavender blush
              Color(0xFFFFE4E9), // Misty rose
              Color(0xFFFFC0CB), // Pink
            ],
          ),
        ),
        child: SafeArea(
          child: predictionsAsync.when(
            data: (predictions) => settingsAsync.when(
              data: (settings) => _buildContent(context, predictions, settings),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Predictions? predictions, UserSettings? settings) {
    // Check what data we have
    final cycles = ref.watch(cycleListProvider).valueOrNull ?? [];
    
    if (cycles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 80, color: Color(0xFFFF6B9D)),
              const SizedBox(height: 24),
              const Text(
                'No Period Data Yet',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Load training data from Profile or log your first period to see predictions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    
    if (predictions == null || settings == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Calculating predictions...\nCycles loaded: ${cycles.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final daysUntilPeriod = predictions.nextPeriod.difference(DateTime.now()).inDays;
    final isPeriodToday = daysUntilPeriod == 0;
    final isPeriodLate = daysUntilPeriod < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildCountdownCard(daysUntilPeriod, isPeriodToday, isPeriodLate, predictions),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFertileWindowCard(predictions)),
              const SizedBox(width: 16),
              Expanded(child: _buildOvulationCard(predictions)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF880E4F),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Beautiful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: TextStyle(
                fontSize: 16,
                color: Colors.pink[600],
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.pink[100],
          child: Icon(Icons.person, color: Colors.pink[400]),
        ),
      ],
    );
  }

  Widget _buildCountdownCard(int days, bool isToday, bool isLate, Predictions predictions) {
    String title;
    String subtitle;
    Color color;
    String animationAsset;

    if (isToday) {
      title = 'Period Today';
      subtitle = 'Make sure you are prepared!';
      color = const Color(0xFFFF80AB);
      animationAsset = 'animations/drop.json';
    } else if (isLate) {
      title = 'Period Late';
      subtitle = '${days.abs()} days late';
      color = const Color(0xFFFF5252);
      animationAsset = 'animations/alert.json';
    } else {
      title = '$days Days';
      subtitle = 'Until next period';
      color = const Color(0xFFFF4081);
      animationAsset = 'animations/flower.json';
    }

    // Get trend icon and text
    IconData trendIcon;
    String trendText;
    Color trendColor;
    
    switch (predictions.trend) {
      case 'lengthening':
        trendIcon = Icons.trending_up;
        trendText = 'Cycles getting longer';
        trendColor = Colors.orange;
        break;
      case 'shortening':
        trendIcon = Icons.trending_down;
        trendText = 'Cycles getting shorter';
        trendColor = Colors.blue;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendText = 'Stable cycle';
        trendColor = Colors.green;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Icon instead of Lottie (to avoid LateInitializationError)
            SizedBox(
              height: 120,
              child: Icon(
                isToday ? Icons.water_drop : (isLate ? Icons.warning : Icons.calendar_today),
                size: 80,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Confidence Interval
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined, size: 16, color: Colors.pink[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Confidence: ±${predictions.confidenceDays} days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.pink[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Trend Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, size: 16, color: trendColor),
                  const SizedBox(width: 8),
                  Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFertileWindowCard(Predictions predictions) {
    final now = DateTime.now();
    final isFertile = now.isAfter(predictions.fertileStart) && now.isBefore(predictions.fertileEnd);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isFertile ? const Color(0xFFE1BEE7) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.child_care, color: Colors.purple[300], size: 32),
            const SizedBox(height: 12),
            Text(
              'Fertile Window',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('MMM d').format(predictions.fertileStart)} - ${DateFormat('MMM d').format(predictions.fertileEnd)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple[700],
              ),
            ),
            if (isFertile) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'High Chance',
                  style: TextStyle(fontSize: 10, color: Colors.purple),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOvulationCard(Predictions predictions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.egg_outlined, color: Colors.orange[300], size: 32),
            const SizedBox(height: 12),
            Text(
              'Ovulation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d').format(predictions.ovulationDay),
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Log Period',
                Icons.water_drop,
                const Color(0xFFFF4081),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LogPeriodScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                'Add Symptoms',
                Icons.healing,
                const Color(0xFF7C4DFF),
                () {
                  // Navigate to symptoms screen (reusing log screen for now)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LogPeriodScreen()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            context,
            'Ask AI Assistant',
            Icons.smart_toy,
            const Color(0xFF00BCD4),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            context,
            'Delivery Store',
            Icons.shopping_bag,
            Colors.purple,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeliveryHomeScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
