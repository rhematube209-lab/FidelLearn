import 'dart:math';

class OtpRecord {
  final String phoneNumber;
  final String code;
  final DateTime expiresAt;

  OtpRecord({
    required this.phoneNumber,
    required this.code,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class SmsGatewayService {
  final Map<String, OtpRecord> _activeOtps = {};
  final List<String> _sentSmsLogs = [];

  String generateOtpCode() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  String sendOtpSms(String phoneNumber) {
    final code = generateOtpCode();
    final expiresAt = DateTime.now().add(const Duration(seconds: 120));

    _activeOtps[phoneNumber.trim()] = OtpRecord(
      phoneNumber: phoneNumber.trim(),
      code: code,
      expiresAt: expiresAt,
    );

    final log =
        '[ETHIO_TELECOM_SMS] To: $phoneNumber — Your FidelLearn verification code is: $code. Valid for 2 minutes.';
    _sentSmsLogs.insert(0, log);

    return code;
  }

  bool verifyOtp(String phoneNumber, String enteredCode) {
    final record = _activeOtps[phoneNumber.trim()];
    if (record == null) return false;
    if (record.isExpired) {
      _activeOtps.remove(phoneNumber.trim());
      return false;
    }

    final isValid = record.code.trim() == enteredCode.trim();
    if (isValid) {
      _activeOtps.remove(phoneNumber.trim());
    }
    return isValid;
  }

  void sendParentProgressSummary({
    required String parentPhone,
    required String studentName,
    required int streakDays,
    required int readinessScore,
    required int questionsPracticed,
  }) {
    final log =
        '[ETHIO_TELECOM_SMS] To: $parentPhone — FidelLearn Update: $studentName has achieved a $streakDays-day study streak with an exam readiness score of $readinessScore% ($questionsPracticed questions solved this week).';
    _sentSmsLogs.insert(0, log);
  }

  List<String> getSmsLogs() => List.unmodifiable(_sentSmsLogs);
}
