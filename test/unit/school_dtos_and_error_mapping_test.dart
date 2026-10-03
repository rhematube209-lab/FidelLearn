import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/school/data/models/school_dtos.dart';
import 'package:fidel_learn/features/school/domain/models/tenant_models.dart';
import 'package:fidel_learn/core/errors/failures.dart';

void main() {
  group('P6 Stage 2 DTOs & Supabase Error Mapping Tests', () {
    test('SchoolDto converts PostgREST json map to School entity', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'name': 'Bole Senior Secondary School',
        'display_name': 'Bole Secondary',
        'school_code': 'FID-BOL001',
        'status': 'active',
        'city': 'Addis Ababa',
        'region': 'Addis Ababa',
        'timezone': 'Africa/Addis_Ababa',
        'logo_url': null,
        'created_at': '2026-09-25T10:00:00Z',
        'updated_at': '2026-09-25T10:00:00Z',
      };

      final school = SchoolDto(json).toDomain();
      expect(school.id, equals('11111111-1111-1111-1111-111111111111'));
      expect(school.name, equals('Bole Senior Secondary School'));
      expect(school.schoolCode, equals('FID-BOL001'));
      expect(school.status, equals(SchoolStatus.active));
    });

    test(
        'SchoolMembershipDto converts PostgREST relational map to SchoolMembershipWithSchool',
        () {
      final json = {
        'id': 'sm-1',
        'school_id': '11111111-1111-1111-1111-111111111111',
        'user_id': 'u-1',
        'role': 'teacher',
        'status': 'active',
        'school_student_id': 'EMP-01',
        'created_at': '2026-09-25T10:00:00Z',
        'updated_at': '2026-09-25T10:00:00Z',
        'schools': {
          'id': '11111111-1111-1111-1111-111111111111',
          'name': 'Bole Senior Secondary School',
          'school_code': 'FID-BOL001',
          'status': 'active',
          'created_at': '2026-09-25T10:00:00Z',
          'updated_at': '2026-09-25T10:00:00Z',
        },
      };

      final dto = SchoolMembershipDto(json);
      final aggregate = dto.toWithSchool();

      expect(aggregate, isNotNull);
      expect(aggregate!.membership.role, equals(SchoolMemberRole.teacher));
      expect(aggregate.school.name, equals('Bole Senior Secondary School'));
    });

    test(
        'mapSupabaseError correctly maps 42501 and RLS violations to PermissionDeniedFailure',
        () {
      const pgError =
          'PostgrestException(message: new row violates row-level security policy, code: 42501)';
      final failure = mapSupabaseError(pgError);
      expect(failure, isA<PermissionDeniedFailure>());
      expect(failure.code, equals('PERMISSION_DENIED'));

      const privilegeError =
          'insufficient_privilege: Caller is not a school_admin';
      final privFailure = mapSupabaseError(privilegeError);
      expect(privFailure, isA<PermissionDeniedFailure>());
    });

    test('mapSupabaseError maps socket and timeout errors to NetworkFailure',
        () {
      const socketError =
          'SocketException: Failed host lookup: xyz.supabase.co';
      final failure = mapSupabaseError(socketError);
      expect(failure, isA<NetworkFailure>());

      const timeoutError =
          'TimeoutException after 0:00:10.000000: Future not completed';
      final timeoutFailure = mapSupabaseError(timeoutError);
      expect(timeoutFailure, isA<NetworkFailure>());
    });

    test('mapSupabaseError maps not found errors to NotFoundFailure', () {
      const pgrst116 =
          'PostgrestException(message: JSON object requested, multiple (or no) rows returned, code: PGRST116)';
      final failure = mapSupabaseError(pgrst116);
      expect(failure, isA<NotFoundFailure>());
    });
  });
}
