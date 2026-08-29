// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appName => 'ፊደል ሌርን';

  @override
  String get welcomeTitle => 'ለሀገር አቀፍ ፈተናዎችዎ ዝግጁ ይሁኑ';

  @override
  String get welcomeSubtitle =>
      'ያለ ኢንተርኔት የሚሰራ፣ የተረጋገጡ ዝርዝር መልሶች እና የማጠቃለያ ትንታኔዎች።';

  @override
  String get getStarted => 'ጀምር';

  @override
  String get login => 'ግባ';

  @override
  String get register => 'ተመዝገብ';

  @override
  String get logout => 'ውጣ';

  @override
  String get phoneNumber => 'ስልክ ቁጥር';

  @override
  String get password => 'የይለፍ ቃል';

  @override
  String get fullName => 'ሙሉ ስም';

  @override
  String get selectLanguage => 'ቋንቋ ይምረጡ';

  @override
  String get selectGrade => 'ክፍል ይምረጡ';

  @override
  String get selectStream => 'የትምህርት ዘርፍ ይምረጡ';

  @override
  String get grade12 => '12ኛ ክፍል';

  @override
  String get grade8 => '8ኛ ክፍል';

  @override
  String get grade6 => '6ኛ ክፍል';

  @override
  String get naturalScience => 'የተፈጥሮ ሳይንስ';

  @override
  String get socialScience => 'የማህበራዊ ሳይንስ';

  @override
  String get home => 'ዋና ገጽ';

  @override
  String get practice => 'ልምምድ';

  @override
  String get progress => 'ውጤትና እድገት';

  @override
  String get rewards => 'ሽልማቶች';

  @override
  String get profile => 'የግል ማህደር';

  @override
  String streakDays(int count) {
    return 'የ$count ቀናት ጉዞ';
  }

  @override
  String coinsCount(int count) {
    return '$count ሳንቲሞች';
  }

  @override
  String get continuePractice => 'ልምምድ ቀጥል';

  @override
  String get dailyGoal => 'የቀኑ ግብ';

  @override
  String get subjects => 'ትምህርቶች';

  @override
  String get customExam => 'የግል ፈተና ማዘጋጃ';

  @override
  String get mockExam => 'ሙሉ የሙከራ ፈተና';

  @override
  String get bookmarks => 'የተቀመጡ ጥያቄዎች';

  @override
  String get mistakesNotebook => 'የስህተቶች ማስታወሻ';

  @override
  String get examGhost => 'የራስን ውጤት መወዳደሪያ (Ghost)';

  @override
  String get challenges => 'ውድድሮች';

  @override
  String questionCount(int current, int total) {
    return 'ጥያቄ $current ከ $total';
  }

  @override
  String get flagForReview => 'ምልክት አድርግ';

  @override
  String get submitExam => 'ፈተናውን ጨርስ';

  @override
  String get examResults => 'የፈተና ውጤት';

  @override
  String get scoreSummary => 'የውጤት ማጠቃለያ';

  @override
  String get reviewSolutions => 'መልሶችን ከነማብራሪያቸው ተመልከት';

  @override
  String get retakeWithGhost => 'ከቀደመ ውጤትህ ጋር እንደገና ተወዳደር';

  @override
  String get offlineReady => 'ያለ ኢንተርኔት ይሰራል';

  @override
  String get syncPending => 'ያልተመሳሰሉ መረጃዎች አሉ';

  @override
  String get syncCompleted => 'ሁሉም ተመሳስሏል';

  @override
  String get weakTopics => 'ትኩረት የሚሹ ርዕሶች';

  @override
  String get readinessScore => 'የዝግጁነት ደረጃ';

  @override
  String get simplerExplanation => 'ቀለል ያለ ማብራሪያ';

  @override
  String get keyConcept => 'ዋና ፅንሰ ሀሳብ እና ቀመር';

  @override
  String get commonMistake => 'የተለመደ ስህተት';
}
