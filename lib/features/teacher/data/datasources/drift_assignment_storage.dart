import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/models/assignment_models.dart';

/// Handles durable local SQLite caching of teacher assignments and student recipient states.
class DriftAssignmentStorage {
  final AppDatabase _db;

  const DriftAssignmentStorage(this._db);

  /// Caches student assignments locally for offline delivery.
  Future<void> saveStudentAssignments(
      List<StudentAssignment> assignments) async {
    for (final a in assignments) {
      try {
        await _db.customStatement('''
          INSERT OR REPLACE INTO db_learning_assignments (
            id, school_id, classroom_id, classroom_name, teacher_user_id,
            teacher_name, subject_id, exam_variant, title, instructions,
            assignment_type, status, due_at, allow_late_submission,
            time_limit_minutes, total_questions, content_hash, question_ids_json,
            created_at, published_at, synced_at
          ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
          );
        ''', [
          a.assignmentId,
          a.schoolId,
          a.classroomId,
          a.classroomName,
          '',
          a.teacherName,
          a.subjectId,
          a.examVariant,
          a.title,
          a.instructions,
          a.assignmentType.dbValue,
          a.assignmentStatus.dbValue,
          a.dueAt?.millisecondsSinceEpoch,
          a.allowLateSubmission ? 1 : 0,
          a.timeLimitMinutes,
          a.totalQuestions,
          null,
          '[]',
          DateTime.now().millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch,
        ]);

        await _db.customStatement('''
          INSERT OR REPLACE INTO db_assignment_recipients (
            id, assignment_id, student_user_id, assigned_at, status,
            attempt_id, started_at, submitted_at, score, percentage, sync_status
          ) VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
          );
        ''', [
          a.recipientId,
          a.assignmentId,
          '',
          DateTime.now().millisecondsSinceEpoch,
          a.studentStatus.dbValue,
          a.attemptId,
          null,
          a.submittedAt?.millisecondsSinceEpoch,
          a.score,
          a.percentage,
          'synced',
        ]);
      } catch (e) {
        debugPrint(
            '[DriftAssignmentStorage] Error saving student assignment ${a.assignmentId}: $e');
      }
    }
  }

  /// Retrieves offline cached student assignments.
  Future<List<StudentAssignment>> getOfflineStudentAssignments({
    AssignmentRecipientStatus? status,
  }) async {
    try {
      final rows = await _db.customSelect('''
        SELECT 
          a.id AS assignment_id,
          r.id AS recipient_id,
          a.school_id,
          a.classroom_id,
          a.classroom_name,
          a.teacher_name,
          a.subject_id,
          a.exam_variant,
          a.title,
          a.instructions,
          a.assignment_type,
          a.status AS assignment_status,
          r.status AS student_status,
          a.due_at,
          a.allow_late_submission,
          a.time_limit_minutes,
          a.total_questions,
          r.attempt_id,
          r.score,
          r.percentage,
          r.submitted_at
        FROM db_learning_assignments a
        JOIN db_assignment_recipients r ON r.assignment_id = a.id
        WHERE (? IS NULL OR r.status = ?)
        ORDER BY a.due_at ASC, a.created_at DESC;
      ''', variables: [
        Variable(status?.dbValue),
        Variable(status?.dbValue),
      ]).get();

      return rows.map((row) {
        final dueAtMs = row.read<int?>('due_at');
        final subAtMs = row.read<int?>('submitted_at');

        return StudentAssignment(
          assignmentId: row.read<String>('assignment_id'),
          recipientId: row.read<String>('recipient_id'),
          schoolId: row.read<String>('school_id'),
          classroomId: row.read<String>('classroom_id'),
          classroomName: row.read<String?>('classroom_name') ?? 'Classroom',
          teacherName: row.read<String?>('teacher_name') ?? 'Teacher',
          subjectId: row.read<String>('subject_id'),
          examVariant: row.read<String?>('exam_variant'),
          title: row.read<String>('title'),
          instructions: row.read<String?>('instructions'),
          assignmentType: AssignmentType.fromString(
            row.read<String>('assignment_type'),
          ),
          assignmentStatus: AssignmentStatus.fromString(
            row.read<String>('assignment_status'),
          ),
          studentStatus: AssignmentRecipientStatus.fromString(
            row.read<String>('student_status'),
          ),
          dueAt: dueAtMs != null
              ? DateTime.fromMillisecondsSinceEpoch(dueAtMs)
              : null,
          allowLateSubmission: row.read<int>('allow_late_submission') == 1,
          timeLimitMinutes: row.read<int>('time_limit_minutes'),
          totalQuestions: row.read<int>('total_questions'),
          attemptId: row.read<String?>('attempt_id'),
          score: row.read<int?>('score'),
          percentage: row.read<double?>('percentage'),
          submittedAt: subAtMs != null
              ? DateTime.fromMillisecondsSinceEpoch(subAtMs)
              : null,
          isOfflineReady: true,
        );
      }).toList();
    } catch (e) {
      debugPrint(
          '[DriftAssignmentStorage] getOfflineStudentAssignments error: $e');
      return [];
    }
  }

  /// Updates local recipient status after offline attempt submission.
  Future<void> recordLocalSubmission({
    required String assignmentId,
    required String attemptId,
    required int score,
    required double percentage,
    required DateTime submittedAt,
    bool isLate = false,
  }) async {
    try {
      await _db.customStatement('''
        UPDATE db_assignment_recipients
        SET status = ?,
            attempt_id = ?,
            score = ?,
            percentage = ?,
            submitted_at = ?,
            sync_status = 'pending'
        WHERE assignment_id = ?;
      ''', [
        isLate ? 'late' : 'submitted',
        attemptId,
        score,
        percentage,
        submittedAt.millisecondsSinceEpoch,
        assignmentId,
      ]);
    } catch (e) {
      debugPrint('[DriftAssignmentStorage] recordLocalSubmission error: $e');
    }
  }
}
