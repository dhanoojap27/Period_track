import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(_getInitialUser()) {
    // Only listen to auth state changes if Supabase is initialized
    try {
      SupabaseConfig.auth.onAuthStateChange.listen((data) {
        state = data.session?.user;
      });
    } catch (e) {
      debugPrint('⚠️ Could not set up auth listener: $e');
    }
  }
  
  static User? _getInitialUser() {
    try {
      return SupabaseConfig.auth.currentUser;
    } catch (e) {
      debugPrint('⚠️ Could not get current user: $e');
      return null;
    }
  }

  /// Clean and validate email address
  String _cleanEmail(String email) {
    // Remove leading/trailing whitespace, convert to lowercase
    String cleaned = email.trim().toLowerCase();
    // Remove any extra spaces within the email
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    return cleaned;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> signIn(String email, String password) async {
    final cleanedEmail = _cleanEmail(email);
    
    debugPrint('Sign In Attempt:');
    debugPrint('   Email: $cleanedEmail');
    debugPrint('   Email valid: ${_isValidEmail(cleanedEmail)}');
    debugPrint('   Supabase initialized: ${SupabaseConfig.isInitialized}');
    
    if (!_isValidEmail(cleanedEmail)) {
      throw Exception('Invalid email format');
    }
    
    if (!SupabaseConfig.isInitialized) {
      throw Exception('Supabase is not initialized. Please wait for app to initialize.');
    }
    
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: cleanedEmail,
        password: password,
      );
      debugPrint('Sign in successful: ${response.user?.email}');
    } catch (e) {
      debugPrint('Sign in failed: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signUp(String email, String password) async {
    final cleanedEmail = _cleanEmail(email);
    
    debugPrint('Sign Up Attempt:');
    debugPrint('   Original email: "$email"');
    debugPrint('   Cleaned email: "$cleanedEmail"');
    debugPrint('   Email valid: ${_isValidEmail(cleanedEmail)}');
    debugPrint('   Password length: ${password.length}');
    debugPrint('   Supabase initialized: ${SupabaseConfig.isInitialized}');
    
    if (!_isValidEmail(cleanedEmail)) {
      throw Exception('Invalid email format');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    if (!SupabaseConfig.isInitialized) {
      throw Exception('Supabase is not initialized. Please wait for app to initialize.');
    }
    
    try {
      debugPrint('Sending sign up request to Supabase...');
      final response = await SupabaseConfig.auth.signUp(
        email: cleanedEmail,
        password: password,
      );
      
      debugPrint('Sign up response received:');
      debugPrint('   User ID: ${response.user?.id}');
      debugPrint('   Email: ${response.user?.email}');
      debugPrint('   Session: ${response.session != null ? "Active" : "Null (email confirmation may be required)"}');
      
      return response;
    } catch (e) {
      debugPrint('Sign up failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await SupabaseConfig.auth.signOut();
    debugPrint('User signed out');
  }

  String? get currentUserId => state?.id;
}