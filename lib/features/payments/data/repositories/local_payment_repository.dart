import 'package:fidel_learn/features/payments/domain/models/payment_models.dart';
import 'package:fidel_learn/features/payments/domain/services/payment_gateway_service.dart';

abstract class PaymentRepository {
  Future<PaymentTransaction> initiateCheckout({
    required String userId,
    required double amountEtb,
    required PaymentMethod method,
    required String description,
  });

  Future<PaymentTransaction> confirmPayment({
    required String transactionId,
    required String confirmationCode,
  });

  Future<List<PaymentTransaction>> getTransactionHistory(String userId);
}

class LocalPaymentRepository implements PaymentRepository {
  final PaymentGatewayService _service;
  final List<PaymentTransaction> _history = [];

  LocalPaymentRepository({PaymentGatewayService? service})
      : _service = service ?? PaymentGatewayService();

  @override
  Future<PaymentTransaction> initiateCheckout({
    required String userId,
    required double amountEtb,
    required PaymentMethod method,
    required String description,
  }) async {
    final tx = _service.initiatePayment(
      userId: userId,
      amountEtb: amountEtb,
      method: method,
      description: description,
    );
    _history.insert(0, tx);
    return tx;
  }

  @override
  Future<PaymentTransaction> confirmPayment({
    required String transactionId,
    required String confirmationCode,
  }) async {
    final updated = await _service.verifyPayment(
      transactionId: transactionId,
      confirmationCode: confirmationCode,
    );

    final idx = _history.indexWhere((t) => t.id == transactionId);
    if (idx != -1) {
      _history[idx] = updated;
    }

    return updated;
  }

  @override
  Future<List<PaymentTransaction>> getTransactionHistory(String userId) async {
    return _history.where((t) => t.userId == userId).toList();
  }
}
