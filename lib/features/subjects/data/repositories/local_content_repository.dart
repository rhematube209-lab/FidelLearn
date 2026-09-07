import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/errors/failures.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/subject_models.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/services/delta_package_service.dart';

class LocalContentRepository implements ContentRepository {
  final List<String> seedAssetPaths;
  bool _isInitialized = false;

  final List<ContentPackage> _packages = [];
  final List<Subject> _subjects = [];
  final List<Unit> _units = [];
  final List<Topic> _topics = [];
  final List<Question> _questions = [];

  LocalContentRepository({
    String? seedAssetPath,
    List<String>? seedAssetPaths,
  }) : seedAssetPaths = seedAssetPaths ??
            (seedAssetPath != null
                ? [seedAssetPath]
                : const [
                    'assets/seed/content_seed_g12.json',
                    'assets/seed/biology_2013_seed.json',
                    'assets/seed/math_2014_seed.json',
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
    _isInitialized = true;
  }

  @override
  Future<List<Subject>> getSubjects({
    int? grade,
    required String stream,
  }) async {
    await initializeSeedData();
    return _subjects
        .where(
          (s) =>
              (grade == null || s.grade == grade) &&
              (s.stream == stream || s.stream == 'common' || s.stream == 'general'),
        )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<List<Unit>> getUnits(String subjectId) async {
    await initializeSeedData();
    return _units.where((u) => u.subjectId == subjectId).toList()
      ..sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
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
  }) async {
    await initializeSeedData();

    var filtered = _questions.where((q) {
      if (grade != null && q.grade != grade) return false;
      if (q.subjectId != subjectId) return false;
      if (q.verificationStatus != VerificationStatus.published) return false;
      if (unitId != null && q.unitId != unitId) return false;
      if (topicId != null && q.topicId != topicId) return false;
      if (difficulty != null && q.difficulty != difficulty) return false;
      if (examYear != null && q.examYear != examYear) return false;
      if (startYear != null && (q.examYear == null || q.examYear! < startYear)) {
        return false;
      }
      if (endYear != null && (q.examYear == null || q.examYear! > endYear)) {
        return false;
      }
      if (examYears != null && examYears.isNotEmpty &&
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
}
