import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/app/app.dart';
import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/widgets/sync_indicator_widget.dart';
import 'package:fidel_learn/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:fidel_learn/features/auth/domain/models/user_profile.dart';
import 'package:fidel_learn/features/bookmarks/data/repositories/local_bookmark_repository.dart';
import 'package:fidel_learn/features/exams/data/repositories/local_exam_repository.dart';
import 'package:fidel_learn/features/mistakes/data/repositories/local_mistake_repository.dart';
import 'package:fidel_learn/features/question_bank/domain/models/question_models.dart';
import 'package:fidel_learn/features/subjects/data/repositories/local_content_repository.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  testWidgets('Complete Offline Student Journey Test', (WidgetTester tester) async {
    // 1. Prepare deterministic seed data
    final contentRepo = LocalContentRepository();
    contentRepo.initializeWithData(
      packages: [
        const ContentPackage(
          packageId: 'pkg_g12_math',
          subjectId: 'math_g12',
          nameEn: 'Grade 12 Math',
          nameAm: 'የ12ኛ ክፍል ሂሳብ',
          grade: 12,
          stream: 'natural',
          version: 1,
          sizeBytes: 1000,
          publisher: 'FidelLearn',
          license: 'demo',
          attribution: 'FidelLearn original demo',
          isDownloaded: true,
        ),
      ],
      subjects: [
        const Subject(
          id: 'math_g12',
          code: 'MATH12',
          nameEn: 'Mathematics',
          nameAm: 'ሂሳብ',
          grade: 12,
          stream: 'natural',
          sortOrder: 1,
        ),
      ],
      units: [
        const Unit(
          id: 'u1',
          subjectId: 'math_g12',
          unitNumber: 1,
          titleEn: 'Sequences',
          titleAm: 'ተከታታዮች',
        ),
      ],
      topics: [
        const Topic(
          id: 't1',
          unitId: 'u1',
          topicNumber: 1,
          titleEn: 'Arithmetic Progressions',
          titleAm: 'አርቲሜቲክ',
        ),
      ],
      questions: [
        const Question(
          id: 'q_demo_1',
          grade: 12,
          stream: 'natural',
          subjectId: 'math_g12',
          unitId: 'u1',
          topicId: 't1',
          examYear: 2023,
          questionTextEn: 'What is 3 + 4 in standard arithmetic?',
          difficulty: 'easy',
          verificationStatus: VerificationStatus.published,
          sourceName: 'FidelLearn Demo',
          contentVersion: 1,
          choices: [
            AnswerChoice(id: 'c1', label: 'A', textEn: '6', isCorrect: false),
            AnswerChoice(id: 'c2', label: 'B', textEn: '7', isCorrect: true),
          ],
          explanation: Explanation(
            solutionTextEn: '3 + 4 = 7 by standard addition.',
            simplerExplanationEn: 'Add 3 and 4 together.',
            keyConcept: 'Basic arithmetic addition.',
          ),
        ),
      ],
    );

    final authRepo = MockAuthRepository(
      initialUser: UserProfile(
        id: 'test-student-1',
        phoneNumber: '+251911223344',
        displayName: 'Abebe B.',
        grade: 12,
        stream: 'natural',
        preferredLanguage: 'en',
        role: UserRole.student,
        createdAt: DateTime.now(),
      ),
    );

    final examRepo = LocalExamRepository();
    final bookmarkRepo = LocalBookmarkRepository();
    final mistakeRepo = LocalMistakeRepository();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 2. Pump widget tree with Riverpod overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          contentRepositoryProvider.overrideWithValue(contentRepo),
          examRepositoryProvider.overrideWithValue(examRepo),
          bookmarkRepositoryProvider.overrideWithValue(bookmarkRepo),
          mistakeRepositoryProvider.overrideWithValue(mistakeRepo),
        ],
        child: const FidelLearnApp(),
      ),
    );

    // Allow splash timer and GoRouter redirect to settle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Home Screen or Splash Screen is reached
    expect(find.text('FidelLearn'), findsWidgets);
    expect(find.byType(SyncIndicatorWidget), findsWidgets);
  });
}
