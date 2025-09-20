import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/transaction_card.dart';
import '../widgets/voice_button.dart';
import '../services/voice_service.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
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

    if (lowerInput.contains('home') ||
        lowerInput.contains('ghar') ||
        lowerInput.contains('घर')) {
      ref.read(navigationProvider.notifier).navigateTo('home');
    } else if (lowerInput.contains('send') ||
        lowerInput.contains('bhej') ||
        lowerInput.contains('भेज')) {
      ref.read(navigationProvider.notifier).navigateTo('send-money');
    } else if (lowerInput.contains('receive') ||
        lowerInput.contains('le') ||
        lowerInput.contains('ले')) {
      ref.read(navigationProvider.notifier).navigateTo('receive-money');
    } else {
      _showInfoSnackBar('Say "Go home", "Send money", or "Receive money"');
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
    final transactions = ref.watch(transactionsProvider);

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
              _buildHeader(ref),

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
                  child: _buildContent(transactions),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
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
              'Transaction History',
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

              final helpMessage = language == 'hi-IN'
                  ? VoiceService.getHindiResponse('view_history')
                  : 'You can say "Go home", "Send money", or "Receive money"';

              await VoiceService.speak(helpMessage, language: language);
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

  Widget _buildContent(List transactions) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionCard(
                        transaction: transaction,
                        onTap: () {
                          // Handle transaction details
                        },
                      );
                    },
                  ),
          ),

          // Voice Assistant Button
          if (transactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: VoiceButton(
                onPressed: () async {
                  setState(() {
                    _isVoiceMode = true;
                  });

                  final settings = ref.read(appSettingsProvider);
                  final language = settings['preferred_language'] ?? 'hi-IN';

                  final helpMessage = language == 'hi-IN'
                      ? 'आप कह सकते हैं: घर जाएं, पैसे भेजें, या पैसे प्राप्त करें'
                      : 'You can say: Go home, Send money, or Receive money';

                  await VoiceService.speak(helpMessage, language: language);
                  await VoiceService.startListening();
                },
                isActive: _isVoiceMode,
                label: 'Voice commands',
              ),
            ),
        ],
      ),
    );
  }
}
