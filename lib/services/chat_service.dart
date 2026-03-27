import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';
import '../models/chat_message.dart';
import '../models/cycle_entry.dart';
import '../models/predictions.dart';
import '../models/user_settings.dart';
import '../models/user_profile.dart';

class ChatService {
  GenerativeModel? _model;
  ChatSession? _assistantSession;
  ChatSession? _doctorSession;

  // System prompts for different modes
  static const String _assistantSystemPrompt = '''
You are a helpful, friendly AI assistant for a period tracking app called PeriodsTracker. 
You help users understand their menstrual cycle, track symptoms, and navigate the app.

PERSONALITY:
- Warm, supportive, and empathetic
- Use the user's name when available to personalize responses
- Use appropriate emojis to make conversations engaging (💕, 🌸, 💪, 🌙, etc.)
- Be conversational but informative
- Keep responses focused and helpful (2-4 paragraphs max)

CAPABILITIES:
- Answer questions about menstrual health, cycle patterns, and reproductive wellness
- Explain cycle predictions, fertile windows, and ovulation
- Provide self-care tips for period symptoms
- Help users understand what's "normal" vs when to seek help
- Guide users on how to use app features

USER DATA ACCESS:
You have access to the user's profile, cycle history, and predictions. Use this to provide personalized advice:
- Reference their specific cycle length, period length, and age
- Mention their upcoming predicted dates when relevant
- Acknowledge their logged symptoms and patterns

IMPORTANT RULES:
- Never provide medical diagnoses or treatment recommendations
- If users ask about concerning symptoms, suggest consulting a healthcare provider
- Be honest if you don't know something
- Celebrate users' progress in tracking their health

Current date: {currentDate}
User name: {userName}
''';

  static const String _doctorSystemPrompt = '''
You are an AI health advisor simulating a professional doctor consultation for the PeriodsTracker app.
You provide evidence-based general health information about menstrual health and reproductive wellness.

⚠️ MEDICAL DISCLAIMER: Always begin your response with:
"⚕️ **Medical Disclaimer**: I am an AI providing general health information, not medical advice. Please consult a qualified healthcare provider for personal medical concerns."

PROFESSIONAL YET APPROACHABLE:
- Use professional but accessible language (not overly clinical)
- Be empathetic and non-judgmental
- Address users by name when available
- Show genuine care for their health concerns

EVIDENCE-BASED INFORMATION:
- Explain what is considered "normal" vs when to seek medical attention
- Discuss common causes of cycle irregularities, symptoms, and concerns
- Reference medical guidelines and general statistics when helpful
- Distinguish between common variations and potential concerns

USER CONTEXT:
You have access to the user's health data. Use it to provide relevant information:
- Consider their age, cycle patterns, and symptoms when discussing concerns
- Reference their specific data when explaining what's typical for them
- Note patterns that may be relevant to their questions

RED FLAGS - Advise seeking immediate medical care for:
- Extremely heavy bleeding (soaking through a pad/tampon every hour)
- Severe pain that disrupts daily life
- Bleeding between periods or after menopause
- Signs of infection (fever, unusual discharge)
- Missed periods with pregnancy possibility
- Sudden significant cycle changes

NEVER:
- Provide specific diagnoses
- Prescribe medications
- Recommend treatments beyond general wellness advice
- Replace professional medical consultation

Current date: {currentDate}
User name: {userName}
''';

  void initialize() {
    if (!ApiConfig.isGeminiConfigured) {
      debugPrint('Gemini API key not configured');
      return;
    }

    try {
      _model = GenerativeModel(
        model: ApiConfig.geminiModel,
        apiKey: ApiConfig.geminiApiKey,
      );
      debugPrint('Gemini API initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Gemini API: $e');
    }
  }

  void startNewSessions({String? userName}) {
    if (_model == null) {
      initialize();
    }
    if (_model == null) return;

    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    final name = userName ?? 'there';
    
    _assistantSession = _model!.startChat(history: [
      Content.text(_assistantSystemPrompt
          .replaceAll('{currentDate}', currentDate)
          .replaceAll('{userName}', name)),
    ]);

    _doctorSession = _model!.startChat(history: [
      Content.text(_doctorSystemPrompt
          .replaceAll('{currentDate}', currentDate)
          .replaceAll('{userName}', name)),
    ]);

    debugPrint('New chat sessions started');
  }

  Future<String> sendMessage({
    required String message,
    required ChatMode mode,
    List<ChatMessage>? chatHistory,
    List<CycleEntry>? cycles,
    Predictions? predictions,
    UserSettings? settings,
    UserProfile? userProfile,
  }) async {
    if (_model == null) {
      initialize();
    }

    if (_model == null) {
      return _getOfflineResponse(message, mode, predictions, settings, userProfile);
    }

    try {
      // Build context from user data
      final context = _buildContext(cycles, predictions, settings, userProfile);
      
      // Get appropriate session
      ChatSession? session = mode == ChatMode.doctor ? _doctorSession : _assistantSession;
      
      // Initialize sessions if needed
      if (session == null) {
        startNewSessions(userName: userProfile?.name);
        session = mode == ChatMode.doctor ? _doctorSession : _assistantSession;
      }

      if (session == null) {
        return _getOfflineResponse(message, mode, predictions, settings, userProfile);
      }

      // Analyze message intent for better context
      final intentContext = _analyzeMessageIntent(message, predictions, settings);
      
      // Prepare the full message with context
      final fullMessage = context.isNotEmpty 
          ? '$context\n\n$intentContext\n\nUser Question: $message'
          : '$intentContext\n\nUser Question: $message';

      // Send message and get response
      final response = await session.sendMessage(Content.text(fullMessage));
      
      return response.text ?? 'I apologize, but I couldn\'t generate a response. Please try again.';
    } catch (e) {
      debugPrint('Error sending message to Gemini: $e');
      return _getOfflineResponse(message, mode, predictions, settings, userProfile);
    }
  }

  String _analyzeMessageIntent(String message, Predictions? predictions, UserSettings? settings) {
    final lower = message.toLowerCase();
    final buffer = StringBuffer();
    
    // Detect intent and add relevant context
    if (lower.contains('next period') || lower.contains('when will') || lower.contains('due date')) {
      buffer.writeln('Intent: User asking about next period prediction');
      if (predictions != null) {
        final daysUntil = predictions.nextPeriod.difference(DateTime.now()).inDays;
        buffer.writeln('Days until next period: $daysUntil');
      }
    }
    
    if (lower.contains('fertile') || lower.contains('ovulation') || lower.contains('pregnant') || lower.contains('conception')) {
      buffer.writeln('Intent: User asking about fertility/ovulation');
      if (predictions != null) {
        final fertileStart = predictions.fertileStart;
        final fertileEnd = predictions.fertileEnd;
        final isFertileNow = DateTime.now().isAfter(fertileStart) && DateTime.now().isBefore(fertileEnd);
        buffer.writeln('Currently in fertile window: $isFertileNow');
      }
    }
    
    if (lower.contains('symptom') || lower.contains('pain') || lower.contains('cramp') || lower.contains('pms')) {
      buffer.writeln('Intent: User asking about symptoms');
    }
    
    if (lower.contains('irregular') || lower.contains('late') || lower.contains('early') || lower.contains('missed')) {
      buffer.writeln('Intent: User concerned about cycle irregularity');
    }
    
    if (lower.contains('normal') || lower.contains('typical') || lower.contains('average')) {
      buffer.writeln('Intent: User seeking reassurance about what is normal');
    }
    
    if (lower.contains('help') || lower.contains('how to') || lower.contains('how do')) {
      buffer.writeln('Intent: User needs help with app features or general guidance');
    }
    
    return buffer.toString();
  }

  String _buildContext(
    List<CycleEntry>? cycles,
    Predictions? predictions,
    UserSettings? settings,
    UserProfile? userProfile,
  ) {
    final buffer = StringBuffer();

    // User profile info
    if (userProfile != null) {
      buffer.writeln('User Profile:');
      buffer.writeln('- Name: ${userProfile.name}');
      buffer.writeln('- Age: ${userProfile.age}');
      if (userProfile.healthConditions.isNotEmpty) {
        buffer.writeln('- Health conditions: ${userProfile.healthConditions.join(', ')}');
      }
      buffer.writeln('');
    } else if (settings != null) {
      buffer.writeln('User Profile:');
      buffer.writeln('- Age: ${settings.age}');
      buffer.writeln('');
    }

    // Cycle settings
    if (settings != null) {
      buffer.writeln('Cycle Information:');
      buffer.writeln('- Average cycle length: ${settings.cycleLength} days');
      buffer.writeln('- Average period length: ${settings.periodLength} days');
      buffer.writeln('- Last period started: ${settings.lastPeriodStart.toIso8601String().split('T')[0]}');
      buffer.writeln('');
    }

    // Recent cycle history
    if (cycles != null && cycles.isNotEmpty) {
      buffer.writeln('Recent Cycle History (${cycles.length} cycles recorded):');
      final recentCycles = cycles.take(6).toList();
      for (var i = 0; i < recentCycles.length; i++) {
        final cycle = recentCycles[i];
        final startDate = cycle.startDate.toIso8601String().split('T')[0];
        final endDate = cycle.endDate?.toIso8601String().split('T')[0] ?? 'ongoing';
        buffer.writeln('- Cycle ${i + 1}: $startDate to $endDate');
        if (cycle.symptoms.isNotEmpty) {
          buffer.writeln('  Symptoms: ${cycle.symptoms.join(', ')}');
        }
        if (cycle.mood.isNotEmpty) {
          buffer.writeln('  Mood: ${cycle.mood.join(', ')}');
        }
        if (cycle.flowLevel.isNotEmpty) {
          buffer.writeln('  Flow: ${cycle.flowLevel}');
        }
      }
      buffer.writeln('');
    }

    // Current predictions
    if (predictions != null) {
      final now = DateTime.now();
      final daysUntilPeriod = predictions.nextPeriod.difference(now).inDays;
      final daysUntilOvulation = predictions.ovulationDay.difference(now).inDays;
      
      buffer.writeln('Current Predictions:');
      buffer.writeln('- Next period: ${predictions.nextPeriod.toIso8601String().split('T')[0]} ($daysUntilPeriod days from now)');
      buffer.writeln('- Fertile window: ${predictions.fertileStart.toIso8601String().split('T')[0]} to ${predictions.fertileEnd.toIso8601String().split('T')[0]}');
      buffer.writeln('- Ovulation day: ${predictions.ovulationDay.toIso8601String().split('T')[0]} ($daysUntilOvulation days from now)');
      buffer.writeln('- Prediction confidence: ±${predictions.confidenceDays} days');
      if (predictions.trend.isNotEmpty) {
        buffer.writeln('- Cycle trend: ${predictions.trend}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _getOfflineResponse(
    String message, 
    ChatMode mode,
    Predictions? predictions,
    UserSettings? settings,
    UserProfile? userProfile,
  ) {
    final lowerMessage = message.toLowerCase();
    final name = userProfile?.name ?? 'there';
    
    if (mode == ChatMode.doctor) {
      return '''⚕️ **Medical Disclaimer**: I am an AI providing general health information, not medical advice. Please consult a qualified healthcare provider for personal medical concerns.

Hi $name! I'm currently operating in offline mode. For personalized medical questions, please consult with a healthcare provider who can examine you and review your complete medical history.

If you have urgent health concerns, please contact your doctor or visit an emergency room. Your health is important! 💕''';
    }

    // Intelligent offline responses based on message content
    if (lowerMessage.contains('next period') || lowerMessage.contains('when')) {
      if (predictions != null) {
        final daysUntil = predictions.nextPeriod.difference(DateTime.now()).inDays;
        return '''Hi $name! 👋

Based on your cycle data, your next period is predicted around ${predictions.nextPeriod.toIso8601String().split('T')[0]}, which is about $daysUntil days from now.

Remember, this is an estimate (±${predictions.confidenceDays} days accuracy). Your actual cycle may vary slightly.

Check your Home screen for more details! 💕''';
      }
      return '''Hi $name! 👋

To see your next predicted period, check the Home screen. Make sure you've logged your recent periods for accurate predictions!

Tip: Regular tracking improves prediction accuracy over time. 📅''';
    }

    if (lowerMessage.contains('symptom') || lowerMessage.contains('pain') || lowerMessage.contains('cramp')) {
      return '''Hi $name! 💕

Tracking symptoms is so important for understanding your body! You can log symptoms when you record a period.

**Common period symptoms include:**
- Cramps and lower back pain
- Headaches
- Bloating
- Breast tenderness
- Mood changes
- Fatigue

For severe pain or unusual symptoms, please consult a healthcare provider. Your comfort matters! 💪''';
    }

    if (lowerMessage.contains('fertile') || lowerMessage.contains('ovulation')) {
      if (predictions != null) {
        final now = DateTime.now();
        final isInFertileWindow = now.isAfter(predictions.fertileStart) && now.isBefore(predictions.fertileEnd);
        return '''Hi $name! 🌸

Your fertile window is predicted: ${predictions.fertileStart.toIso8601String().split('T')[0]} to ${predictions.fertileEnd.toIso8601String().split('T')[0]}

${isInFertileWindow ? 'You are currently in your fertile window! 🎯' : 'Track your cycle for family planning or contraception purposes.'}

Ovulation is predicted around: ${predictions.ovulationDay.toIso8601String().split('T')[0]}

See more details on your Home screen! 💕''';
      }
      return '''Hi $name! 🌸

Your fertile window and ovulation predictions are available on the Home screen. These are calculated based on your cycle history.

For the most accurate results, make sure to log your periods regularly!

Note: These are estimates and should not be used as the sole method for contraception or conception. 💕''';
    }

    if (lowerMessage.contains('normal') || lowerMessage.contains('cycle length') || lowerMessage.contains('irregular')) {
      return '''Hi $name! 💕

**What's "normal" for menstrual cycles:**
- Cycle length: 21-35 days (average is 28 days)
- Period length: 2-7 days
- Some variation month-to-month is normal

**Cycle irregularities can be caused by:**
- Stress, diet changes, or travel
- Hormonal changes
- Certain medications
- Health conditions (PCOS, thyroid issues)

If your cycles are consistently irregular or you notice significant changes, consider consulting a healthcare provider. Your cycle history in the app can help identify patterns! 📊''';
    }

    if (lowerMessage.contains('hello') || lowerMessage.contains('hi') || lowerMessage.contains('hey')) {
      return '''Hello $name! 👋💕

I'm your AI assistant, here to help you understand your cycle and track your health!

I can help you with:
- Understanding your cycle predictions
- Tracking symptoms and patterns
- Learning about menstrual health
- Using app features

What would you like to know today? 🌸''';
    }

    if (lowerMessage.contains('thank')) {
      return '''You're welcome, $name! 💕

I'm always here to help. Feel free to ask me anything about your cycle or health tracking!

Take care of yourself! 🌸''';
    }

    return '''Hi $name! 👋

I'm currently in offline mode. To use the AI chat feature with full capabilities, please ensure you have a stable internet connection.

**In the meantime, you can:**
- 📅 Check the Home screen for cycle predictions
- 📆 View your calendar for logged periods
- 📊 Explore the Insights tab for cycle analysis
- ✨ Log new periods and symptoms

For medical advice, always consult a healthcare provider. 💕''';
  }

  void clearSessions() {
    _assistantSession = null;
    _doctorSession = null;
    debugPrint('Chat sessions cleared');
  }
}
