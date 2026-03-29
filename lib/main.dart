import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'models/predictions.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/log_period_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/delivery/delivery_home_screen.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await HiveService.init();
  
  // Initialize Supabase FIRST before any other operations
  try {
    await SupabaseConfig.initialize();
    debugPrint('✅ Supabase initialized successfully');
    debugPrint('📡 Connected to: ${SupabaseConfig.supabaseUrl}');
    
    // Initialize Notifications (skip on web)
    if (!kIsWeb) {
      await NotificationService.init();
    }
    
    debugPrint('✅ App initialized successfully with Supabase');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
    debugPrint('⚠️ App will run in offline-only mode');
  }

  // Now that Supabase is initialized, we can safely run the app
  runApp(const ProviderScope(child: MyApp()));
  
  // Clear old predictions to force recalculation with new fields
  // This is a one-time migration for the enhanced ML model
  try {
    final predictionsBox = Hive.box<Predictions>(HiveService.predictionsBox);
    await predictionsBox.clear();
    debugPrint('✅ Cleared old predictions for ML model upgrade');
  } catch (e) {
    debugPrint('⚠️ Could not clear predictions: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'PeriodsTracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    
    // Show login screen if not authenticated, otherwise show main app
    if (user == null) {
      return const LoginScreen();
    }
    
    return const MainScaffold();
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    CalendarScreen(),
    InsightsScreen(),
    LogPeriodScreen(),
    ChatScreen(),
    ProfileScreen(),
    DeliveryHomeScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Delivery',
          ),
        ],
      ),
    );
  }
}
