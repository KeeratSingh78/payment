import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_service.dart';

class PinInputDialog extends ConsumerStatefulWidget {
  final String title;
  final String message;
  final Function(String) onPinEntered;
  final VoidCallback? onCancel;

  const PinInputDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onPinEntered,
    this.onCancel,
  });

  @override
  ConsumerState<PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends ConsumerState<PinInputDialog> {
  String _pin = '';
  bool _isLoading = false;

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
      });

      // Auto-submit when 4 digits entered
      if (_pin.length == 4) {
        _submitPin();
      }
    }
  }

  void _onBackspacePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _submitPin() {
    if (_pin.length == 4) {
      setState(() {
        _isLoading = true;
      });

      // Add a small delay to show loading state
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          widget.onPinEntered(_pin);
        }
      });
    }
  }

  void _speakMessage() async {
    await VoiceService.speak(
      'कृपया अपना 4 अंकों का PIN दर्ज करें।',
      language: 'hi-IN',
    );
  }

  @override
  void initState() {
    super.initState();
    // Speak the instruction when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.lock, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // PIN Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: index < _pin.length
                      ? const Color(0xFF3B82F6)
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Number Pad
          _buildNumberPad(),

          const SizedBox(height: 16),

          // Voice instruction button
          TextButton.icon(
            onPressed: _speakMessage,
            icon: const Icon(Icons.volume_up, size: 20),
            label: const Text('सुनें'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
            child: const Text('रद्द करें'),
          ),
        if (_isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('1'),
            _buildNumberButton('2'),
            _buildNumberButton('3'),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('4'),
            _buildNumberButton('5'),
            _buildNumberButton('6'),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumberButton('7'),
            _buildNumberButton('8'),
            _buildNumberButton('9'),
          ],
        ),
        const SizedBox(height: 12),

        // Row 4: *, 0, backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 50), // Empty space
            _buildNumberButton('0'),
            _buildBackspaceButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _onBackspacePressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace,
            size: 20,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
