import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fidel_learn/features/progress/domain/models/mastery_models.dart';
import 'package:fidel_learn/features/progress/domain/models/study_plan_models.dart';
import 'package:fidel_learn/features/progress/presentation/widgets/mastery_overview_card.dart';
import 'package:fidel_learn/features/progress/presentation/widgets/reviews_due_banner.dart';
import 'package:fidel_learn/features/progress/presentation/widgets/why_this_dialog.dart';
import 'package:fidel_learn/features/subjects/domain/models/subject_models.dart';

void main() {
  group('MasteryOverviewCard Widget Tests', () {
    testWidgets('Renders 4 pillars and reviews due chip in English',
        (tester) async {
      const summary = SubjectMasterySummary(
        subjectId: 'physics_g12',
        examVariant: ExamVariantCode.naturalScience,
        masteredTargets: 14,
        improvingTargets: 5,
        atRiskTargets: 2,
        newTargets: 7,
        reviewsDue: 4,
        averageAccuracy: 82.5,
      );

      bool reviewTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MasteryOverviewCard(
              summary: summary,
              subjectNameEn: 'Physics',
              subjectNameAm: 'ፊዚክስ',
              isAmharic: false,
              onReviewTap: () => reviewTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Natural Science'), findsOneWidget);
      expect(find.text('4 Due'), findsOneWidget);

      expect(find.text('14'), findsOneWidget);
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Improving'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('At Risk'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);

      await tester.tap(find.text('4 Due'));
      await tester.pumpAndSettle();
      expect(reviewTapped, isTrue);
    });

    testWidgets('Renders 4 pillars and Amharic labels when isAmharic = true',
        (tester) async {
      const summary = SubjectMasterySummary(
        subjectId: 'math_g12',
        examVariant: ExamVariantCode.socialScience,
        masteredTargets: 8,
        improvingTargets: 3,
        atRiskTargets: 1,
        newTargets: 4,
        reviewsDue: 2,
        averageAccuracy: 75.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MasteryOverviewCard(
              summary: summary,
              subjectNameEn: 'Mathematics',
              subjectNameAm: 'ሒሳብ',
              isAmharic: true,
            ),
          ),
        ),
      );

      expect(find.text('ሒሳብ'), findsOneWidget);
      expect(find.text('የማህበራዊ ሳይንስ'), findsOneWidget);
      expect(find.text('2 ክለሳ'), findsOneWidget);
      expect(find.text('የተካኑበት'), findsOneWidget);
      expect(find.text('እየተሻሻለ'), findsOneWidget);
      expect(find.text('ክለሳ የሚሻ'), findsOneWidget);
      expect(find.text('አዲስ'), findsOneWidget);
    });
  });

  group('ReviewsDueBanner Widget Tests', () {
    testWidgets('Renders due count and triggers onReviewNow on tap',
        (tester) async {
      bool reviewStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewsDueBanner(
              dueCount: 7,
              isAmharic: false,
              onReviewNow: () => reviewStarted = true,
            ),
          ),
        ),
      );

      expect(find.text('7 Spaced Reviews Due Today'), findsOneWidget);
      expect(find.text('Review Now'), findsOneWidget);

      await tester.tap(find.text('Review Now'));
      await tester.pumpAndSettle();
      expect(reviewStarted, isTrue);
    });

    testWidgets('Renders Amharic banner text when isAmharic = true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewsDueBanner(
              dueCount: 5,
              isAmharic: true,
              onReviewNow: () {},
            ),
          ),
        ),
      );

      expect(find.text('5 የተቀጠሩ የክለሳ ጥያቄዎች ደርሰዋል'), findsOneWidget);
      expect(find.text('አሁን ከልስ'), findsOneWidget);
    });

    testWidgets('Renders nothing if dueCount is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReviewsDueBanner(
              dueCount: 0,
              onReviewNow: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('WhyThisDialog Mastery Explainability Tests', () {
    testWidgets('Renders explainability dialog for masteryReviewDue in English',
        (tester) async {
      const session = StudyPlanSession(
        id: 'plan_1_spaced',
        planId: 'plan_1',
        subjectId: 'physics_g12',
        sessionType: StudySessionType.masteryMaintenance,
        titleEn: 'Physics Spaced Mastery Recall',
        titleAm: 'ፊዚክስ የተቀጠረ የብቃት ክለሳ',
        reasonCode: RecommendationReasonCode.masteryReviewDue,
        reasonDetailEn: 'You have 3 questions due for spaced review today.',
        reasonDetailAm: 'ዛሬ 3 የተቀጠሩ የክለሳ ጥያቄዎች ደርሰዋል።',
        questionTarget: 3,
        estimatedMinutes: 6,
        priorityScore: 88.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhyThisDialog(
              session: session,
              isAmharic: false,
            ),
          ),
        ),
      );

      expect(find.text('Spaced Review Due'), findsOneWidget);
      expect(find.text('Physics Spaced Mastery Recall'), findsOneWidget);
      expect(find.text('You have 3 questions due for spaced review today.'),
          findsOneWidget);
    });

    testWidgets('Renders explainability dialog for relearningNeeded in Amharic',
        (tester) async {
      const session = StudyPlanSession(
        id: 'plan_1_relearning',
        planId: 'plan_1',
        subjectId: 'chemistry_g12',
        sessionType: StudySessionType.masteryMaintenance,
        titleEn: 'Chemistry Relearning',
        titleAm: 'የኬሚስትሪ ዳግም ትምህርት',
        reasonCode: RecommendationReasonCode.relearningNeeded,
        reasonDetailEn: 'You missed questions previously.',
        reasonDetailAm: 'ቀደም ሲል የተሳሳቷቸው ጥያቄዎች አሉ። እንደገና የመማር ክለሳ ተይዞልዎታል።',
        questionTarget: 4,
        estimatedMinutes: 8,
        priorityScore: 92.0,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WhyThisDialog(
              session: session,
              isAmharic: true,
            ),
          ),
        ),
      );

      expect(find.text('እንደገና መማር የሚያስፈልግ'), findsOneWidget);
      expect(find.text('የኬሚስትሪ ዳግም ትምህርት'), findsOneWidget);
      expect(find.text('ቀደም ሲል የተሳሳቷቸው ጥያቄዎች አሉ። እንደገና የመማር ክለሳ ተይዞልዎታል።'),
          findsOneWidget);
    });
  });
}
