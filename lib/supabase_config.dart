import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class SupabaseConfig {
  // Supabase project credentials loaded from .env file
  static late final String supabaseUrl;
  static late final String supabaseAnonKey;
  
  // Flag to track if Supabase has been initialized
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      // For testing, use hardcoded values directly
      // This bypasses .env file loading issues
      debugPrint('🔍 Initializing Supabase with hardcoded credentials...');
      
      supabaseUrl = 'https://vfzbewmyektmblkzlirp.supabase.co';
      supabaseAnonKey = 'sb_publishable_DrH_abQya8dbBgxdObMmmA_GbS80Tpa';
      
      debugPrint('📝 Supabase URL: $supabaseUrl');
      debugPrint('📝 Anon Key starts with: ${supabaseAnonKey.substring(0, 20)}...');
      
      debugPrint('🔌 Initializing Supabase connection...');
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('✅ Supabase initialized successfully');
      debugPrint('📡 Connected to: $supabaseUrl');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      debugPrint('⚠️ App will run in offline-only mode');
      // Don't rethrow - let app continue in offline mode
    }
  }

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }
  
  static GoTrueClient get auth {
    if (!_isInitialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return Supabase.instance.client.auth;
  }
  
  /// Check if Supabase is initialized
  static bool get isInitialized => _isInitialized;
}