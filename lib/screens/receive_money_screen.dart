import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/app_providers.dart';
import '../services/voice_service.dart';
import '../widgets/voice_button.dart';

class ReceiveMoneyScreen extends ConsumerStatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  ConsumerState<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends ConsumerState<ReceiveMoneyScreen> {
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
    final lowerInput = input.toLowerCase();

    if (lowerInput.contains('qr') || lowerInput.contains('code')) {
      // Already showing QR code
      _showInfoSnackBar('QR code is already displayed');
    } else if (lowerInput.contains('upi') || lowerInput.contains('id')) {
      _showInfoSnackBar('Your UPI ID is displayed below');
    } else {
      _showInfoSnackBar('Say "Show QR code" or "Show UPI ID"');
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final settings = ref.watch(appSettingsProvider);

    if (user == null) {
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
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _buildContent(user, settings),
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
              ref.read(navigationProvider.notifier).navigateTo('home');
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
          ),
          const Expanded(
            child: Text(
              'Receive Money',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              setState(() {
                _isVoiceMode = true;
              });

              final settings = ref.read(appSettingsProvider);
              final language = settings['preferred_language'] ?? 'hi-IN';

              await VoiceService.speak(
                'Say "Show QR code" or "Show UPI ID"',
                language: language,
              );

              await VoiceService.startListening();
            },
            icon: const Icon(
              Icons.mic,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(user, settings) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // QR Code Section
          _buildQRCodeSection(user),

          const SizedBox(height: 32),

          // UPI ID Section
          _buildUPIIdSection(user),

          const SizedBox(height: 32),

          // Instructions
          _buildInstructions(),

          const Spacer(),

          // Voice Assistant Button
          VoiceButton(
            onPressed: () async {
              setState(() {
                _isVoiceMode = true;
              });

              final language = settings['preferred_language'] ?? 'hi-IN';

              final helpMessage = language == 'hi-IN'
                  ? VoiceService.getHindiResponse('receive_money')
                  : 'Your QR code and UPI ID are displayed. Share them to receive money.';

              await VoiceService.speak(helpMessage, language: language);

              await VoiceService.startListening();
            },
            isActive: _isVoiceMode,
            label: 'Get help',
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: QrImageView(
                data: user.upiId,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask sender to scan this QR code',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIIdSection(user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'UPI ID',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      user.upiId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Copy to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UPI ID copied to clipboard'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.copy,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this UPI ID with the sender',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to receive money:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              '1',
              'Share your QR code or UPI ID with the sender',
            ),
            _buildInstructionItem(
              '2',
              'The sender will scan the QR code or enter your UPI ID',
            ),
            _buildInstructionItem(
              '3',
              'Money will be transferred to your account instantly',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
