import 'dart:convert';
import 'package:flutter/services.dart';

import '../../../../core/errors/failures.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/subject_models.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/services/delta_package_service.dart';
import '../../../exams/domain/models/exam_availability.dart';

class LocalContentRepository implements ContentRepository {
  final List<String> seedAssetPaths;
  bool _isInitialized = false;

  final List<ContentPackage> _packages = [];
  final List<Subject> _subjects = [];
  final List<Unit> _units = [];
  final List<Topic> _topics = [];
  final List<Question> _questions = [];
  final Map<String, List<ExamAvailability>> _availabilityCache = {};

  LocalContentRepository({
    String? seedAssetPath,
    List<String>? seedAssetPaths,
  }) : seedAssetPaths = seedAssetPaths ??
            (seedAssetPath != null
                ? [seedAssetPath]
                : const [
                    'assets/seed/content_seed_g12.json',
                    'assets/seed/biology_2013_seed.json',
                    'assets/seed/chemistry_2013_seed.json',
                    'assets/seed/chemistry_2014_seed.json',
                    'assets/seed/math_2014_seed.json',
                    'assets/seed/physics_2014_seed.json',
                    'assets/seed/secondary_curriculum_seed.json',
                  ]);

  @override
  Future<void> initializeSeedData() async {
    if (_isInitialized) return;

    try {
      _packages.clear();
      _subjects.clear();
      _units.clear();
      _topics.clear();
      _questions.clear();
      _availabilityCache.clear();

      final seenPackageIds = <String>{};
      final seenSubjectIds = <String>{};
      final seenUnitIds = <String>{};
      final seenTopicIds = <String>{};
      final seenQuestionIds = <String>{};

      for (final assetPath in seedAssetPaths) {
        try {
          final jsonString = await rootBundle.loadString(assetPath);
          final Map<String, dynamic> data =
              jsonDecode(jsonString) as Map<String, dynamic>;

          if (data.containsKey('packages')) {
            for (final p in data['packages'] as List<dynamic>) {
              final pkg = ContentPackage.fromJson(p as Map<String, dynamic>);
              if (seenPackageIds.add(pkg.packageId)) {
                if (pkg.packageId.contains('bio') ||
                    pkg.subjectId.contains('bio')) {
                  _packages.add(pkg.copyWith(
                    hasUpdate: true,
                    availableVersion: 2,
                    updateSizeBytes: 124 * 1024,
                  ));
                } else {
                  _packages.add(pkg);
                }
              }
            }
          }
          if (data.containsKey('subjects')) {
            for (final s in data['subjects'] as List<dynamic>) {
              final subj = Subject.fromJson(s as Map<String, dynamic>);
              if (seenSubjectIds.add(subj.id)) {
                _subjects.add(subj);
              }
            }
          }
          if (data.containsKey('units')) {
            for (final u in data['units'] as List<dynamic>) {
              final unit = Unit.fromJson(u as Map<String, dynamic>);
              if (seenUnitIds.add(unit.id)) {
                _units.add(unit);
              }
            }
          }
          if (data.containsKey('topics')) {
            for (final t in data['topics'] as List<dynamic>) {
              final topic = Topic.fromJson(t as Map<String, dynamic>);
              if (seenTopicIds.add(topic.id)) {
                _topics.add(topic);
              }
            }
          }
          if (data.containsKey('questions')) {
            for (final q in data['questions'] as List<dynamic>) {
              final question = Question.fromJson(q as Map<String, dynamic>);
              if (seenQuestionIds.add(question.id)) {
                _questions.add(question);
              }
            }
          }
        } catch (_) {
          // If optional package file is missing in test environment, continue
        }
      }

      _isInitialized = true;
    } catch (e) {
      throw StorageFailure('Failed to load seed educational data: $e');
    }
  }

  // Method to initialize directly with pre-parsed data (great for unit tests)
  void initializeWithData({
    required List<ContentPackage> packages,
    required List<Subject> subjects,
    required List<Unit> units,
    required List<Topic> topics,
    required List<Question> questions,
  }) {
    _packages.clear();
    _packages.addAll(packages);
    _subjects.clear();
    _subjects.addAll(subjects);
    _units.clear();
    _units.addAll(units);
    _topics.clear();
    _topics.addAll(topics);
    _questions.clear();
    _questions.addAll(questions);
    _availabilityCache.clear();
    _isInitialized = true;
  }

  void addQuestions(List<Question> newQuestions) {
    _questions.addAll(newQuestions);
    _availabilityCache.clear();
  }

  @override
  Future<List<Subject>> getSubjects({
    int? grade,
    required String stream,
  }) async {
    await initializeSeedData();
    final list = _subjects
        .where(
          (s) =>
              (grade == null || s.grade == grade) &&
              (s.stream == stream ||
                  s.stream == 'common' ||
                  s.stream == 'general'),
        )
        .toList();

    // Ensure all standard subjects for this grade/stream are available
    final defaultList = getAllDefaultSubjects(grade: grade ?? 12);
    final existingIds = list.map((s) => s.id.toLowerCase()).toSet();
    final existingNames = list.map((s) => s.nameEn.toLowerCase()).toSet();
    for (final def in defaultList) {
      if ((def.stream == stream ||
              def.stream == 'common' ||
              def.stream == 'general') &&
          !existingIds.contains(def.id.toLowerCase()) &&
          !existingNames.contains(def.nameEn.toLowerCase())) {
        list.add(def);
      }
    }

    return list..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  static bool matchesSubjectId(String a, String b) {
    if (a == b) return true;
    final aCanon = canonicalSubjectId(a);
    final bCanon = canonicalSubjectId(b);
    if (aCanon == bCanon) return true;
    return false;
  }

  static bool matchesSubjectDiscipline(String a, String b) {
    if (matchesSubjectId(a, b)) return true;
    final aBase = baseSubjectCode(a);
    final bBase = baseSubjectCode(b);
    return aBase.isNotEmpty && aBase == bBase;
  }

  static String baseSubjectCode(String id) {
    final lower = id.toLowerCase().trim();
    if (lower.contains('bio')) return 'biology';
    if (lower.contains('math')) return 'mathematics';
    if (lower.contains('phys')) return 'physics';
    if (lower.contains('chem')) return 'chemistry';
    if (lower.contains('eng')) return 'english';
    if (lower.contains('hist')) return 'history';
    if (lower.contains('geo')) return 'geography';
    if (lower.contains('econ')) return 'economics';
    if (lower.contains('apt')) return 'aptitude';
    if (lower.contains('sci')) return 'science';
    return lower;
  }

  static String canonicalSubjectId(String id) {
    final lower = id.toLowerCase().trim();
    final gradeMatch = RegExp(r'(g\d+|\d+)').firstMatch(lower);
    final gradeSuffix = gradeMatch != null
        ? (gradeMatch.group(0)!.startsWith('g')
            ? gradeMatch.group(0)!
            : 'g${gradeMatch.group(0)!}')
        : 'g12';

    if (lower.contains('bio')) return 'biology_$gradeSuffix';
    if (lower.contains('math')) return 'math_$gradeSuffix';
    if (lower.contains('phys')) return 'physics_$gradeSuffix';
    if (lower.contains('chem')) return 'chemistry_$gradeSuffix';
    if (lower.contains('eng')) return 'english_$gradeSuffix';
    if (lower.contains('hist')) return 'history_$gradeSuffix';
    if (lower.contains('geo')) return 'geography_$gradeSuffix';
    if (lower.contains('econ')) return 'economics_$gradeSuffix';
    if (lower.contains('apt')) return 'aptitude_$gradeSuffix';
    if (lower.contains('sci')) return 'science_$gradeSuffix';

    return lower;
  }

  static Subject resolveDefaultSubject(String id,
      {int grade = 12, String? stream}) {
    final canonId = canonicalSubjectId(id);
    final lower = id.toLowerCase().trim();
    final effectiveStream = stream ??
        (lower.contains('hist') ||
                lower.contains('geo') ||
                lower.contains('econ')
            ? 'social'
            : 'natural');

    if (lower.contains('math')) {
      return Subject(
        id: canonId,
        code: 'MATH$grade',
        nameEn: 'Mathematics',
        nameAm: 'ሒሳብ',
        grade: grade,
        stream: effectiveStream,
        iconAsset: 'assets/images/math_icon.png',
        sortOrder: 1,
      );
    } else if (lower.contains('bio')) {
      return Subject(
        id: canonId,
        code: 'BIO$grade',
        nameEn: 'Biology',
        nameAm: 'ባዮሎጂ',
        grade: grade,
        stream: 'natural',
        iconAsset: 'assets/images/biology_icon.png',
        sortOrder: 2,
      );
    } else if (lower.contains('phys')) {
      return Subject(
        id: canonId,
        code: 'PHYS$grade',
        nameEn: 'Physics',
        nameAm: 'ፊዚክስ',
        grade: grade,
        stream: 'natural',
        iconAsset: 'assets/images/physics_icon.png',
        sortOrder: 3,
      );
    } else if (lower.contains('chem')) {
      return Subject(
        id: canonId,
        code: 'CHEM$grade',
        nameEn: 'Chemistry',
        nameAm: 'ኬሚስትሪ',
        grade: grade,
        stream: 'natural',
        iconAsset: 'assets/images/chemistry_icon.png',
        sortOrder: 4,
      );
    } else if (lower.contains('eng')) {
      return Subject(
        id: canonId,
        code: 'ENG$grade',
        nameEn: 'English',
        nameAm: 'እንግሊዝኛ',
        grade: grade,
        stream: 'common',
        iconAsset: 'assets/images/english_icon.png',
        sortOrder: 5,
      );
    } else if (lower.contains('apt')) {
      return Subject(
        id: canonId,
        code: 'APT$grade',
        nameEn: 'Scholastic Aptitude',
        nameAm: 'አፕቲትዩድ',
        grade: grade,
        stream: 'common',
        iconAsset: 'assets/images/aptitude_icon.png',
        sortOrder: 6,
      );
    } else if (lower.contains('hist')) {
      return Subject(
        id: canonId,
        code: 'HIST$grade',
        nameEn: 'History',
        nameAm: 'ታሪክ',
        grade: grade,
        stream: 'social',
        iconAsset: 'assets/images/history_icon.png',
        sortOrder: 1,
      );
    } else if (lower.contains('geo')) {
      return Subject(
        id: canonId,
        code: 'GEO$grade',
        nameEn: 'Geography',
        nameAm: 'ጂኦግራፊ',
        grade: grade,
        stream: 'social',
        iconAsset: 'assets/images/geography_icon.png',
        sortOrder: 2,
      );
    } else if (lower.contains('econ')) {
      return Subject(
        id: canonId,
        code: 'ECON$grade',
        nameEn: 'Economics',
        nameAm: 'ኢኮኖሚክስ',
        grade: grade,
        stream: 'social',
        iconAsset: 'assets/images/economics_icon.png',
        sortOrder: 3,
      );
    } else if (lower.contains('civ')) {
      return Subject(
        id: canonId,
        code: 'CIV$grade',
        nameEn: 'Civics',
        nameAm: 'ስነ-ዜጋ',
        grade: grade,
        stream: 'common',
        sortOrder: 7,
      );
    } else {
      return Subject(
        id: canonId,
        code: 'SUBJ$grade',
        nameEn: 'National Exam Subject',
        nameAm: 'የትምህርት ዓይነት',
        grade: grade,
        stream: effectiveStream,
        sortOrder: 10,
      );
    }
  }

  static List<Subject> getAllDefaultSubjects({int grade = 12}) {
    return [
      resolveDefaultSubject('math_g$grade', grade: grade, stream: 'natural'),
      resolveDefaultSubject('biology_g$grade', grade: grade, stream: 'natural'),
      resolveDefaultSubject('physics_g$grade', grade: grade, stream: 'natural'),
      resolveDefaultSubject('chemistry_g$grade',
          grade: grade, stream: 'natural'),
      resolveDefaultSubject('english_g$grade', grade: grade, stream: 'common'),
      resolveDefaultSubject('aptitude_g$grade', grade: grade, stream: 'common'),
      resolveDefaultSubject('history_g$grade', grade: grade, stream: 'social'),
      resolveDefaultSubject('geography_g$grade',
          grade: grade, stream: 'social'),
      resolveDefaultSubject('economics_g$grade',
          grade: grade, stream: 'social'),
    ];
  }

  static List<Unit> getDefaultUnits(String subjectId) {
    final lower = subjectId.toLowerCase();
    if (lower.contains('phys')) {
      return const [
        Unit(
            id: 'phys_g9_u2',
            subjectId: 'physics_g12',
            unitNumber: 1,
            titleEn: '[Grade 9] Unit 2: Physical Quantities',
            titleAm: 'የመለኪያ መጠኖችና ስህተቶች'),
        Unit(
            id: 'phys_g9_u6',
            subjectId: 'physics_g12',
            unitNumber: 2,
            titleEn: '[Grade 9] Unit 6: Mechanical Oscillation and Sound Wave',
            titleAm: 'ንዝረቶችና የድምፅ ሞገዶች'),
        Unit(
            id: 'phys_g10_u1',
            subjectId: 'physics_g12',
            unitNumber: 3,
            titleEn: '[Grade 10] Unit 1: Vector Quantities',
            titleAm: 'የቬክተር መጠኖች'),
        Unit(
            id: 'phys_g10_u2',
            subjectId: 'physics_g12',
            unitNumber: 4,
            titleEn: '[Grade 10] Unit 2: Uniformly Accelerated Motion',
            titleAm: 'የፍጥነት ለውጥ እንቅስቃሴ'),
        Unit(
            id: 'phys_g10_u4',
            subjectId: 'physics_g12',
            unitNumber: 5,
            titleEn: '[Grade 10] Unit 4: Static and Current Electricity',
            titleAm: 'የኤሌክትሪክ ፍሰትና ዑደት'),
        Unit(
            id: 'phys_g10_u5',
            subjectId: 'physics_g12',
            unitNumber: 6,
            titleEn: '[Grade 10] Unit 5: Magnetism',
            titleAm: 'ማግኔቲዝም'),
        Unit(
            id: 'phys_g10_u6',
            subjectId: 'physics_g12',
            unitNumber: 7,
            titleEn:
                '[Grade 10] Unit 6: Electromagnetic Waves & Geometrical Optics',
            titleAm: 'ኤሌክትሮማግኔቲክ ሞገድና ጂኦሜትሪያዊ ኦፕቲክስ'),
        Unit(
            id: 'phys_g11_u4',
            subjectId: 'physics_g12',
            unitNumber: 8,
            titleEn: '[Grade 11] Unit 4: Dynamics',
            titleAm: 'ዳይናሚክስ፣ ጉልበትና ሃይል'),
        Unit(
            id: 'phys_g11_u6',
            subjectId: 'physics_g12',
            unitNumber: 9,
            titleEn: '[Grade 11] Unit 6: Electrostatics and Electric Circuit',
            titleAm: 'ኤሌክትሮስታቲክስና ዑደቶች'),
        Unit(
            id: 'phys_g11_u7',
            subjectId: 'physics_g12',
            unitNumber: 10,
            titleEn: '[Grade 11] Unit 7: Nuclear Physics',
            titleAm: 'ኒውክሌር ፊዚክስ'),
        Unit(
            id: 'phys_g12_u2',
            subjectId: 'physics_g12',
            unitNumber: 11,
            titleEn: '[Grade 12] Unit 2: Two-Dimensional Motion',
            titleAm: 'ባለ ሁለት አቅጣጫ እንቅስቃሴና ስበት'),
        Unit(
            id: 'phys_g12_u4',
            subjectId: 'physics_g12',
            unitNumber: 12,
            titleEn: '[Grade 12] Unit 4: Electromagnetism',
            titleAm: 'ኤሌክትሮማግኔቲዝምና ኤሲ ዑደቶች'),
        Unit(
            id: 'phys_g12_u5',
            subjectId: 'physics_g12',
            unitNumber: 13,
            titleEn: '[Grade 12] Unit 5: Basics of Electronics',
            titleAm: 'መሰረታዊ ኤሌክትሮኒክስ'),
      ];
    } else if (lower.contains('chem')) {
      return const [
        Unit(
            id: 'chem_g9_u1',
            subjectId: 'chemistry_g12',
            unitNumber: 1,
            titleEn: '[Grade 9] Unit 1: Chemistry and Its Importance',
            titleAm: 'ኬሚስትሪና ጠቀሜታው'),
        Unit(
            id: 'chem_g9_u2',
            subjectId: 'chemistry_g12',
            unitNumber: 2,
            titleEn: '[Grade 9] Unit 2: Measurements and Scientific Methods',
            titleAm: 'መለኪያዎችና ሳይንሳዊ ዘዴዎች'),
        Unit(
            id: 'chem_g9_u3',
            subjectId: 'chemistry_g12',
            unitNumber: 3,
            titleEn: '[Grade 9] Unit 3: Structure of the Atom',
            titleAm: 'የአተም መዋቅር'),
        Unit(
            id: 'chem_g9_u4',
            subjectId: 'chemistry_g12',
            unitNumber: 4,
            titleEn: '[Grade 9] Unit 4: Periodic Classification of Elements',
            titleAm: 'የንጥረ ነገሮች ወቅታዊ ምደባ'),
        Unit(
            id: 'chem_g9_u5',
            subjectId: 'chemistry_g12',
            unitNumber: 5,
            titleEn: '[Grade 9] Unit 5: Chemical Bonding',
            titleAm: 'ኬሚካላዊ ትስስር'),
        Unit(
            id: 'chem_g10_u1',
            subjectId: 'chemistry_g12',
            unitNumber: 6,
            titleEn: '[Grade 10] Unit 1: Chemical Reactions and Stoichiometry',
            titleAm: 'ኬሚካላዊ ግብረ-መልስና ስቶይኪዮሜትሪ'),
        Unit(
            id: 'chem_g10_u2',
            subjectId: 'chemistry_g12',
            unitNumber: 7,
            titleEn: '[Grade 10] Unit 2: Solutions',
            titleAm: 'መፍትሔዎችና የመሟሟት ባህሪ'),
        Unit(
            id: 'chem_g10_u3',
            subjectId: 'chemistry_g12',
            unitNumber: 8,
            titleEn: '[Grade 10] Unit 3: Important Inorganic Compounds',
            titleAm: 'ጠቃሚ ኢ-ኦርጋኒክ ውህዶች'),
        Unit(
            id: 'chem_g10_u4',
            subjectId: 'chemistry_g12',
            unitNumber: 9,
            titleEn: '[Grade 10] Unit 4: Energy Changes and Electrochemistry',
            titleAm: 'የሃይል ለውጥና ኤሌክትሮኬሚስትሪ'),
        Unit(
            id: 'chem_g10_u5',
            subjectId: 'chemistry_g12',
            unitNumber: 10,
            titleEn: '[Grade 10] Unit 5: Metals and Nonmetals',
            titleAm: 'ብረቶችና ኢ-ብረቶች'),
        Unit(
            id: 'chem_g10_u6',
            subjectId: 'chemistry_g12',
            unitNumber: 11,
            titleEn: '[Grade 10] Unit 6: Hydrocarbons and Their Natural Sources',
            titleAm: 'ሃይድሮካርቦኖችና የተፈጥሮ ምንጮቻቸው'),
        Unit(
            id: 'chem_g11_u1',
            subjectId: 'chemistry_g12',
            unitNumber: 12,
            titleEn: '[Grade 11] Unit 1: Atomic Structure and Periodic Properties',
            titleAm: 'የአተም መዋቅርና ወቅታዊ ባህሪያት'),
        Unit(
            id: 'chem_g11_u2',
            subjectId: 'chemistry_g12',
            unitNumber: 13,
            titleEn: '[Grade 11] Unit 2: Chemical Bonding',
            titleAm: 'ኬሚካላዊ ትስስርና ሞለኪዩላር መዋቅር'),
        Unit(
            id: 'chem_g11_u3',
            subjectId: 'chemistry_g12',
            unitNumber: 14,
            titleEn: '[Grade 11] Unit 3: Physical States of Matter',
            titleAm: 'የቁስ አካላዊ ሁኔታዎች'),
        Unit(
            id: 'chem_g11_u4',
            subjectId: 'chemistry_g12',
            unitNumber: 15,
            titleEn: '[Grade 11] Unit 4: Chemical Kinetics',
            titleAm: 'ኬሚካላዊ ኪነቲክስና የግብረ-መልስ ፍጥነት'),
        Unit(
            id: 'chem_g11_u5',
            subjectId: 'chemistry_g12',
            unitNumber: 16,
            titleEn: '[Grade 11] Unit 5: Chemical Equilibrium',
            titleAm: 'ኬሚካላዊ ሚዛን'),
        Unit(
            id: 'chem_g11_u6',
            subjectId: 'chemistry_g12',
            unitNumber: 17,
            titleEn:
                '[Grade 11] Unit 6: Some Important Oxygen-containing Organic Compounds',
            titleAm: 'ኦክስጅን የያዙ ኦርጋኒክ ውህዶች'),
        Unit(
            id: 'chem_g12_u1',
            subjectId: 'chemistry_g12',
            unitNumber: 18,
            titleEn: '[Grade 12] Unit 1: Acid-Base Concepts',
            titleAm: 'የአሲድና ቤዝ ጽንሰ-ሃሳቦች'),
        Unit(
            id: 'chem_g12_u2',
            subjectId: 'chemistry_g12',
            unitNumber: 19,
            titleEn: '[Grade 12] Unit 2: Electrochemistry',
            titleAm: 'ኤሌክትሮኬሚስትሪ'),
        Unit(
            id: 'chem_g12_u3',
            subjectId: 'chemistry_g12',
            unitNumber: 20,
            titleEn: '[Grade 12] Unit 3: Industrial Chemistry',
            titleAm: 'ኢንዱስትሪያል ኬሚስትሪ'),
        Unit(
            id: 'chem_g12_u4',
            subjectId: 'chemistry_g12',
            unitNumber: 21,
            titleEn: '[Grade 12] Unit 4: Polymers',
            titleAm: 'ፖሊመሮች'),
        Unit(
            id: 'chem_g12_u5',
            subjectId: 'chemistry_g12',
            unitNumber: 22,
            titleEn: '[Grade 12] Unit 5: Introduction to Environmental Chemistry',
            titleAm: 'የአካባቢ ኬሚስትሪ'),
      ];
    } else if (lower.contains('eng')) {
      return const [
        Unit(
            id: 'eng_u1',
            subjectId: 'english_g12',
            unitNumber: 1,
            titleEn: 'Family Life and Society',
            titleAm: 'የቤተሰብ ሕይወትና ማህበረሰብ'),
        Unit(
            id: 'eng_u2',
            subjectId: 'english_g12',
            unitNumber: 2,
            titleEn: 'Education and Global Future',
            titleAm: 'ትምህርትና የወደፊት ዕድሎች'),
        Unit(
            id: 'eng_u3',
            subjectId: 'english_g12',
            unitNumber: 3,
            titleEn: 'Science, Technology & AI',
            titleAm: 'ሳይንስ፣ ቴክኖሎጂና አርቴፊሻል ኢንተለጀንስ'),
        Unit(
            id: 'eng_u4',
            subjectId: 'english_g12',
            unitNumber: 4,
            titleEn: 'Ethiopian Cultural Heritage',
            titleAm: 'የኢትዮጵያ ባህላዊ ቅርስ'),
        Unit(
            id: 'eng_u5',
            subjectId: 'english_g12',
            unitNumber: 5,
            titleEn: 'Grammar, Reading & Vocabulary',
            titleAm: 'ሰዋሰው፣ ንባብና የቃላት አጠቃቀም'),
      ];
    } else if (lower.contains('hist')) {
      return const [
        Unit(
            id: 'hist_u1',
            subjectId: 'history_g12',
            unitNumber: 1,
            titleEn: 'State Formation & Sovereignty in Ethiopia',
            titleAm: 'የሀገር ግንባታና ሉዓላዊነት በኢትዮጵያ'),
        Unit(
            id: 'hist_u2',
            subjectId: 'history_g12',
            unitNumber: 2,
            titleEn: 'The Horn of Africa in the 19th Century',
            titleAm: 'የአፍሪካ ቀንድ በ19ኛው ክፍለ ዘመን'),
        Unit(
            id: 'hist_u3',
            subjectId: 'history_g12',
            unitNumber: 3,
            titleEn: 'Ethiopian Resistance & Victory of Adwa',
            titleAm: 'የኢትዮጵያ ተጋድሎና የአድዋ ድል'),
        Unit(
            id: 'hist_u4',
            subjectId: 'history_g12',
            unitNumber: 4,
            titleEn: 'Modernization and State Consolidation',
            titleAm: 'ዘመናዊነትና የመንግስት መጠናከር'),
        Unit(
            id: 'hist_u5',
            subjectId: 'history_g12',
            unitNumber: 5,
            titleEn: 'Contemporary Ethiopia & Global Relations',
            titleAm: 'ወቅታዊቷ ኢትዮጵያና ዓለም አቀፍ ግንኙነቶች'),
      ];
    } else if (lower.contains('geo')) {
      return const [
        Unit(
            id: 'geo_u1',
            subjectId: 'geography_g12',
            unitNumber: 1,
            titleEn: 'Geology & Rift Valley of Ethiopia',
            titleAm: 'የኢትዮጵያ ጂኦሎጂና ስምጥ ሸለቆ'),
        Unit(
            id: 'geo_u2',
            subjectId: 'geography_g12',
            unitNumber: 2,
            titleEn: 'Climate & Drainage Systems of Ethiopia',
            titleAm: 'የአየር ንብረትና የውሃ ፍሰት ስርአቶች'),
        Unit(
            id: 'geo_u3',
            subjectId: 'geography_g12',
            unitNumber: 3,
            titleEn: 'Natural Resources & Environmental Issues',
            titleAm: 'የተፈጥሮ ሀብትና የአካባቢ ጥበቃ'),
        Unit(
            id: 'geo_u4',
            subjectId: 'geography_g12',
            unitNumber: 4,
            titleEn: 'Population Dynamics & Urbanization',
            titleAm: 'የህዝብ ቁጥር እድገትና ከተሞች'),
        Unit(
            id: 'geo_u5',
            subjectId: 'geography_g12',
            unitNumber: 5,
            titleEn: 'Economic Activities & Sustainable Development',
            titleAm: 'የኢኮኖሚ እንቅስቃሴዎችና ዘላቂ ልማት'),
      ];
    } else if (lower.contains('econ')) {
      return const [
        Unit(
            id: 'econ_u1',
            subjectId: 'economics_g12',
            unitNumber: 1,
            titleEn: 'Market Equilibrium & Price Mechanism',
            titleAm: 'የገበያ ሚዛንና የዋጋ ስርአት'),
        Unit(
            id: 'econ_u2',
            subjectId: 'economics_g12',
            unitNumber: 2,
            titleEn: 'National Income Accounting & GDP',
            titleAm: 'ብሔራዊ ገቢና አጠቃላይ የሀገር ውስጥ ምርት'),
        Unit(
            id: 'econ_u3',
            subjectId: 'economics_g12',
            unitNumber: 3,
            titleEn: 'Money, Banking & Financial Institutions',
            titleAm: 'ገንዘብ፣ ባንክና የፋይናንስ ተቋማት'),
        Unit(
            id: 'econ_u4',
            subjectId: 'economics_g12',
            unitNumber: 4,
            titleEn: 'Macroeconomic Problems & Policies',
            titleAm: 'የማክሮ ኢኮኖሚ ችግሮችና ፖሊሲዎች'),
        Unit(
            id: 'econ_u5',
            subjectId: 'economics_g12',
            unitNumber: 5,
            titleEn: 'International Trade & Economic Growth',
            titleAm: 'ዓለም አቀፍ ንግድና የኢኮኖሚ እድገት'),
      ];
    }
    return const [];
  }

  @override
  Future<List<Unit>> getUnits(String subjectId) async {
    await initializeSeedData();
    final matched = _units
        .where((u) =>
            matchesSubjectId(u.subjectId, subjectId) ||
            matchesSubjectDiscipline(u.subjectId, subjectId))
        .toList()
      ..sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    if (matched.isNotEmpty) return matched;
    return getDefaultUnits(subjectId);
  }

  @override
  Future<List<Topic>> getTopics(String unitId) async {
    await initializeSeedData();
    return _topics.where((t) => t.unitId == unitId).toList()
      ..sort((a, b) => a.topicNumber.compareTo(b.topicNumber));
  }

  @override
  Future<List<ContentPackage>> getPackages({
    required int grade,
    required String stream,
  }) async {
    await initializeSeedData();
    return _packages
        .where(
          (p) =>
              p.grade == grade && (p.stream == stream || p.stream == 'common'),
        )
        .toList();
  }

  final DeltaPackageService _deltaService = DeltaPackageService();

  @override
  Future<void> downloadPackage(String packageId) async {
    await initializeSeedData();
    final index = _packages.indexWhere((p) => p.packageId == packageId);
    if (index != -1) {
      _packages[index] = _packages[index].copyWith(isDownloaded: true);
    }
  }

  @override
  Future<void> removePackage(String packageId) async {
    await initializeSeedData();
    final index = _packages.indexWhere((p) => p.packageId == packageId);
    if (index != -1) {
      _packages[index] = _packages[index].copyWith(isDownloaded: false);
    }
  }

  @override
  Future<PackageDelta?> checkPackageUpdate(String packageId) async {
    await initializeSeedData();
    final pkg = _packages.where((p) => p.packageId == packageId).firstOrNull;
    if (pkg == null) return null;
    if (pkg.hasUpdate) {
      return PackageDelta(
        packageId: packageId,
        fromVersion: '${pkg.version}.0',
        toVersion: '${pkg.availableVersion ?? (pkg.version + 1)}.0',
        addedQuestions: const [],
        updatedQuestions: const [],
        deprecatedQuestionIds: const [],
        releaseDate: DateTime.now(),
      );
    }
    return null;
  }

  @override
  Future<void> applyDeltaUpdate(String packageId, PackageDelta delta) async {
    await initializeSeedData();
    final index = _packages.indexWhere((p) => p.packageId == packageId);
    if (index != -1) {
      final updatedQuestions = _deltaService.applyDeltaPatch(
        existingQuestions: _questions,
        delta: delta,
      );
      _questions.clear();
      _questions.addAll(updatedQuestions);
      final newVer = int.tryParse(delta.toVersion.split('.').first) ??
          (_packages[index].version + 1);
      _packages[index] = _packages[index].copyWith(
        version: newVer,
        hasUpdate: false,
        availableVersion: null,
        updateSizeBytes: null,
      );
    }
  }

  @override
  Future<List<Question>> getQuestions({
    int? grade,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? difficulty,
    int? examYear,
    int? startYear,
    int? endYear,
    List<int>? examYears,
    int? limit,
    bool practiceEligibleOnly = false,
  }) async {
    await initializeSeedData();

    var filtered = _questions.where((q) {
      if (grade != null && q.grade != grade && q.curriculumGrade != grade) {
        return false;
      }
      if (!matchesSubjectId(q.subjectId, subjectId) &&
          !matchesSubjectDiscipline(q.subjectId, subjectId)) {
        return false;
      }
      if (q.verificationStatus == VerificationStatus.archived ||
          q.verificationStatus == VerificationStatus.draft) {
        return false;
      }
      if (practiceEligibleOnly && !q.isPracticeEligible) {
        return false;
      }
      if (unitId != null &&
          q.unitId != unitId &&
          q.curriculumUnitId != unitId) {
        return false;
      }
      if (topicId != null &&
          q.topicId != topicId &&
          q.curriculumTopicId != topicId) {
        return false;
      }
      if (difficulty != null && q.difficulty != difficulty) return false;
      if (examYear != null && q.examYear != examYear) return false;
      if (startYear != null &&
          (q.examYear == null || q.examYear! < startYear)) {
        return false;
      }
      if (endYear != null && (q.examYear == null || q.examYear! > endYear)) {
        return false;
      }
      if (examYears != null &&
          examYears.isNotEmpty &&
          (q.examYear == null || !examYears.contains(q.examYear))) {
        return false;
      }
      return true;
    }).toList();

    if (limit != null && limit > 0 && filtered.length > limit) {
      filtered = filtered.sublist(0, limit);
    }

    return filtered;
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    await initializeSeedData();
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ExamAvailability>> getExamAvailabilities(String subjectId) async {
    await initializeSeedData();
    final cacheKey = baseSubjectCode(subjectId);
    if (_availabilityCache.containsKey(cacheKey)) {
      return _availabilityCache[cacheKey]!;
    }

    final matching = _questions.where((q) =>
        matchesSubjectId(q.subjectId, subjectId) ||
        matchesSubjectDiscipline(q.subjectId, subjectId));

    final Map<int, List<Question>> byYear = {};
    for (final q in matching) {
      if (q.examYear != null &&
          q.verificationStatus != VerificationStatus.archived &&
          q.verificationStatus != VerificationStatus.draft) {
        byYear.putIfAbsent(q.examYear!, () => []).add(q);
      }
    }

    final List<ExamAvailability> availabilities = [];
    final sortedYears = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final year in sortedYears) {
      final qs = byYear[year]!;
      final Map<String, int> unitCounts = {};
      String? sourceName;
      for (final q in qs) {
        if (q.sourceName.isNotEmpty) {
          sourceName ??= q.sourceName;
        }
        unitCounts[q.unitId] = (unitCounts[q.unitId] ?? 0) + 1;
        if (q.curriculumUnitId != null && q.curriculumUnitId != q.unitId) {
          unitCounts[q.curriculumUnitId!] =
              (unitCounts[q.curriculumUnitId!] ?? 0) + 1;
        }
      }
      availabilities.add(ExamAvailability(
        subjectId: subjectId,
        year: year,
        totalQuestions: qs.length,
        unitCounts: unitCounts,
        verified: true,
        sourceName: sourceName,
      ));
    }

    _availabilityCache[cacheKey] = availabilities;
    return availabilities;
  }

  @override
  Future<List<int>> getAvailableExamYears(String subjectId) async {
    final avail = await getExamAvailabilities(subjectId);
    return avail.map((a) => a.year).toList();
  }

  @override
  Future<Map<String, int>> getUnitQuestionCounts({
    required String subjectId,
    int? examYear,
    int? grade,
  }) async {
    await initializeSeedData();
    final matching = _questions.where((q) {
      if (grade != null && q.grade != grade && q.curriculumGrade != grade) {
        return false;
      }
      if (!matchesSubjectId(q.subjectId, subjectId) &&
          !matchesSubjectDiscipline(q.subjectId, subjectId)) {
        return false;
      }
      if (q.verificationStatus == VerificationStatus.archived ||
          q.verificationStatus == VerificationStatus.draft) {
        return false;
      }
      if (examYear != null && q.examYear != examYear) return false;
      return true;
    });

    final Map<String, int> counts = {};
    for (final q in matching) {
      counts[q.unitId] = (counts[q.unitId] ?? 0) + 1;
      if (q.curriculumUnitId != null && q.curriculumUnitId != q.unitId) {
        counts[q.curriculumUnitId!] = (counts[q.curriculumUnitId!] ?? 0) + 1;
      }
    }
    return counts;
  }
}
