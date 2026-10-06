enum ErrorCategory {
  network,
  authentication,
  authorization,
  validation,
  license,
  seatLimit,
  sync,
  content,
  server,
  maintenance,
  unknown;

  bool get isRetryable {
    switch (this) {
      case ErrorCategory.network:
      case ErrorCategory.sync:
      case ErrorCategory.server:
        return true;
      case ErrorCategory.authentication:
      case ErrorCategory.authorization:
      case ErrorCategory.validation:
      case ErrorCategory.license:
      case ErrorCategory.seatLimit:
      case ErrorCategory.content:
      case ErrorCategory.maintenance:
      case ErrorCategory.unknown:
        return false;
    }
  }
}

/// Standardized operational error descriptor for client UX and diagnostics.
class AppErrorDescriptor {
  final ErrorCategory category;
  final String code;
  final String userMessageEn;
  final String userMessageAm;
  final bool isRetryable;

  const AppErrorDescriptor({
    required this.category,
    required this.code,
    required this.userMessageEn,
    required this.userMessageAm,
    required this.isRetryable,
  });

  /// Translates raw exceptions or error strings into safe user-facing descriptors.
  static AppErrorDescriptor fromException(dynamic exception) {
    final str = exception.toString().toLowerCase();

    // 1. Network / Connectivity
    if (str.contains('socketexception') ||
        str.contains('network') ||
        str.contains('connection refused') ||
        str.contains('failed host lookup') ||
        str.contains('timed out') ||
        str.contains('clientexception')) {
      return const AppErrorDescriptor(
        category: ErrorCategory.network,
        code: 'NETWORK_UNAVAILABLE',
        userMessageEn:
            'Network connection issue. Your work is saved locally and will sync when connected.',
        userMessageAm:
            'የኔትወርክ ችግር አጋጥሟል። መረጃዎ በስልክዎ ተቀምጧል፣ ኢንተርኔት ሲገናኝ ይመሳሰላል።',
        isRetryable: true,
      );
    }

    // 2. Seat Limit Exceeded
    if (str.contains('seat_limit_exceeded') ||
        str.contains('seat capacity') ||
        str.contains('seat limit')) {
      return const AppErrorDescriptor(
        category: ErrorCategory.seatLimit,
        code: 'SEAT_LIMIT_EXCEEDED',
        userMessageEn:
            'Your school has reached its licensed student capacity. Please contact your administrator.',
        userMessageAm:
            'የትምህርት ቤቱ የተማሪዎች መቀመጫ ገደብ ሞልቷል። እባክዎ የትምህርት ቤት አስተዳዳሪዎን ያነጋግሩ።',
        isRetryable: false,
      );
    }

    // 3. License Suspended / Inactive
    if (str.contains('license') ||
        str.contains('suspended') ||
        str.contains('expired')) {
      return const AppErrorDescriptor(
        category: ErrorCategory.license,
        code: 'LICENSE_INACTIVE',
        userMessageEn:
            'School institutional license is inactive. Offline learning remains available.',
        userMessageAm:
            'የትምህርት ቤቱ የፍቃድ አገልግሎት ጊዜው አልቋል። ከመስመር ውጭ የነበሩ ፈተናዎች አሁንም ይሰራሉ።',
        isRetryable: false,
      );
    }

    // 4. Authorization / Permission Denied
    if (str.contains('permission denied') ||
        str.contains('access denied') ||
        str.contains('42501') ||
        str.contains('unauthorized')) {
      return const AppErrorDescriptor(
        category: ErrorCategory.authorization,
        code: 'PERMISSION_DENIED',
        userMessageEn:
            'You do not have permission to perform this institutional action.',
        userMessageAm: 'ይህንን እርምጃ ለመፈጸም የሚያስችል የፈቃድ ደረጃ የለዎትም።',
        isRetryable: false,
      );
    }

    // 5. Authentication Expired
    if (str.contains('jwt') ||
        str.contains('token') ||
        str.contains('auth_expired')) {
      return const AppErrorDescriptor(
        category: ErrorCategory.authentication,
        code: 'AUTH_SESSION_EXPIRED',
        userMessageEn: 'Your session has expired. Please sign in again.',
        userMessageAm: 'የመግቢያ ክፍለ-ጊዜዎ አልቋል። እባክዎ እንደገና ይግቡ።',
        isRetryable: false,
      );
    }

    // 6. Content Package Integrity
    if (str.contains('package') ||
        str.contains('integrity') ||
        str.contains('corrupt') ||
        str.contains('hash mismatch')) {
      return const AppErrorDescriptor(
        category: ErrorCategory.content,
        code: 'PACKAGE_INTEGRITY_FAILED',
        userMessageEn:
            'Exam content package verification failed. Please re-download the package.',
        userMessageAm: 'የፈተናው ይዘት ማረጋገጫ አልተሳካም። እባክዎ እንደገና ያውርዱ።',
        isRetryable: true,
      );
    }

    // 7. General Server Error
    if (str.contains('500') ||
        str.contains('502') ||
        str.contains('503') ||
        str.contains('postgrestexception')) {
      return const AppErrorDescriptor(
        category: ErrorCategory.server,
        code: 'SERVER_TEMPORARILY_UNAVAILABLE',
        userMessageEn:
            'The server is temporarily unavailable. Please try again shortly.',
        userMessageAm: 'ሰርቨሩ ለጊዜው አይሰራም። እባክዎ ጥቂት ቆይተው እንደገና ይሞክሩ።',
        isRetryable: true,
      );
    }

    // 8. Default fallback
    return const AppErrorDescriptor(
      category: ErrorCategory.unknown,
      code: 'UNEXPECTED_ERROR',
      userMessageEn:
          'An unexpected issue occurred. Your local progress is preserved.',
      userMessageAm: 'ያልተጠበቀ ችግር አጋጥሟል። የፈተና ሂደትዎ በስልክዎ ተቀምጧል።',
      isRetryable: false,
    );
  }
}
