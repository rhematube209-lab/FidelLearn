import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/subject_models.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/services/delta_package_service.dart';
import 'local_content_repository.dart';

class SupabaseContentRepository implements ContentRepository {
  final SupabaseClient? _client;
  final LocalContentRepository _localFallback;

  static SupabaseClient? _getSafeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseContentRepository({
    SupabaseClient? client,
    LocalContentRepository? localFallback,
  })  : _client = client ?? _getSafeClient(),
        _localFallback = localFallback ?? LocalContentRepository();

  @override
  Future<void> initializeSeedData() async {
    try {
      await _localFallback.initializeSeedData();
    } catch (e) {
      debugPrint('SupabaseContentRepository: local seed init error: $e');
    }
  }

  @override
  Future<List<Subject>> getSubjects({
    int? grade,
    required String stream,
  }) async {
    final localSubjects =
        await _localFallback.getSubjects(grade: grade, stream: stream);

    final client = _client;
    if (client != null) {
      try {
        dynamic query = client.from('subjects').select();
        if (grade != null) {
          query = query.eq('grade', grade);
        }
        final response = await query
            .or('stream.eq.$stream,stream.eq.common,stream.eq.general')
            .order('sort_order', ascending: true)
            .timeout(const Duration(seconds: 5));

        final list = (response as List<dynamic>)
            .map((json) => Subject.fromJson(json as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) {
          // Merge local seed subjects that might not be in the remote DB yet!
          final existingIds = list.map((s) => s.id.toLowerCase()).toSet();
          final existingNames = list.map((s) => s.nameEn.toLowerCase()).toSet();
          for (final localSub in localSubjects) {
            if (!existingIds.contains(localSub.id.toLowerCase()) &&
                !existingNames.contains(localSub.nameEn.toLowerCase())) {
              list.add(localSub);
            }
          }
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return list;
        }
      } catch (e) {
        debugPrint(
            'SupabaseContentRepository: getSubjects remote failed (using local fallback): $e');
      }
    }

    return localSubjects;
  }

  @override
  Future<List<Unit>> getUnits(String subjectId) async {
    final client = _client;
    if (client != null) {
      try {
        final canonicalId =
            LocalContentRepository.canonicalSubjectId(subjectId);
        final response = await client
            .from('units')
            .select()
            .inFilter('subject_id', [subjectId, canonicalId])
            .order('unit_number', ascending: true)
            .timeout(const Duration(seconds: 5));

        final list = (response as List<dynamic>)
            .map((json) => Unit.fromJson(json as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint(
            'SupabaseContentRepository: getUnits remote failed (using local fallback): $e');
      }
    }

    return _localFallback.getUnits(subjectId);
  }

  @override
  Future<List<Topic>> getTopics(String unitId) async {
    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('topics')
            .select()
            .eq('unit_id', unitId)
            .order('topic_number', ascending: true)
            .timeout(const Duration(seconds: 5));

        final list = (response as List<dynamic>)
            .map((json) => Topic.fromJson(json as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint(
            'SupabaseContentRepository: getTopics remote failed (using local fallback): $e');
      }
    }

    return _localFallback.getTopics(unitId);
  }

  @override
  Future<List<ContentPackage>> getPackages({
    required int grade,
    required String stream,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('content_packages')
            .select()
            .eq('grade', grade)
            .or('stream.eq.$stream,stream.eq.common')
            .timeout(const Duration(seconds: 5));

        final list = (response as List<dynamic>)
            .map(
                (json) => ContentPackage.fromJson(json as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint(
            'SupabaseContentRepository: getPackages remote failed (using local fallback): $e');
      }
    }

    return _localFallback.getPackages(grade: grade, stream: stream);
  }

  @override
  Future<void> downloadPackage(String packageId) async {
    await _localFallback.downloadPackage(packageId);
  }

  @override
  Future<void> removePackage(String packageId) async {
    await _localFallback.removePackage(packageId);
  }

  @override
  Future<PackageDelta?> checkPackageUpdate(String packageId) async {
    return _localFallback.checkPackageUpdate(packageId);
  }

  @override
  Future<void> applyDeltaUpdate(String packageId, PackageDelta delta) async {
    await _localFallback.applyDeltaUpdate(packageId, delta);
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
    final client = _client;
    if (client != null) {
      try {
        final canonicalId =
            LocalContentRepository.canonicalSubjectId(subjectId);
        final subjectIds = {subjectId, canonicalId}.toList();
        dynamic query = client
            .from('questions')
            .select('*, choices:answer_choices(*), explanations(*)')
            .inFilter('subject_id', subjectIds)
            .eq('verification_status', 'published');

        if (grade != null) {
          query = query.eq('grade', grade);
        }
        if (unitId != null) {
          query = query.eq('unit_id', unitId);
        }
        if (topicId != null) {
          query = query.eq('topic_id', topicId);
        }
        if (difficulty != null) {
          query = query.eq('difficulty', difficulty);
        }
        if (examYear != null) {
          query = query.eq('exam_year', examYear);
        }
        if (startYear != null) {
          query = query.gte('exam_year', startYear);
        }
        if (endYear != null) {
          query = query.lte('exam_year', endYear);
        }
        if (examYears != null && examYears.isNotEmpty) {
          query = query.inFilter('exam_year', examYears);
        }
        if (limit != null && limit > 0) {
          query = query.limit(limit);
        }

        final response = await query.timeout(const Duration(seconds: 5));
        final list = (response as List<dynamic>)
            .map((json) => Question.fromJson(json as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint(
            'SupabaseContentRepository: getQuestions remote failed (using local fallback): $e');
      }
    }

    return _localFallback.getQuestions(
      grade: grade,
      subjectId: subjectId,
      unitId: unitId,
      topicId: topicId,
      difficulty: difficulty,
      examYear: examYear,
      startYear: startYear,
      endYear: endYear,
      examYears: examYears,
      limit: limit,
    );
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('questions')
            .select('*, choices:answer_choices(*), explanations(*)')
            .eq('id', id)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));

        if (response != null) {
          return Question.fromJson(response);
        }
      } catch (_) {}
    }

    return _localFallback.getQuestionById(id);
  }
}
