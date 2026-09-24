import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';
import 'package:fidel_learn/features/progress/presentation/widgets/today_study_plan_card.dart';
import 'package:fidel_learn/features/progress/presentation/widgets/why_this_dialog.dart';

void main() {
  group('TodayStudyPlanCard Widget Tests', () {
    late StudyPlan samplePlan;

    setUp(() {
      final now = DateTime(2026, 9, 24);
      samplePlan = StudyPlan(
        id: 'plan_test_001',
        userId: 'student_001',
        planDate: now,
        targetMinutes: 45,
        estimatedMinutes: 30,
        sessions: const [
          StudyPlanSession(
            id: 'sess_phys',
            planId: 'plan_test_001',
            subjectId: 'physics_g12',
            unitId: 'u_em',
            topicId: 'top_ind',
            sessionType: StudySessionType.weakTopicPractice,
            titleEn: 'Physics: Electromagnetic Induction',
            titleAm: 'ፊዚክስ፦ ኤሌክትሮማግኔቲክ ኢንዳክሽን',
            questionTarget: 10,
            estimatedMinutes: 15,
            priorityScore: 84.0,
            reasonCode: RecommendationReasonCode.weakTopic,
            reasonDetailEn: 'Your accuracy in this topic is 42%.',
            reasonDetailAm: 'በዚህ ርዕስ ላይ ውጤትዎ 42% ነው።',
            status: SessionCompletionStatus.notStarted,
            questionIds: ['q1', 'q2'],
          ),
          StudyPlanSession(
            id: 'sess_math',
            planId: 'plan_test_001',
            subjectId: 'math_g12',
            unitId: 'u_calc',
            topicId: 'top_lim',
            sessionType: StudySessionType.curriculumCoverage,
            titleEn: 'Mathematics: Calculus',
            titleAm: 'ሒሳብ፦ ካልኩለስ',
            questionTarget: 8,
            estimatedMinutes: 15,
            priorityScore: 65.0,
            reasonCode: RecommendationReasonCode.newCurriculum,
            reasonDetailEn: 'You have not practiced this unit yet.',
            reasonDetailAm: 'ይህን ክፍል እስካሁን አልሰሩትም።',
            status: SessionCompletionStatus.notStarted,
            questionIds: ['qm1'],
          ),
        ],
        status: SessionCompletionStatus.notStarted,
        generatedAt: now,
      );
    });

    testWidgets('1. Renders session items, badges, and progress bar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayStudyPlanCard(
              studyPlan: samplePlan,
              onStartSession: (_) {},
            ),
          ),
        ),
      );

      // Verify Header and Session Titles
      expect(find.text("Today's Study Plan"), findsOneWidget);
      expect(find.text('Physics: Electromagnetic Induction'), findsOneWidget);
      expect(find.text('Mathematics: Calculus'), findsOneWidget);

      // Verify reason badges
      expect(find.text('Weak Topic'), findsOneWidget);
      expect(find.text('New Curriculum'), findsOneWidget);

      // Verify Start buttons
      expect(find.text('Start'), findsNWidgets(2));
    });

    testWidgets('2. Tapping "Why this?" opens explainability dialog',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayStudyPlanCard(
              studyPlan: samplePlan,
              onStartSession: (_) {},
            ),
          ),
        ),
      );

      // Find and tap the first "Why this?" button
      final whyThisButton = find.text('Why this?').first;
      await tester.tap(whyThisButton);
      await tester.pumpAndSettle();

      // Verify WhyThisDialog is displayed with transparent detail
      expect(find.byType(WhyThisDialog), findsOneWidget);
      expect(find.text('Your accuracy in this topic is 42%.'), findsOneWidget);
      expect(find.text('Priority 84'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(WhyThisDialog), findsNothing);
    });

    testWidgets('3. Tapping Start triggers onStartSession callback',
        (tester) async {
      StudyPlanSession? launchedSession;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayStudyPlanCard(
              studyPlan: samplePlan,
              onStartSession: (session) {
                launchedSession = session;
              },
            ),
          ),
        ),
      );

      final startButtons = find.text('Start');
      await tester.tap(startButtons.first);
      await tester.pump();

      expect(launchedSession, isNotNull);
      expect(launchedSession!.id, 'sess_phys');
    });

    testWidgets(
        '4. Completed sessions render green completed badge and celebrate when all done',
        (tester) async {
      final completedPlan = samplePlan.copyWith(
        sessions: [
          samplePlan.sessions[0].copyWith(
            status: SessionCompletionStatus.completed,
            completedAt: DateTime.now(),
          ),
          samplePlan.sessions[1].copyWith(
            status: SessionCompletionStatus.completed,
            completedAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayStudyPlanCard(
              studyPlan: completedPlan,
              onStartSession: (_) {},
            ),
          ),
        ),
      );

      // Verify completed badges rendered instead of Start
      expect(find.text('Completed'), findsNWidgets(2));
      expect(find.text('Start'), findsNothing);

      // Verify All Completed banner
      expect(
          find.text(
              "Great job! You've completed today's personalized study plan."),
          findsOneWidget);
    });

    testWidgets('5. Loading state renders spinner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayStudyPlanCard(
              studyPlan: null,
              isLoading: true,
              onStartSession: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Personalizing today's study plan..."), findsOneWidget);
    });
  });
}
