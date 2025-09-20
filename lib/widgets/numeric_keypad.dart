import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDelete;

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Row 2: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Row 3: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Row 4: Empty, 0, Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 80), // Empty space
              _buildKey('0'),
              _buildDeleteKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String number) {
    return GestureDetector(
      onTap: () {
        onNumberPressed(number);
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 28,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

