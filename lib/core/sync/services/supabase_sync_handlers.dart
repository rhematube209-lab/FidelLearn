import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sync_models.dart';
import 'sync_engine.dart';

/// Registers Supabase remote handlers on the [SyncEngine].
///
/// Each handler receives a [SyncOperation] dequeued from the local SQLite
/// sync queue and is responsible for executing the corresponding remote write
/// against Supabase.
///
/// All handlers must be idempotent — they may be called more than once for
/// the same operation if a previous attempt was interrupted.
///
/// The [SyncEngine] guarantees that handlers are only called when the device
/// is online. If a handler returns false or throws, the engine applies
/// exponential backoff and retries later.
///
/// **Offline-first guarantee:** These handlers are wired after Supabase
/// initialisation. If Supabase is not configured, this class is never
/// instantiated and all operations remain in the local queue indefinitely.
class SupabaseSyncHandlers {
  final SyncEngine _engine;
  final SupabaseClient _client;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _isValidUuid(String s) => _uuidRegex.hasMatch(s);

  SupabaseSyncHandlers({
    required SyncEngine engine,
    required SupabaseClient client,
  })  : _engine = engine,
        _client = client {
    _registerAll();
  }

  void _registerAll() {
    _engine.registerHandler(
        SyncOperationType.submitAttempt, _handleSubmitAttempt);
    _engine.registerHandler(
        SyncOperationType.toggleBookmark, _handleToggleBookmark);
    _engine.registerHandler(
        SyncOperationType.recordMistake, _handleRecordMistake);
    _engine.registerHandler(
        SyncOperationType.updateProfile, _handleUpdateProfile);
    _engine.registerHandler(SyncOperationType.claimReward, _handleClaimReward);
    _engine.registerHandler(SyncOperationType.redeemCoins, _handleRedeemCoins);
    // Legacy handler: appendCoinEntry entries in the queue from before the
    // security redesign are promoted to claimReward if they contain eventType,
    // otherwise they are acknowledged and dropped (cannot be securely replayed).
    _engine.registerHandler(
        SyncOperationType.appendCoinEntry, _handleLegacyCoinEntry);
  }

  // ── SUBMIT ATTEMPT ────────────────────────────────────────────────────────

  Future<bool> _handleSubmitAttempt(SyncOperation op) async {
    final p = op.payload;
    final attemptId = p['id'] as String?;
    final userId = p['user_id'] as String?;
    final examId = p['exam_id'] as String?;

    if (attemptId == null || userId == null || examId == null) return false;
    if (!_isValidUuid(attemptId) ||
        !_isValidUuid(userId) ||
        !_isValidUuid(examId)) {
      // Non-UUID IDs are demo/local — acknowledge and skip
      return true;
    }

    try {
      await _client.from('attempts').upsert({
        'id': attemptId,
        'user_id': userId,
        'exam_id': examId,
        'start_time': p['start_time'],
        'end_time': p['end_time'],
        'duration_seconds': p['duration_seconds'] ?? 0,
        'total_questions': p['total_questions'] ?? 0,
        'score': p['score'] ?? 0,
        'percentage': p['percentage'] ?? 0.0,
        'correct_count': p['correct_count'] ?? 0,
        'incorrect_count': p['incorrect_count'] ?? 0,
        'skipped_count': p['skipped_count'] ?? 0,
        'is_completed': p['is_completed'] ?? false,
      }).timeout(const Duration(seconds: 10));

      // Sync individual responses if present
      final responses = p['responses'];
      if (responses is Map && responses.isNotEmpty) {
        final rows = <Map<String, dynamic>>[];
        for (final resp in responses.values) {
          final r = resp as Map<String, dynamic>;
          final qId = r['question_id'] as String?;
          if (qId != null && _isValidUuid(qId)) {
            final choiceId = r['selected_choice_id'] as String?;
            rows.add({
              'attempt_id': attemptId,
              'question_id': qId,
              'selected_choice_id': (choiceId != null && _isValidUuid(choiceId))
                  ? choiceId
                  : null,
              'is_correct': r['is_correct'] ?? false,
              'is_flagged': r['is_flagged'] ?? false,
              'time_spent_seconds': r['time_spent_seconds'] ?? 0,
            });
          }
        }
        if (rows.isNotEmpty) {
          await _client
              .from('attempt_responses')
              .upsert(rows)
              .timeout(const Duration(seconds: 10));
        }
      }
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncHandlers.submitAttempt error: $e');
      return false;
    }
  }

  // ── TOGGLE BOOKMARK ───────────────────────────────────────────────────────

  Future<bool> _handleToggleBookmark(SyncOperation op) async {
    final p = op.payload;
    final userId = p['user_id'] as String?;
    final questionId = p['question_id'] as String?;

    if (userId == null || questionId == null) {
      return false;
    }
    if (!_isValidUuid(userId) || !_isValidUuid(questionId)) {
      return true; // demo IDs
    }

    final isActive = p['is_active'] as bool? ?? true;

    try {
      if (!isActive) {
        // Soft-delete: set is_active = false
        await _client
            .from('bookmarks')
            .update({'is_active': false})
            .eq('user_id', userId)
            .eq('question_id', questionId)
            .timeout(const Duration(seconds: 8));
      } else {
        await _client.from('bookmarks').upsert({
          'id': p['id'],
          'user_id': userId,
          'question_id': questionId,
          'subject_id': p['subject_id'] ?? 'general',
          'topic_id': p['topic_id'] ?? 'general',
          'is_active': true,
          'created_at': p['created_at'],
        }).timeout(const Duration(seconds: 8));
      }
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncHandlers.toggleBookmark error: $e');
      return false;
    }
  }

  // ── RECORD MISTAKE ────────────────────────────────────────────────────────

  Future<bool> _handleRecordMistake(SyncOperation op) async {
    final p = op.payload;
    final userId = p['user_id'] as String?;
    final questionId = p['question_id'] as String?;

    if (userId == null || questionId == null) return false;
    if (!_isValidUuid(userId) || !_isValidUuid(questionId)) return true;

    try {
      await _client.from('mistake_records').upsert({
        'id': p['id'],
        'user_id': userId,
        'question_id': questionId,
        'mistake_count': p['miss_count'] ?? 1,
        'is_mastered': (p['mastery_status'] == 'mastered'),
        'last_failed_at': p['last_missed_at'],
        'mastered_at':
            p['mastery_status'] == 'mastered' ? p['updated_at'] : null,
      }).timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncHandlers.recordMistake error: $e');
      return false;
    }
  }

  // ── UPDATE PROFILE ────────────────────────────────────────────────────────

  Future<bool> _handleUpdateProfile(SyncOperation op) async {
    final p = op.payload;
    final userId = p['user_id'] as String?;
    if (userId == null || !_isValidUuid(userId)) return true;

    try {
      await _client
          .from('profiles')
          .update({
            'display_name': p['display_name'],
            'grade': p['grade'],
            'stream': p['stream'],
            'preferred_language': p['preferred_language'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('SupabaseSyncHandlers.updateProfile error: $e');
      return false;
    }
  }

  // ── CLAIM REWARD ──────────────────────────────────────────────────────────
  //
  // Sends an EVENT CLAIM to the claim-reward Edge Function.
  // The server determines the coin amount — this handler must NOT send amount.

  Future<bool> _handleClaimReward(SyncOperation op) async {
    final p = op.payload;
    final eventType = p['event_type'] as String?;
    final sourceEntityId = p['source_entity_id'] as String?;
    final idempotencyKey = p['idempotency_key'] as String?;

    if (eventType == null || sourceEntityId == null || idempotencyKey == null) {
      debugPrint(
          'SupabaseSyncHandlers.claimReward: missing required fields, skipping');
      return true; // acknowledge to prevent infinite retry on malformed payload
    }

    try {
      final response = await _client.functions.invoke(
        'claim-reward',
        body: {
          'event_type': eventType,
          'source_entity_id': sourceEntityId,
          'idempotency_key': idempotencyKey,
          // amount is intentionally NOT sent — server determines it
        },
      );

      final statusCode = response.status;
      if (statusCode == 200 || statusCode == 409) {
        // 200 = success; 409 = already claimed (idempotent — treat as success)
        return true;
      }
      debugPrint(
          'SupabaseSyncHandlers.claimReward: server returned $statusCode');
      return false;
    } catch (e) {
      debugPrint('SupabaseSyncHandlers.claimReward error: $e');
      return false;
    }
  }

  // ── REDEEM COINS ──────────────────────────────────────────────────────────

  Future<bool> _handleRedeemCoins(SyncOperation op) async {
    final p = op.payload;
    final itemId = p['redemption_item_id'] as String?;
    final idempotencyKey = p['idempotency_key'] as String?;

    if (itemId == null || idempotencyKey == null) {
      debugPrint(
          'SupabaseSyncHandlers.redeemCoins: missing required fields, skipping');
      return true;
    }

    try {
      final response = await _client.functions.invoke(
        'redeem-coins',
        body: {
          'redemption_item_id': itemId,
          'idempotency_key': idempotencyKey,
          // cost is intentionally NOT sent — server determines it
        },
      );

      final statusCode = response.status;
      if (statusCode == 200 || statusCode == 409) return true;
      if (statusCode == 402) {
        // Insufficient balance — acknowledge and drop (local balance check
        // should have prevented this; if it still occurs, do not retry forever)
        debugPrint(
            'SupabaseSyncHandlers.redeemCoins: insufficient balance, dropping');
        return true;
      }
      debugPrint(
          'SupabaseSyncHandlers.redeemCoins: server returned $statusCode');
      return false;
    } catch (e) {
      debugPrint('SupabaseSyncHandlers.redeemCoins error: $e');
      return false;
    }
  }

  // ── LEGACY appendCoinEntry (backward compatibility) ───────────────────────

  Future<bool> _handleLegacyCoinEntry(SyncOperation op) async {
    final p = op.payload;
    // If this legacy entry has eventType, promote to claimReward logic
    final eventType = p['event_type'] as String?;
    final sourceEntityId = p['source_entity_id'] as String?;
    final idempotencyKey = p['idempotency_key'] as String?;

    if (eventType != null && sourceEntityId != null && idempotencyKey != null) {
      // Promote to secure path
      return _handleClaimReward(op);
    }

    // Cannot securely replay a legacy entry that carries raw amount.
    // Acknowledge and discard — the local Drift ledger already has this entry.
    debugPrint(
      'SupabaseSyncHandlers: discarding legacy appendCoinEntry (no eventType) '
      'for idempotency_key=${op.idempotencyKey}',
    );
    return true;
  }
}
