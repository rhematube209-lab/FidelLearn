import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/payments/data/repositories/local_payment_repository.dart';
import 'package:fidel_learn/features/payments/domain/models/payment_models.dart';
import 'package:fidel_learn/features/payments/domain/services/payment_gateway_service.dart';

void main() {
  group('PaymentGatewayService & LocalPaymentRepository Tests', () {
    late PaymentGatewayService service;
    late LocalPaymentRepository repository;

    setUp(() {
      service = PaymentGatewayService();
      repository = LocalPaymentRepository(service: service);
    });

    test('initiates Telebirr payment transaction with invoice and QR payload',
        () {
      final tx = service.initiatePayment(
        userId: 'usr_student_123',
        amountEtb: 150.0,
        method: PaymentMethod.telebirr,
        description: 'Grade 12 Complete Prep Bundle',
      );

      expect(tx.status, PaymentStatus.pending);
      expect(tx.amountEtb, 150.0);
      expect(tx.paymentMethod, PaymentMethod.telebirr);
      expect(tx.invoiceNumber.startsWith('INV-'), isTrue);
      expect(tx.qrCodePayload.startsWith('TELEBIRR:PAY:'), isTrue);
      expect(tx.deepLink, contains('telebirr://pay'));
      expect(tx.completedAt, isNull);
    });

    test('initiates CBE Birr payment transaction with CBE payload', () {
      final tx = service.initiatePayment(
        userId: 'usr_student_123',
        amountEtb: 200.0,
        method: PaymentMethod.cbeBirr,
        description: 'Mock Exam Simulation Pass',
      );

      expect(tx.status, PaymentStatus.pending);
      expect(tx.paymentMethod, PaymentMethod.cbeBirr);
      expect(tx.qrCodePayload.startsWith('CBEBIRR:PAY:'), isTrue);
      expect(tx.deepLink, contains('cbebirr://pay'));
    });

    test('successfully verifies payment with valid confirmation code',
        () async {
      final tx = service.initiatePayment(
        userId: 'usr_student_123',
        amountEtb: 50.0,
        method: PaymentMethod.telebirr,
        description: 'Physics Subject Package',
      );

      final verified = await service.verifyPayment(
        transactionId: tx.id,
        confirmationCode: '1234',
      );

      expect(verified.status, PaymentStatus.completed);
      expect(verified.completedAt, isNotNull);
      expect(verified.referenceMessage, contains('verified successfully'));
    });

    test(
        'fails payment verification if confirmation code is too short or invalid',
        () async {
      final tx = service.initiatePayment(
        userId: 'usr_student_123',
        amountEtb: 50.0,
        method: PaymentMethod.telebirr,
        description: 'Physics Subject Package',
      );

      final failed = await service.verifyPayment(
        transactionId: tx.id,
        confirmationCode: '12', // Invalid / short
      );

      expect(failed.status, PaymentStatus.failed);
      expect(failed.referenceMessage,
          contains('Invalid transaction confirmation code'));
    });

    test(
        'manages checkout lifecycle and transaction history in LocalPaymentRepository',
        () async {
      final tx1 = await repository.initiateCheckout(
        userId: 'usr_student_1',
        amountEtb: 50.0,
        method: PaymentMethod.telebirr,
        description: 'Item 1',
      );

      final history1 = await repository.getTransactionHistory('usr_student_1');
      expect(history1.length, 1);
      expect(history1.first.status, PaymentStatus.pending);

      final confirmed = await repository.confirmPayment(
        transactionId: tx1.id,
        confirmationCode: '1234',
      );
      expect(confirmed.status, PaymentStatus.completed);

      final historyAfter =
          await repository.getTransactionHistory('usr_student_1');
      expect(historyAfter.first.status, PaymentStatus.completed);
    });
  });
}
