import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/voice_service.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/voice_button.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _trustedContactController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _duressPinController = TextEditingController();

  int _currentStep = 1; // 1: Name, 2: Phone & Trusted Contact, 3: PIN, 4: Confirm PIN, 5: Duress PIN
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
        _processVoiceInput(result);
      }
    };
    
    VoiceService.onError = (error) {
      if (_isVoiceMode) {
        _showErrorSnackBar('Voice recognition error: $error');
      }
    };
  }

  void _processVoiceInput(String input) {
    switch (_currentStep) {
      case 1:
        _nameController.text = input;
        break;
      case 2:
        // Extract phone numbers from voice input
        final phoneRegex = RegExp(r'\b\d{10}\b');
        final matches = phoneRegex.allMatches(input).toList();
        if (matches.length >= 2) {
          _phoneController.text = '+91 ${matches[0].group(0)}';
          _trustedContactController.text = '+91 ${matches[1].group(0)}';
        } else if (matches.length == 1) {
          _phoneController.text = '+91 ${matches[0].group(0)}';
        }
        break;
      case 3:
      case 4:
      case 5:
        // Extract PIN from voice input
        final pinRegex = RegExp(r'\b\d{4}\b');
        final match = pinRegex.firstMatch(input);
        if (match != null) {
          if (_currentStep == 3) {
            _pinController.text = match.group(0)!;
          } else if (_currentStep == 4) {
            _confirmPinController.text = match.group(0)!;
          } else if (_currentStep == 5) {
            _duressPinController.text = match.group(0)!;
          }
        }
        break;
    }
  }

  void _nextStep() {
    if (_canProceedToNextStep()) {
      setState(() {
        _currentStep++;
        _clearCurrentInput();
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _clearCurrentInput();
      });
    }
  }

  void _clearCurrentInput() {
    switch (_currentStep) {
      case 1:
        _nameController.clear();
        break;
      case 2:
        _phoneController.clear();
        _trustedContactController.clear();
        break;
      case 3:
        _pinController.clear();
        break;
      case 4:
        _confirmPinController.clear();
        break;
      case 5:
        _duressPinController.clear();
        break;
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 1:
        return _nameController.text.trim().isNotEmpty;
      case 2:
        return _phoneController.text.length >= 10 && 
               _trustedContactController.text.length >= 10;
      case 3:
        return _pinController.text.length == 4;
      case 4:
        return _confirmPinController.text.length == 4 && 
               _pinController.text == _confirmPinController.text;
      case 5:
        return _duressPinController.text.length == 4;
      default:
        return false;
    }
  }

  Future<void> _completeRegistration() async {
    if (!_canProceedToNextStep()) {
      _showErrorSnackBar('Please complete all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProvider.notifier).signUp(
        phone: _phoneController.text,
        name: _nameController.text.trim(),
        pin: _pinController.text,
        duressPin: _duressPinController.text,
        trustedContact: _trustedContactController.text,
      );

      final user = ref.read(userProvider);
      if (user != null) {
        // Load user data
        await ref.read(transactionsProvider.notifier).loadTransactions(user.id);
        await ref.read(contactsProvider.notifier).loadContacts(user.id);
        await ref.read(fraudLogsProvider.notifier).loadFraudLogs(user.id);
        await ref.read(appSettingsProvider.notifier).loadSettings(user.id);
        
        // Navigate to home
        ref.read(navigationProvider.notifier).navigateTo('home');
        
        // Speak welcome message
        await VoiceService.speak(
          'Welcome to SurakshaPay! Your account has been created successfully.',
          language: 'hi-IN',
        );
      } else {
        _showErrorSnackBar('Registration failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Registration failed: $e');
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
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Progress Bar
              _buildProgressBar(),
              
              // Content
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
              
              // Navigation Buttons
              _buildNavigationButtons(),
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
          if (_currentStep > 1)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF3B82F6)),
            )
          else
            const SizedBox(width: 48),
          
          Expanded(
            child: Text(
              'Step $_currentStep of 5',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LinearProgressIndicator(
        value: _currentStep / 5,
        backgroundColor: const Color(0xFFE5E7EB),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
        borderRadius: BorderRadius.circular(4),
        minHeight: 8,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildNameStep();
      case 2:
        return _buildPhoneStep();
      case 3:
        return _buildPinStep();
      case 4:
        return _buildConfirmPinStep();
      case 5:
        return _buildDuressPinStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNameStep() {
    return Column(
      children: [
        const Icon(
          Icons.person,
          size: 60,
          color: Color(0xFF3B82F6),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Your Name',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'What should we call you?',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        
        const SizedBox(height: 32),
        
        TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your name',
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
        
        const SizedBox(height: 32),
        
        VoiceButton(
          onPressed: () async {
            setState(() {
              _isVoiceMode = true;
            });
            
            await VoiceService.speak(
              'Please speak your full name',
              language: 'hi-IN',
            );
            
            await VoiceService.startListening();
          },
          isActive: _isVoiceMode,
          label: 'Speak your name',
        ),
      ],
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      children: [
        const Icon(
          Icons.phone_android,
          size: 60,
          color: Color(0xFF3B82F6),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Phone Numbers',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Your phone & trusted contact',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        
        const SizedBox(height: 32),
        
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Your Phone Number',
            hintText: 'Enter your phone number',
            prefixText: '+91 ',
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
        
        const SizedBox(height: 16),
        
        TextField(
          controller: _trustedContactController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Trusted Contact',
            hintText: 'Family member\'s phone',
            prefixText: '+91 ',
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
        
        const SizedBox(height: 32),
        
        VoiceButton(
          onPressed: () async {
            setState(() {
              _isVoiceMode = true;
            });
            
            await VoiceService.speak(
              'Please speak your phone number and trusted contact number',
              language: 'hi-IN',
            );
            
            await VoiceService.startListening();
          },
          isActive: _isVoiceMode,
          label: 'Speak phone numbers',
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    return Column(
      children: [
        const Icon(
          Icons.lock,
          size: 60,
          color: Color(0xFF3B82F6),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Create PIN',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Choose a 4-digit PIN to secure your account',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // PIN Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: index < _pinController.text.length
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        
        const SizedBox(height: 32),
        
        NumericKeypad(
          onNumberPressed: (number) {
            if (_pinController.text.length < 4) {
              setState(() {
                _pinController.text += number;
              });
            }
          },
          onDelete: () {
            if (_pinController.text.isNotEmpty) {
              setState(() {
                _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
              });
            }
          },
        ),
        
        const SizedBox(height: 24),
        
        VoiceButton(
          onPressed: () async {
            setState(() {
              _isVoiceMode = true;
            });
            
            await VoiceService.speak(
              'Please speak your 4-digit PIN',
              language: 'hi-IN',
            );
            
            await VoiceService.startListening();
          },
          isActive: _isVoiceMode,
          label: 'Speak your PIN',
        ),
      ],
    );
  }

  Widget _buildConfirmPinStep() {
    return Column(
      children: [
        const Icon(
          Icons.verified_user,
          size: 60,
          color: Color(0xFF10B981),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Confirm PIN',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Enter your PIN again to confirm',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // PIN Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: index < _confirmPinController.text.length
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        
        const SizedBox(height: 32),
        
        NumericKeypad(
          onNumberPressed: (number) {
            if (_confirmPinController.text.length < 4) {
              setState(() {
                _confirmPinController.text += number;
              });
            }
          },
          onDelete: () {
            if (_confirmPinController.text.isNotEmpty) {
              setState(() {
                _confirmPinController.text = _confirmPinController.text.substring(0, _confirmPinController.text.length - 1);
              });
            }
          },
        ),
        
        const SizedBox(height: 24),
        
        VoiceButton(
          onPressed: () async {
            setState(() {
              _isVoiceMode = true;
            });
            
            await VoiceService.speak(
              'Please speak your PIN again to confirm',
              language: 'hi-IN',
            );
            
            await VoiceService.startListening();
          },
          isActive: _isVoiceMode,
          label: 'Speak PIN to confirm',
        ),
      ],
    );
  }

  Widget _buildDuressPinStep() {
    return Column(
      children: [
        const Icon(
          Icons.warning,
          size: 60,
          color: Color(0xFFEF4444),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Duress PIN',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Set a different PIN for emergency situations',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Text(
            'If you enter this PIN under threat, the app will look normal but secretly send an alert to your trusted contact.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // PIN Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: index < _duressPinController.text.length
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        
        const SizedBox(height: 32),
        
        NumericKeypad(
          onNumberPressed: (number) {
            if (_duressPinController.text.length < 4) {
              setState(() {
                _duressPinController.text += number;
              });
            }
          },
          onDelete: () {
            if (_duressPinController.text.isNotEmpty) {
              setState(() {
                _duressPinController.text = _duressPinController.text.substring(0, _duressPinController.text.length - 1);
              });
            }
          },
        ),
        
        const SizedBox(height: 24),
        
        VoiceButton(
          onPressed: () async {
            setState(() {
              _isVoiceMode = true;
            });
            
            await VoiceService.speak(
              'Please speak your 4-digit duress PIN',
              language: 'hi-IN',
            );
            
            await VoiceService.startListening();
          },
          isActive: _isVoiceMode,
          label: 'Speak duress PIN',
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : (_currentStep == 5 ? _completeRegistration : _nextStep),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _currentStep == 5 ? 'Complete Registration' : 'Continue',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _trustedContactController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _duressPinController.dispose();
    super.dispose();
  }
}

