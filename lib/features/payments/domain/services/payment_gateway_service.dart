import 'dart:async';
import 'dart:math';

import '../models/payment_models.dart';

class PaymentGatewayService {
  final Map<String, PaymentTransaction> _transactions = {};

  PaymentTransaction initiatePayment({
    required String userId,
    required double amountEtb,
    required PaymentMethod method,
    required String description,
  }) {
    final now = DateTime.now();
    final rand = Random();
    final invoiceNumber =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}-${rand.nextInt(90000) + 10000}';
    final txId = 'tx_pay_${now.millisecondsSinceEpoch}';

    final qrPayload = method == PaymentMethod.telebirr
        ? 'TELEBIRR:PAY:$invoiceNumber:$amountEtb:FIDEL_LEARN_MERCHANT'
        : 'CBEBIRR:PAY:$invoiceNumber:$amountEtb:FIDEL_LEARN_CBE';

    final deepLink = method == PaymentMethod.telebirr
        ? 'telebirr://pay?invoice=$invoiceNumber&amount=$amountEtb'
        : 'cbebirr://pay?invoice=$invoiceNumber&amount=$amountEtb';

    final tx = PaymentTransaction(
      id: txId,
      userId: userId,
      amountEtb: amountEtb,
      paymentMethod: method,
      status: PaymentStatus.pending,
      invoiceNumber: invoiceNumber,
      qrCodePayload: qrPayload,
      deepLink: deepLink,
      createdAt: now,
      referenceMessage: description,
    );

    _transactions[tx.id] = tx;
    return tx;
  }

  Future<PaymentTransaction> verifyPayment({
    required String transactionId,
    required String confirmationCode,
  }) async {
    final tx = _transactions[transactionId];
    if (tx == null) {
      throw Exception('Transaction $transactionId not found.');
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Valid simulation confirmation check (e.g. 4-digit PIN like 1234 or non-empty)
    if (confirmationCode.trim().length >= 4) {
      final completed = tx.copyWith(
        status: PaymentStatus.completed,
        completedAt: DateTime.now(),
        referenceMessage:
            'Payment verified successfully via ${tx.paymentMethod.displayName}.',
      );
      _transactions[transactionId] = completed;
      return completed;
    } else {
      final failed = tx.copyWith(
        status: PaymentStatus.failed,
        completedAt: DateTime.now(),
        referenceMessage: 'Invalid transaction confirmation code.',
      );
      _transactions[transactionId] = failed;
      return failed;
    }
  }

  PaymentTransaction? getTransaction(String id) => _transactions[id];
}
