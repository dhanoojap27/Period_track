/// Configuration for external APIs
/// 
/// To use the AI chat feature, you need to obtain a Gemini API key:
/// 1. Visit https://makersuite.google.com/app/apikey
/// 2. Create a free API key
/// 3. Replace the value below with your actual API key
class ApiConfig {
  /// Google Gemini API Key
  /// Get your free API key from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'AIzaSyAIZpzXJdzYE0L5eqe9lGVRMh4Vlj-6kfs';

  /// Check if API key is configured
  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;

  /// Gemini model to use
  static const String geminiModel = 'gemini-2.0-flash';
}
