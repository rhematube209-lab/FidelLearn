import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/payment_models.dart';
import '../../domain/services/payment_gateway_service.dart';

final paymentGatewayServiceProvider = Provider((ref) {
  return PaymentGatewayService();
});

class TelebirrCheckoutModal extends ConsumerStatefulWidget {
  final double amountEtb;
  final String itemDescription;
  final VoidCallback onPaymentSuccess;

  const TelebirrCheckoutModal({
    super.key,
    required this.amountEtb,
    required this.itemDescription,
    required this.onPaymentSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required double amountEtb,
    required String itemDescription,
    required VoidCallback onPaymentSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TelebirrCheckoutModal(
        amountEtb: amountEtb,
        itemDescription: itemDescription,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }

  @override
  ConsumerState<TelebirrCheckoutModal> createState() =>
      _TelebirrCheckoutModalState();
}

class _TelebirrCheckoutModalState extends ConsumerState<TelebirrCheckoutModal> {
  PaymentMethod _selectedMethod = PaymentMethod.telebirr;
  PaymentTransaction? _activeTx;
  bool _isProcessing = false;
  final TextEditingController _pinController =
      TextEditingController(text: '1234');

  void _initiatePayment() {
    final user = ref.read(currentUserProvider).valueOrNull;
    final service = ref.read(paymentGatewayServiceProvider);

    final tx = service.initiatePayment(
      userId: user?.id ?? 'guest_student',
      amountEtb: widget.amountEtb,
      method: _selectedMethod,
      description: widget.itemDescription,
    );

    setState(() {
      _activeTx = tx;
    });
  }

  Future<void> _confirmPayment() async {
    if (_activeTx == null) return;

    setState(() => _isProcessing = true);
    final service = ref.read(paymentGatewayServiceProvider);

    final completed = await service.verifyPayment(
      transactionId: _activeTx!.id,
      confirmationCode: _pinController.text.trim(),
    );

    setState(() {
      _activeTx = completed;
      _isProcessing = false;
    });

    if (completed.status == PaymentStatus.completed) {
      widget.onPaymentSuccess();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ethiopian Payment Checkout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Item summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemDescription,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Verified National Content Package',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.amountEtb.toStringAsFixed(0)} ETB',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_activeTx == null) ...[
              const Text(
                'Select Payment Gateway:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Telebirr Option
              Card(
                color: _selectedMethod == PaymentMethod.telebirr
                    ? AppTheme.primaryGreen.withOpacity(0.08)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedMethod == PaymentMethod.telebirr
                        ? AppTheme.primaryGreen
                        : const Color(0xFFE2E8F0),
                    width: _selectedMethod == PaymentMethod.telebirr ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.primaryGreen,
                  ),
                  title: const Text(
                    'Telebirr (Ethio Telecom)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Instant USSD push notification & SuperApp pay',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Radio<PaymentMethod>(
                    value: PaymentMethod.telebirr,
                    groupValue: _selectedMethod,
                    onChanged: (val) => setState(() => _selectedMethod = val!),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // CBE Birr Option
              Card(
                color: _selectedMethod == PaymentMethod.cbeBirr
                    ? AppTheme.accentGold.withOpacity(0.08)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedMethod == PaymentMethod.cbeBirr
                        ? AppTheme.accentGoldDark
                        : const Color(0xFFE2E8F0),
                    width: _selectedMethod == PaymentMethod.cbeBirr ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.account_balance,
                    color: AppTheme.accentGoldDark,
                  ),
                  title: const Text(
                    'CBE Birr (Commercial Bank of Ethiopia)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Direct bank debit & CBE mobile banking',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Radio<PaymentMethod>(
                    value: PaymentMethod.cbeBirr,
                    groupValue: _selectedMethod,
                    onChanged: (val) => setState(() => _selectedMethod = val!),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _initiatePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.lock_outline),
                label: Text(
                  'Proceed with ${_selectedMethod == PaymentMethod.telebirr ? "Telebirr" : "CBE Birr"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (_activeTx!.status == PaymentStatus.pending) ...[
              // Prompt USSD & PIN Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.phone_android,
                      size: 36,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Confirming with ${_activeTx!.paymentMethod.displayName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice: ${_activeTx!.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Enter Wallet PIN (Simulated: 1234)',
                        counterText: '',
                        prefixIcon: Icon(Icons.password),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text(
                  'Confirm & Authorize Payment',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (_activeTx!.status == PaymentStatus.completed) ...[
              // Success State
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.successGreen.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Payment Verified & Complete! 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _activeTx!.referenceMessage ?? 'Package unlocked!',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Return to FidelLearn'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
