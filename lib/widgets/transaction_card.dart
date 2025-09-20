import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTransactionColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTransactionIcon(),
                  color: _getTransactionColor(),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTransactionName(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTransactionTime(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _getAmountText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getTransactionColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      transaction.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTransactionName() {
    switch (transaction.type) {
      case TransactionType.sent:
        return transaction.receiverName ?? 'Unknown';
      case TransactionType.received:
        return transaction.senderName ?? 'Unknown';
      case TransactionType.qrPayment:
        return 'QR Payment';
    }
  }

  String _getTransactionTime() {
    final now = DateTime.now();
    final transactionTime = transaction.createdAt;
    final difference = now.difference(transactionTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _getAmountText() {
    final prefix = transaction.type == TransactionType.received ? '+' : '-';
    return '$prefix${transaction.formattedAmount}';
  }

  IconData _getTransactionIcon() {
    switch (transaction.type) {
      case TransactionType.sent:
        return Icons.send;
      case TransactionType.received:
        return Icons.download;
      case TransactionType.qrPayment:
        return Icons.qr_code;
    }
  }

  Color _getTransactionColor() {
    switch (transaction.type) {
      case TransactionType.sent:
        return const Color(0xFF3B82F6);
      case TransactionType.received:
        return const Color(0xFF10B981);
      case TransactionType.qrPayment:
        return const Color(0xFF8B5CF6);
    }
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return const Color(0xFF10B981);
      case TransactionStatus.pending:
        return const Color(0xFFF59E0B);
      case TransactionStatus.failed:
        return const Color(0xFFEF4444);
      case TransactionStatus.cancelled:
        return const Color(0xFF6B7280);
    }
  }
}
