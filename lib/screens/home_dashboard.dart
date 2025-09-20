import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/voice_service.dart';
import '../widgets/voice_button.dart';
import '../widgets/transaction_card.dart';
import '../widgets/pin_input_dialog.dart';
import '../services/phone_contacts_service.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/contact_model.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with TickerProviderStateMixin {
  bool _showBalance = true;
  bool _isVoiceMode = false;
  late AnimationController _balanceAnimationController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _setupVoiceCallbacks();
    _setupAnimations();

    // Load contacts when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      if (user != null) {
        ref.read(contactsProvider.notifier).loadContacts(user.id).then((_) {
          // Show a helpful message if no contacts were loaded
          final contacts = ref.read(contactsProvider);
          if (contacts.isEmpty) {
            final settings = ref.read(appSettingsProvider);
            final language = settings['preferred_language'] ?? 'hi-IN';
            final message = language == 'hi-IN'
                ? 'संपर्कों तक पहुंचने के लिए अनुमति दें। सेटिंग्स में जाकर संपर्क अनुमति सक्षम करें।'
                : 'Please grant contacts permission to access your phone contacts. Enable contacts permission in settings.';
            VoiceService.speak(message, language: language);
          }
        });
      }
    });
  }

  void _setupVoiceCallbacks() {
    VoiceService.onResult = (result) {
      print('🎤 Voice result received in home dashboard: "$result"');
      if (_isVoiceMode) {
        _processVoiceCommand(result);
      }
    };

    VoiceService.onError = (error) {
      print('❌ Voice error in home dashboard: $error');
      if (_isVoiceMode) {
        _showErrorSnackBar('Voice recognition error: $error');
        setState(() {
          _isVoiceMode = false;
        });
      }
    };
  }

  void _setupAnimations() {
    _balanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _balanceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeInOut,
    ));

    _balanceAnimationController.forward();
  }

  void _processVoiceCommand(String command) {
    print('🎤 Processing voice command: "$command"');

    // Stop listening to prevent multiple recognitions
    VoiceService.stopListening();

    // First check if this is a direct transfer command with contact name
    final extractedName = PhoneContactsService.extractNameFromCommand(command);
    final extractedAmount =
        PhoneContactsService.extractAmountFromCommand(command);

    if (extractedName != null) {
      print(
          '🎯 Direct transfer detected: $extractedName, amount: $extractedAmount');
      _handleDirectTransferCommand(command, extractedName, extractedAmount);
      setState(() {
        _isVoiceMode = false;
      });
      return;
    }

    final processedCommand = VoiceService.processVoiceCommand(command);
    final action = processedCommand['action'];

    print('🎯 Detected action: $action');
    print('🎯 Full processed command: $processedCommand');

    // Provide immediate feedback that command was recognized
    final settings = ref.read(appSettingsProvider);
    final language = settings['preferred_language'] ?? 'hi-IN';

    switch (action) {
      case 'send_money':
        _handleSendMoneyCommand(processedCommand);
        break;
      case 'receive_money':
        _handleReceiveMoneyCommand();
        break;
      case 'check_balance':
        _handleCheckBalanceCommand();
        break;
      case 'view_history':
        _handleViewHistoryCommand();
        break;
      case 'help':
        _handleHelpCommand();
        break;
      default:
        _handleUnknownCommand(command, language);
    }

    // Reset voice mode after processing
    setState(() {
      _isVoiceMode = false;
    });
  }

  void _handleSendMoneyCommand(Map<String, dynamic> command) {
    // Check if user has sufficient balance first
    final user = ref.read(userProvider);
    final settings = ref.read(appSettingsProvider);
    final language = settings['preferred_language'] ?? 'hi-IN';

    if (user == null) {
      _speakAndShowError('User not found', language);
      return;
    }

    if (user.balance <= 0) {
      final message = language == 'hi-IN'
          ? 'आपके खाते में पर्याप्त बैलेंस नहीं है।'
          : 'You do not have sufficient balance to send money.';
      VoiceService.speak(message, language: language);
      _showErrorSnackBar(message);
      return;
    }

    // Provide confirmation and navigate
    final confirmMessage = language == 'hi-IN'
        ? 'पैसे भेजने के लिए आपको भेजने वाले व्यक्ति का चयन करना होगा।'
        : 'Opening send money screen. Please select the recipient.';

    VoiceService.speak(confirmMessage, language: language);
    ref.read(navigationProvider.notifier).navigateTo('send-money');
  }

  void _handleReceiveMoneyCommand() {
    final settings = ref.read(appSettingsProvider);
    final language = settings['preferred_language'] ?? 'hi-IN';

    final confirmMessage = language == 'hi-IN'
        ? 'पैसे प्राप्त करने के लिए आपका QR कोड दिखाया जा रहा है।'
        : 'Opening receive money screen to show your QR code.';

    VoiceService.speak(confirmMessage, language: language);
    ref.read(navigationProvider.notifier).navigateTo('receive-money');
  }

  void _handleCheckBalanceCommand() {
    print('💰 Handling check balance command');
    final user = ref.read(userProvider);
    if (user != null) {
      final settings = ref.read(appSettingsProvider);
      final language = settings['preferred_language'] ?? 'hi-IN';

      final balanceText = language == 'hi-IN'
          ? VoiceService.getHindiResponse('check_balance',
              additionalInfo: user.balance.toStringAsFixed(0))
          : 'Your current balance is ${user.balance.toStringAsFixed(0)} rupees';

      print('💰 Speaking balance: "$balanceText"');
      VoiceService.speak(balanceText, language: language);
    } else {
      print('❌ User is null, cannot check balance');
    }
  }

  void _handleViewHistoryCommand() {
    final settings = ref.read(appSettingsProvider);
    final language = settings['preferred_language'] ?? 'hi-IN';

    final confirmMessage = language == 'hi-IN'
        ? 'आपके लेनदेन का इतिहास दिखाया जा रहा है।'
        : 'Opening transaction history.';

    VoiceService.speak(confirmMessage, language: language);
    ref.read(navigationProvider.notifier).navigateTo('history');
  }

  void _handleHelpCommand() {
    final settings = ref.read(appSettingsProvider);
    final language = settings['preferred_language'] ?? 'hi-IN';

    final helpText = language == 'hi-IN'
        ? 'आप कह सकते हैं: पैसे भेजो, पैसे प्राप्त करो, बैलेंस चेक करो, इतिहास दिखाओ, या किसी व्यक्ति का नाम लेकर पैसे भेजो जैसे "राहुल को 500 रुपये भेजो"'
        : 'You can say: Send money, Receive money, Check balance, View history, or send money to someone by saying their name like "Send 500 rupees to Rahul"';

    VoiceService.speak(helpText, language: language);
  }

  void _handleUnknownCommand(String command, String language) {
    print('❓ Unknown command: "$command"');

    final errorMessage = language == 'hi-IN'
        ? 'मुझे समझ नहीं आया। कृपया फिर से कहें: पैसे भेजो, पैसे प्राप्त करो, बैलेंस चेक करो, या मदद।'
        : 'I did not understand. Please say: Send money, Receive money, Check balance, or Help.';

    VoiceService.speak(errorMessage, language: language);
    _showErrorSnackBar('Command not recognized. Please try again.');
  }

  void _speakAndShowError(String message, String language) {
    final localizedMessage = language == 'hi-IN'
        ? 'कुछ गलत हुआ है। कृपया फिर से कोशिश करें।'
        : 'Something went wrong. Please try again.';

    VoiceService.speak(localizedMessage, language: language);
    _showErrorSnackBar(message);
  }

  void _handleDirectTransferCommand(
      String originalCommand, String contactName, double? amount) async {
    final user = ref.read(userProvider);
    final settings = ref.read(appSettingsProvider);
    final language = settings['preferred_language'] ?? 'hi-IN';

    if (user == null) {
      _speakAndShowError('User not found', language);
      return;
    }

    if (user.balance <= 0) {
      final message = language == 'hi-IN'
          ? 'आपके खाते में पर्याप्त बैलेंस नहीं है।'
          : 'You do not have sufficient balance to send money.';
      VoiceService.speak(message, language: language);
      _showErrorSnackBar(message);
      return;
    }

    // Find contact by name with enhanced matching
    final contact = _findBestContactMatch(contactName);

    if (contact == null) {
      final message = language == 'hi-IN'
          ? '$contactName नाम का कोई संपर्क नहीं मिला। कृपया नाम दोबारा कहें।'
          : 'Contact $contactName not found. Please say the name again.';
      VoiceService.speak(message, language: language);
      _showErrorSnackBar('Contact not found: $contactName');
      return;
    }

    // If amount is provided, proceed with transfer
    if (amount != null && amount > 0) {
      if (amount > user.balance) {
        final message = language == 'hi-IN'
            ? 'आपके पास पर्याप्त बैलेंस नहीं है। आपका बैलेंस ${user.balance.toStringAsFixed(0)} रुपये है।'
            : 'Insufficient balance. Your balance is ${user.balance.toStringAsFixed(0)} rupees.';
        VoiceService.speak(message, language: language);
        _showErrorSnackBar('Insufficient balance');
        return;
      }

      // Confirm the transaction
      final confirmMessage = language == 'hi-IN'
          ? '${contact.name} को ${amount.toStringAsFixed(0)} रुपये भेजने के लिए अपना PIN दर्ज करें।'
          : 'Enter your PIN to send ${amount.toStringAsFixed(0)} rupees to ${contact.name}.';

      VoiceService.speak(confirmMessage, language: language);

      // Show PIN dialog with fraud detection
      _showPinDialogWithFraudDetection(contact, amount, language);
    } else {
      // Ask for amount
      final message = language == 'hi-IN'
          ? '${contact.name} को कितने रुपये भेजना चाहते हैं?'
          : 'How much money do you want to send to ${contact.name}?';
      VoiceService.speak(message, language: language);

      // For now, navigate to send money screen
      // TODO: Implement amount input via voice
      ref.read(navigationProvider.notifier).navigateTo('send-money');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Enhanced contact matching with fuzzy search
  ContactModel? _findBestContactMatch(String contactName) {
    final contacts = ref.read(contactsProvider);
    if (contacts.isEmpty) return null;

    final lowerName = contactName.toLowerCase().trim();

    // 1. Exact match
    for (final contact in contacts) {
      if (contact.name.toLowerCase() == lowerName) {
        return contact;
      }
    }

    // 2. Contains match
    for (final contact in contacts) {
      if (contact.name.toLowerCase().contains(lowerName) ||
          lowerName.contains(contact.name.toLowerCase())) {
        return contact;
      }
    }

    // 3. First name match
    for (final contact in contacts) {
      final firstName = contact.name.split(' ').first.toLowerCase();
      if (firstName == lowerName || lowerName.contains(firstName)) {
        return contact;
      }
    }

    // 4. Partial word match
    for (final contact in contacts) {
      final words = contact.name.toLowerCase().split(' ');
      for (final word in words) {
        if (word.startsWith(lowerName) || lowerName.startsWith(word)) {
          return contact;
        }
      }
    }

    return null;
  }

  /// PIN dialog with fraud detection
  void _showPinDialogWithFraudDetection(
      ContactModel contact, double amount, String language) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        title: language == 'hi-IN' ? 'PIN दर्ज करें' : 'Enter PIN',
        message: language == 'hi-IN'
            ? '${contact.name} को ₹${amount.toStringAsFixed(0)} भेजने के लिए PIN दर्ज करें'
            : 'Enter PIN to send ₹${amount.toStringAsFixed(0)} to ${contact.name}',
        onPinEntered: (pin) async {
          Navigator.of(context).pop();
          await _processDirectTransferWithFraudDetection(
              contact, amount, pin, language);
        },
        onCancel: () {
          Navigator.of(context).pop();
          final cancelMessage = language == 'hi-IN'
              ? 'लेनदेन रद्द किया गया।'
              : 'Transaction cancelled.';
          VoiceService.speak(cancelMessage, language: language);
        },
      ),
    );
  }

  /// Process transfer with fraud detection
  Future<void> _processDirectTransferWithFraudDetection(
      ContactModel contact, double amount, String pin, String language) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    // Check for fraud patterns
    final fraudDetected = await _checkForFraud(user, pin, contact, amount);

    if (fraudDetected) {
      // Notify trusted contact
      await _notifyTrustedContact(user, contact, amount, language);

      final fraudMessage = language == 'hi-IN'
          ? 'संदिग्ध लेनदेन का पता चला है। आपके विश्वसनीय संपर्क को सूचित किया गया है।'
          : 'Suspicious transaction detected. Your trusted contact has been notified.';

      VoiceService.speak(fraudMessage, language: language);
      _showErrorSnackBar('Suspicious transaction detected');
      return;
    }

    // Verify PIN (in real app, this would be against stored PIN)
    if (!_verifyPin(pin, user)) {
      final errorMessage = language == 'hi-IN'
          ? 'गलत PIN। कृपया पुनः प्रयास करें।'
          : 'Incorrect PIN. Please try again.';

      VoiceService.speak(errorMessage, language: language);
      _showErrorSnackBar('Incorrect PIN');
      return;
    }

    try {
      // Show loading
      setState(() {
        _isVoiceMode = true;
      });

      // Process transaction
      await ref.read(transactionsProvider.notifier).sendMoney(
            senderId: user.id,
            receiverId: contact.userId,
            amount: amount,
            description: 'Voice transfer to ${contact.name}',
          );

      // Update user balance
      await ref
          .read(userProvider.notifier)
          .updateBalance(user.balance - amount);

      // Success message
      final successMessage = language == 'hi-IN'
          ? '${amount.toStringAsFixed(0)} रुपये ${contact.name} को सफलतापूर्वक भेजे गए।'
          : '${amount.toStringAsFixed(0)} rupees sent to ${contact.name} successfully.';

      VoiceService.speak(successMessage, language: language);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final errorMessage = language == 'hi-IN'
          ? 'लेनदेन असफल रहा। कृपया पुनः प्रयास करें।'
          : 'Transaction failed. Please try again.';

      VoiceService.speak(errorMessage, language: language);
      _showErrorSnackBar('Transaction failed: $e');
    } finally {
      setState(() {
        _isVoiceMode = false;
      });
    }
  }

  /// Check for fraud patterns
  Future<bool> _checkForFraud(
      UserModel user, String pin, ContactModel contact, double amount) async {
    // Example fraud detection logic
    // In real app, this would be more sophisticated

    // Check if PIN is suspicious (example: if last digit is wrong)
    final userPin = "1234"; // In real app, this would be stored securely
    if (pin.length == 4) {
      final lastDigit = pin[3];
      final correctLastDigit = userPin[3];

      if (lastDigit != correctLastDigit) {
        // This could be a typo or fraud attempt
        // In real implementation, you'd track failed attempts
        return true; // For demo purposes, treat as fraud
      }
    }

    // Check for unusual amounts
    if (amount > user.balance * 0.8) {
      // More than 80% of balance
      return true;
    }

    // Check for unusual time (example: very late night)
    final hour = DateTime.now().hour;
    if (hour < 6 || hour > 23) {
      return true;
    }

    return false;
  }

  /// Verify PIN against user's stored PIN
  bool _verifyPin(String enteredPin, UserModel user) {
    // In real app, this would verify against securely stored PIN
    // For demo purposes, using a simple check
    const correctPin = "1234";
    return enteredPin == correctPin;
  }

  /// Notify trusted contact about suspicious activity
  Future<void> _notifyTrustedContact(UserModel user, ContactModel contact,
      double amount, String language) async {
    try {
      // In real app, this would send SMS/email to trusted contact
      print('🚨 FRAUD ALERT: Notifying trusted contact ${user.trustedContact}');
      print(
          '🚨 Suspicious transaction: ${user.name} trying to send ₹${amount.toStringAsFixed(0)} to ${contact.name}');

      // Log fraud attempt
      final fraudLog = FraudLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        fraudType: 'voice_transfer_fraud',
        description:
            'Suspicious PIN entry or unusual transaction pattern for ${contact.name}',
        severity: 'high',
        isResolved: false,
        alertSent: true,
        createdAt: DateTime.now(),
      );
      await ref.read(fraudLogsProvider.notifier).addFraudLog(fraudLog);
    } catch (e) {
      print('Error notifying trusted contact: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final transactions = ref.watch(transactionsProvider);

    print(
        '🏠 Home Dashboard build - User: ${user?.name}, Balance: ${user?.balance}');

    if (user == null) {
      print('⚠️ User is null in Home Dashboard, showing loading');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF10B981),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(user),
              _buildBalanceCard(user),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                      _buildVoiceAssistantButton(),
                      const SizedBox(height: 32),
                      _buildRecentTransactions(transactions),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user.name.split(' ').first}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Good to see you!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFE0F2FE),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(navigationProvider.notifier).navigateTo('settings');
            },
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Balance',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showBalance = !_showBalance;
                      });
                    },
                    icon: Icon(
                      _showBalance ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _balanceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _balanceAnimation.value,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.currency_rupee,
                          size: 40,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _showBalance
                              ? '₹${user.balance.toStringAsFixed(0).replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  )}'
                              : '••••',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.send,
              label: 'Send Money',
              color: const Color(0xFF3B82F6),
              onTap: () {
                ref.read(navigationProvider.notifier).navigateTo('send-money');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.download,
              label: 'Receive Money',
              color: const Color(0xFF10B981),
              onTap: () {
                ref
                    .read(navigationProvider.notifier)
                    .navigateTo('receive-money');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceAssistantButton() {
    return VoiceButton(
      onPressed: () async {
        setState(() {
          _isVoiceMode = true;
        });

        final settings = ref.read(appSettingsProvider);
        final language = settings['preferred_language'] ?? 'hi-IN';

        final greetingText = language == 'hi-IN'
            ? VoiceService.getGreeting(language)
            : 'How can I help you today?';

        await VoiceService.speak(greetingText, language: language);

        await VoiceService.startListening();
      },
      isActive: _isVoiceMode,
      label: 'Tap to speak',
    );
  }

  Widget _buildRecentTransactions(List<TransactionModel> transactions) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    ref.read(navigationProvider.notifier).navigateTo('history');
                  },
                  icon: const Icon(
                    Icons.history,
                    color: Color(0xFF82F6),
                  ),
                  label: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: transactions.take(3).length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return TransactionCard(
                          transaction: transaction,
                          onTap: () {}, // optional action
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _balanceAnimationController.dispose();
    super.dispose();
  }
}
