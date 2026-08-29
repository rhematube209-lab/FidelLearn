import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/subject_models.dart';
import '../../domain/repositories/content_repository.dart';

class SupabaseContentRepository implements ContentRepository {
  final SupabaseClient _client;

  SupabaseContentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> initializeSeedData() async {
    // Cloud data already initialized in Supabase tables
  }

  @override
  Future<List<Subject>> getSubjects({
    required int grade,
    required String stream,
  }) async {
    try {
      final response = await _client
          .from('subjects')
          .select()
          .eq('grade', grade)
          .or('stream.eq.$stream,stream.eq.common')
          .order('sort_order', ascending: true);

      return (response as List<dynamic>)
          .map((json) => Subject.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageFailure('Failed to fetch subjects from Supabase: $e');
    }
  }

  @override
  Future<List<Unit>> getUnits(String subjectId) async {
    try {
      final response = await _client
          .from('units')
          .select()
          .eq('subject_id', subjectId)
          .order('unit_number', ascending: true);

      return (response as List<dynamic>)
          .map((json) => Unit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageFailure('Failed to fetch units from Supabase: $e');
    }
  }

  @override
  Future<List<Topic>> getTopics(String unitId) async {
    try {
      final response = await _client
          .from('topics')
          .select()
          .eq('unit_id', unitId)
          .order('topic_number', ascending: true);

      return (response as List<dynamic>)
          .map((json) => Topic.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageFailure('Failed to fetch topics from Supabase: $e');
    }
  }

  @override
  Future<List<ContentPackage>> getPackages({
    required int grade,
    required String stream,
  }) async {
    try {
      final response = await _client
          .from('content_packages')
          .select()
          .eq('grade', grade)
          .or('stream.eq.$stream,stream.eq.common');

      return (response as List<dynamic>)
          .map((json) => ContentPackage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageFailure('Failed to fetch packages from Supabase: $e');
    }
  }

  @override
  Future<void> downloadPackage(String packageId) async {
    // In full package system, downloads package bundle .flpkg
  }

  @override
  Future<void> removePackage(String packageId) async {
    // In full package system, removes local cached SQLite package
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
    try {
      dynamic query = _client
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

      final response = await query;
      return (response as List<dynamic>)
          .map((json) => Question.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageFailure('Failed to query questions from Supabase: $e');
    }
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    try {
      final response = await _client
          .from('questions')
          .select('*, choices:answer_choices(*), explanations(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Question.fromJson(response);
    } catch (_) {
      return null;
    }
  }
}
