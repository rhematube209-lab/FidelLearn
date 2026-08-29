import 'package:equatable/equatable.dart';

enum PaymentMethod {
  telebirr,
  cbeBirr,
  airtimeDirect;

  String get displayName {
    switch (this) {
      case PaymentMethod.telebirr:
        return 'Telebirr (Ethio Telecom)';
      case PaymentMethod.cbeBirr:
        return 'CBE Birr (Commercial Bank of Ethiopia)';
      case PaymentMethod.airtimeDirect:
        return 'Airtime Direct Debit';
    }
  }

  String get logoAsset {
    switch (this) {
      case PaymentMethod.telebirr:
        return 'assets/images/telebirr.png';
      case PaymentMethod.cbeBirr:
        return 'assets/images/cbe_birr.png';
      case PaymentMethod.airtimeDirect:
        return 'assets/images/airtime.png';
    }
  }
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  expired;

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending Confirmation';
      case PaymentStatus.completed:
        return 'Payment Successful';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.expired:
        return 'Invoice Expired';
    }
  }
}

class PaymentTransaction extends Equatable {
  final String id;
  final String userId;
  final double amountEtb;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final String invoiceNumber;
  final String qrCodePayload;
  final String? deepLink;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? referenceMessage;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amountEtb,
    required this.paymentMethod,
    required this.status,
    required this.invoiceNumber,
    required this.qrCodePayload,
    this.deepLink,
    required this.createdAt,
    this.completedAt,
    this.referenceMessage,
  });

  PaymentTransaction copyWith({
    PaymentStatus? status,
    DateTime? completedAt,
    String? referenceMessage,
  }) {
    return PaymentTransaction(
      id: id,
      userId: userId,
      amountEtb: amountEtb,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      invoiceNumber: invoiceNumber,
      qrCodePayload: qrCodePayload,
      deepLink: deepLink,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      referenceMessage: referenceMessage ?? this.referenceMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amountEtb,
        paymentMethod,
        status,
        invoiceNumber,
        qrCodePayload,
        deepLink,
        createdAt,
        completedAt,
        referenceMessage,
      ];
}
