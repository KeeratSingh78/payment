import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class VoiceService {
  static final stt.SpeechToText _speechToText = stt.SpeechToText();
  static final FlutterTts _flutterTts = FlutterTts();

  static bool _isInitialized = false;
  static bool _isListening = false;

  // Callbacks
  static Function(String result)? onResult;
  static Function(String error)? onError;

  /// Initialize both STT and TTS
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final available = await _speechToText.initialize(
        onStatus: (status) => print("🎤 Status: $status"),
        onError: (error) {
          print("❌ STT error: $error");
          onError?.call(error.errorMsg);
        },
      );

      await _flutterTts.awaitSpeakCompletion(true);

      if (available) {
        _isInitialized = true;
        print("✅ VoiceService initialized");
      } else {
        print("⚠️ Speech recognition not available");
      }
    } catch (e) {
      print("❌ Initialization failed: $e");
      onError?.call(e.toString());
    }
  }

  /// Speak text aloud
  static Future<void> speak(String text, {String language = 'en-US'}) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.9);
    await _flutterTts.speak(text);
  }

  /// Start listening (with fallback)
  static Future<void> startListening({
    String? localeId,
    Duration listenFor = const Duration(seconds: 15),
    Duration pauseFor = const Duration(seconds: 5),
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isInitialized) return;

    if (_isListening) {
      await stopListening();
    }

    Future<void> _tryListen(bool onDevice) async {
      print("🎤 Trying listen (onDevice=$onDevice) ...");
      final started = await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            print("✅ Recognized: ${result.recognizedWords}");
            onResult?.call(result.recognizedWords);
          } else {
            print("⚠️ Empty recognition");
          }
        },
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        onDevice: onDevice,
      );

      if (started) {
        _isListening = true;
        print("🎤 Listening started (onDevice=$onDevice)");
      } else {
        print("❌ listen() failed (onDevice=$onDevice)");
      }
    }

    // Try device first
    await _tryListen(true);

    // Retry with cloud if nothing recognized
    Future.delayed(const Duration(seconds: 3), () async {
      if (_isListening && _speechToText.lastRecognizedWords.isEmpty) {
        print("⚠️ Retrying with cloud recognition...");
        await stopListening();
        await _tryListen(false);
      }
    });
  }

  /// Stop listening
  static Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      print("🛑 Stopped listening");
    }
  }

  /// Cancel listening
  static Future<void> cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
      print("🛑 Cancelled listening");
    }
  }

  /// Helper: return Hindi responses
  static String getHindiResponse(String intent, {String? additionalInfo}) {
    switch (intent) {
      case 'check_balance':
        return "आपका बैलेंस ${additionalInfo ?? ''} रुपये है";
      case 'send_money':
        return "पैसे भेजने के लिए आपको भेजने वाले व्यक्ति का चयन करना होगा।";
      case 'receive_money':
        return "पैसे प्राप्त करने के लिए आपका QR कोड दिखाया जा रहा है।";
      case 'view_history':
        return "आपके लेनदेन का इतिहास दिखाया जा रहा है।";
      case 'help':
        return "आप कह सकते हैं: पैसे भेजो, पैसे प्राप्त करो, बैलेंस चेक करो, इतिहास दिखाओ, या मदद";
      case 'transaction_success':
        return additionalInfo != null
            ? 'लेनदेन सफलतापूर्वक पूरा हुआ। $additionalInfo'
            : 'लेनदेन सफलतापूर्वक पूरा हुआ।';
      case 'insufficient_balance':
        return 'आपके खाते में पर्याप्त बैलेंस नहीं है।';
      default:
        return "क्षमा करें, मैं समझ नहीं पाया। कृपया फिर से कहें: पैसे भेजो, पैसे प्राप्त करो, बैलेंस चेक करो, या मदद";
    }
  }

  /// Helper: greeting
  static String getGreeting(String language) {
    final hour = DateTime.now().hour;
    if (language == 'hi-IN') {
      if (hour < 12) return "सुप्रभात! मैं आपकी कैसे मदद कर सकता हूँ?";
      if (hour < 18) return "नमस्कार! मैं आपकी कैसे मदद कर सकता हूँ?";
      return "शुभ संध्या! मैं आपकी कैसे मदद कर सकता हूँ?";
    } else {
      if (hour < 12) return "Good morning! How can I help you today?";
      if (hour < 18) return "Good afternoon! How can I help you today?";
      return "Good evening! How can I help you today?";
    }
  }

  /// Helper: process commands with enhanced Hindi support
  static Map<String, dynamic> processVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase().trim();
    print('🔍 Processing command: "$lowerCommand"');

    // Stop any ongoing listening to prevent multiple recognitions
    stopListening();

    // Send Money Commands (Hindi & English)
    if (_containsAny(lowerCommand, [
      // Hindi variations
      'पैसे भेज', 'पैसा भेज', 'भेज', 'भेजो', 'भेजना', 'send कर', 'transfer कर',
      'पैसे transfer', 'money भेज', 'rupee भेज', 'रुपए भेज', 'रुपये भेज',
      'paisa bhej', 'paise bhej', 'bhej', 'bhejo', 'bhejana', 'bhejiye',
      // English variations
      'send money', 'send', 'transfer money', 'transfer', 'pay', 'payment'
    ])) {
      print('✅ Detected: send_money');
      return {'action': 'send_money'};
    }

    // Receive Money Commands (Hindi & English)
    if (_containsAny(lowerCommand, [
      // Hindi variations
      'पैसे ले', 'पैसा ले', 'प्राप्त कर', 'receive कर', 'qr दिखा',
      'qr code दिखा',
      'पैसे receive', 'money ले', 'पैसे मांग', 'upi id दिखा',
      'paisa le', 'paise le', 'prapt kar', 'receive kar', 'qr dikha',
      // English variations
      'receive money', 'receive', 'show qr', 'qr code', 'get money'
    ])) {
      print('✅ Detected: receive_money');
      return {'action': 'receive_money'};
    }

    // Balance Check Commands (Hindi & English)
    if (_containsAny(lowerCommand, [
      // Hindi variations
      'बैलेंस चेक', 'बैलेंस देख', 'बैलेंस बता', 'कितना पैसा', 'कितने रुपए',
      'balance देख', 'balance बता', 'balance check', 'kitna paisa',
      'kitne rupee', 'बैलेंस', 'बैलेन्स',
      'balance kitna', 'paisa kitna', 'rupee kitne', 'account balance',
      // English variations - including short forms
      'check balance', 'balance', 'bal', 'show balance', 'my balance',
      'account balance', 'check bal', 'show bal', 'my bal'
    ])) {
      print('✅ Detected: check_balance');
      return {'action': 'check_balance'};
    }

    // History Commands (Hindi & English)
    if (_containsAny(lowerCommand, [
      // Hindi variations
      'इतिहास देख', 'history देख', 'transaction देख', 'लेनदेन देख',
      'पुराने transaction',
      'itihas dekh', 'history dekh', 'transaction dekh', 'lenden dekh',
      'purane transaction', 'transaction history',
      // English variations
      'transaction history', 'history', 'transactions', 'show history',
      'past transactions'
    ])) {
      print('✅ Detected: view_history');
      return {'action': 'view_history'};
    }

    // Help Commands (Hindi & English)
    if (_containsAny(lowerCommand, [
      // Hindi variations
      'मदद', 'सहायता', 'help कर', 'क्या कर सकते', 'कैसे काम करता',
      'madad', 'sahayata', 'help kar', 'kya kar sakte', 'kaise kaam karta',
      // English variations
      'help', 'assistance', 'what can you do', 'commands', 'options'
    ])) {
      print('✅ Detected: help');
      return {'action': 'help'};
    }

    print('❓ Unknown command: "$lowerCommand"');
    return {'action': 'unknown', 'original_command': command};
  }

  /// Helper method to check if command contains any of the given phrases
  static bool _containsAny(String command, List<String> phrases) {
    for (String phrase in phrases) {
      if (command.contains(phrase.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  static bool get isListening => _isListening;
}
