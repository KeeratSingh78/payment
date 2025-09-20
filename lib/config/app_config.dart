class AppConfig {
  // Voice Recognition
  static const List<String> supportedLanguages = ['en-US', 'hi-IN', 'bn-IN', 'ta-IN', 'te-IN'];
  static const String defaultLanguage = 'hi-IN';
  
  // Fraud Detection
  static const List<String> gamblingKeywords = [
    'bet', 'gambling', 'casino', 'poker', 'lottery', 'jackpot',
    'शर्त', 'जुआ', 'कैसीनो', 'लॉटरी', 'जैकपॉट',
    'বাজি', 'জুয়া', 'ক্যাসিনো', 'লটারি',
    'பந்தயம்', 'சூதாட்டம்', 'லாட்டரி',
    'జూదం', 'లాటరీ', 'కాసినో'
  ];
  
  // Transaction Limits
  static const double dailyLimit = 50000.0;
  static const double maxTransactionAmount = 50000.0;
  static const double minTransactionAmount = 1.0;
  
  // Duress PIN
  static const String duressPin = '0000';
  
  // API Endpoints
  static const String fraudDetectionUrl = 'http://localhost:8000/detect-fraud';
  static const String nlpProcessingUrl = 'http://localhost:8000/process-voice';
  
  // App Settings
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration voiceTimeout = Duration(seconds: 10);
  static const Duration ttsDelay = Duration(milliseconds: 500);
}

