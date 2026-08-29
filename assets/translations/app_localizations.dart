import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'translations/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'FidelLearn'**
  String get appName;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Master Your National Exams'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline-first exam preparation, verified step-by-step solutions, and smart progress tracking.'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectGrade.
  ///
  /// In en, this message translates to:
  /// **'Select Grade'**
  String get selectGrade;

  /// No description provided for @selectStream.
  ///
  /// In en, this message translates to:
  /// **'Select Academic Stream'**
  String get selectStream;

  /// No description provided for @grade12.
  ///
  /// In en, this message translates to:
  /// **'Grade 12'**
  String get grade12;

  /// No description provided for @grade8.
  ///
  /// In en, this message translates to:
  /// **'Grade 8'**
  String get grade8;

  /// No description provided for @grade6.
  ///
  /// In en, this message translates to:
  /// **'Grade 6'**
  String get grade6;

  /// No description provided for @naturalScience.
  ///
  /// In en, this message translates to:
  /// **'Natural Science'**
  String get naturalScience;

  /// No description provided for @socialScience.
  ///
  /// In en, this message translates to:
  /// **'Social Science'**
  String get socialScience;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} Day Streak'**
  String streakDays(int count);

  /// No description provided for @coinsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Coins'**
  String coinsCount(int count);

  /// No description provided for @continuePractice.
  ///
  /// In en, this message translates to:
  /// **'Continue Practicing'**
  String get continuePractice;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @subjects.
  ///
  /// In en, this message translates to:
  /// **'Subjects'**
  String get subjects;

  /// No description provided for @customExam.
  ///
  /// In en, this message translates to:
  /// **'Custom Exam Builder'**
  String get customExam;

  /// No description provided for @mockExam.
  ///
  /// In en, this message translates to:
  /// **'Full Mock Exam'**
  String get mockExam;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @mistakesNotebook.
  ///
  /// In en, this message translates to:
  /// **'Mistake Notebook'**
  String get mistakesNotebook;

  /// No description provided for @examGhost.
  ///
  /// In en, this message translates to:
  /// **'Exam Ghost Challenge'**
  String get examGhost;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @questionCount.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionCount(int current, int total);

  /// No description provided for @flagForReview.
  ///
  /// In en, this message translates to:
  /// **'Flag for Review'**
  String get flagForReview;

  /// No description provided for @submitExam.
  ///
  /// In en, this message translates to:
  /// **'Submit Exam'**
  String get submitExam;

  /// No description provided for @examResults.
  ///
  /// In en, this message translates to:
  /// **'Exam Results'**
  String get examResults;

  /// No description provided for @scoreSummary.
  ///
  /// In en, this message translates to:
  /// **'Score Summary'**
  String get scoreSummary;

  /// No description provided for @reviewSolutions.
  ///
  /// In en, this message translates to:
  /// **'Review Solutions'**
  String get reviewSolutions;

  /// No description provided for @retakeWithGhost.
  ///
  /// In en, this message translates to:
  /// **'Retake with Exam Ghost'**
  String get retakeWithGhost;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Offline Ready'**
  String get offlineReady;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Sync Pending'**
  String get syncPending;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'All Synced'**
  String get syncCompleted;

  /// No description provided for @weakTopics.
  ///
  /// In en, this message translates to:
  /// **'Recommended Weak Topics'**
  String get weakTopics;

  /// No description provided for @readinessScore.
  ///
  /// In en, this message translates to:
  /// **'Readiness Score'**
  String get readinessScore;

  /// No description provided for @simplerExplanation.
  ///
  /// In en, this message translates to:
  /// **'Simpler Explanation'**
  String get simplerExplanation;

  /// No description provided for @keyConcept.
  ///
  /// In en, this message translates to:
  /// **'Key Concept & Formula'**
  String get keyConcept;

  /// No description provided for @commonMistake.
  ///
  /// In en, this message translates to:
  /// **'Common Pitfall'**
  String get commonMistake;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
