import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/question_editor_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../features/challenges/presentation/screens/challenges_screen.dart';
import '../../features/school/presentation/screens/school_admin_dashboard_screen.dart';
import '../../features/teacher/domain/models/teacher_models.dart';
import '../../features/teacher/presentation/screens/create_assignment_screen.dart';
import '../../features/teacher/presentation/screens/teacher_dashboard_screen.dart';
import '../../features/exam_ghost/presentation/screens/exam_ghost_screen.dart';
import '../../features/exams/domain/models/exam_models.dart';
import '../../features/exams/presentation/screens/exam_builder_screen.dart';
import '../../features/exams/presentation/screens/exam_runner_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return appRouter;
});

final appRouter = GoRouter(
  initialLocation: '/',
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
      path: '/exam_builder',
      builder: (context, state) {
        final subjectId = state.uri.queryParameters['subjectId'];
        final mode = state.uri.queryParameters['mode'];
        return ExamBuilderScreen(initialSubjectId: subjectId, mode: mode);
      },
    ),
    GoRoute(
      path: '/exam_runner',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final exam = extra?['exam'] as Exam;
        final attempt = extra?['attempt'] as ExamAttempt;
        return ExamRunnerScreen(exam: exam, initialAttempt: attempt);
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
      builder: (context, state) => const TeacherDashboardScreen(),
    ),
    GoRoute(
      path: '/teacher/create_assignment',
      builder: (context, state) {
        final classroom = state.extra as Classroom?;
        return CreateAssignmentScreen(classroom: classroom);
      },
    ),
    GoRoute(
      path: '/school',
      builder: (context, state) => const SchoolAdminDashboardScreen(),
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
