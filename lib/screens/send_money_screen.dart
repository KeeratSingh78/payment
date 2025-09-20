import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/voice_service.dart';
import '../services/fraud_detection_service.dart';
import '../services/supabase_service.dart';
import '../widgets/voice_button.dart';
import '../widgets/pin_input_dialog.dart';
import '../models/contact_model.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  final String? recipientName;
  final double? prefillAmount;

  const SendMoneyScreen({super.key, this.recipientName, this.prefillAmount});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _currentStep = 1; // 1: Select Contact, 2: Enter Amount, 3: Confirm
  ContactModel? _selectedContact;
  double _amount = 0.0;
  bool _isVoiceMode = false;
  bool _isLoading = false;

  // PIN verification tracking
  String? _lastAttemptedPin;
  int _pinAttempts = 0;

  @override
  void initState() {
    super.initState();
    _setupVoiceCallbacks();
    _loadContacts();

    // Pre-fill recipient and amount if passed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.recipientName != null) {
        final contacts = ref.read(contactsProvider);
        final matched = contacts.where(
          (c) => c.name.toLowerCase() == widget.recipientName!.toLowerCase(),
        );
        if (matched.isNotEmpty) {
          setState(() {
            _selectedContact = matched.first;
            _currentStep = 2;
          });
        }
      }
      if (widget.prefillAmount != null && widget.prefillAmount! > 0) {
        setState(() {
          _amount = widget.prefillAmount!;
          _amountController.text = _amount.toStringAsFixed(0);
        });
      }
    });
  }

  void _setupVoiceCallbacks() {
    VoiceService.onResult = (result) {
      print('🎤 Voice result received: "$result"');
      if (_isVoiceMode) {
        _processVoiceInput(result);
        setState(() {
          _isVoiceMode = false;
        });
      }
    };

    VoiceService.onError = (error) {
      print('❌ Voice error: $error');
      if (_isVoiceMode) {
        _showErrorSnackBar('Voice recognition error: $error');
        setState(() {
          _isVoiceMode = false;
        });
      }
    };
  }

  void _loadContacts() {
    final user = ref.read(userProvider);
    if (user != null) {
      ref.read(contactsProvider.notifier).loadContacts(user.id);
    }
  }

  void _processVoiceInput(String input) {
    print('🎤 Processing voice input: "$input" for step $_currentStep');

    if (_currentStep == 1) {
      // Process contact selection with enhanced matching
      final contacts = ref.read(contactsProvider);
      final lowerInput = input.toLowerCase().trim();

      print('🔍 Searching for contact with input: "$lowerInput"');
      print('📋 Available contacts: ${contacts.map((c) => c.name).toList()}');

      // Try exact match first
      ContactModel? matchedContact;
      for (final contact in contacts) {
        final contactName = contact.name.toLowerCase();
        if (contactName == lowerInput) {
          matchedContact = contact;
          break;
        }
      }

      // Try partial match if no exact match
      if (matchedContact == null) {
        for (final contact in contacts) {
          final contactName = contact.name.toLowerCase();
          if (contactName.contains(lowerInput) ||
              lowerInput.contains(contactName)) {
            matchedContact = contact;
            break;
          }
        }
      }

      // Try first name match
      if (matchedContact == null) {
        for (final contact in contacts) {
          final firstName = contact.name.split(' ').first.toLowerCase();
          if (firstName == lowerInput || lowerInput.contains(firstName)) {
            matchedContact = contact;
            break;
          }
        }
      }

      // Try phone number match
      if (matchedContact == null) {
        final phoneDigits = input.replaceAll(RegExp(r'[^\d]'), '');
        for (final contact in contacts) {
          if (contact.phone.contains(phoneDigits)) {
            matchedContact = contact;
            break;
          }
        }
      }

      if (matchedContact != null) {
        print('✅ Contact found: ${matchedContact.name}');
        setState(() {
          _selectedContact = matchedContact;
          _currentStep = 2;
        });

        // Provide feedback
        final settings = ref.read(appSettingsProvider);
        final language = settings['preferred_language'] ?? 'hi-IN';
        final message = language == 'hi-IN'
            ? '${matchedContact.name} चुना गया। अब राशि दर्ज करें।'
            : '${matchedContact.name} selected. Now enter the amount.';
        VoiceService.speak(message, language: language);
      } else {
        print('❌ No contact found for input: "$input"');
        final settings = ref.read(appSettingsProvider);
        final language = settings['preferred_language'] ?? 'hi-IN';
        final message = language == 'hi-IN'
            ? 'कोई संपर्क नहीं मिला। कृपया नाम दोबारा कहें।'
            : 'No contact found. Please say the name again.';
        VoiceService.speak(message, language: language);
        _showErrorSnackBar('Contact not found: $input');
      }
    } else if (_currentStep == 2) {
      // Process amount input or send commands
      final lowerInput = input.toLowerCase();

      // Check for send commands
      if (lowerInput.contains('send') ||
          lowerInput.contains('भेज') ||
          lowerInput.contains('भेजो') ||
          lowerInput.contains('proceed') ||
          lowerInput.contains('continue')) {
        if (_amount > 0 && _selectedContact != null) {
          // Proceed to confirmation or send directly
          _proceedToConfirmation();
        } else {
          final settings = ref.read(appSettingsProvider);
          final language = settings['preferred_language'] ?? 'hi-IN';
          final message = language == 'hi-IN'
              ? 'कृपया पहले राशि दर्ज करें।'
              : 'Please enter an amount first.';
          VoiceService.speak(message, language: language);
        }
        return;
      }

      // Process amount input
      final amountRegex = RegExp(r'(\d+(?:,\d{3})*(?:\.\d{2})?)');
      final match = amountRegex.firstMatch(input);
      if (match != null) {
        final amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (amount != null && amount > 0) {
          setState(() {
            _amount = amount;
            _amountController.text = amount.toStringAsFixed(0);
          });

          // Provide feedback
          final settings = ref.read(appSettingsProvider);
          final language = settings['preferred_language'] ?? 'hi-IN';
          final message = language == 'hi-IN'
              ? 'राशि ${amount.toStringAsFixed(0)} रुपये सेट की गई। भेजने के लिए "भेजो" कहें।'
              : 'Amount set to ${amount.toStringAsFixed(0)} rupees. Say "send" to proceed.';
          VoiceService.speak(message, language: language);
        }
      }
    }
  }

  void _selectContact(ContactModel contact) {
    setState(() {
      _selectedContact = contact;
      _currentStep = 2;
    });
  }

  void _setAmount(double amount) {
    setState(() {
      _amount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _confirmTransaction() async {
    if (_selectedContact == null || _amount <= 0) {
      _showErrorSnackBar('Please select a contact and enter amount');
      return;
    }

    final user = ref.read(userProvider);
    if (user == null) return;

    if (_amount > user.balance) {
      _showErrorSnackBar('Insufficient balance');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isFraud = await FraudDetectionService.detectFraud(
        userId: user.id,
        amount: _amount,
        description: 'Payment to ${_selectedContact!.name}',
        recipientName: _selectedContact!.name,
      );

      if (isFraud) {
        _showErrorSnackBar('Transaction blocked due to security concerns');
        return;
      }

      await ref.read(transactionsProvider.notifier).sendMoney(
            senderId: user.id,
            receiverId: _selectedContact!.userId,
            amount: _amount,
            description: 'Payment to ${_selectedContact!.name}',
          );

      // Update user balance with validation
      final newBalance = user.balance - _amount;
      if (newBalance < 0) {
        throw Exception('Balance cannot go negative');
      }

      await ref.read(userProvider.notifier).updateBalance(newBalance);

      final settings = ref.read(appSettingsProvider);
      final language = settings['preferred_language'] ?? 'hi-IN';

      final successMessage = language == 'hi-IN'
          ? VoiceService.getHindiResponse('transaction_success',
              additionalInfo:
                  '${_amount.toStringAsFixed(0)} रुपये ${_selectedContact!.name} को सफलतापूर्वक भेजे गए।')
          : '${_amount.toStringAsFixed(0)} rupees sent to ${_selectedContact!.name} successfully';

      await VoiceService.speak(successMessage, language: language);

      // Show success message and navigate after delay
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to home after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            print('🔄 Navigating to home after successful payment (main flow)');
            ref.read(navigationProvider.notifier).navigateTo('home');
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Transaction failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);
    final user = ref.watch(userProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

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
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: isTablet
                      ? _buildTabletLayout(contacts, user, screenSize)
                      : _buildMobileLayout(contacts, user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_currentStep == 1) {
                ref.read(navigationProvider.notifier).navigateTo('home');
              } else {
                setState(() {
                  _currentStep--;
                  if (_currentStep == 1) _selectedContact = null;
                  if (_currentStep == 2) _amount = 0.0;
                });
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          Expanded(
            child: Text(
              _getStepTitle(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              try {
                setState(() {
                  _isVoiceMode = true;
                });

                final settings = ref.read(appSettingsProvider);
                final language = settings['preferred_language'] ?? 'hi-IN';

                String prompt = _currentStep == 1
                    ? (language == 'hi-IN'
                        ? 'कृपया व्यक्ति का नाम बताएं'
                        : 'Please say the name of the person')
                    : _currentStep == 2
                        ? (language == 'hi-IN'
                            ? 'कृपया राशि बताएं'
                            : 'Please say the amount')
                        : (language == 'hi-IN'
                            ? 'कृपया लेनदेन की पुष्टि करें'
                            : 'Please confirm the transaction');

                print('🎤 Starting voice recognition for step $_currentStep');
                await VoiceService.speak(prompt, language: language);

                // Wait a bit for speech to complete
                await Future.delayed(const Duration(milliseconds: 500));

                await VoiceService.startListening(
                  localeId: language == 'hi-IN' ? 'hi-IN' : 'en-US',
                  listenFor: const Duration(seconds: 10),
                );
              } catch (e) {
                print('❌ Error starting voice recognition: $e');
                _showErrorSnackBar('Failed to start voice recognition: $e');
                setState(() {
                  _isVoiceMode = false;
                });
              }
            },
            icon: Icon(
              _isVoiceMode ? Icons.mic : Icons.mic_none,
              color: _isVoiceMode ? Colors.yellow : Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Select Contact';
      case 2:
        return 'Enter Amount';
      case 3:
        return 'Confirm Payment';
      default:
        return 'Send Money';
    }
  }

  Widget _buildMobileLayout(List<ContactModel> contacts, user) {
    return _buildCurrentStep(contacts, user);
  }

  Widget _buildTabletLayout(
      List<ContactModel> contacts, user, Size screenSize) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.1,
        vertical: 20,
      ),
      child: _buildCurrentStep(contacts, user),
    );
  }

  Widget _buildCurrentStep(List<ContactModel> contacts, user) {
    switch (_currentStep) {
      case 1:
        return _buildContactSelection(contacts);
      case 2:
        return _buildAmountEntry();
      case 3:
        return _buildConfirmation();
      default:
        return const SizedBox();
    }
  }

  Widget _buildContactSelection(List<ContactModel> contacts) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Padding(
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts or enter phone number',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Contacts List
          Expanded(
            child: contacts.isEmpty
                ? Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  )
                : _buildContactsList(contacts, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(List<ContactModel> contacts, bool isTablet) {
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isVisible = _searchController.text.isEmpty ||
            contact.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
            contact.phone.contains(_searchController.text);

        if (!isVisible) return const SizedBox.shrink();

        return Card(
          margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            onTap: () => _selectContact(contact),
            leading: CircleAvatar(
              radius: isTablet ? 28 : 24,
              backgroundColor: const Color(0xFF3B82F6),
              child: Text(
                contact.name[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ),
            title: Text(
              contact.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
            subtitle: Text(
              contact.phone,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (contact.isFrequent)
                  const Icon(
                    Icons.star,
                    color: Color(0xFFF59E0B),
                  ),
                const SizedBox(width: 8),
                // Send button for direct transfer
                IconButton(
                  onPressed: () => _sendMoneyDirectly(contact),
                  icon: const Icon(
                    Icons.send,
                    color: Color(0xFF3B82F6),
                  ),
                  tooltip: 'Send money directly',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountEntry() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Padding(
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Selected Contact
            if (_selectedContact != null)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isTablet ? 28 : 24,
                        backgroundColor: const Color(0xFF3B82F6),
                        child: Text(
                          _selectedContact!.name[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 18 : 16,
                          ),
                        ),
                      ),
                      SizedBox(width: isTablet ? 20 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sending to',
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _selectedContact!.name,
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: isTablet ? 40 : 32),

            // Amount Input
            Text(
              'Enter Amount',
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),

            SizedBox(height: isTablet ? 32 : 24),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: isTablet ? 40 : 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: isTablet ? 24 : 20,
                ),
              ),
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null) {
                  _setAmount(amount);
                }
              },
            ),

            SizedBox(height: isTablet ? 32 : 24),

            // Quick Amount Buttons
            _buildQuickAmountButtons(isTablet),

            SizedBox(height: isTablet ? 40 : 32),

            // Voice Button
            VoiceButton(
              onPressed: () async {
                setState(() {
                  _isVoiceMode = true;
                });

                final settings = ref.read(appSettingsProvider);
                final language = settings['preferred_language'] ?? 'hi-IN';

                await VoiceService.speak(
                  'Please say the amount you want to send',
                  language: language,
                );

                await VoiceService.startListening();
              },
              isActive: _isVoiceMode,
              label: 'Speak amount',
            ),

            SizedBox(height: isTablet ? 40 : 32),

            // Send Button (only show if amount is entered)
            if (_amount > 0) ...[
              SizedBox(
                width: double.infinity,
                height: isTablet ? 64 : 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _proceedToConfirmation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Send ₹${_amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              SizedBox(height: isTablet ? 20 : 16),

              // Voice Send Button
              SizedBox(
                width: double.infinity,
                height: isTablet ? 56 : 48,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : () => _sendWithVoice(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.mic,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                  label: Text(
                    'Send with Voice',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButtons(bool isTablet) {
    return Wrap(
      spacing: isTablet ? 12 : 8,
      runSpacing: isTablet ? 12 : 8,
      children: [100, 500, 1000, 2000, 5000, 10000]
          .map((amount) => _buildQuickAmountButton(amount, isTablet))
          .toList(),
    );
  }

  Widget _buildQuickAmountButton(int amount, bool isTablet) {
    return GestureDetector(
      onTap: () => _setAmount(amount.toDouble()),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 10 : 6,
        ),
        decoration: BoxDecoration(
          color: _amount == amount
              ? const Color(0xFF3B82F6)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '₹${amount.toString()}',
          style: TextStyle(
            color: _amount == amount ? Colors.white : const Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmation() {
    final user = ref.watch(userProvider);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Padding(
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      child: Column(
        children: [
          // Transaction Summary
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              child: Column(
                children: [
                  Text(
                    'Transaction Summary',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),

                  SizedBox(height: isTablet ? 32 : 24),

                  // Recipient
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'To',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        _selectedContact?.name ?? '',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '₹${_amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Balance After
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance After',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '₹${(user?.balance ?? 0 - _amount).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: isTablet ? 64 : 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _confirmTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Confirm Payment',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Send money directly with voice support and fraud detection
  void _sendMoneyDirectly(ContactModel contact) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    // Check balance
    if (user.balance <= 0) {
      _showErrorSnackBar('Insufficient balance');
      return;
    }

    // Ask for amount via voice
    final settings = ref.read(appSettingsProvider);
    final language = settings['preferred_language'] ?? 'hi-IN';

    final message = language == 'hi-IN'
        ? '${contact.name} को कितने रुपये भेजना चाहते हैं?'
        : 'How much money do you want to send to ${contact.name}?';

    VoiceService.speak(message, language: language);

    // For now, show amount input dialog
    _showAmountInputDialog(contact, language);
  }

  /// Show amount input dialog
  void _showAmountInputDialog(ContactModel contact, String language) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(language == 'hi-IN' ? 'राशि दर्ज करें' : 'Enter Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              language == 'hi-IN'
                  ? '${contact.name} को कितने रुपये भेजना चाहते हैं?'
                  : 'How much do you want to send to ${contact.name}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: language == 'hi-IN' ? 'राशि' : 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(language == 'hi-IN' ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.of(context).pop();
                _processDirectTransfer(contact, amount, language);
              }
            },
            child: Text(language == 'hi-IN' ? 'भेजें' : 'Send'),
          ),
        ],
      ),
    );
  }

  /// Process direct transfer with fraud detection
  Future<void> _processDirectTransfer(
      ContactModel contact, double amount, String language) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    if (amount > user.balance) {
      final message = language == 'hi-IN'
          ? 'आपके पास पर्याप्त बैलेंस नहीं है। आपका बैलेंस ${user.balance.toStringAsFixed(0)} रुपये है।'
          : 'Insufficient balance. Your balance is ${user.balance.toStringAsFixed(0)} rupees.';
      VoiceService.speak(message, language: language);
      _showErrorSnackBar('Insufficient balance');
      return;
    }

    // Show PIN dialog with fraud detection
    _showPinDialogWithFraudDetection(contact, amount, language);
  }

  /// PIN dialog with fraud detection
  void _showPinDialogWithFraudDetection(
      ContactModel contact, double amount, String language) {
    print(
        '🔐 Showing PIN dialog for ${contact.name}, amount: ₹${amount.toStringAsFixed(0)}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        title: language == 'hi-IN' ? 'PIN दर्ज करें' : 'Enter PIN',
        message: language == 'hi-IN'
            ? '${contact.name} को ₹${amount.toStringAsFixed(0)} भेजने के लिए PIN दर्ज करें'
            : 'Enter PIN to send ₹${amount.toStringAsFixed(0)} to ${contact.name}',
        onPinEntered: (pin) async {
          print('🔐 PIN entered: $pin');
          Navigator.of(context).pop();
          await _processTransferWithFraudDetection(
              contact, amount, pin, language);
        },
        onCancel: () {
          print('❌ PIN dialog cancelled');
          Navigator.of(context).pop();
          final cancelMessage = language == 'hi-IN'
              ? 'लेनदेन रद्द किया गया।'
              : 'Transaction cancelled.';
          VoiceService.speak(cancelMessage, language: language);
        },
      ),
    );
  }

  /// Process transfer with enhanced fraud detection
  Future<void> _processTransferWithFraudDetection(
      ContactModel contact, double amount, String pin, String language) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    // Double-check balance before processing
    if (amount > user.balance) {
      final message = language == 'hi-IN'
          ? 'आपके पास पर्याप्त बैलेंस नहीं है। आपका बैलेंस ${user.balance.toStringAsFixed(0)} रुपये है।'
          : 'Insufficient balance. Your balance is ${user.balance.toStringAsFixed(0)} rupees.';
      VoiceService.speak(message, language: language);
      _showErrorSnackBar('Insufficient balance');
      return;
    }

    // Check if PIN is correct
    if (await _verifyPin(pin, user)) {
      // Correct PIN - proceed with transaction
      _pinAttempts = 0;
      _lastAttemptedPin = null;
      await _executeTransaction(contact, amount, language);
      return;
    }

    // PIN is incorrect - implement enhanced fraud detection
    _pinAttempts++;

    // Check if we've reached the maximum allowed attempts (2 attempts)
    if (_pinAttempts >= 2) {
      print(
          '🚨 Maximum PIN attempts reached ($_pinAttempts). Alerting trusted contact and blocking transaction.');
      await _handleMaxPinAttemptsReached(user, contact, amount, language);
      return;
    }

    // Check for specific fraud patterns as described
    final fraudDetected =
        await _checkPinFraudPatterns(user, pin, contact, amount, language);
    if (fraudDetected) {
      await _handleSuspiciousPinAttempt(user, contact, amount, language);
      return;
    }

    // Check if this is the same wrong PIN as last time
    if (_lastAttemptedPin == pin && _pinAttempts > 1) {
      // Same wrong PIN entered twice - this is suspicious!
      await _handleSuspiciousPinAttempt(user, contact, amount, language);
      return;
    }

    // Store this PIN attempt
    _lastAttemptedPin = pin;

    // Check if PIN length is correct
    if (pin.length != 4) {
      final message = language == 'hi-IN'
          ? 'PIN 4 अंकों का होना चाहिए। कृपया PIN को दोबारा दर्ज करें।'
          : 'PIN must be 4 digits. Please re-enter your PIN.';

      VoiceService.speak(message, language: language);
      _showErrorSnackBar('PIN must be 4 digits');

      // Show PIN dialog again with a small delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _showPinDialogWithFraudDetection(contact, amount, language);
        }
      });
      return;
    }

    // Other fraud patterns
    final otherFraudDetected = await _checkForFraud(user, pin, contact, amount);
    if (otherFraudDetected) {
      await _handleSuspiciousPinAttempt(user, contact, amount, language);
      return;
    }

    // Generic incorrect PIN
    final errorMessage = language == 'hi-IN'
        ? 'गलत PIN। कृपया पुनः प्रयास करें।'
        : 'Incorrect PIN. Please try again.';

    VoiceService.speak(errorMessage, language: language);
    _showErrorSnackBar('Incorrect PIN');

    // Show PIN dialog again with a small delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _showPinDialogWithFraudDetection(contact, amount, language);
      }
    });
  }

  /// Handle when maximum PIN attempts are reached (2 attempts)
  Future<void> _handleMaxPinAttemptsReached(UserModel user,
      ContactModel contact, double amount, String language) async {
    print(
        '🚨 Maximum PIN attempts reached - blocking transaction and alerting trusted contact');

    // Close any open PIN dialog immediately
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Notify trusted contact about multiple failed PIN attempts
    await _notifyTrustedContactMaxAttempts(user, contact, amount, language);

    // Show blocking message
    final blockMessage = language == 'hi-IN'
        ? 'गलत PIN के 2 प्रयास हो गए हैं। सुरक्षा के लिए लेनदेन ब्लॉक किया गया है। आपके विश्वसनीय संपर्क को सूचना भेजी गई है।'
        : 'Wrong PIN entered 2 times. Transaction blocked for security. Your trusted contact has been notified.';

    VoiceService.speak(blockMessage, language: language);
    _showErrorSnackBar('Transaction blocked after 2 wrong PIN attempts');

    // Reset PIN tracking and block further attempts
    _pinAttempts = 0;
    _lastAttemptedPin = null;

    // Navigate back to home after showing the message
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(navigationProvider.notifier).navigateTo('home');
      }
    });
  }

  /// Handle suspicious PIN attempt
  Future<void> _handleSuspiciousPinAttempt(UserModel user, ContactModel contact,
      double amount, String language) async {
    // Notify trusted contact about suspicious activity
    await _notifyTrustedContact(user, contact, amount, language);

    final fraudMessage = language == 'hi-IN'
        ? 'संदिग्ध PIN प्रयास का पता चला है। आपके विश्वसनीय संपर्क को सूचित किया गया है। लेनदेन रद्द किया गया।'
        : 'Suspicious PIN attempt detected. Your trusted contact has been notified. Transaction cancelled.';

    VoiceService.speak(fraudMessage, language: language);
    _showErrorSnackBar('Suspicious activity detected - Transaction cancelled');

    // Reset PIN tracking
    _pinAttempts = 0;
    _lastAttemptedPin = null;
  }

  /// Notify trusted contact when maximum PIN attempts are reached
  Future<void> _notifyTrustedContactMaxAttempts(UserModel user,
      ContactModel contact, double amount, String language) async {
    try {
      print(
          '🚨 SECURITY ALERT: Maximum PIN attempts reached - notifying trusted contact ${user.trustedContact}');
      print(
          '🚨 Blocked transaction: ${user.name} tried to send ₹${amount.toStringAsFixed(0)} to ${contact.name}');
      print('🚨 Total PIN attempts: $_pinAttempts');

      // Create detailed fraud log for max attempts
      final fraudLog = FraudLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        fraudType: 'max_pin_attempts_reached',
        description:
            'SECURITY ALERT: Multiple wrong PIN attempts detected. User: ${user.name}, Contact: ${contact.name}, Amount: ₹${amount.toStringAsFixed(0)}, Total attempts: $_pinAttempts. Transaction blocked for security.',
        severity: 'critical',
        isResolved: false,
        alertSent: true,
        createdAt: DateTime.now(),
      );

      await ref.read(fraudLogsProvider.notifier).addFraudLog(fraudLog);

      // Send specific alert for max attempts
      await _sendMaxAttemptsAlert(user, contact, amount, language);
    } catch (e) {
      print('Error notifying trusted contact about max attempts: $e');
    }
  }

  /// Enhanced trusted contact notification with detailed fraud information
  Future<void> _notifyTrustedContact(UserModel user, ContactModel contact,
      double amount, String language) async {
    try {
      print('🚨 FRAUD ALERT: Notifying trusted contact ${user.trustedContact}');
      print(
          '🚨 Suspicious transaction: ${user.name} trying to send ₹${amount.toStringAsFixed(0)} to ${contact.name}');
      print(
          '🚨 PIN attempts: $_pinAttempts, Last attempted PIN: $_lastAttemptedPin');

      // Create detailed fraud log
      final fraudLog = FraudLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        fraudType: 'suspicious_pin_attempt',
        description:
            'Suspicious PIN entry pattern detected. User: ${user.name}, Contact: ${contact.name}, Amount: ₹${amount.toStringAsFixed(0)}, PIN Attempts: $_pinAttempts, Last PIN: $_lastAttemptedPin',
        severity: 'high',
        isResolved: false,
        alertSent: true,
        createdAt: DateTime.now(),
      );

      await ref.read(fraudLogsProvider.notifier).addFraudLog(fraudLog);

      // Send notification to trusted contact (in real app, this would be SMS/email)
      await _sendTrustedContactAlert(user, contact, amount, language);
    } catch (e) {
      print('Error notifying trusted contact: $e');
    }
  }

  /// Send specific alert for maximum PIN attempts
  Future<void> _sendMaxAttemptsAlert(UserModel user, ContactModel contact,
      double amount, String language) async {
    try {
      // In a real app, this would send SMS or email to the trusted contact
      final alertMessage = language == 'hi-IN'
          ? '🚨 तत्काल सुरक्षा चेतावनी: ${user.name} के खाते में 2 बार गलत PIN डाला गया है। ${contact.name} को ₹${amount.toStringAsFixed(0)} भेजने का प्रयास किया गया लेकिन सुरक्षा के लिए ब्लॉक कर दिया गया। यदि यह ${user.name} नहीं है तो तुरंत संपर्क करें।'
          : '🚨 URGENT Security Alert: Wrong PIN entered 2 times in ${user.name}\'s account. Attempted to send ₹${amount.toStringAsFixed(0)} to ${contact.name} but blocked for security. If this is not ${user.name}, contact immediately.';

      print('📱 URGENT TRUSTED CONTACT ALERT: ${user.trustedContact}');
      print('📱 Message: $alertMessage');

      // Log the critical alert
      await SupabaseService.logFraudAttempt(
        userId: user.id,
        fraudType: 'max_pin_attempts_alert_sent',
        description:
            'URGENT: Max PIN attempts alert sent to trusted contact: ${user.trustedContact}',
        severity: 'critical',
      );
    } catch (e) {
      print('Error sending max attempts alert: $e');
    }
  }

  /// Send alert to trusted contact
  Future<void> _sendTrustedContactAlert(UserModel user, ContactModel contact,
      double amount, String language) async {
    try {
      // In a real app, this would send SMS or email to the trusted contact
      final alertMessage = language == 'hi-IN'
          ? '🚨 सुरक्षा चेतावनी: ${user.name} के खाते में संदिग्ध गतिविधि का पता चला है। ${contact.name} को ₹${amount.toStringAsFixed(0)} भेजने का प्रयास किया गया। कृपया तुरंत संपर्क करें।'
          : '🚨 Security Alert: Suspicious activity detected in ${user.name}\'s account. Attempted to send ₹${amount.toStringAsFixed(0)} to ${contact.name}. Please contact immediately.';

      print('📱 TRUSTED CONTACT ALERT: ${user.trustedContact}');
      print('📱 Message: $alertMessage');

      // Log the alert
      await SupabaseService.logFraudAttempt(
        userId: user.id,
        fraudType: 'trusted_contact_alert_sent',
        description: 'Alert sent to trusted contact: ${user.trustedContact}',
        severity: 'high',
      );
    } catch (e) {
      print('Error sending trusted contact alert: $e');
    }
  }

  /// Execute the actual transaction
  Future<void> _executeTransaction(
      ContactModel contact, double amount, String language) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    // Final balance check before processing
    if (amount > user.balance) {
      final message = language == 'hi-IN'
          ? 'आपके पास पर्याप्त बैलेंस नहीं है। आपका बैलेंस ${user.balance.toStringAsFixed(0)} रुपये है।'
          : 'Insufficient balance. Your balance is ${user.balance.toStringAsFixed(0)} rupees.';
      VoiceService.speak(message, language: language);
      _showErrorSnackBar('Insufficient balance');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Process transaction
      await ref.read(transactionsProvider.notifier).sendMoney(
            senderId: user.id,
            receiverId: contact.userId,
            amount: amount,
            description: 'Direct transfer to ${contact.name}',
          );

      // Update user balance with final validation
      final newBalance = user.balance - amount;
      if (newBalance < 0) {
        throw Exception('Balance cannot go negative');
      }

      await ref.read(userProvider.notifier).updateBalance(newBalance);

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
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back to home using navigation provider after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            print('🔄 Navigating to home after successful payment');
            ref.read(navigationProvider.notifier).navigateTo('home');
          }
        });
      }
    } catch (e) {
      final errorMessage = language == 'hi-IN'
          ? 'लेनदेन असफल रहा। कृपया पुनः प्रयास करें।'
          : 'Transaction failed. Please try again.';

      VoiceService.speak(errorMessage, language: language);
      _showErrorSnackBar('Transaction failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Check for specific PIN fraud patterns as described
  Future<bool> _checkPinFraudPatterns(UserModel user, String pin,
      ContactModel contact, double amount, String language) async {
    // Get user's actual PIN for comparison (this would be stored securely in real app)
    final userPin = await _getUserPin(user);
    if (userPin == null) return false;

    // Check if last digit is wrong (potential typo or fraud attempt)
    if (pin.length == 4 && userPin.length == 4) {
      final lastDigit = pin[3];
      final correctLastDigit = userPin[3];

      if (lastDigit != correctLastDigit) {
        // Last digit is wrong - ask for PIN verification again
        final message = language == 'hi-IN'
            ? 'PIN का अंतिम अंक गलत लग रहा है। कृपया PIN को दोबारा दर्ज करें।'
            : 'The last digit of PIN seems incorrect. Please re-enter your PIN.';

        VoiceService.speak(message, language: language);
        _showErrorSnackBar('Please verify your PIN again');

        // Show PIN dialog again with a small delay
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _showPinDialogWithFraudDetection(contact, amount, language);
          }
        });
        return false; // Don't treat as fraud yet, just ask for verification
      }
    }

    // Check for other suspicious patterns
    if (pin.length == 4) {
      // Check if 3 out of 4 digits are correct (potential forced entry)
      int correctDigits = 0;
      for (int i = 0; i < 4; i++) {
        if (pin[i] == userPin[i]) {
          correctDigits++;
        }
      }

      if (correctDigits == 3) {
        // 3 correct digits - potentially forced entry
        print(
            '🚨 Suspicious: 3 out of 4 PIN digits correct - potential forced entry');
        return true;
      }
    }

    return false;
  }

  /// Get user's PIN for comparison (in real app, this would be securely retrieved)
  Future<String?> _getUserPin(UserModel user) async {
    // In a real app, you would retrieve the PIN hash and compare
    // For now, we'll use a placeholder - in production this should be secure
    try {
      // This is a simplified approach - in real app, you'd verify against stored hash
      return "1234"; // This should be retrieved securely from user's stored PIN
    } catch (e) {
      print('Error retrieving user PIN: $e');
      return null;
    }
  }

  /// Check for fraud patterns with enhanced PIN verification
  Future<bool> _checkForFraud(
      UserModel user, String pin, ContactModel contact, double amount) async {
    // Check for unusual amounts
    if (amount > user.balance * 0.8) {
      // More than 80% of balance
      return true;
    }

    // Check for unusual time
    final hour = DateTime.now().hour;
    if (hour < 6 || hour > 23) {
      return true;
    }

    // Check for rapid successive transactions
    if (_pinAttempts > 3) {
      return true;
    }

    return false;
  }

  /// Verify PIN against user's stored PIN
  Future<bool> _verifyPin(String enteredPin, UserModel user) async {
    try {
      return await SupabaseService.verifyPin(user.id, enteredPin);
    } catch (e) {
      print('Error verifying PIN: $e');
      return false;
    }
  }

  /// Proceed to PIN verification step
  void _proceedToConfirmation() {
    if (_selectedContact != null && _amount > 0) {
      // Skip confirmation step, go directly to PIN verification
      final settings = ref.read(appSettingsProvider);
      final language = settings['preferred_language'] ?? 'hi-IN';

      // Show PIN dialog with fraud detection
      _showPinDialogWithFraudDetection(_selectedContact!, _amount, language);
    }
  }

  /// Send with voice confirmation
  void _sendWithVoice() async {
    if (_selectedContact == null || _amount <= 0) return;

    final settings = ref.read(appSettingsProvider);
    final language = settings['preferred_language'] ?? 'hi-IN';

    // Ask for voice confirmation
    final confirmMessage = language == 'hi-IN'
        ? 'क्या आप ${_selectedContact!.name} को ${_amount.toStringAsFixed(0)} रुपये भेजना चाहते हैं? हाँ या नहीं कहें।'
        : 'Do you want to send ${_amount.toStringAsFixed(0)} rupees to ${_selectedContact!.name}? Say yes or no.';

    VoiceService.speak(confirmMessage, language: language);

    // Set up voice callback for confirmation
    VoiceService.onResult = (result) async {
      final lowerResult = result.toLowerCase();
      final isConfirmed = lowerResult.contains('yes') ||
          lowerResult.contains('हाँ') ||
          lowerResult.contains('haan') ||
          lowerResult.contains('ok') ||
          lowerResult.contains('ठीक');

      if (isConfirmed) {
        // Proceed with transfer using enhanced fraud detection
        _showPinDialogWithFraudDetection(_selectedContact!, _amount, language);
      } else {
        // Cancel transfer
        final cancelMessage = language == 'hi-IN'
            ? 'लेनदेन रद्द किया गया।'
            : 'Transaction cancelled.';
        VoiceService.speak(cancelMessage, language: language);
      }

      // Reset voice callback
      VoiceService.onResult = null;
    };

    // Start listening for confirmation
    await VoiceService.startListening();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
