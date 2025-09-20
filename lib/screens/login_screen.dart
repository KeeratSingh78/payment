import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/voice_service.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/voice_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  int _currentStep = 1; // 1: Phone, 2: PIN
  bool _isLoading = false;
  bool _isVoiceMode = false;

  @override
  void initState() {
    super.initState();
    _setupVoiceCallbacks();
  }

  void _setupVoiceCallbacks() {
    VoiceService.onResult = (result) {
      if (_isVoiceMode) {
        setState(() {
          _processVoiceInput(result);
        });
      }
    };

    VoiceService.onError = (error) {
      if (_isVoiceMode) {
        _showErrorSnackBar('Voice recognition error: $error');
      }
    };
  }

  /// Process recognized speech and fill text fields in real-time
  void _processVoiceInput(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    debugPrint("🎤 Heard (digits only): $digits");

    if (_currentStep == 1) {
      setState(() {
        _phoneController.text = '$digits';
        _phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: _phoneController.text.length),
        );
      });
      if (digits.length >= 10) {
        _nextStep();
      }
    } else if (_currentStep == 2) {
      setState(() {
        _pinController.text =
            digits.length > 4 ? digits.substring(0, 4) : digits;
      });
      if (_pinController.text.length == 4) {
        Future.delayed(const Duration(milliseconds: 500), _handleLogin);
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 1 && _phoneController.text.length >= 10) {
      setState(() {
        _currentStep = 2;
        _pinController.clear();
      });
    }
  }

  void _previousStep() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
        _pinController.clear();
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty || _pinController.text.length != 4) {
      _showErrorSnackBar('Please enter valid phone number and PIN');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProvider.notifier).signIn(
            _phoneController.text,
            _pinController.text,
          );

      final user = ref.read(userProvider);
      if (user != null) {
        await ref.read(transactionsProvider.notifier).loadTransactions(user.id);
        await ref.read(contactsProvider.notifier).loadContacts(user.id);
        await ref.read(fraudLogsProvider.notifier).loadFraudLogs(user.id);
        await ref.read(appSettingsProvider.notifier).loadSettings(user.id);

        ref.read(navigationProvider.notifier).navigateTo('home');

        final settings = ref.read(appSettingsProvider);
        final language = settings['preferred_language'] ?? 'hi-IN';
        await VoiceService.speak(
          VoiceService.getGreeting(language),
          language: language,
        );
      } else {
        _showErrorSnackBar('Invalid phone number or PIN');
      }
    } catch (e) {
      _showErrorSnackBar('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFE8F5E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.05),
                _buildHeader(screenWidth),
                SizedBox(height: screenHeight * 0.05),
                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _currentStep == 1
                            ? _buildPhoneStep(screenHeight)
                            : _buildPinStep(screenWidth, screenHeight),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                _buildRegistrationLink(screenWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Column(
      children: [
        Container(
          width: screenWidth * 0.2,
          height: screenWidth * 0.2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B82F6), Color(0xFF10B981)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(Icons.security,
              size: screenWidth * 0.1, color: Colors.white),
        ),
        SizedBox(height: screenWidth * 0.04),
        const Text(
          'SurakshaPay',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentStep == 1 ? 'Welcome back' : 'Enter your PIN',
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneStep(double screenHeight) {
    return Column(
      children: [
        const Icon(Icons.phone_android, size: 60, color: Color(0xFF3B82F6)),
        SizedBox(height: screenHeight * 0.03),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
            prefixText: '+91 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: screenHeight * 0.04),
        SizedBox(
          width: double.infinity,
          height: screenHeight * 0.07,
          child: ElevatedButton(
            onPressed: _phoneController.text.length >= 10 ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        VoiceButton(
          onPressed: () async {
            setState(() => _isVoiceMode = true);
            await VoiceService.speak(
              'Please speak your 10-digit phone number',
              language: 'hi-IN',
            );
            await VoiceService.startListening();
          },
          isActive: _isVoiceMode,
        ),
      ],
    );
  }

  Widget _buildPinStep(double screenWidth, double screenHeight) {
    return Column(
      children: [
        const Icon(Icons.lock, size: 60, color: Color(0xFF3B82F6)),
        SizedBox(height: screenHeight * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              width: screenWidth * 0.04,
              height: screenWidth * 0.04,
              decoration: BoxDecoration(
                color: i < _pinController.text.length
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        SizedBox(height: screenHeight * 0.03),
        NumericKeypad(
          onNumberPressed: (number) {
            if (_pinController.text.length < 4) {
              setState(() {
                _pinController.text += number;
              });
              if (_pinController.text.length == 4) {
                Future.delayed(const Duration(milliseconds: 500), _handleLogin);
              }
            }
          },
          onDelete: () {
            if (_pinController.text.isNotEmpty) {
              setState(() {
                _pinController.text = _pinController.text
                    .substring(0, _pinController.text.length - 1);
              });
            }
          },
        ),
        SizedBox(height: screenHeight * 0.02),
        TextButton(
          onPressed: _previousStep,
          child: const Text('Change phone number',
              style: TextStyle(fontSize: 16, color: Color(0xFF3B82F6))),
        ),
        SizedBox(height: screenHeight * 0.02),
        VoiceButton(
          onPressed: () async {
            setState(() => _isVoiceMode = true);
            await VoiceService.speak(
              'Please speak your 4-digit PIN',
              language: 'hi-IN',
            );
            await VoiceService.startListening();
          },
          isActive: _isVoiceMode,
        ),
      ],
    );
  }

  Widget _buildRegistrationLink(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: const Text(
            "Don't have an account? ",
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: TextButton(
            onPressed: () {
              ref.read(navigationProvider.notifier).navigateTo('registration');
            },
            child: const Text(
              'Create New Account',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}
