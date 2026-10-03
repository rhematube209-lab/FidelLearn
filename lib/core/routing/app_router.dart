import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/question_editor_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../features/challenges/presentation/screens/challenges_screen.dart';
import '../../features/school/presentation/screens/school_admin_dashboard_screen.dart';
import '../../features/teacher/presentation/screens/create_assignment_screen.dart';
import '../../features/teacher/presentation/screens/teacher_assignment_center_screen.dart';
import '../../features/teacher/presentation/screens/teacher_assignment_detail_screen.dart';
import '../../features/teacher/presentation/screens/teacher_intervention_center_screen.dart';
import '../../features/teacher/presentation/screens/student_assignment_inbox_screen.dart';
import '../../features/teacher/presentation/screens/student_assignment_detail_screen.dart';
import '../../features/teacher/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/presentation/screens/teacher_home_screen.dart';
import '../../features/teacher/presentation/screens/teacher_class_detail_screen.dart';
import '../../features/teacher/presentation/screens/teacher_class_roster_screen.dart';
import '../../features/teacher/presentation/screens/teacher_attention_screen.dart';
import '../../features/teacher/presentation/screens/teacher_student_summary_screen.dart';
import '../../features/exam_ghost/presentation/screens/exam_ghost_screen.dart';
import '../../features/exams/domain/models/exam_models.dart';
import '../../features/exams/presentation/screens/exam_builder_screen.dart';
import '../../features/exams/presentation/screens/exam_runner_screen.dart';
import '../../features/exams/presentation/screens/pre_exam_check_screen.dart';
import '../../features/exams/presentation/screens/subject_exams_hub_screen.dart';
import '../../features/home/presentation/screens/student_home_screen.dart';
import '../../features/mistakes/presentation/screens/mistakes_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/question_bank/domain/models/question_models.dart';
import '../../features/results/presentation/screens/exam_result_screen.dart';
import '../../features/results/presentation/screens/solution_review_screen.dart';
import '../../features/rewards/presentation/screens/airtime_store_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/subjects/presentation/screens/subjects_screen.dart';
import '../../features/p2p_transfer/presentation/screens/p2p_sharing_screen.dart';

import '../../features/school/presentation/providers/active_school_context_provider.dart';
import '../../features/school/presentation/screens/school_leadership_home_screen.dart';
import '../../features/school/domain/models/institutional_reporting_models.dart';
import '../../features/school/presentation/screens/reports_hub_screen.dart';
import '../../features/school/presentation/screens/report_preview_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return createAppRouter(ref: ref);
});

final appRouter = createAppRouter();

GoRouter createAppRouter({String initialLocation = '/', Ref? ref}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final gradeStr = state.uri.queryParameters['grade'];
            final stream = state.uri.queryParameters['stream'];
            final lang = state.uri.queryParameters['lang'];
            return LoginScreen(
              initialGrade: gradeStr != null ? int.tryParse(gradeStr) : null,
              initialStream: stream,
              initialLang: lang,
            );
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            final gradeStr = state.uri.queryParameters['grade'];
            final stream = state.uri.queryParameters['stream'];
            final lang = state.uri.queryParameters['lang'];
            return RegisterScreen(
              initialGrade: gradeStr != null ? int.tryParse(gradeStr) : null,
              initialStream: stream,
              initialLang: lang,
            );
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const StudentHomeScreen(),
        ),
        GoRoute(
          path: '/subjects',
          builder: (context, state) => const SubjectsScreen(),
        ),
        GoRoute(
          path: '/subject_exams/:subjectId',
          builder: (context, state) {
            final subjectId = state.pathParameters['subjectId'] ?? '';
            return SubjectExamsHubScreen(subjectId: subjectId);
          },
        ),
        GoRoute(
          path: '/exam_builder',
          builder: (context, state) {
            final subjectId = state.uri.queryParameters['subjectId'];
            final mode = state.uri.queryParameters['mode'];
            return ExamBuilderScreen(
              key: ValueKey('exam_builder_${subjectId}_$mode'),
              initialSubjectId: subjectId,
              mode: mode,
            );
          },
        ),
        GoRoute(
          path: '/pre_exam_check',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final exam = extra?['exam'] as Exam;
            final policy = extra?['policy'] as NationalExamPolicy?;
            return PreExamCheckScreen(exam: exam, policy: policy);
          },
        ),
        GoRoute(
          path: '/exam_runner',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final exam = extra?['exam'] as Exam;
            final attempt = extra?['attempt'] as ExamAttempt;
            final showInstantFeedback =
                extra?['showInstantFeedback'] as bool? ?? false;
            final policy = extra?['policy'] as NationalExamPolicy?;
            return ExamRunnerScreen(
              exam: exam,
              initialAttempt: attempt,
              showInstantFeedback: showInstantFeedback,
              policy: policy,
            );
          },
        ),
        GoRoute(
          path: '/results/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final extra = state.extra as Map<String, dynamic>?;
            return ExamResultScreen(
              attemptId: id,
              passedExam: extra?['exam'] as Exam?,
              passedAttempt: extra?['attempt'] as ExamAttempt?,
            );
          },
        ),
        GoRoute(
          path: '/solutions',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final questions = extra?['questions'] as List<Question>? ?? [];
            final attempt = extra?['attempt'] as ExamAttempt;
            return SolutionReviewScreen(questions: questions, attempt: attempt);
          },
        ),
        GoRoute(
          path: '/solution_review',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final questions = extra?['questions'] as List<Question>? ?? [];
            final attempt = extra?['attempt'] as ExamAttempt;
            return SolutionReviewScreen(questions: questions, attempt: attempt);
          },
        ),
        GoRoute(
          path: '/bookmarks',
          builder: (context, state) => const BookmarksScreen(),
        ),
        GoRoute(
          path: '/mistakes',
          builder: (context, state) => const MistakesScreen(),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressScreen(),
        ),
        GoRoute(
          path: '/assignments',
          builder: (context, state) => const StudentAssignmentInboxScreen(),
        ),
        GoRoute(
          path: '/assignment/:assignmentId',
          builder: (context, state) {
            final assignmentId = state.pathParameters['assignmentId']!;
            return StudentAssignmentDetailScreen(assignmentId: assignmentId);
          },
        ),
        GoRoute(
          path: '/exam_ghost/:examId',
          builder: (context, state) {
            final examId = state.pathParameters['examId'] ?? '';
            return ExamGhostScreen(examId: examId);
          },
        ),
        GoRoute(
          path: '/challenges',
          builder: (context, state) => const ChallengesScreen(),
        ),
        GoRoute(
          path: '/teacher',
          builder: (context, state) => const TeacherHomeScreen(),
        ),
        GoRoute(
          path: '/teacher/home',
          builder: (context, state) => const TeacherHomeScreen(),
        ),
        GoRoute(
          path: '/teacher/legacy_dashboard',
          builder: (context, state) => const TeacherDashboardScreen(),
        ),
        GoRoute(
          path: '/teacher/assignments',
          builder: (context, state) => const TeacherAssignmentCenterScreen(),
        ),
        GoRoute(
          path: '/teacher/assignment/new',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CreateAssignmentScreen(
              initialClassroomId: extra?['classroomId'] as String?,
              initialSubjectId: extra?['subjectId'] as String?,
              initialExamVariant: extra?['examVariant'] as String?,
              initialStudentUserId: extra?['studentUserId'] as String?,
              initialTopicId: extra?['topicId'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/teacher/create_assignment',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CreateAssignmentScreen(
              initialClassroomId: extra?['classroomId'] as String?,
              initialSubjectId: extra?['subjectId'] as String?,
              initialExamVariant: extra?['examVariant'] as String?,
              initialStudentUserId: extra?['studentUserId'] as String?,
              initialTopicId: extra?['topicId'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/teacher/assignment/:assignmentId',
          builder: (context, state) {
            final assignmentId = state.pathParameters['assignmentId']!;
            return TeacherAssignmentDetailScreen(assignmentId: assignmentId);
          },
        ),
        GoRoute(
          path: '/teacher/interventions',
          builder: (context, state) => const TeacherInterventionCenterScreen(),
        ),
        GoRoute(
          path: '/teacher/class/:classroomId/:subjectId',
          builder: (context, state) {
            final classroomId = state.pathParameters['classroomId']!;
            final subjectId = state.pathParameters['subjectId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return TeacherClassDetailScreen(
              classroomId: classroomId,
              subjectId: subjectId,
              classroomName:
                  extra?['classroomName'] as String? ?? 'Class Detail',
              subjectName: extra?['subjectName'] as String? ?? 'Subject',
              examVariant: extra?['examVariant'] as String?,
              enrolledCount: extra?['enrolledCount'] as int? ?? 0,
            );
          },
        ),
        GoRoute(
          path: '/teacher/class/:classroomId/:subjectId/roster',
          builder: (context, state) {
            final classroomId = state.pathParameters['classroomId']!;
            final subjectId = state.pathParameters['subjectId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return TeacherClassRosterScreen(
              classroomId: classroomId,
              subjectId: subjectId,
              classroomName: extra?['classroomName'] as String?,
              subjectName: extra?['subjectName'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/teacher/class/:classroomId/:subjectId/attention',
          builder: (context, state) {
            final classroomId = state.pathParameters['classroomId']!;
            final subjectId = state.pathParameters['subjectId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return TeacherAttentionScreen(
              classroomId: classroomId,
              subjectId: subjectId,
              classroomName: extra?['classroomName'] as String?,
              subjectName: extra?['subjectName'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/teacher/class/:classroomId/:subjectId/student/:studentId',
          builder: (context, state) {
            final classroomId = state.pathParameters['classroomId']!;
            final subjectId = state.pathParameters['subjectId']!;
            final studentId = state.pathParameters['studentId']!;
            final extra = state.extra as Map<String, dynamic>?;
            return TeacherStudentSummaryScreen(
              classroomId: classroomId,
              subjectId: subjectId,
              studentId: studentId,
              studentName: extra?['studentName'] as String?,
              schoolStudentId: extra?['schoolStudentId'] as String?,
              subjectName: extra?['subjectName'] as String?,
              classroomName: extra?['classroomName'] as String?,
            );
          },
        ),
        GoRoute(
          path: '/school',
          redirect: (context, state) {
            if (ref != null) {
              final schoolContext = ref.read(activeSchoolContextProvider);
              if (!schoolContext.isSchoolAdmin) {
                return '/home';
              }
            }
            return null;
          },
          builder: (context, state) => const SchoolLeadershipHomeScreen(),
        ),
        GoRoute(
          path: '/school/home',
          redirect: (context, state) {
            if (ref != null) {
              final schoolContext = ref.read(activeSchoolContextProvider);
              if (!schoolContext.isSchoolAdmin) {
                return '/home';
              }
            }
            return null;
          },
          builder: (context, state) => const SchoolLeadershipHomeScreen(),
        ),
        GoRoute(
          path: '/school/legacy_dashboard',
          builder: (context, state) => const SchoolAdminDashboardScreen(),
        ),
        GoRoute(
          path: '/school/reports',
          redirect: (context, state) {
            if (ref != null) {
              final schoolContext = ref.read(activeSchoolContextProvider);
              if (!schoolContext.isSchoolAdmin) {
                return '/home';
              }
            }
            return null;
          },
          builder: (context, state) =>
              const ReportsHubScreen(isTeacherView: false),
        ),
        GoRoute(
          path: '/school/reports/preview',
          redirect: (context, state) {
            if (ref != null) {
              final schoolContext = ref.read(activeSchoolContextProvider);
              if (!schoolContext.isSchoolAdmin && !schoolContext.isTeacher) {
                return '/home';
              }
            }
            return null;
          },
          builder: (context, state) {
            final typeStr = state.uri.queryParameters['type'];
            final schoolId = state.uri.queryParameters['schoolId'] ?? '';
            final extraReport = state.extra as ExecutiveReport?;
            return ReportPreviewScreen(
              schoolId: schoolId,
              reportType: InstitutionalReportType.fromString(typeStr),
              passedExecutiveReport: extraReport,
            );
          },
        ),
        GoRoute(
          path: '/teacher/reports',
          redirect: (context, state) {
            if (ref != null) {
              final schoolContext = ref.read(activeSchoolContextProvider);
              if (!schoolContext.isTeacher && !schoolContext.isSchoolAdmin) {
                return '/home';
              }
            }
            return null;
          },
          builder: (context, state) =>
              const ReportsHubScreen(isTeacherView: true),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/question_editor',
          builder: (context, state) => const QuestionEditorScreen(),
        ),
        GoRoute(
          path: '/rewards',
          builder: (context, state) => const RewardsScreen(),
        ),
        GoRoute(
          path: '/airtime_store',
          builder: (context, state) => const AirtimeStoreScreen(),
        ),
        GoRoute(
          path: '/p2p_share',
          builder: (context, state) => const P2PSharingScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
