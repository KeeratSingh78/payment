import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/contact_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // User Management
  static Future<UserModel?> getUser(String userId) async {
    try {
      final response =
          await _client.from('users').select().eq('id', userId).single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  static Future<UserModel?> getUserByPhone(String phone) async {
    try {
      final response =
          await _client.from('users').select().eq('phone', phone).single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user by phone: $e');
      return null;
    }
  }

  static Future<UserModel?> createUser({
    required String phone,
    required String name,
    required String pin,
    required String duressPin,
    required String trustedContact,
  }) async {
    try {
      final upiId =
          '${phone.replaceAll('+91', '').replaceAll(' ', '')}@surakshapay';

      final response = await _client
          .from('users')
          .insert({
            'phone': phone,
            'name': name,
            'pin_hash': _hashPin(pin),
            'duress_pin_hash': _hashPin(duressPin),
            'trusted_contact': trustedContact,
            'upi_id': upiId,
            'balance': 0.0,
          })
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  static Future<bool> verifyPin(String userId, String pin) async {
    try {
      final user = await getUser(userId);
      if (user == null || user.pinHash == null) return false;

      final hashedPin = _hashPin(pin);

      // Check if it's the correct PIN
      if (hashedPin == user.pinHash) {
        return true;
      }

      // Check if it's duress PIN
      if (user.duressPinHash != null && hashedPin == user.duressPinHash) {
        // Log duress PIN attempt
        print('Duress PIN detected for user: $userId');
        await logFraudAttempt(
          userId: userId,
          fraudType: 'duress_pin_used',
          description: 'Duress PIN was used for authentication',
          severity: 'high',
        );
        return true; // Return true but log as duress
      }

      return false;
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  static Future<bool> updateUserBalance(
      String userId, double newBalance) async {
    try {
      await _client
          .from('users')
          .update({'balance': newBalance}).eq('id', userId);

      return true;
    } catch (e) {
      print('Error updating user balance: $e');
      return false;
    }
  }

  // Contact Management
  static Future<List<ContactModel>> getContacts(String userId) async {
    try {
      final response = await _client
          .from('contacts')
          .select()
          .eq('user_id', userId)
          .order('is_frequent', ascending: false)
          .order('name');

      return (response as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting contacts: $e');
      return [];
    }
  }

  static Future<ContactModel?> addContact({
    required String userId,
    required String name,
    required String phone,
    String? upiId,
  }) async {
    try {
      final response = await _client
          .from('contacts')
          .insert({
            'user_id': userId,
            'name': name,
            'phone': phone,
            'upi_id': upiId,
          })
          .select()
          .single();

      return ContactModel.fromJson(response);
    } catch (e) {
      print('Error adding contact: $e');
      return null;
    }
  }

  // Transaction Management
  static Future<TransactionModel?> createTransaction({
    required String senderId,
    required String receiverId,
    required double amount,
    required TransactionType type,
    String? description,
  }) async {
    try {
      final referenceId = 'SP${DateTime.now().millisecondsSinceEpoch}';

      // Get sender and receiver names
      final sender = await getUser(senderId);
      final receiver = await getUser(receiverId);

      // If receiver is not found in users table, try to find in contacts
      String? receiverName = receiver?.name;
      if (receiverName == null) {
        // Try to find receiver in contacts
        final contacts = await getContacts(senderId);
        final contact =
            contacts.where((c) => c.userId == receiverId).firstOrNull;
        receiverName = contact?.name ?? 'Unknown';
      }

      final response = await _client
          .from('transactions')
          .insert({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'amount': amount,
            'transaction_type': type.name,
            'status': TransactionStatus.completed.name,
            'reference_id': referenceId,
            'description': description,
            'sender_name': sender?.name ?? 'Unknown',
            'receiver_name': receiverName,
          })
          .select()
          .single();

      return TransactionModel.fromJson(response);
    } catch (e) {
      print('Error creating transaction: $e');
      return null;
    }
  }

  static Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      final response = await _client
          .from('transaction_history')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  static Future<List<TransactionModel>> getRecentTransactions({
    required String userId,
    required int hours,
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));

      final response = await _client
          .from('transactions')
          .select()
          .eq('sender_id', userId)
          .gte('created_at', cutoffTime.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting recent transactions: $e');
      return [];
    }
  }

  // Fraud Detection
  static Future<void> logFraudAttempt({
    required String userId,
    required String fraudType,
    required String description,
    required String severity,
  }) async {
    try {
      await _client.from('fraud_logs').insert({
        'user_id': userId,
        'fraud_type': fraudType,
        'description': description,
        'severity': severity,
        'alert_sent': severity == 'critical',
      });
    } catch (e) {
      print('Error logging fraud attempt: $e');
    }
  }

  static Future<List<FraudLogModel>> getFraudLogs(String userId) async {
    try {
      final response = await _client
          .from('fraud_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FraudLogModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting fraud logs: $e');
      return [];
    }
  }

  static Future<void> markFraudAsResolved(String fraudId) async {
    try {
      await _client.from('fraud_logs').update({
        'is_resolved': true,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', fraudId);
    } catch (e) {
      print('Error marking fraud as resolved: $e');
    }
  }

  // Voice Commands
  static Future<void> logVoiceCommand({
    required String userId,
    required String commandText,
    String? processedText,
    String? actionTaken,
    double? confidenceScore,
    String? language,
  }) async {
    try {
      await _client.from('voice_commands').insert({
        'user_id': userId,
        'command_text': commandText,
        'processed_text': processedText,
        'action_taken': actionTaken,
        'confidence_score': confidenceScore,
        'language': language,
      });
    } catch (e) {
      print('Error logging voice command: $e');
    }
  }

  // App Settings
  static Future<Map<String, dynamic>?> getAppSettings(String userId) async {
    try {
      final response = await _client
          .from('app_settings')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      print('Error getting app settings: $e');
      return null;
    }
  }

  static Future<bool> updateAppSettings({
    required String userId,
    bool? voiceEnabled,
    String? preferredLanguage,
    bool? ttsEnabled,
    bool? fraudAlertsEnabled,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (voiceEnabled != null) updateData['voice_enabled'] = voiceEnabled;
      if (preferredLanguage != null)
        updateData['preferred_language'] = preferredLanguage;
      if (ttsEnabled != null) updateData['tts_enabled'] = ttsEnabled;
      if (fraudAlertsEnabled != null)
        updateData['fraud_alerts_enabled'] = fraudAlertsEnabled;

      await _client
          .from('app_settings')
          .update(updateData)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error updating app settings: $e');
      return false;
    }
  }

  // Utility Functions
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Authentication
  static Future<UserModel?> signInWithPhone(String phone, String pin) async {
    try {
      final user = await getUserByPhone(phone);
      if (user == null) return null;

      final isValidPin = await verifyPin(user.id, pin);
      if (!isValidPin) return null;

      return user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
