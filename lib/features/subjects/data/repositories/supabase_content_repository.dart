import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/subject_models.dart';
import '../../domain/repositories/content_repository.dart';
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
    required int grade,
    required String stream,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('subjects')
            .select()
            .eq('grade', grade)
            .or('stream.eq.$stream,stream.eq.common')
            .order('sort_order', ascending: true)
            .timeout(const Duration(seconds: 5));

        final list = (response as List<dynamic>)
            .map((json) => Subject.fromJson(json as Map<String, dynamic>))
            .toList();

        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint(
            'SupabaseContentRepository: getSubjects remote failed (using local fallback): $e');
      }
    }

    return _localFallback.getSubjects(grade: grade, stream: stream);
  }

  @override
  Future<List<Unit>> getUnits(String subjectId) async {
    final client = _client;
    if (client != null) {
      try {
        final response = await client
            .from('units')
            .select()
            .eq('subject_id', subjectId)
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
  Future<List<Question>> getQuestions({
    required int grade,
    required String subjectId,
    String? unitId,
    String? topicId,
    String? difficulty,
    int? examYear,
    int? limit,
  }) async {
    final client = _client;
    if (client != null) {
      try {
        dynamic query = client
            .from('questions')
            .select('*, choices:answer_choices(*), explanations(*)')
            .eq('grade', grade)
            .eq('subject_id', subjectId)
            .eq('verification_status', 'published');

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
