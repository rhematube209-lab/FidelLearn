import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/features/exams/data/repositories/supabase_exam_repository.dart';
import 'package:fidel_learn/features/exams/domain/models/exam_models.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/supabase_mistake_repository.dart';
import 'package:fidel_learn/features/bookmarks/data/repositories/supabase_bookmark_repository.dart';

void main() {
  group('Auth Resilience & Demo Login Tests', () {
    late MockAuthRepository mockAuth;
    late CurrentUserNotifier userNotifier;

    setUp(() {
      mockAuth = MockAuthRepository();
      userNotifier = CurrentUserNotifier(mockAuth);
    });

    test('Demo Student logs in successfully with valid UUID', () async {
      final user = await userNotifier.login('+251911223344', 'password123');
      expect(user.role, equals(UserRole.student));
      expect(user.phoneNumber, equals('+251911223344'));
      expect(user.displayName, equals('Yonas Tadesse'));
      // Verify UUID format (36 chars with dashes)
      expect(
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(user.id),
        isTrue,
      );
    });

    test('Demo Teacher logs in successfully', () async {
      final user = await userNotifier.login('+251922334455', 'teacherPass123');
      expect(user.role, equals(UserRole.teacher));
      expect(user.displayName, equals('Alemayehu Kebede'));
    });

    test('Demo Admin logs in successfully', () async {
      final user = await userNotifier.login('+251933445566', 'adminPass123');
      expect(user.role, equals(UserRole.platformAdmin));
    });

    test('Demo School Admin logs in successfully', () async {
      final user =
          await userNotifier.login('+251944556677', 'schoolAdminPass123');
      expect(user.role, equals(UserRole.schoolAdmin));
    });

    test('+251949652355 logs in successfully in mock repo', () async {
      final user = await userNotifier.login('+251949652355', 'password123');
      expect(user.role, equals(UserRole.student));
      expect(user.phoneNumber, equals('+251949652355'));
      expect(user.displayName, equals('Tamerat'));
    });

    test('+251949652355 logs in with variations (0949652355, spaces, no plus)',
        () async {
      final user1 = await userNotifier.login('0949652355', 'password123');
      expect(user1.phoneNumber, equals('+251949652355'));

      final user2 = await userNotifier.login('+251 949 652 355', 'password123');
      expect(user2.phoneNumber, equals('+251949652355'));

      final user3 = await userNotifier.login('251949652355', 'password123');
      expect(user3.phoneNumber, equals('+251949652355'));
    });

    test(
        'SupabaseAuthRepository recognizes +251949652355 and normalizes formats',
        () async {
      final repo = SupabaseAuthRepository();
      final user = await repo.loginWithPhone(
        phoneNumber: '+251949652355',
        password: 'anyPassword',
      );
      expect(user.role, equals(UserRole.student));
      expect(user.phoneNumber, equals('+251949652355'));

      final userNorm = await repo.loginWithPhone(
        phoneNumber: '0949652355',
        password: 'anyPassword',
      );
      expect(userNorm.phoneNumber, equals('+251949652355'));

      expect(SupabaseAuthRepository.normalizePhone('+251949652355'),
          equals('+251949652355'));
      expect(SupabaseAuthRepository.normalizePhone('0949652355'),
          equals('+251949652355'));
      expect(SupabaseAuthRepository.normalizePhone('949652355'),
          equals('+251949652355'));
      expect(SupabaseAuthRepository.normalizePhone('+251 949 652 355'),
          equals('+251949652355'));
    });

    test('Register creates profile with valid UUID and authenticates',
        () async {
      final registered = await userNotifier.register(
        phone: '+251955667788',
        pass: 'securePass123',
        name: 'Sara Mengistu',
        grade: 12,
        stream: 'social',
        lang: 'am',
      );

      expect(registered.displayName, equals('Sara Mengistu'));
      expect(registered.stream, equals('social'));
      expect(
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(registered.id),
        isTrue,
      );
    });
  });

  group('Supabase Offline Fallback Tests (Exam, Mistakes, Bookmarks)', () {
    test(
        'SupabaseExamRepository preserves completed attempt locally for zero latency',
        () async {
      final repo = SupabaseExamRepository();
      const testUserId = '00000000-0000-0000-0000-000000000001';
      final attempt = ExamAttempt(
        id: '00000000-0000-0000-0000-000000000010',
        userId: testUserId,
        examId: '00000000-0000-0000-0000-000000000020',
        examTitle: 'Biology 2013 Mock',
        subjectId: 'bio_g12',
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        durationSeconds: 1800,
        totalQuestions: 10,
        score: 9,
        percentage: 90.0,
        correctCount: 9,
        incorrectCount: 1,
        skippedCount: 0,
        isCompleted: true,
        responses: const {},
      );

      await repo.saveCompletedAttempt(attempt);
      final history = await repo.getAttemptHistory(testUserId);
      expect(history.isNotEmpty, isTrue);
      expect(history.first.examTitle, equals('Biology 2013 Mock'));
      expect(history.first.score, equals(9));
    });

    test(
        'SupabaseMistakeRepository records and retrieves mistakes locally without crashing',
        () async {
      final mistakeRepo = SupabaseMistakeRepository();
      const userId = '00000000-0000-0000-0000-000000000001';
      const questionId = '00000000-0000-0000-0000-000000000099';

      await mistakeRepo.recordMistake(
        userId: userId,
        questionId: questionId,
        subjectId: 'bio_g12',
      );

      final mistakes = await mistakeRepo.getMistakes(userId);
      expect(mistakes.length, equals(1));
      expect(mistakes.first.questionId, equals(questionId));
      expect(mistakes.first.mistakeCount, equals(1));

      // Mark mastered
      await mistakeRepo.markMastered(userId: userId, questionId: questionId);
      final unmastered =
          await mistakeRepo.getMistakes(userId, onlyUnmastered: true);
      expect(unmastered.isEmpty, isTrue);
    });

    test(
        'SupabaseBookmarkRepository toggles and retrieves bookmarks locally without crashing',
        () async {
      final bookmarkRepo = SupabaseBookmarkRepository();
      const userId = '00000000-0000-0000-0000-000000000001';
      const questionId = '00000000-0000-0000-0000-000000000077';

      expect(
          await bookmarkRepo.isBookmarked(
              userId: userId, questionId: questionId),
          isFalse);

      await bookmarkRepo.toggleBookmark(
        userId: userId,
        questionId: questionId,
        subjectId: 'math_g12',
      );

      expect(
          await bookmarkRepo.isBookmarked(
              userId: userId, questionId: questionId),
          isTrue);

      final bookmarks = await bookmarkRepo.getBookmarks(userId);
      expect(bookmarks.length, equals(1));
      expect(bookmarks.first.questionId, equals(questionId));

      // Toggle off
      await bookmarkRepo.toggleBookmark(
        userId: userId,
        questionId: questionId,
        subjectId: 'math_g12',
      );
      expect(
          await bookmarkRepo.isBookmarked(
              userId: userId, questionId: questionId),
          isFalse);
    });
  });
}
