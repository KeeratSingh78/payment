import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact_model.dart';

class PhoneContactsService {
  /// Request contacts permission
  static Future<bool> requestContactsPermission() async {
    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        print('✅ Contacts permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('❌ Contacts permission permanently denied');
        return false;
      } else {
        print('❌ Contacts permission denied');
        return false;
      }
    } catch (e) {
      print('Error requesting contacts permission: $e');
      return false;
    }
  }

  /// Check if contacts permission is granted
  static Future<bool> hasContactsPermission() async {
    try {
      final status = await Permission.contacts.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking contacts permission: $e');
      return false;
    }
  }

  /// Fetch phone contacts and convert to app contact models
  static Future<List<ContactModel>> getPhoneContacts(String userId) async {
    try {
      // Check permission first
      bool hasPermission = await hasContactsPermission();
      if (!hasPermission) {
        print('📱 Requesting contacts permission...');
        hasPermission = await requestContactsPermission();
        if (!hasPermission) {
          print('❌ Contacts permission denied - cannot load phone contacts');
          return [];
        }
      }

      // Fetch contacts
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final List<ContactModel> appContacts = [];

      for (final contact in contacts) {
        // Skip contacts without phone numbers
        if (contact.phones.isEmpty) continue;

        // Get the first phone number
        final phone = contact.phones.first.number;
        if (phone.isEmpty) continue;

        // Clean phone number (remove spaces, dashes, etc.)
        final cleanPhone = _cleanPhoneNumber(phone);
        if (cleanPhone.isEmpty) continue;

        // Create app contact model
        final appContact = ContactModel(
          id: contact.id,
          userId: userId,
          name:
              contact.displayName.isNotEmpty ? contact.displayName : 'Unknown',
          phone: cleanPhone,
          upiId: null, // Will be set later if available
          isFrequent: false,
          createdAt: DateTime.now(),
        );

        appContacts.add(appContact);
      }

      // Sort by name
      appContacts.sort((a, b) => a.name.compareTo(b.name));

      print('Loaded ${appContacts.length} phone contacts');
      return appContacts;
    } catch (e) {
      print('Error loading phone contacts: $e');
      return [];
    }
  }

  /// Clean phone number to standard format
  static String _cleanPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Handle Indian phone numbers
    if (cleaned.startsWith('+91')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      cleaned = cleaned.substring(2);
    }

    // Ensure it's a valid 10-digit number
    if (cleaned.length == 10 && cleaned.startsWith(RegExp(r'[6-9]'))) {
      return cleaned;
    }

    return '';
  }

  /// Find contact by name (fuzzy search)
  static ContactModel? findContactByName(
      List<ContactModel> contacts, String name) {
    final lowerName = name.toLowerCase().trim();

    // Exact match first
    for (final contact in contacts) {
      if (contact.name.toLowerCase() == lowerName) {
        return contact;
      }
    }

    // Partial match
    for (final contact in contacts) {
      if (contact.name.toLowerCase().contains(lowerName) ||
          lowerName.contains(contact.name.toLowerCase())) {
        return contact;
      }
    }

    // First name match
    for (final contact in contacts) {
      final firstName = contact.name.split(' ').first.toLowerCase();
      if (firstName == lowerName || lowerName.contains(firstName)) {
        return contact;
      }
    }

    return null;
  }

  /// Extract name from voice command
  static String? extractNameFromCommand(String command) {
    final lowerCommand = command.toLowerCase();

    // Common patterns for sending money
    final patterns = [
      RegExp(r'(?:पैसे भेज|भेज|send).+?(?:को|to)\s+([a-zA-Z\s]+)',
          caseSensitive: false),
      RegExp(r'([a-zA-Z\s]+)\s+(?:को|to)\s+(?:पैसे भेज|भेज|send)',
          caseSensitive: false),
      RegExp(r'(?:पैसे भेज|भेज|send)\s+([a-zA-Z\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerCommand);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.isNotEmpty && name.length > 2) {
          return name;
        }
      }
    }

    return null;
  }

  /// Extract amount from voice command
  static double? extractAmountFromCommand(String command) {
    // Look for numbers in the command
    final numberPattern =
        RegExp(r'(\d+(?:,\d{3})*(?:\.\d{2})?)', caseSensitive: false);
    final match = numberPattern.firstMatch(command);

    if (match != null) {
      final amountStr = match.group(1)?.replaceAll(',', '');
      return double.tryParse(amountStr ?? '');
    }

    return null;
  }
}
