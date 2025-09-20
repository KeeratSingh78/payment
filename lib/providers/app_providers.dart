import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/contact_model.dart';
import '../services/supabase_service.dart';
import '../services/voice_service.dart';
import '../services/fraud_detection_service.dart';
import '../services/phone_contacts_service.dart';

// User Provider
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null);

  Future<void> signIn(String phone, String pin) async {
    try {
      final user = await SupabaseService.signInWithPhone(phone, pin);
      state = user;
    } catch (e) {
      print('Error signing in: $e');
    }
  }

  Future<void> signUp({
    required String phone,
    required String name,
    required String pin,
    required String duressPin,
    required String trustedContact,
  }) async {
    try {
      final user = await SupabaseService.createUser(
        phone: phone,
        name: name,
        pin: pin,
        duressPin: duressPin,
        trustedContact: trustedContact,
      );
      state = user;
    } catch (e) {
      print('Error signing up: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
      state = null;
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> updateBalance(double newBalance) async {
    if (state == null) return;

    try {
      final success =
          await SupabaseService.updateUserBalance(state!.id, newBalance);
      if (success) {
        state = state!.copyWith(balance: newBalance);
      }
    } catch (e) {
      print('Error updating balance: $e');
    }
  }

  void setUser(UserModel? user) {
    state = user;
  }
}

// Transactions Provider
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>((ref) {
  return TransactionsNotifier();
});

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionsNotifier() : super([]);

  Future<void> loadTransactions(String userId) async {
    try {
      final transactions = await SupabaseService.getTransactions(userId);
      state = transactions;
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    state = [transaction, ...state];
  }

  Future<void> sendMoney({
    required String senderId,
    required String receiverId,
    required double amount,
    String? description,
  }) async {
    try {
      // Check for fraud before processing
      final isFraud = await FraudDetectionService.detectFraud(
        userId: senderId,
        amount: amount,
        description: description,
      );

      if (isFraud) {
        throw Exception('Fraud detected. Transaction blocked.');
      }

      // Create transaction
      final transaction = await SupabaseService.createTransaction(
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
        type: TransactionType.sent,
        description: description,
      );

      if (transaction != null) {
        addTransaction(transaction);
      }
    } catch (e) {
      print('Error sending money: $e');
      rethrow;
    }
  }
}

// Contacts Provider
final contactsProvider =
    StateNotifierProvider<ContactsNotifier, List<ContactModel>>((ref) {
  return ContactsNotifier();
});

class ContactsNotifier extends StateNotifier<List<ContactModel>> {
  ContactsNotifier() : super([]);

  Future<void> loadContacts(String userId) async {
    try {
      // Load both saved contacts and phone contacts
      final savedContacts = await SupabaseService.getContacts(userId);
      final phoneContacts = await PhoneContactsService.getPhoneContacts(userId);

      // Merge contacts, prioritizing saved contacts
      final Map<String, ContactModel> contactMap = {};

      // Add phone contacts first
      for (final contact in phoneContacts) {
        contactMap[contact.phone] = contact;
      }

      // Override with saved contacts (they have UPI IDs and frequency data)
      for (final contact in savedContacts) {
        contactMap[contact.phone] = contact;
      }

      state = contactMap.values.toList();
      state.sort((a, b) => a.name.compareTo(b.name));

      print(
          'Loaded ${state.length} total contacts (${savedContacts.length} saved, ${phoneContacts.length} from phone)');
    } catch (e) {
      print('Error loading contacts: $e');
    }
  }

  Future<void> addContact({
    required String userId,
    required String name,
    required String phone,
    String? upiId,
  }) async {
    try {
      final contact = await SupabaseService.addContact(
        userId: userId,
        name: name,
        phone: phone,
        upiId: upiId,
      );

      if (contact != null) {
        state = [...state, contact];
      }
    } catch (e) {
      print('Error adding contact: $e');
    }
  }

  /// Find contact by name using fuzzy search
  ContactModel? findContactByName(String name) {
    return PhoneContactsService.findContactByName(state, name);
  }
}

// Voice Service Provider
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

// Fraud Detection Provider
final fraudLogsProvider =
    StateNotifierProvider<FraudLogsNotifier, List<FraudLogModel>>((ref) {
  return FraudLogsNotifier();
});

class FraudLogsNotifier extends StateNotifier<List<FraudLogModel>> {
  FraudLogsNotifier() : super([]);

  Future<void> loadFraudLogs(String userId) async {
    try {
      final fraudLogs = await FraudDetectionService.getFraudLogs(userId);
      state = fraudLogs;
    } catch (e) {
      print('Error loading fraud logs: $e');
    }
  }

  Future<void> addFraudLog(FraudLogModel fraudLog) async {
    state = [fraudLog, ...state];
  }

  Future<void> markAsResolved(String fraudId) async {
    try {
      await FraudDetectionService.markFraudAsResolved(fraudId);
      state = state.map((log) {
        if (log.id == fraudId) {
          return log.copyWith(isResolved: true, resolvedAt: DateTime.now());
        }
        return log;
      }).toList();
    } catch (e) {
      print('Error marking fraud as resolved: $e');
    }
  }
}

// App Settings Provider
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, Map<String, dynamic>>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  AppSettingsNotifier()
      : super({
          'voice_enabled': true,
          'preferred_language': 'hi-IN',
          'tts_enabled': true,
          'fraud_alerts_enabled': true,
        });

  Future<void> loadSettings(String userId) async {
    try {
      final settings = await SupabaseService.getAppSettings(userId);
      if (settings != null) {
        state = settings;
      }
    } catch (e) {
      print('Error loading app settings: $e');
    }
  }

  Future<void> updateSettings({
    required String userId,
    bool? voiceEnabled,
    String? preferredLanguage,
    bool? ttsEnabled,
    bool? fraudAlertsEnabled,
  }) async {
    try {
      final success = await SupabaseService.updateAppSettings(
        userId: userId,
        voiceEnabled: voiceEnabled,
        preferredLanguage: preferredLanguage,
        ttsEnabled: ttsEnabled,
        fraudAlertsEnabled: fraudAlertsEnabled,
      );

      if (success) {
        final newSettings = Map<String, dynamic>.from(state);
        if (voiceEnabled != null) newSettings['voice_enabled'] = voiceEnabled;
        if (preferredLanguage != null)
          newSettings['preferred_language'] = preferredLanguage;
        if (ttsEnabled != null) newSettings['tts_enabled'] = ttsEnabled;
        if (fraudAlertsEnabled != null)
          newSettings['fraud_alerts_enabled'] = fraudAlertsEnabled;

        state = newSettings;
      }
    } catch (e) {
      print('Error updating app settings: $e');
    }
  }
}

// Voice Command Provider
final voiceCommandProvider =
    StateNotifierProvider<VoiceCommandNotifier, Map<String, dynamic>>((ref) {
  return VoiceCommandNotifier();
});

class VoiceCommandNotifier extends StateNotifier<Map<String, dynamic>> {
  VoiceCommandNotifier() : super({});

  void processCommand(String command) {
    final processedCommand = VoiceService.processVoiceCommand(command);
    state = processedCommand;
  }

  void clearCommand() {
    state = {};
  }
}

// Navigation Provider
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, String>((ref) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<String> {
  NavigationNotifier() : super('splash');

  void navigateTo(String screen) {
    state = screen;
  }

  void goBack() {
    // Implement back navigation logic
    switch (state) {
      case 'login':
      case 'registration':
        state = 'splash';
        break;
      case 'home':
        state = 'login';
        break;
      case 'send-money':
      case 'receive-money':
      case 'history':
      case 'settings':
        state = 'home';
        break;
      default:
        state = 'home';
    }
  }
}
