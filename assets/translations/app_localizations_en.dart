// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FidelLearn';

  @override
  String get welcomeTitle => 'Master Your National Exams';

  @override
  String get welcomeSubtitle =>
      'Offline-first exam preparation, verified step-by-step solutions, and smart progress tracking.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Register';

  @override
  String get logout => 'Log Out';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectGrade => 'Select Grade';

  @override
  String get selectStream => 'Select Academic Stream';

  @override
  String get grade12 => 'Grade 12';

  @override
  String get grade8 => 'Grade 8';

  @override
  String get grade6 => 'Grade 6';

  @override
  String get naturalScience => 'Natural Science';

  @override
  String get socialScience => 'Social Science';

  @override
  String get home => 'Home';

  @override
  String get practice => 'Practice';

  @override
  String get progress => 'Progress';

  @override
  String get rewards => 'Rewards';

  @override
  String get profile => 'Profile';

  @override
  String streakDays(int count) {
    return '$count Day Streak';
  }

  @override
  String coinsCount(int count) {
    return '$count Coins';
  }

  @override
  String get continuePractice => 'Continue Practicing';

  @override
  String get dailyGoal => 'Daily Goal';

  @override
  String get subjects => 'Subjects';

  @override
  String get customExam => 'Custom Exam Builder';

  @override
  String get mockExam => 'Full Mock Exam';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get mistakesNotebook => 'Mistake Notebook';

  @override
  String get examGhost => 'Exam Ghost Challenge';

  @override
  String get challenges => 'Challenges';

  @override
  String questionCount(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get flagForReview => 'Flag for Review';

  @override
  String get submitExam => 'Submit Exam';

  @override
  String get examResults => 'Exam Results';

  @override
  String get scoreSummary => 'Score Summary';

  @override
  String get reviewSolutions => 'Review Solutions';

  @override
  String get retakeWithGhost => 'Retake with Exam Ghost';

  @override
  String get offlineReady => 'Offline Ready';

  @override
  String get syncPending => 'Sync Pending';

  @override
  String get syncCompleted => 'All Synced';

  @override
  String get weakTopics => 'Recommended Weak Topics';

  @override
  String get readinessScore => 'Readiness Score';

  @override
  String get simplerExplanation => 'Simpler Explanation';

  @override
  String get keyConcept => 'Key Concept & Formula';

  @override
  String get commonMistake => 'Common Pitfall';
}
