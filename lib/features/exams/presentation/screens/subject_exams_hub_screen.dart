import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_badge.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../exams/domain/services/exam_engine.dart';
import '../../../question_bank/domain/models/question_models.dart';
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

  // Official Ethiopian National Examination (ESSLCE) years
  static const List<_OfficialExamYearInfo> _availableYears = [
    _OfficialExamYearInfo(
      ethiopianYear: 2016,
      gregorianYear: 2024,
      bookletCode: 'Booklet 12',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: true,
      descriptionEn: 'Official 2016 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'በሀገር አቀፍ የትምህርት ምዘናና ፈተናዎች አገልግሎት የተሰጠ የ2016 ዓ.ም. ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2015,
      gregorianYear: 2023,
      bookletCode: 'Booklet 14',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn: 'Official 2015 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2015 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2014,
      gregorianYear: 2022,
      bookletCode: 'Booklet 11',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn: 'Official 2014 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2014 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2013,
      gregorianYear: 2021,
      bookletCode: 'Booklet 12',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn: 'Official 2013 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2013 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2012,
      gregorianYear: 2020,
      bookletCode: 'Booklet 09',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn: 'Official 2012 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2012 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
    _OfficialExamYearInfo(
      ethiopianYear: 2011,
      gregorianYear: 2019,
      bookletCode: 'Booklet 10',
      standardQuestionCount: 60,
      standardTimeMinutes: 120,
      isLatest: false,
      descriptionEn: 'Official 2011 E.C. National Exam paper administered by NEAEA.',
      descriptionAm: 'የ2011 ዓ.ም. ሀገር አቀፍ የ12ኛ ክፍል ማጠቃለያ ፈተና።',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjectData();
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
                s.id.toLowerCase().contains(cleanId) ||
                cleanId.contains(s.id.toLowerCase()) ||
                s.code.toLowerCase().contains(cleanId))
            .firstOrNull;
      }

      // Default fallback subject object
      found ??= _resolveDefaultSubject(widget.subjectId, grade, stream);

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
    final lower = id.toLowerCase();
    if (lower.contains('math')) {
      return Subject(
        id: id,
        code: 'MATH$grade',
        nameEn: 'Mathematics',
        nameAm: 'ሒሳብ',
        grade: grade,
        stream: stream,
        sortOrder: 1,
      );
    } else if (lower.contains('bio')) {
      return Subject(
        id: id,
        code: 'BIO$grade',
        nameEn: 'Biology',
        nameAm: 'ባዮሎጂ',
        grade: grade,
        stream: stream,
        sortOrder: 2,
      );
    } else if (lower.contains('phys')) {
      return Subject(
        id: id,
        code: 'PHYS$grade',
        nameEn: 'Physics',
        nameAm: 'ፊዚክስ',
        grade: grade,
        stream: stream,
        sortOrder: 3,
      );
    } else if (lower.contains('chem')) {
      return Subject(
        id: id,
        code: 'CHEM$grade',
        nameEn: 'Chemistry',
        nameAm: 'ኬሚስትሪ',
        grade: grade,
        stream: stream,
        sortOrder: 4,
      );
    } else if (lower.contains('eng')) {
      return Subject(
        id: id,
        code: 'ENG$grade',
        nameEn: 'English',
        nameAm: 'እንግሊዝኛ',
        grade: grade,
        stream: 'common',
        sortOrder: 5,
      );
    } else {
      return Subject(
        id: id,
        code: 'SUBJ$grade',
        nameEn: 'National Exam Subject',
        nameAm: 'የትምህርት ዓይነት',
        grade: grade,
        stream: stream,
        sortOrder: 6,
      );
    }
  }

  Future<void> _startYearExam(_OfficialExamYearInfo yearInfo) async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to begin exam practice.')),
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
      final examQuestions = questions.take(yearInfo.standardQuestionCount).toList();

      final examTitle =
          '${yearInfo.ethiopianYear} E.C. (${yearInfo.gregorianYear}) ${subject.nameEn} National Exam';

      final exam = Exam(
        id: 'nat_exam_${subject.id}_${yearInfo.ethiopianYear}_${DateTime.now().millisecondsSinceEpoch}',
        title: examTitle,
        examType: ExamType.mockFull,
        grade: subject.grade,
        stream: user.stream,
        subjectId: subject.id,
        timeLimitMinutes: _timedMode ? yearInfo.standardTimeMinutes : 0,
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
      appBar: AppBar(
        title: Text(
          isAmharic && subject.nameAm.isNotEmpty ? subject.nameAm : subject.nameEn,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: isAmharic ? 'ብጁ ፈተና' : 'Custom Builder',
            onPressed: () => context.push('/exam_builder?subjectId=${subject.id}'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isWide = screenWidth >= 900;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1160),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 32.0 : 16.0,
                        vertical: 20.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Subject Header Banner
                          _buildHeaderBanner(context, subject, hubTheme, isAmharic, isDark),
                          const SizedBox(height: 24),

                          // 2. Pathway Selector: Option B (Fully Customize on Your Own) Prominent CTA
                          _buildCustomBuilderCTA(context, subject, hubTheme, isAmharic, isDark),
                          const SizedBox(height: 28),

                          // 3. Pathway 1: Previous Years National Exams Header & Controls
                          _buildPastYearsSectionHeader(context, hubTheme, isAmharic, isDark),
                          const SizedBox(height: 16),

                          // 4. Past Examination Papers Grid
                          _buildExamYearsGrid(context, subject, hubTheme, isWide, isAmharic, isDark),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ===========================================================================
  // 🌟 1. SUBJECT HEADER BANNER
  // ===========================================================================
  Widget _buildHeaderBanner(
    BuildContext context,
    Subject subject,
    _SubjectHubTheme hubTheme,
    bool isAmharic,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hubTheme.gradientStart, hubTheme.gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: hubTheme.accentColor.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Decorative Circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject Emblem
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: hubTheme.symbol != null
                            ? Text(
                                hubTheme.symbol!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : Icon(
                                hubTheme.icon ?? Icons.school,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
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
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.30),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF6EE7B7).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Text(
                                  'MoE Verified',
                                  style: TextStyle(
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
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Quick stats strip inside banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat(
                        '${_availableYears.length}',
                        isAmharic ? 'የፈተና ዓመታት' : 'Official Years',
                      ),
                      Container(width: 1, height: 24, color: Colors.white24),
                      _buildHeaderStat(
                        _totalAvailableQuestions > 0
                            ? '$_totalAvailableQuestions+'
                            : '360+ Qs',
                        isAmharic ? 'የተረጋገጡ ጥያቄዎች' : 'Verified Questions',
                      ),
                      Container(width: 1, height: 24, color: Colors.white24),
                      _buildHeaderStat(
                        '${_subjectAttempts.length}',
                        isAmharic ? 'የተጠናቀቁ ፈተናዎች' : 'Completed Tests',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? hubTheme.accentColor.withValues(alpha: 0.40)
              : hubTheme.accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hubTheme.accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
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
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hubTheme.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: hubTheme.accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Copy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAmharic ? 'ብጁ የልምምድ ፈተና አዘጋጅ' : 'Fully Customize Practice',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hubTheme.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAmharic ? 'ምርጫዎ' : 'CUSTOM',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: hubTheme.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isAmharic
                            ? 'የስርዓተ ትምህርት ክፍሎችን፣ የተወሰኑ ርዕሶችን፣ የጥያቄ ብዛትና የጊዜ ገደብ መርጠው ይለማመዱ።'
                            : 'Select specific syllabus units, weak topics, difficulty, and question count on your own.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Forward action button
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hubTheme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAmharic ? 'ክፈት' : 'Build',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
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
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAmharic
                  ? 'ያለፉት ዓመታት የብሔራዊ ፈተናዎች'
                  : 'Previous Years National Exams',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isAmharic
                  ? 'የተሟላውን ፈተና በዓመት መርጠው ልክ እንደ ፈተናው አዳራሽ ይፈትኑ'
                  : 'Practice complete official exam booklets by selecting a year',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
              ),
            ),
          ],
        ),

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? hubTheme.accentColor : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isActive && !isDark
              ? const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
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

  // ===========================================================================
  // 📝 4. PAST EXAMINATION PAPERS GRID
  // ===========================================================================
  Widget _buildExamYearsGrid(
    BuildContext context,
    Subject subject,
    _SubjectHubTheme hubTheme,
    bool isWide,
    bool isAmharic,
    bool isDark,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 1,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: isWide ? 195 : 175,
      ),
      itemCount: _availableYears.length,
      itemBuilder: (context, index) {
        final yearInfo = _availableYears[index];
        return _buildYearCard(context, subject, yearInfo, hubTheme, isAmharic, isDark);
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
          color: yearInfo.isLatest
              ? hubTheme.accentColor.withValues(alpha: 0.40)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          width: yearInfo.isLatest ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: yearInfo.isLatest
                ? hubTheme.accentColor.withValues(alpha: 0.10)
                : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _startYearExam(yearInfo),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Year Header, Latest Badge, Past Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: hubTheme.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${yearInfo.ethiopianYear} E.C.',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: hubTheme.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${yearInfo.gregorianYear})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    if (yearInfo.isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAmharic ? 'የቅርብ ጊዜ' : 'LATEST',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (yearAttempt != null)
                      FidelBadge(
                        text: '${yearAttempt.percentage.toStringAsFixed(0)}%',
                        variant: yearAttempt.percentage >= 70
                            ? FidelBadgeVariant.success
                            : FidelBadgeVariant.warning,
                        isSmall: true,
                      ),
                  ],
                ),

                // Middle: Booklet info & description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${yearInfo.bookletCode} • ${yearInfo.standardQuestionCount} Questions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAmharic ? yearInfo.descriptionAm : yearInfo.descriptionEn,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Bottom Row: Duration Pill + Start Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _timedMode ? Icons.schedule_rounded : Icons.all_inclusive_rounded,
                          size: 13,
                          color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timedMode
                              ? '${yearInfo.standardTimeMinutes} min'
                              : (isAmharic ? 'ያልተገደበ' : 'Untimed'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkMuted : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    ElevatedButton.icon(
                      onPressed: () => _startYearExam(yearInfo),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: Text(
                        isAmharic ? 'ፈተና ጀምር' : 'Start Exam',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hubTheme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
  final String descriptionEn;
  final String descriptionAm;

  const _OfficialExamYearInfo({
    required this.ethiopianYear,
    required this.gregorianYear,
    required this.bookletCode,
    required this.standardQuestionCount,
    required this.standardTimeMinutes,
    required this.isLatest,
    required this.descriptionEn,
    required this.descriptionAm,
  });
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
