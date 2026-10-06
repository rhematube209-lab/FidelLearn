import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/licensing_onboarding_models.dart';
import '../../domain/repositories/licensing_onboarding_repository.dart';

/// Exception thrown when caller lacks authority for commercial operations.
class CommercialAuthorizationException implements Exception {
  final String message;
  const CommercialAuthorizationException(this.message);

  @override
  String toString() => 'CommercialAuthorizationException: $message';
}

/// Exception thrown when seat limit is exceeded.
class SeatLimitExceededException implements Exception {
  final String message;
  const SeatLimitExceededException(this.message);

  @override
  String toString() => 'SeatLimitExceededException: $message';
}

/// Exception thrown when school activation requirements are not met.
class SchoolActivationException implements Exception {
  final String message;
  final List<dynamic> errors;
  const SchoolActivationException(this.message, [this.errors = const []]);

  @override
  String toString() => 'SchoolActivationException: $message. Errors: $errors';
}

/// Exception thrown when commercial actions cannot reach the cloud.
class CommercialOfflineException implements Exception {
  final String message;
  const CommercialOfflineException([
    this.message =
        'Commercial and licensing operations require an active internet connection. Please reconnect and retry.',
  ]);

  @override
  String toString() => message;
}

/// Production Supabase implementation of [LicensingOnboardingRepository].
/// All commercial mutations execute via SECURITY DEFINER PostgreSQL functions.
class SupabaseLicensingOnboardingRepository
    implements LicensingOnboardingRepository {
  final SupabaseClient? _customClient;

  SupabaseLicensingOnboardingRepository([this._customClient]);

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  Never _handleError(String caller, Object error) {
    debugPrint('SupabaseLicensingOnboardingRepository.$caller: $error');
    if (error is PostgrestException) {
      if (error.message.contains('SEAT_LIMIT_EXCEEDED')) {
        throw SeatLimitExceededException(error.message);
      }
      if (error.message.contains('ACTIVATION_BLOCKED')) {
        throw SchoolActivationException(error.message);
      }
      if (error.message.contains('NOT_AUTHORIZED') ||
          error.message.contains('PERMISSION_DENIED') ||
          error.code == '42501') {
        throw CommercialAuthorizationException(error.message);
      }
      throw error;
    }
    if (error is CommercialAuthorizationException ||
        error is SeatLimitExceededException ||
        error is SchoolActivationException) {
      throw error;
    }
    throw const CommercialOfflineException();
  }

  @override
  Future<SchoolLicense> getSchoolLicense(String schoolId) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_school_license',
        params: {'p_school_id': schoolId},
      );
      if (res == null) {
        throw const CommercialAuthorizationException('No license found');
      }
      return SchoolLicense.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      _handleError('getSchoolLicense', e);
    }
  }

  @override
  Future<SchoolSeatUsage> getSchoolSeatUsage(String schoolId) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_school_seat_usage',
        params: {'p_school_id': schoolId},
      );
      return SchoolSeatUsage.fromJson(Map<String, dynamic>.from(res as Map));
    } catch (e) {
      _handleError('getSchoolSeatUsage', e);
    }
  }

  @override
  Future<SchoolEntitlements> getSchoolEntitlements(String schoolId) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_school_entitlements',
        params: {'p_school_id': schoolId},
      );
      return SchoolEntitlements.fromJson(
        Map<String, dynamic>.from(res as Map),
      );
    } catch (e) {
      _handleError('getSchoolEntitlements', e);
    }
  }

  @override
  Future<bool> schoolHasEntitlement(String schoolId, String entitlement) async {
    try {
      final res = await _client.rpc<dynamic>(
        'school_has_entitlement',
        params: {
          'p_school_id': schoolId,
          'p_entitlement': entitlement,
        },
      );
      return res as bool? ?? false;
    } catch (e) {
      _handleError('schoolHasEntitlement', e);
    }
  }

  @override
  Future<SchoolOnboardingState> getSchoolOnboardingState(
    String schoolId,
  ) async {
    try {
      final res = await _client.rpc<dynamic>(
        'get_school_onboarding_status',
        params: {'p_school_id': schoolId},
      );
      return SchoolOnboardingState.fromJson(
        Map<String, dynamic>.from(res as Map),
      );
    } catch (e) {
      _handleError('getSchoolOnboardingState', e);
    }
  }

  @override
  Future<Map<String, dynamic>> validateSchoolActivation(
    String schoolId,
  ) async {
    try {
      final res = await _client.rpc<dynamic>(
        'validate_school_activation',
        params: {'p_school_id': schoolId},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      _handleError('validateSchoolActivation', e);
    }
  }

  @override
  Future<SchoolOnboardingState> activateSchool(String schoolId) async {
    try {
      await _client.rpc<dynamic>(
        'activate_school',
        params: {'p_school_id': schoolId},
      );
      return await getSchoolOnboardingState(schoolId);
    } catch (e) {
      _handleError('activateSchool', e);
    }
  }

  @override
  Future<InstitutionalImportRun> executeBulkStudentEnrollment({
    required String schoolId,
    required String classroomId,
    required List<Map<String, dynamic>> students,
    required String idempotencyKey,
  }) async {
    try {
      final res = await _client.rpc<dynamic>(
        'execute_bulk_student_enrollment_internal',
        params: {
          'p_school_id': schoolId,
          'p_classroom_id': classroomId,
          'p_students_payload': students,
          'p_idempotency_key': idempotencyKey,
        },
      );
      return InstitutionalImportRun.fromJson(
        Map<String, dynamic>.from(res as Map),
      );
    } catch (e) {
      _handleError('executeBulkStudentEnrollment', e);
    }
  }

  @override
  Future<void> updateClassroomMemberStatus({
    required String classroomId,
    required String userId,
    required String status,
  }) async {
    try {
      await _client.rpc<dynamic>(
        'update_classroom_member_status_internal',
        params: {
          'p_classroom_id': classroomId,
          'p_user_id': userId,
          'p_new_status': status,
        },
      );
    } catch (e) {
      _handleError('updateClassroomMemberStatus', e);
    }
  }

  @override
  Future<List<InstitutionalPlan>> getInstitutionalPlans() async {
    try {
      final res = await _client
          .from('institutional_plans')
          .select()
          .eq('is_active', true)
          .order('plan_code');
      return (res as List)
          .map((row) =>
              InstitutionalPlan.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      _handleError('getInstitutionalPlans', e);
    }
  }
}
