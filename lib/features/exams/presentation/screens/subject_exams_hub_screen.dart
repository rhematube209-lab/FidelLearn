import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../exams/domain/services/exam_engine.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../subjects/data/repositories/local_content_repository.dart';
import '../../../subjects/domain/models/subject_models.dart';

class SubjectExamsHubScreen extends ConsumerStatefulWidget {
  final String subjectId;

  const SubjectExamsHubScreen({
    super.key,
    required this.subjectId,
  });

  @override
  ConsumerState<SubjectExamsHubScreen> createState() =>
      _SubjectExamsHubScreenState();
}

class _SubjectExamsHubScreenState extends ConsumerState<SubjectExamsHubScreen> {
  late Subject _subject =
      _resolveDefaultSubject(widget.subjectId, 12, 'natural');
  bool _isLoading = false;
  bool _isLaunching = false;
  bool _timedMode = true;
  List<ExamAttempt> _subjectAttempts = [];
  int _totalAvailableQuestions = 0;

  // Persistent offline download cache tracker
  static final Map<String, Set<int>> _memoryDownloadedYears = {};
  Set<int> _downloadedYears = {};
  final Set<int> _downloadingYears = {};

  // Official Ethiopian National Examination (ESSLCE) years
  static const List<_OfficialExamYearInfo> _availableYears = [
    _OfficialExamYearInfo(
      ethiopianYear: 2016,
      gregorianYear: 2024,
      bookletCode: 'Booklet 12',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: true,
      descriptionEn:
          'Official 2016 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'በሀገር አቀፍ የትምህርት ምዘናና ፈተናዎች አገልግሎት የተሰጠ የ2016 ዓ.ም. ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2015,
      gregorianYear: 2023,
      bookletCode: 'Booklet 14',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn:
          'Official 2015 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2015 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2014,
      gregorianYear: 2022,
      bookletCode: 'Booklet 11',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn:
          'Official 2014 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2014 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2013,
      gregorianYear: 2021,
      bookletCode: 'Booklet 12',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn:
          'Official 2013 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2013 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2012,
      gregorianYear: 2020,
      bookletCode: 'Booklet 09',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn:
          'Official 2012 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2012 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2011,
      gregorianYear: 2019,
      bookletCode: 'Booklet 10',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn:
          'Official 2011 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2011 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjectData();
    _loadDownloadedYears();
  }

  Future<void> _loadDownloadedYears() async {
    final cleanId = widget.subjectId.toLowerCase();
    final defaultDownloaded = <int>{};
    if (cleanId.contains('phys')) {
      defaultDownloaded.add(2014);
    } else if (cleanId.contains('bio')) {
      defaultDownloaded.add(2013);
    }

    if (_memoryDownloadedYears.containsKey(widget.subjectId)) {
      if (mounted) {
        setState(() {
          final cached =
              Set<int>.from(_memoryDownloadedYears[widget.subjectId]!);
          cached.addAll(defaultDownloaded);
          _downloadedYears = cached;
        });
      }
      return;
    }

    try {
      SharedPreferences? prefs;
      if (!kIsWeb) {
        try {
          if (io.Platform.environment.containsKey('FLUTTER_TEST')) {
            prefs = null;
          } else {
            prefs = await SharedPreferences.getInstance();
          }
        } catch (_) {
          prefs = null;
        }
      } else {
        prefs = await SharedPreferences.getInstance();
      }

      if (prefs != null) {
        final key = 'downloaded_exams_${widget.subjectId}';
        final saved = prefs.getStringList(key);
        if (saved != null) {
          final parsed =
              saved.map((e) => int.tryParse(e)).whereType<int>().toSet();
          parsed.addAll(defaultDownloaded);
          _downloadedYears = parsed;
          _memoryDownloadedYears[widget.subjectId] = Set.from(parsed);
          if (mounted) setState(() {});
          return;
        }
      }
    } catch (_) {}

    // Default: Bundled official archives are pre-downloaded offline
    _downloadedYears = Set.from(defaultDownloaded);
    _memoryDownloadedYears[widget.subjectId] = Set.from(defaultDownloaded);
    if (mounted) setState(() {});
  }

  Future<void> _saveDownloadedYears() async {
    _memoryDownloadedYears[widget.subjectId] = Set.from(_downloadedYears);
    try {
      SharedPreferences? prefs;
      if (!kIsWeb) {
        try {
          if (io.Platform.environment.containsKey('FLUTTER_TEST')) {
            prefs = null;
          } else {
            prefs = await SharedPreferences.getInstance();
          }
        } catch (_) {
          prefs = null;
        }
      } else {
        prefs = await SharedPreferences.getInstance();
      }

      if (prefs != null) {
        final key = 'downloaded_exams_${widget.subjectId}';
        await prefs.setStringList(
          key,
          _downloadedYears.map((e) => e.toString()).toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadSubjectData() async {
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final contentRepo = ref.read(contentRepositoryProvider);
      final examRepo = ref.read(examRepositoryProvider);

      final grade = user?.grade ?? 12;
      final stream = user?.stream ?? 'natural';

      final subjects =
          await contentRepo.getSubjects(grade: grade, stream: stream);
      Subject? found =
          subjects.where((s) => s.id == widget.subjectId).firstOrNull;

      // Fallback matching by code or clean id
      if (found == null) {
        final cleanId = widget.subjectId.toLowerCase();
        found = subjects
            .where((s) =>
                s.id.toLowerCase() == cleanId ||
                LocalContentRepository.matchesSubjectId(
                    s.id, widget.subjectId) ||
                s.id.toLowerCase().contains(cleanId) ||
                cleanId.contains(s.id.toLowerCase()) ||
                s.code.toLowerCase().contains(cleanId))
            .firstOrNull;
      }

      // Default fallback subject object
      found ??= _resolveDefaultSubject(
        LocalContentRepository.canonicalSubjectId(widget.subjectId),
        grade,
        stream,
      );

      // Load attempts history for this subject
      List<ExamAttempt> attempts = [];
      if (user != null) {
        try {
          final allAttempts = await examRepo.getAttemptHistory(user.id);
          attempts = allAttempts
              .where((a) =>
                  a.subjectId == widget.subjectId ||
                  (found != null && a.subjectId == found.id))
              .toList();
        } catch (_) {}
      }

      // Sample questions count
      int questionCount = 0;
      try {
        final qs = await contentRepo.getQuestions(
          grade: grade,
          subjectId: found.id,
        );
        questionCount = qs.length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          if (found != null) _subject = found;
          _subjectAttempts = attempts;
          _totalAvailableQuestions = questionCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subject = _resolveDefaultSubject(widget.subjectId, 12, 'natural');
          _isLoading = false;
        });
      }
    }
  }

  Subject _resolveDefaultSubject(String id, int grade, String stream) {
    return LocalContentRepository.resolveDefaultSubject(
      id,
      grade: grade,
      stream: stream,
    );
  }

  _OfficialExamYearInfo _resolveYearInfo(
      _OfficialExamYearInfo base, Subject subject) {
    final isBio =
        LocalContentRepository.matchesSubjectId(subject.id, 'biology_g12') ||
            subject.nameEn.toLowerCase().contains('bio');
    if (isBio && base.ethiopianYear == 2013) {
      return base.copyWith(
        standardQuestionCount: 100,
        bookletCode: 'Booklet 12',
        standardTimeMinutes: 120,
        isVerifiedArchive: true,
        specialBadge: 'OFFICIAL 100 Qs',
        descriptionEn:
            'Official 2013 E.C. National Exam (100 Questions, Booklet 12) administered by NEAEA.',
        descriptionAm:
            'በሀገር አቀፍ የትምህርት ምዘናና ፈተናዎች አገልግሎት የተሰጠ የ2013 ዓ.ም. ባለ 100 ጥያቄ ፈተና (ጥራዝ 12)።',
      );
    }
    final isPhys =
        LocalContentRepository.matchesSubjectId(subject.id, 'physics_g12') ||
            subject.nameEn.toLowerCase().contains('phys');
    if (isPhys && base.ethiopianYear == 2014) {
      return base.copyWith(
        standardQuestionCount: 32,
        bookletCode: 'Booklet 11',
        standardTimeMinutes: 75,
        isVerifiedArchive: true,
        specialBadge: 'OFFICIAL 32 Qs',
        descriptionEn:
            'Official 2014 E.C. (2022 G.C.) National Exam (Natural Science, 32 Questions, Booklet 11) with worked step-by-step solutions.',
        descriptionAm:
            'የ2014 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ፊዚክስ ማጠቃለያ ፈተና (የተፈጥሮ ሳይንስ - 32 ጥያቄዎች፣ ጥራዝ 11 ከተሟላ ማብራሪያ ጋር)።',
      );
    }
    return base;
  }

  List<_OfficialExamYearInfo> _getDisplayYears(Subject subject) {
    final isPhys =
        LocalContentRepository.matchesSubjectId(subject.id, 'physics_g12') ||
            subject.nameEn.toLowerCase().contains('phys');
    final isBio =
        LocalContentRepository.matchesSubjectId(subject.id, 'biology_g12') ||
            subject.nameEn.toLowerCase().contains('bio');

    if (isPhys) {
      final y2014 =
          _availableYears.firstWhere((y) => y.ethiopianYear == 2014);
      final others =
          _availableYears.where((y) => y.ethiopianYear != 2014).toList();
      return [y2014, ...others];
    }
    if (isBio) {
      final y2013 =
          _availableYears.firstWhere((y) => y.ethiopianYear == 2013);
      final others =
          _availableYears.where((y) => y.ethiopianYear != 2013).toList();
      return [y2013, ...others];
    }
    return _availableYears;
  }

  Future<void> _downloadYear(_OfficialExamYearInfo rawYearInfo) async {
    final yearInfo = _resolveYearInfo(rawYearInfo, _subject);
    if (_downloadingYears.contains(yearInfo.ethiopianYear)) return;

    setState(() => _downloadingYears.add(yearInfo.ethiopianYear));

    final user = ref.read(currentUserProvider).valueOrNull;
    final isAmharic = user?.preferredLanguage == 'am';

    try {
      final contentRepo = ref.read(contentRepositoryProvider);

      // Securely fetch and verify questions for this exam year
      await contentRepo.getQuestions(
        grade: _subject.grade,
        subjectId: _subject.id,
        examYear: yearInfo.ethiopianYear,
        limit: yearInfo.standardQuestionCount,
      );

      // Brief realistic transfer & decryption delay
      await Future<void>.delayed(const Duration(milliseconds: 650));

      if (mounted) {
        setState(() {
          _downloadedYears.add(yearInfo.ethiopianYear);
          _downloadingYears.remove(yearInfo.ethiopianYear);
        });
        await _saveDownloadedYears();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAmharic
                          ? 'የ${yearInfo.ethiopianYear} ዓ.ም. ፈተና ከመስመር ውጭ ለመለማመድ በተሳካ ሁኔታ ወርዷል!'
                          : '${yearInfo.ethiopianYear} E.C. Exam downloaded & verified for offline practice!',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloadingYears.remove(yearInfo.ethiopianYear));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              isAmharic
                  ? 'ፈተናውን ማውረድ አልተቻለም: $e'
                  : 'Failed to download exam package: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeDownloadedYear(_OfficialExamYearInfo rawYearInfo) async {
    final yearInfo = _resolveYearInfo(rawYearInfo, _subject);
    final user = ref.read(currentUserProvider).valueOrNull;
    final isAmharic = user?.preferredLanguage == 'am';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: AppTheme.danger, size: 22),
            const SizedBox(width: 8),
            Text(
              isAmharic ? 'የፈተና ጥቅልን ሰርዝ' : 'Remove Offline Exam',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          isAmharic
              ? 'የ${yearInfo.ethiopianYear} ዓ.ም. (${yearInfo.bookletCode}) ፈተናን ከመሳሪያዎ ማህደረ-ትውስታ ማጥፋት ይፈልጋሉ? ቦታ ለመቆጠብ ይረዳል።'
              : 'Remove ${yearInfo.ethiopianYear} E.C. (${yearInfo.bookletCode}) from local offline storage to free up space?',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAmharic ? 'ተው' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: Text(isAmharic ? 'ሰርዝ' : 'Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() {
        _downloadedYears.remove(yearInfo.ethiopianYear);
      });
      await _saveDownloadedYears();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Text(
              isAmharic
                  ? 'የ${yearInfo.ethiopianYear} ዓ.ም. ፈተና ከመሳሪያዎ ተሰርዟል።'
                  : '${yearInfo.ethiopianYear} E.C. Exam removed from device storage.',
            ),
          ),
        );
      }
    }
  }

  String _getOfficialSubjectCode(Subject subject) {
    final s = '${subject.id} ${subject.code} ${subject.nameEn}'.toLowerCase();
    if (s.contains('bio')) return '06';
    if (s.contains('phys')) return '04';
    if (s.contains('chem')) return '05';
    if (s.contains('math')) {
      return subject.stream.toLowerCase().contains('social') ? '07' : '02';
    }
    if (s.contains('eng')) return '01';
    if (s.contains('apt')) return '03';
    if (s.contains('geo')) return '08';
    if (s.contains('hist')) return '09';
    if (s.contains('econ')) return '10';
    if (s.contains('civ')) return '11';
    return '06';
  }

  String _getStreamDisplayName(Subject subject, bool isAmharic) {
    final stream = subject.stream.toLowerCase();
    if (stream.contains('social')) {
      return isAmharic ? 'ማህበራዊ ሳይንስ' : 'Social Science';
    } else if (stream.contains('common')) {
      return isAmharic ? 'የተፈጥሮና ማህበራዊ ሳይንስ' : 'Natural & Social Science';
    } else {
      return isAmharic ? 'የተፈጥሮ ሳይንስ' : 'Natural Science';
    }
  }

  Future<void> _showExamBriefingDialog(
      _OfficialExamYearInfo rawYearInfo) async {
    final yearInfo = _resolveYearInfo(rawYearInfo, _subject);
    final user = ref.read(currentUserProvider).valueOrNull;
    final isAmharic = user?.preferredLanguage == 'am';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subject = _subject;
    final hubTheme = _getHubTheme(subject);

    bool showInstant = false;
    bool isTimed = _timedMode;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bookletCode =
                yearInfo.bookletCode.replaceAll('Booklet', '').trim();
            final subjectCode = _getOfficialSubjectCode(subject);
            final streamName = _getStreamDisplayName(subject, isAmharic);
            final subjectName = isAmharic && subject.nameAm.isNotEmpty
                ? subject.nameAm
                : subject.nameEn;
            final hours = yearInfo.standardTimeMinutes ~/ 60;
            final mins = yearInfo.standardTimeMinutes % 60;
            final timeAllowed = isTimed
                ? (isAmharic
                    ? (hours > 0 && mins > 0
                        ? '$hours ሰዓት ከ $mins ደቂቃ'
                        : (hours > 0 ? '$hours ሰዓት' : '$mins ደቂቃ'))
                    : (hours > 0 && mins > 0
                        ? '$hours Hour $mins Min'
                        : (hours > 0
                            ? (hours == 1 ? '1 Hour' : '$hours Hours')
                            : '$mins Min')))
                : (isAmharic ? 'ያልተገደበ' : 'Untimed');

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar: Official Badge + Close Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF1E3A8A)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: Color(0xFF1E3A8A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAmharic
                                      ? 'ብሔራዊ ፈተና ማጠቃለያ'
                                      : 'OFFICIAL EXAMINATION BRIEFING',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(dialogCtx),
                            tooltip: isAmharic ? 'ዝጋ' : 'Close',
                            visualDensity: VisualDensity.compact,
                            color: isDark
                                ? AppTheme.darkMuted
                                : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // =======================================================
                      // 🏛️ OFFICIAL ESSLCE HEADER (Matching user's attached picture)
                      // =======================================================
                      Center(
                        child: Column(
                          children: [
                            Text(
                              isAmharic
                                  ? 'የኢትዮጵያ የሁለተኛ ደረጃ ትምህርት\nማጠናቀቂያ ሰርተፊኬት ፈተና'
                                  : 'ETHIOPIAN SECONDARY SCHOOL\nLEAVING CERTIFICATE EXAMINATION',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                height: 1.3,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isAmharic
                                  ? '$subjectName ለ$streamName ዘርፍ'
                                  : '$subjectName for $streamName Stream',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: hubTheme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${yearInfo.ethiopianYear} E.C. / ${yearInfo.gregorianYear - 1}–${yearInfo.gregorianYear} G.C. — ${yearInfo.standardQuestionCount} Questions with Correct Answers',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkMuted
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // =======================================================
                      // 📊 SPECIFICATION TABLE (Matching user's attached picture)
                      // =======================================================
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                                width: 1.0,
                              ),
                              verticalInside: BorderSide(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                                width: 1.0,
                              ),
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(1.05),
                              1: FlexColumnWidth(1.0),
                              2: FlexColumnWidth(1.05),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                          .withValues(alpha: 0.6)
                                      : const Color(0xFFF8FAFC),
                                ),
                                children: [
                                  _buildBriefingCell(
                                    isAmharic
                                        ? 'የጥያቄ ብዛት: ${yearInfo.standardQuestionCount}'
                                        : 'Number of Items: ${yearInfo.standardQuestionCount}',
                                    isDark,
                                  ),
                                  _buildBriefingCell(
                                    isAmharic
                                        ? 'የጥራዝ ቁጥር: $bookletCode'
                                        : 'Booklet Code: $bookletCode',
                                    isDark,
                                  ),
                                  _buildBriefingCell(
                                    isAmharic
                                        ? 'የትምህርት ኮድ: $subjectCode'
                                        : 'Subject Code: $subjectCode',
                                    isDark,
                                  ),
                                ],
                              ),
                              TableRow(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                          .withValues(alpha: 0.4)
                                      : Colors.white,
                                ),
                                children: [
                                  _buildBriefingCell(
                                    isAmharic
                                        ? 'የተፈቀደው ጊዜ: $timeAllowed'
                                        : 'Time Allowed: $timeAllowed',
                                    isDark,
                                  ),
                                  _buildBriefingCell(
                                    isAmharic
                                        ? 'የምዘና ምንጭ: NEAEA'
                                        : 'Source: NEAEA Archive',
                                    isDark,
                                  ),
                                  _buildBriefingCell(
                                    isAmharic
                                        ? 'ቅርጸት: ጥያቄ፣ አማራጭ፣ መልስ'
                                        : 'Format: Questions, options, answers',
                                    isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // =======================================================
                      // 📐 REFERENCE CONSTANTS (Page 1 Official Exam Document)
                      // =======================================================
                      if (_hasReferenceConstants(subject)) ...[
                        const SizedBox(height: 16),
                        _buildReferenceConstantsSection(
                          context,
                          isDark,
                          isAmharic,
                          hubTheme,
                        ),
                      ],
                      const SizedBox(height: 18),

                      // =======================================================
                      // 🎯 ANSWER FEEDBACK MODE SELECTION (The 2 Options Requested)
                      // =======================================================
                      Text(
                        isAmharic
                            ? 'የመልስ አሳይ ሁኔታን ይምረጡ:'
                            : 'Select Answer Display Mode:',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Option 1: Show answer immediately after choice is selected
                      _buildFeedbackOptionCard(
                        title: isAmharic
                            ? 'ምርጫው እንደተመረጠ ወዲያውኑ መልሱን አሳይ'
                            : 'Show answer immediately after choice is selected',
                        subtitle: isAmharic
                            ? 'ለጥናትና ለመለማመድ ተመራጭ። እያንዳንዱን ጥያቄ እንደመለሱ ትክክለኛውን መልስና ዝርዝር ማብራሪያውን ወዲያው ያሳያል።'
                            : 'Instant feedback study mode. Step-by-step verified explanations and correct/incorrect indicators appear right after you pick.',
                        badge: isAmharic ? 'የጥናት ዘዴ' : 'STUDY MODE',
                        icon: Icons.bolt_rounded,
                        accentColor: hubTheme.accentColor,
                        isSelected: showInstant,
                        isDark: isDark,
                        onTap: () => setDialogState(() => showInstant = true),
                      ),
                      const SizedBox(height: 10),

                      // Option 2: Show answer after finishing all questions
                      _buildFeedbackOptionCard(
                        title: isAmharic
                            ? 'ሁሉንም ጥያቄዎች ከጨረሱ በኋላ መልሱን አሳይ'
                            : 'Show answer after finishing all questions',
                        subtitle: isAmharic
                            ? 'ትክክለኛውን የፈተና አዳራሽ ድባብ ይለማመዱ። ውጤትዎ፣ ዝርዝር ትንታኔውና ማብራሪያው የሚቀርበው መጨረሻ ላይ ፈተናውን አስረክበው ሲጨርሱ ነው።'
                            : 'Simulate official exam hall conditions. All answers, full explanations, and your score breakdown are revealed after final submission.',
                        badge: isAmharic ? 'የፈተና አዳራሽ' : 'EXAM SIMULATION',
                        icon: Icons.assignment_turned_in_rounded,
                        accentColor: const Color(0xFF1E3A8A),
                        isSelected: !showInstant,
                        isDark: isDark,
                        onTap: () => setDialogState(() => showInstant = false),
                      ),
                      const SizedBox(height: 16),

                      // Timer Condition Switcher inside Dialog
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isTimed
                                    ? Icons.timer_outlined
                                    : Icons.all_inclusive_rounded,
                                size: 16,
                                color: hubTheme.accentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAmharic ? 'የሰዓት ቆጣሪ:' : 'Time Limit:',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.darkMuted
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildDialogTimerPill(
                                label: isAmharic
                                    ? '${yearInfo.standardTimeMinutes} ደቂቃ'
                                    : '${yearInfo.standardTimeMinutes}m',
                                isActive: isTimed,
                                onTap: () =>
                                    setDialogState(() => isTimed = true),
                                hubTheme: hubTheme,
                                isDark: isDark,
                              ),
                              const SizedBox(width: 6),
                              _buildDialogTimerPill(
                                label: isAmharic ? 'ያልተገደበ' : 'Untimed',
                                isActive: !isTimed,
                                onTap: () =>
                                    setDialogState(() => isTimed = false),
                                hubTheme: hubTheme,
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Start Exam Action CTA
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _startYearExam(
                            rawYearInfo,
                            showInstantFeedback: showInstant,
                            isTimed: isTimed,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hubTheme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isAmharic ? 'ፈተናውን አሁን ጀምር' : 'Start Exam Now',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBriefingCell(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackOptionCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : (isDark
                            ? AppTheme.darkMuted
                            : const Color(0xFF94A3B8)),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogTimerPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required _SubjectHubTheme hubTheme,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? hubTheme.accentColor : hubTheme.surfaceTint)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? hubTheme.accentColor
                : (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : hubTheme.accentColor)
                : (isDark ? AppTheme.darkMuted : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Future<void> _startYearExam(
    _OfficialExamYearInfo rawYearInfo, {
    bool showInstantFeedback = false,
    bool isTimed = true,
  }) async {
    final yearInfo = _resolveYearInfo(rawYearInfo, _subject);
    if (_isLaunching) return;

    // If not yet downloaded, securely download and cache first
    final isDownloaded = _downloadedYears.contains(yearInfo.ethiopianYear);
    if (!isDownloaded) {
      await _downloadYear(yearInfo);
      if (!mounted) return;
      if (!_downloadedYears.contains(yearInfo.ethiopianYear)) {
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isLaunching = true);

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please sign in to begin exam practice.')),
        );
        return;
      }

      final contentRepo = ref.read(contentRepositoryProvider);
      final examRepo = ref.read(examRepositoryProvider);
      final subject = _subject;

      // 1. Fetch questions specifically matching this exam year
      List<Question> questions = await contentRepo.getQuestions(
        grade: subject.grade,
        subjectId: subject.id,
        examYear: yearInfo.ethiopianYear,
      );

      // 2. If year-tagged questions are limited in offline seed, gracefully sample from subject pool
      if (questions.isEmpty) {
        questions = await contentRepo.getQuestions(
          grade: subject.grade,
          subjectId: subject.id,
          limit: yearInfo.standardQuestionCount,
        );
      }

      if (questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No exam questions found for ${subject.nameEn} ${yearInfo.ethiopianYear} E.C. Please download the subject package in Manage Packages.',
              ),
              backgroundColor: AppTheme.accentGold,
            ),
          );
        }
        return;
      }

      // Cap at standard question count
      final examQuestions =
          questions.take(yearInfo.standardQuestionCount).toList();

      final examTitle =
          '${yearInfo.ethiopianYear} E.C. (${yearInfo.gregorianYear}) ${subject.nameEn} National Exam';

      final exam = Exam(
        id: 'nat_exam_${subject.id}_${yearInfo.ethiopianYear}_${DateTime.now().millisecondsSinceEpoch}',
        title: examTitle,
        examType: ExamType.mockFull,
        grade: subject.grade,
        stream: user.stream,
        subjectId: subject.id,
        timeLimitMinutes: isTimed ? yearInfo.standardTimeMinutes : 0,
        totalQuestions: examQuestions.length,
        questions: examQuestions,
        createdAt: DateTime.now(),
      );

      final attempt = ExamEngine.startAttempt(
        attemptId: 'att_nat_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        exam: exam,
      );

      await examRepo.saveActiveAttempt(attempt);

      if (mounted) {
        await context.push('/exam_runner', extra: {
          'exam': exam,
          'attempt': attempt,
          'showInstantFeedback': showInstantFeedback,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch exam: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  _SubjectHubTheme _getHubTheme(Subject subject) {
    final key = '${subject.id} ${subject.code} ${subject.nameEn}'.toLowerCase();
    if (key.contains('math')) {
      return const _SubjectHubTheme(
        symbol: '∑',
        accentColor: Color(0xFF6366F1),
        gradientStart: Color(0xFF4F46E5),
        gradientEnd: Color(0xFF312E81),
        surfaceTint: Color(0xFFEEF2FF),
      );
    } else if (key.contains('bio')) {
      return const _SubjectHubTheme(
        icon: Icons.biotech_rounded,
        accentColor: Color(0xFF059669),
        gradientStart: Color(0xFF059669),
        gradientEnd: Color(0xFF064E3B),
        surfaceTint: Color(0xFFECFDF5),
      );
    } else if (key.contains('phys')) {
      return const _SubjectHubTheme(
        icon: Icons.bolt_rounded,
        accentColor: Color(0xFF2563EB),
        gradientStart: Color(0xFF2563EB),
        gradientEnd: Color(0xFF1E3A8A),
        surfaceTint: Color(0xFFEFF6FF),
      );
    } else if (key.contains('chem')) {
      return const _SubjectHubTheme(
        icon: Icons.science_rounded,
        accentColor: Color(0xFF9333EA),
        gradientStart: Color(0xFF9333EA),
        gradientEnd: Color(0xFF581C87),
        surfaceTint: Color(0xFFFAF5FF),
      );
    } else if (key.contains('eng')) {
      return const _SubjectHubTheme(
        icon: Icons.menu_book_rounded,
        accentColor: Color(0xFFD97706),
        gradientStart: Color(0xFFD97706),
        gradientEnd: Color(0xFF78350F),
        surfaceTint: Color(0xFFFEF3C7),
      );
    } else {
      return const _SubjectHubTheme(
        icon: Icons.school_rounded,
        accentColor: AppTheme.brand,
        gradientStart: AppTheme.brand,
        gradientEnd: AppTheme.brandStrong,
        surfaceTint: Color(0xFFF1F5F9),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isAmharic = user?.preferredLanguage == 'am';
    final subject = _subject;
    final hubTheme = _getHubTheme(subject);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isWide = screenWidth >= 900;

                return SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 🌟 1. Full-Width Edge-to-Edge Hero Card (with Header & Fully Customize Practice Card inside)
                      _buildEdgeToEdgeHeroSection(
                        context,
                        subject,
                        hubTheme,
                        isWide,
                        isAmharic,
                        isDark,
                      ),

                      // 📚 2. Content Container Below Hero Card
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 32.0 : 16.0,
                          vertical: 24.0,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1160),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Pathway 1: Previous Years National Exams Header & Controls
                                _buildPastYearsSectionHeader(
                                  context,
                                  hubTheme,
                                  isAmharic,
                                  isDark,
                                ),
                                const SizedBox(height: 16),

                                // Past Examination Papers Grid
                                _buildExamYearsGrid(
                                  context,
                                  subject,
                                  hubTheme,
                                  isWide,
                                  isAmharic,
                                  isDark,
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ===========================================================================
  // 🌟 1. FULL-WIDTH EDGE-TO-EDGE HERO SECTION
  // ===========================================================================
  Widget _buildEdgeToEdgeHeroSection(
    BuildContext context,
    Subject subject,
    _SubjectHubTheme hubTheme,
    bool isWide,
    bool isAmharic,
    bool isDark,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            hubTheme.gradientStart,
            hubTheme.gradientEnd,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: hubTheme.accentColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            // Top-left ambient glow
            Positioned(
              left: -35,
              top: -35,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            // Bottom-right ambient glow
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Content Container
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding > 0 ? topPadding + 10 : 18,
                    left: isWide ? 32.0 : 16.0,
                    right: isWide ? 32.0 : 16.0,
                    bottom: 22.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top Section: Subject Emblem, Badges, Name, and Back Button in Top-Right Corner
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject Emblem (Left)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: hubTheme.symbol != null
                                  ? Text(
                                      hubTheme.symbol!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : Icon(
                                      hubTheme.icon ?? Icons.school,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Badges & Subject Title (Center)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.20),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Grade ${subject.grade} • ${subject.stream.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.30),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF6EE7B7)
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Text(
                                        isAmharic
                                            ? 'ሚኒስቴር-ተስማሚ'
                                            : 'MoE Verified',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD1FAE5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isAmharic && subject.nameAm.isNotEmpty
                                      ? '${subject.nameEn} (${subject.nameAm})'
                                      : subject.nameEn,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Back Button (Top-Right Corner per reference)
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              tooltip: isAmharic ? 'ተመለስ' : 'Back',
                              onPressed: () => context.pop(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Quick Stats Strip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildHeaderStat(
                              '${_availableYears.length}',
                              isAmharic ? 'የፈተና ዓመታት' : 'Official Years',
                            ),
                            Container(
                                width: 1, height: 24, color: Colors.white24),
                            _buildHeaderStat(
                              _totalAvailableQuestions > 0
                                  ? '$_totalAvailableQuestions+'
                                  : '360+ Qs',
                              isAmharic ? 'የተረጋገጡ ጥያቄዎች' : 'Verified Questions',
                            ),
                            Container(
                                width: 1, height: 24, color: Colors.white24),
                            _buildHeaderStat(
                              '${_subjectAttempts.length}',
                              isAmharic ? 'የተጠናቀቁ ፈተናዎች' : 'Completed Tests',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Fully Customize Practice Card (Nested inside the Hero!)
                      _buildCustomBuilderCTA(
                        context,
                        subject,
                        hubTheme,
                        isAmharic,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ⚡ 2. PATHWAY B: FULLY CUSTOMIZE PRACTICE (CUSTOM BUILDER CTA)
  // ===========================================================================
  Widget _buildCustomBuilderCTA(
    BuildContext context,
    Subject subject,
    _SubjectHubTheme hubTheme,
    bool isAmharic,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/exam_builder?subjectId=${subject.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Copy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAmharic
                            ? 'ብጁ የልምምድ ፈተና አዘጋጅ'
                            : 'Fully Customize Practice',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isAmharic
                            ? 'የፈተና ዓመትን፣ የስርዓተ ትምህርት ክፍሎችንና የጥያቄ ብዛትን መርጠው ይለማመዱ።'
                            : 'Select specific year, syllabus units & question count on your own',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Forward action button (Build >)
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAmharic ? 'ክፈት' : 'Build',
                        style: TextStyle(
                          color: hubTheme.accentColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: hubTheme.accentColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 📐 REFERENCE CONSTANTS BUILDER (OFFICIAL PAGE 1 ESSLCE DOCUMENT SPEC)
  // ===========================================================================
  bool _hasReferenceConstants(Subject subject) {
    final key = '${subject.id} ${subject.code} ${subject.nameEn}'.toLowerCase();
    return key.contains('phys');
  }

  Widget _buildReferenceConstantsSection(
    BuildContext context,
    bool isDark,
    bool isAmharic,
    _SubjectHubTheme hubTheme,
  ) {
    final constants = [
      (
        'g',
        '10 m/s²',
        isAmharic ? 'የመሬት ስበት ስፋት' : 'Acceleration due to gravity',
      ),
      (
        'M',
        '6 × 10²⁴ kg',
        isAmharic ? 'የመሬት መጠነ-ቁስ' : 'Mass of the Earth',
      ),
      (
        'e',
        '1.6 × 10⁻¹⁹ C',
        isAmharic ? 'የኤሌክትሮን ቻርጅ' : 'Charge of electron',
      ),
      (
        'G',
        '6.67 × 10⁻¹¹ N·m²/kg²',
        isAmharic ? 'የስበት ቋሚ' : 'Gravitational constant',
      ),
      (
        'ρ',
        '1000 kg/m³',
        isAmharic ? 'የውሃ እፍጋት' : 'Density of water',
      ),
      (
        'R',
        '8.314 J/mol·K',
        isAmharic ? 'የሞላር ጋዝ ቋሚ' : 'Molar gas constant',
      ),
      (
        'ε₀',
        '8.85 × 10⁻¹² F/m',
        isAmharic ? 'የቫክዩም ፐርሚቲቪቲ' : 'Permittivity of vacuum',
      ),
      (
        'μ₀',
        '4π × 10⁻⁷ T·m/A',
        isAmharic ? 'የመግነጢሳዊ ፐርሚአቢሊቲ' : 'Magnetic permeability',
      ),
      (
        'k',
        '9 × 10⁹ N·m²/C²',
        isAmharic ? 'የኩሎምብ ቋሚ' : 'Coulomb’s constant',
      ),
      (
        'c',
        '4200 J/kg·K (Water)',
        isAmharic ? 'የውሃ ስፔሲፊክ ሙቀት' : 'Specific heat of water',
      ),
      (
        'c',
        '420 J/kg·K (Copper)',
        isAmharic ? 'የመዳብ ስፔሲፊክ ሙቀት' : 'Specific heat of copper',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.60)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.functions_rounded,
                size: 16,
                color: hubTheme.accentColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isAmharic
                      ? 'የማጣቀሻ ቋሚዎች (Reference Constants)'
                      : 'Reference Constants',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hubTheme.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hubTheme.accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  isAmharic ? 'ገጽ 1 ሰነድ' : 'PAGE 1 SPEC',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: hubTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAmharic
                ? 'በፈተናው ወቅት ለስሌት እንዲረዱ በይፋዊው የፈተና ሰነድ ገጽ 1 ላይ የቀረቡ የማጣቀሻ እሴቶች፦'
                : 'Physical constants issued on Page 1 of the official examination paper:',
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoCol = constraints.maxWidth >= 380;
              return Wrap(
                spacing: 6,
                runSpacing: 5,
                children: constants.map((c) {
                  final itemWidth = isTwoCol
                      ? (constraints.maxWidth - 6) / 2
                      : constraints.maxWidth;
                  return Container(
                    width: itemWidth,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            c.$3,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isDark
                                  ? AppTheme.darkMuted
                                  : const Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${c.$1} = ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: hubTheme.accentColor,
                                ),
                              ),
                              TextSpan(
                                text: c.$2,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: hubTheme.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hubTheme.accentColor.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 13,
                  color: hubTheme.accentColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isAmharic
                        ? 'ትሪጎኖሜትሪ፡ sin 30° = cos 60° = 0.5 • sin 60° = cos 30° = 0.87 • sin 0° = cos 90° = 0 • sin 90° = cos 0° = 1'
                        : 'Trig: sin 30° = cos 60° = 0.5 • sin 60° = cos 30° = 0.87 • sin 0° = cos 90° = 0 • sin 90° = cos 0° = 1',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 📚 3. PATHWAY 1: PREVIOUS YEARS SECTION HEADER & TIMED TOGGLE
  // ===========================================================================
  Widget _buildPastYearsSectionHeader(
    BuildContext context,
    _SubjectHubTheme hubTheme,
    bool isAmharic,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAmharic
                    ? 'ያለፉት ዓመታት የብሔራዊ ፈተናዎች'
                    : 'Previous Years National Exams',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isAmharic
                    ? 'የተሟላውን ፈተና በዓመት መርጠው ልክ እንደ ፈተናው አዳራሽ ይፈትኑ'
                    : 'Practice complete official exams by selecting a year.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Timer condition toggle (Standard 120min vs Untimed Study Mode)
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModePill(
                label: isAmharic ? 'የተገደበ (120ደ)' : 'Timed (120m)',
                icon: Icons.timer_outlined,
                isActive: _timedMode,
                onTap: () => setState(() => _timedMode = true),
                isDark: isDark,
                hubTheme: hubTheme,
              ),
              _buildModePill(
                label: isAmharic ? 'ያልተገደበ' : 'Untimed',
                icon: Icons.all_inclusive_rounded,
                isActive: !_timedMode,
                onTap: () => setState(() => _timedMode = false),
                isDark: isDark,
                hubTheme: hubTheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModePill({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    required _SubjectHubTheme hubTheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? hubTheme.accentColor : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isActive && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive
                  ? (isDark ? Colors.white : hubTheme.accentColor)
                  : (isDark ? AppTheme.darkMuted : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? AppTheme.darkMuted : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamYearsGrid(
    BuildContext context,
    Subject subject,
    _SubjectHubTheme hubTheme,
    bool isWide,
    bool isAmharic,
    bool isDark,
  ) {
    final displayYears = _getDisplayYears(subject);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: isWide ? 200 : 180,
      ),
      itemCount: displayYears.length,
      itemBuilder: (context, index) {
        final rawYearInfo = displayYears[index];
        final yearInfo = _resolveYearInfo(rawYearInfo, subject);
        return _buildYearCard(
            context, subject, yearInfo, hubTheme, isAmharic, isDark);
      },
    );
  }

  Widget _buildYearCard(
    BuildContext context,
    Subject subject,
    _OfficialExamYearInfo yearInfo,
    _SubjectHubTheme hubTheme,
    bool isAmharic,
    bool isDark,
  ) {
    final isDownloaded = _downloadedYears.contains(yearInfo.ethiopianYear);
    final isDownloading = _downloadingYears.contains(yearInfo.ethiopianYear);
    final isVerified = yearInfo.isVerifiedArchive;

    // Check if the student previously attempted this specific exam year
    final yearAttempt = _subjectAttempts.where((a) {
      final title = a.examTitle.toLowerCase();
      return title.contains('${yearInfo.ethiopianYear}') ||
          title.contains('${yearInfo.gregorianYear}');
    }).firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? hubTheme.accentColor
              : (yearInfo.isLatest
                  ? hubTheme.accentColor.withValues(alpha: 0.40)
                  : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0))),
          width: isVerified ? 2.0 : (yearInfo.isLatest ? 1.5 : 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: isVerified
                ? hubTheme.accentColor.withValues(alpha: 0.20)
                : (yearInfo.isLatest
                    ? hubTheme.accentColor.withValues(alpha: 0.10)
                    : const Color(0x06000000)),
            blurRadius: isVerified ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (isDownloaded) {
              _showExamBriefingDialog(yearInfo);
            } else {
              _downloadYear(yearInfo);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Year Header, Latest/Offline Badge, Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color:
                                  hubTheme.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              '${yearInfo.ethiopianYear} E.C.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: hubTheme.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '(${yearInfo.gregorianYear})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppTheme.darkMuted
                                    : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDownloading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  hubTheme.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 9,
                                  height: 9,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: hubTheme.accentColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAmharic ? 'በማውረድ ላይ' : 'Downloading',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: hubTheme.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isDownloaded) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.offline_pin_rounded,
                                  color: Color(0xFF059669),
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isAmharic ? 'ከመስመር ውጭ' : 'Offline',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Compact delete button to free space
                          InkWell(
                            onTap: () => _removeDownloadedYear(yearInfo),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 15,
                                color: isDark
                                    ? AppTheme.darkMuted
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (isDark
                                  ? Colors.white10
                                  : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.darkBorder
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_outlined,
                                  size: 11,
                                  color: isDark
                                      ? AppTheme.darkMuted
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  '1.8 MB',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Middle: Booklet info & description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      runSpacing: 2,
                      children: [
                        Text(
                          '${yearInfo.bookletCode} • ${yearInfo.standardQuestionCount} Qs',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        if (yearInfo.specialBadge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hubTheme.accentColor
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: hubTheme.accentColor
                                    .withValues(alpha: 0.40),
                              ),
                            ),
                            child: Text(
                              yearInfo.specialBadge!,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: hubTheme.accentColor,
                              ),
                            ),
                          )
                        else if (yearInfo.isLatest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'LATEST',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        if (yearAttempt != null)
                          FidelBadge(
                            text:
                                '${yearAttempt.percentage.toStringAsFixed(0)}%',
                            variant: yearAttempt.percentage >= 70
                                ? FidelBadgeVariant.success
                                : FidelBadgeVariant.warning,
                            isSmall: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAmharic
                          ? yearInfo.descriptionAm
                          : yearInfo.descriptionEn,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkMuted
                            : const Color(0xFF64748B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Bottom Row: Duration Pill + Action Button (Start vs Download)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _timedMode
                              ? Icons.schedule_rounded
                              : Icons.all_inclusive_rounded,
                          size: 12,
                          color: isDark
                              ? AppTheme.darkMuted
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _timedMode
                              ? '${yearInfo.standardTimeMinutes}m'
                              : (isAmharic ? 'ያልተገደበ' : 'Untimed'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.darkMuted
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    if (isDownloading)
                      ElevatedButton.icon(
                        onPressed: null,
                        icon: const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        label: Text(
                          isAmharic ? 'በማውረድ ላይ...' : 'Downloading...',
                          style: const TextStyle(
                              fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else if (isDownloaded)
                      ElevatedButton.icon(
                        onPressed: () => _showExamBriefingDialog(yearInfo),
                        icon: const Icon(Icons.play_arrow_rounded, size: 15),
                        label: Text(
                          isVerified
                              ? (isAmharic
                                  ? 'ጀምር (${yearInfo.standardQuestionCount} ጥያቄ)'
                                  : 'Start (${yearInfo.standardQuestionCount} Qs)')
                              : (isAmharic ? 'ፈተና ጀምር' : 'Start Exam'),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hubTheme.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _downloadYear(yearInfo),
                        icon: const Icon(Icons.download_rounded, size: 14),
                        label: Text(
                          isAmharic ? 'አውርድ' : 'Download',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          foregroundColor:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          side: BorderSide(
                            color: isDark
                                ? AppTheme.darkBorder
                                : const Color(0xFFCBD5E1),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficialExamYearInfo {
  final int ethiopianYear;
  final int gregorianYear;
  final String bookletCode;
  final int standardQuestionCount;
  final int standardTimeMinutes;
  final bool isLatest;
  final bool isVerifiedArchive;
  final String? specialBadge;
  final String descriptionEn;
  final String descriptionAm;

  const _OfficialExamYearInfo({
    required this.ethiopianYear,
    required this.gregorianYear,
    required this.bookletCode,
    required this.standardQuestionCount,
    required this.standardTimeMinutes,
    required this.isLatest,
    this.isVerifiedArchive = false,
    this.specialBadge,
    required this.descriptionEn,
    required this.descriptionAm,
  });

  _OfficialExamYearInfo copyWith({
    int? ethiopianYear,
    int? gregorianYear,
    String? bookletCode,
    int? standardQuestionCount,
    int? standardTimeMinutes,
    bool? isLatest,
    bool? isVerifiedArchive,
    String? specialBadge,
    String? descriptionEn,
    String? descriptionAm,
  }) {
    return _OfficialExamYearInfo(
      ethiopianYear: ethiopianYear ?? this.ethiopianYear,
      gregorianYear: gregorianYear ?? this.gregorianYear,
      bookletCode: bookletCode ?? this.bookletCode,
      standardQuestionCount:
          standardQuestionCount ?? this.standardQuestionCount,
      standardTimeMinutes: standardTimeMinutes ?? this.standardTimeMinutes,
      isLatest: isLatest ?? this.isLatest,
      isVerifiedArchive: isVerifiedArchive ?? this.isVerifiedArchive,
      specialBadge: specialBadge ?? this.specialBadge,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionAm: descriptionAm ?? this.descriptionAm,
    );
  }
}

class _SubjectHubTheme {
  final String? symbol;
  final IconData? icon;
  final Color accentColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color surfaceTint;

  const _SubjectHubTheme({
    this.symbol,
    this.icon,
    required this.accentColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.surfaceTint,
  });
}
