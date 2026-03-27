import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase project credentials
  // You can find these in your Supabase dashboard under Project Settings > API
  static const String supabaseUrl = 'https://zmkwewyeqiywrtvakglh.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_wH53or9--Nq7SgJDQxjGPA_T6mMHCWE';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}
