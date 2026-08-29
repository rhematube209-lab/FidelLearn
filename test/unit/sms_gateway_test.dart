import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/auth/domain/services/sms_gateway_service.dart';

void main() {
  group('SmsGatewayService Tests', () {
    late SmsGatewayService smsService;

    setUp(() {
      smsService = SmsGatewayService();
    });

    test('generates 6-digit numeric OTP code', () {
      final code = smsService.generateOtpCode();
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('dispatches OTP SMS, logs transmission, and validates correctly', () {
      const phone = '0911223344';
      final sentCode = smsService.sendOtpSms(phone);

      expect(sentCode.length, 6);
      final logs = smsService.getSmsLogs();
      expect(logs.isNotEmpty, isTrue);
      expect(logs.first, contains(phone));
      expect(logs.first, contains(sentCode));

      // Correct verification
      final isVerified = smsService.verifyOtp(phone, sentCode);
      expect(isVerified, isTrue);

      // Subsequent verification fails (consumed code)
      final reVerify = smsService.verifyOtp(phone, sentCode);
      expect(reVerify, isFalse);
    });

    test('rejects incorrect OTP code', () {
      const phone = '0911223344';
      smsService.sendOtpSms(phone);

      final isVerified = smsService.verifyOtp(phone, '000000');
      expect(isVerified, isFalse);
    });

    test('sends and logs weekly parent progress summary SMS', () {
      smsService.sendParentProgressSummary(
        parentPhone: '0912345678',
        studentName: 'Dawit Abebe',
        streakDays: 7,
        readinessScore: 84,
        questionsPracticed: 120,
      );

      final logs = smsService.getSmsLogs();
      expect(logs.first, contains('0912345678'));
      expect(logs.first, contains('Dawit Abebe'));
      expect(logs.first, contains('7-day study streak'));
      expect(logs.first, contains('84%'));
    });
  });
}
