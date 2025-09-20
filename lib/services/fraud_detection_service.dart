import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/transaction_model.dart';
import 'supabase_service.dart';

class FraudDetectionService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    _isInitialized = true;
  }

  static Future<bool> detectFraud({
    required String userId,
    required double amount,
    String? description,
    String? recipientName,
    String? transactionType,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Check for gambling keywords
      if (description != null && _containsGamblingKeywords(description)) {
        await _logFraudAttempt(
          userId: userId,
          fraudType: 'gambling_detected',
          description: 'Gambling keywords detected in transaction description',
          severity: 'high',
        );
        return true;
      }

      // Check for suspicious transaction patterns
      if (await _isSuspiciousTransaction(userId, amount)) {
        await _logFraudAttempt(
          userId: userId,
          fraudType: 'suspicious_transaction',
          description: 'Suspicious transaction pattern detected',
          severity: 'medium',
        );
        return true;
      }

      // Check for unusual recipient patterns
      if (recipientName != null && await _isSuspiciousRecipient(recipientName)) {
        await _logFraudAttempt(
          userId: userId,
          fraudType: 'suspicious_recipient',
          description: 'Suspicious recipient detected',
          severity: 'medium',
        );
        return true;
      }

      // Call external fraud detection API if available
      if (await _callExternalFraudDetectionAPI(
        userId: userId,
        amount: amount,
        description: description,
        recipientName: recipientName,
      )) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error in fraud detection: $e');
      return false;
    }
  }

  static bool _containsGamblingKeywords(String text) {
    final lowerText = text.toLowerCase();
    return AppConfig.gamblingKeywords.any((keyword) => 
      lowerText.contains(keyword.toLowerCase())
    );
  }

  static Future<bool> _isSuspiciousTransaction(String userId, double amount) async {
    try {
      // Check for multiple large transactions in short time
      final recentTransactions = await SupabaseService.getRecentTransactions(
        userId: userId,
        hours: 1,
      );
      
      final largeTransactions = recentTransactions
          .where((tx) => tx.amount > 10000)
          .length;
      
      if (largeTransactions > 5) {
        return true;
      }

      // Check for rapid successive transactions
      if (recentTransactions.length > 10) {
        return true;
      }

      // Check for unusual amount patterns
      if (amount > AppConfig.maxTransactionAmount * 0.8) {
        return true;
      }

      return false;
    } catch (e) {
      print('Error checking suspicious transactions: $e');
      return false;
    }
  }

  static Future<bool> _isSuspiciousRecipient(String recipientName) async {
    // Check against known suspicious names/patterns
    final suspiciousPatterns = [
      'test',
      'demo',
      'fake',
      'unknown',
      'anonymous',
      'टेस्ट',
      'डेमो',
      'अज्ञात',
    ];
    
    final lowerName = recipientName.toLowerCase();
    return suspiciousPatterns.any((pattern) => 
      lowerName.contains(pattern.toLowerCase())
    );
  }

  static Future<bool> _callExternalFraudDetectionAPI({
    required String userId,
    required double amount,
    String? description,
    String? recipientName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.fraudDetectionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'amount': amount,
          'description': description,
          'recipient_name': recipientName,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_fraud'] == true;
      }
    } catch (e) {
      print('Error calling external fraud detection API: $e');
    }
    
    return false;
  }

  static Future<void> _logFraudAttempt({
    required String userId,
    required String fraudType,
    required String description,
    required String severity,
  }) async {
    try {
      await SupabaseService.logFraudAttempt(
        userId: userId,
        fraudType: fraudType,
        description: description,
        severity: severity,
      );
    } catch (e) {
      print('Error logging fraud attempt: $e');
    }
  }

  static Future<void> handleDuressPin(String userId) async {
    try {
      await _logFraudAttempt(
        userId: userId,
        fraudType: 'duress_pin',
        description: 'Duress PIN entered - user may be under threat',
        severity: 'critical',
      );
      
      // Send alert to trusted contact
      await _sendDuressAlert(userId);
    } catch (e) {
      print('Error handling duress PIN: $e');
    }
  }

  static Future<void> _sendDuressAlert(String userId) async {
    try {
      // Get user's trusted contact
      final user = await SupabaseService.getUser(userId);
      if (user != null) {
        // In a real app, this would send SMS/email to trusted contact
        print('ALERT: Duress PIN entered for user ${user.name}');
        print('Trusted contact: ${user.trustedContact}');
        
        // Log the alert
        await SupabaseService.logFraudAttempt(
          userId: userId,
          fraudType: 'duress_alert_sent',
          description: 'Duress alert sent to trusted contact',
          severity: 'critical',
        );
      }
    } catch (e) {
      print('Error sending duress alert: $e');
    }
  }

  static Future<List<FraudLogModel>> getFraudLogs(String userId) async {
    try {
      return await SupabaseService.getFraudLogs(userId);
    } catch (e) {
      print('Error getting fraud logs: $e');
      return [];
    }
  }

  static Future<void> markFraudAsResolved(String fraudId) async {
    try {
      await SupabaseService.markFraudAsResolved(fraudId);
    } catch (e) {
      print('Error marking fraud as resolved: $e');
    }
  }

  static Future<Map<String, dynamic>> getFraudStatistics(String userId) async {
    try {
      final fraudLogs = await getFraudLogs(userId);
      
      final stats = {
        'total_frauds': fraudLogs.length,
        'resolved_frauds': fraudLogs.where((f) => f.isResolved).length,
        'critical_frauds': fraudLogs.where((f) => f.severity == 'critical').length,
        'high_frauds': fraudLogs.where((f) => f.severity == 'high').length,
        'medium_frauds': fraudLogs.where((f) => f.severity == 'medium').length,
        'low_frauds': fraudLogs.where((f) => f.severity == 'low').length,
        'duress_pin_attempts': fraudLogs.where((f) => f.fraudType == 'duress_pin').length,
        'gambling_detections': fraudLogs.where((f) => f.fraudType == 'gambling_detected').length,
      };
      
      return stats;
    } catch (e) {
      print('Error getting fraud statistics: $e');
      return {};
    }
  }
}

