import 'dart:math' as math;

import '../../../exams/domain/models/exam_models.dart';
import '../../../mistakes/domain/models/mistake_model.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../../subjects/domain/services/subject_resolver.dart';
import '../models/mastery_models.dart';
import '../models/study_plan_models.dart';

class AdaptiveStudyPlanner {
  const AdaptiveStudyPlanner();

  /// Deterministically generates today's personalized study plan.
  StudyPlan generateDailyPlan({
    required String userId,
    required int grade,
    required String stream,
    required PlannerSettings settings,
    required List<ExamAttempt> completedAttempts,
    required List<MistakeRecord> unmasteredMistakes,
    required List<Question> availableQuestions,
    required List<Subject> allSubjects,
    required Map<String, List<Unit>> unitsBySubject,
    required Map<String, List<Topic>> topicsByUnit,
    required Set<String> installedSubjectIds,
    List<QuestionMasteryRecord> questionMasteryRecords = const [],
    List<LearningTargetMasteryRecord> targetMasteryRecords = const [],
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final planDateStr = now.toIso8601String().substring(0, 10);
    final planId = 'plan_${userId}_$planDateStr';
    final isNatural = stream.toLowerCase() != 'social';

    // 1. Resolve Stream Subjects through frozen P0 subject model
    final eligibleSubjects = _filterStreamSubjects(
      allSubjects: allSubjects,
      grade: grade,
      stream: stream,
    );

    // Filter to installed subjects with available questions (Offline-first safety)
    final activeSubjects = eligibleSubjects.where((s) {
      if (installedSubjectIds.isNotEmpty &&
          !installedSubjectIds.contains(s.id)) {
        return false;
      }
      return availableQuestions.any((q) =>
          q.subjectId == s.id &&
          _isQuestionEligibleForStudent(
            question: q,
            stream: stream,
            targetVariant: _resolveVariantForSubject(s.id, isNatural),
          ));
    }).toList();

    // Fallback if no installed subjects match: use all eligible stream subjects
    final resolvedSubjects =
        activeSubjects.isNotEmpty ? activeSubjects : eligibleSubjects;
    final resolvedSubjectIds = resolvedSubjects.map((s) => s.id).toSet();

    // 2. Aggregate Historical Learning Statistics per Topic / Learning Target
    final Map<String, _TopicLearningStats> statsByTarget =
        _aggregateLearningStats(
      completedAttempts: completedAttempts,
      availableQuestions: availableQuestions,
    );

    // 3. Subject-level recent activity (for Multi-Subject Balancing)
    final Map<String, DateTime> lastPracticedBySubject = {};
    final Map<String, int> attemptsTodayBySubject = {};
    for (final att in completedAttempts) {
      final sId = att.subjectId;
      final prev = lastPracticedBySubject[sId];
      if (prev == null || att.startTime.isAfter(prev)) {
        lastPracticedBySubject[sId] = att.startTime;
      }
      if (att.startTime.year == now.year &&
          att.startTime.month == now.month &&
          att.startTime.day == now.day) {
        attemptsTodayBySubject[sId] = (attemptsTodayBySubject[sId] ?? 0) + 1;
      }
    }

    // 4. Days until National Examination & Canonical Exam Preparation Phase
    final policy = ExamPreparationPolicy.fromDates(
      targetExamDate: settings.targetExamDate,
      currentDate: now,
    );
    final int? daysUntilExam = policy.daysUntilExam;

    // 5. Build candidate sessions
    final List<StudyPlanSession> candidates = [];

    // --- A. Mistake Review Session Candidates ---
    final relevantMistakes = unmasteredMistakes.where((m) {
      if (!resolvedSubjectIds.contains(m.subjectId)) return false;
      if (m.masteryStatus != MasteryStatus.needsReview &&
          m.masteryStatus != MasteryStatus.improving) {
        return false;
      }
      // Guarantee Mathematics mistake isolation across tracks
      if (m.subjectId == 'math_g12' || m.subjectId.contains('math')) {
        final q = availableQuestions
            .where((qItem) => qItem.id == m.questionId)
            .firstOrNull;
        if (q != null) {
          if (isNatural &&
              (q.stream == 'social' ||
                  q.examVariant == ExamVariantCode.socialScience)) {
            return false;
          }
          if (!isNatural &&
              (q.stream == 'natural' ||
                  q.examVariant == ExamVariantCode.naturalScience)) {
            return false;
          }
        }
      }
      return true;
    }).toList();

    if (relevantMistakes.isNotEmpty) {
      // Group mistakes by subject to find highest mistake concentration
      final Map<String, List<MistakeRecord>> mistakesBySubject = {};
      for (final m in relevantMistakes) {
        mistakesBySubject.putIfAbsent(m.subjectId, () => []).add(m);
      }

      // Create a mistake review candidate for the top mistake subject
      final sortedMistakeSubjects = mistakesBySubject.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

      for (final entry in sortedMistakeSubjects.take(2)) {
        final sId = entry.key;
        final subMistakes = entry.value;
        final subject = resolvedSubjects.firstWhere((s) => s.id == sId,
            orElse: () => resolvedSubjects.first);
        final targetVariant = _resolveVariantForSubject(sId, isNatural);
        final targetStructure = subject.assessmentStructure;

        // Ensure questions are strictly eligible for student stream
        final eligibleMistakeQuestionIds = subMistakes
            .where((m) {
              final q = availableQuestions
                  .where((qItem) => qItem.id == m.questionId)
                  .firstOrNull;
              if (q == null) return true;
              return _isQuestionEligibleForStudent(
                question: q,
                stream: stream,
                targetVariant: targetVariant,
              );
            })
            .map((m) => m.questionId)
            .take(5)
            .toList();

        if (eligibleMistakeQuestionIds.isEmpty) continue;

        final priority = 70.0 + math.min(30.0, subMistakes.length * 5.0);

        final titleEn = (sId == 'math_g12')
            ? (isNatural
                ? 'Mathematics (Natural Science) Mistake Review'
                : 'Mathematics (Social Science) Mistake Review')
            : '${subject.nameEn} Mistake Review';
        final titleAm = (sId == 'math_g12')
            ? (isNatural
                ? 'የሒሳብ (የተፈጥሮ ሳይንስ) ስህተቶች ክለሳ'
                : 'የሒሳብ (የማህበራዊ ሳይንስ) ስህተቶች ክለሳ')
            : 'የ${subject.nameAm} ስህተቶች ክለሳ';

        candidates.add(
          StudyPlanSession(
            id: '${planId}_mistake_$sId',
            planId: planId,
            subjectId: sId,
            examVariant: targetVariant,
            assessmentStructure: targetStructure,
            sessionType: StudySessionType.mistakeReview,
            titleEn: titleEn,
            titleAm: titleAm,
            questionTarget: eligibleMistakeQuestionIds.length,
            estimatedMinutes:
                math.max(6, (eligibleMistakeQuestionIds.length * 2)),
            priorityScore: priority,
            reasonCode: RecommendationReasonCode.mistakeReview,
            reasonDetailEn:
                'You have ${subMistakes.length} mistakes waiting for review in ${subject.nameEn}.',
            reasonDetailAm:
                'በ${subject.nameAm} ውስጥ ${subMistakes.length} ክለሳ የሚሹ ስህተቶች አሉ።',
            questionIds: eligibleMistakeQuestionIds,
          ),
        );
      }
    }

    // --- A2. Spaced Review & Mastery Maintenance Candidates ---
    if (questionMasteryRecords.isNotEmpty || targetMasteryRecords.isNotEmpty) {
      final dueQuestionRecords = questionMasteryRecords.where((r) {
        if (!resolvedSubjectIds.contains(r.subjectId)) return false;
        // Guarantee Mathematics isolation across tracks
        if (r.subjectId == 'math_g12' || r.subjectId.contains('math')) {
          if (isNatural && r.examVariant == ExamVariantCode.socialScience) {
            return false;
          }
          if (!isNatural && r.examVariant == ExamVariantCode.naturalScience) {
            return false;
          }
        }
        return r.isDueForReview ||
            r.masteryState == MasteryState.atRisk ||
            r.masteryState == MasteryState.relearning;
      }).toList();

      if (dueQuestionRecords.isNotEmpty) {
        final Map<String, List<QuestionMasteryRecord>> dueBySubject = {};
        for (final r in dueQuestionRecords) {
          dueBySubject.putIfAbsent(r.subjectId, () => []).add(r);
        }

        for (final entry in dueBySubject.entries.take(2)) {
          final sId = entry.key;
          final records = entry.value;
          final subject = resolvedSubjects.firstWhere((s) => s.id == sId,
              orElse: () => resolvedSubjects.first);
          final targetVariant = _resolveVariantForSubject(sId, isNatural);
          final targetStructure = subject.assessmentStructure;

          final eligibleDueQIds = records
              .map((r) => r.questionId)
              .where((qId) {
                final q = availableQuestions
                    .where((qItem) => qItem.id == qId)
                    .firstOrNull;
                if (q == null) return false;
                return _isQuestionEligibleForStudent(
                  question: q,
                  stream: stream,
                  targetVariant: targetVariant,
                );
              })
              .take(5)
              .toList();

          if (eligibleDueQIds.isEmpty) continue;

          final hasRelearning =
              records.any((r) => r.masteryState == MasteryState.relearning);
          final hasAtRisk =
              records.any((r) => r.masteryState == MasteryState.atRisk);

          final RecommendationReasonCode reasonCode;
          final double priorityBoost;
          if (hasRelearning) {
            reasonCode = RecommendationReasonCode.relearningNeeded;
            priorityBoost = 25.0;
          } else if (hasAtRisk) {
            reasonCode = RecommendationReasonCode.masteryAtRisk;
            priorityBoost = 20.0;
          } else {
            reasonCode = RecommendationReasonCode.masteryReviewDue;
            priorityBoost = 15.0;
          }

          final priority =
              72.0 + priorityBoost + math.min(10.0, records.length * 2.0);

          final titleEn = (sId == 'math_g12')
              ? (isNatural
                  ? 'Mathematics (Natural) Spaced Mastery Recall'
                  : 'Mathematics (Social) Spaced Mastery Recall')
              : '${subject.nameEn} Spaced Mastery Recall';
          final titleAm = (sId == 'math_g12')
              ? (isNatural
                  ? 'ሒሳብ (ተፈጥሮ) የተቀጠረ የብቃት ክለሳ'
                  : 'ሒሳብ (ማህበራዊ) የተቀጠረ የብቃት ክለሳ')
              : '${subject.nameAm} የተቀጠረ የብቃት ክለሳ';

          final reasonDetailEn = hasRelearning
              ? 'You missed questions previously in ${subject.nameEn}. A quick relearning review is scheduled today.'
              : (hasAtRisk
                  ? 'Knowledge in ${subject.nameEn} is at risk of decay. A spaced review is due today to keep it strong.'
                  : 'You have ${records.length} questions in ${subject.nameEn} due for spaced review today.');

          final reasonDetailAm = hasRelearning
              ? 'በ${subject.nameAm} ውስጥ የተሳሳቷቸው ጥያቄዎች አሉ። ዛሬ እንደገና የመማር ክለሳ ተይዞልዎታል።'
              : (hasAtRisk
                  ? 'በ${subject.nameAm} ላይ ያካበቱት እውቀት እንዳይረሳ ዛሬ የተቀጠረ ክለሳ ደርሷል።'
                  : 'በ${subject.nameAm} ውስጥ ዛሬ ${records.length} የተቀጠሩ የክለሳ ጥያቄዎች ደርሰዋል።');

          candidates.add(
            StudyPlanSession(
              id: '${planId}_spaced_$sId',
              planId: planId,
              subjectId: sId,
              examVariant: targetVariant,
              assessmentStructure: targetStructure,
              sessionType: StudySessionType.masteryMaintenance,
              titleEn: titleEn,
              titleAm: titleAm,
              questionTarget: eligibleDueQIds.length,
              estimatedMinutes: math.max(6, (eligibleDueQIds.length * 2)),
              priorityScore: priority,
              reasonCode: reasonCode,
              reasonDetailEn: reasonDetailEn,
              reasonDetailAm: reasonDetailAm,
              questionIds: eligibleDueQIds,
            ),
          );
        }
      }
    }

    // --- B. Topic & Skill Remediation & Curriculum Coverage Candidates ---
    for (final subject in resolvedSubjects) {
      final sId = subject.id;
      final targetVariant = _resolveVariantForSubject(sId, isNatural);
      final targetStructure = subject.assessmentStructure;

      // Filter subject questions to eligible questions only
      final subjectEligibleQuestions = availableQuestions.where((q) {
        if (q.subjectId != sId) return false;
        return _isQuestionEligibleForStudent(
          question: q,
          stream: stream,
          targetVariant: targetVariant,
        );
      }).toList();

      if (subjectEligibleQuestions.isEmpty) continue;

      // Multi-subject balance adjustments
      double subjectBalanceBonus = 0.0;
      final todayCount = attemptsTodayBySubject[sId] ?? 0;
      if (todayCount > 0) {
        subjectBalanceBonus -=
            (todayCount * 15.0); // Penalty for already practiced today
      }
      final lastPracticed = lastPracticedBySubject[sId];
      if (lastPracticed == null) {
        subjectBalanceBonus += 5.0; // Subtle bonus for fresh subject
      } else if (now.difference(lastPracticed).inDays >= 3) {
        subjectBalanceBonus += 5.0; // Bonus for neglected subject
      }

      // Discover learning targets for this subject
      final targets = _discoverLearningTargets(
        subject: subject,
        questions: subjectEligibleQuestions,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        isNatural: isNatural,
      );

      for (final target in targets) {
        final targetQuestions = target.questions;
        if (targetQuestions.isEmpty) continue;

        final stats = statsByTarget[target.targetKey];

        // 1. Weak Topic / Skill Check (Evidence threshold: minimum 3 completed attempts)
        if (stats != null &&
            stats.totalAttempts >= 3 &&
            stats.accuracyPercentage < 60.0) {
          final weaknessWeight =
              (1.0 - (stats.accuracyPercentage / 100.0)) * 40.0;
          final recentErrorRate = stats.recentMistakeRatio * 20.0;
          final double examWeight = policy.weakTopicProximityWeight;

          final priority = weaknessWeight +
              recentErrorRate +
              examWeight +
              subjectBalanceBonus +
              45.0;

          final selectedQIds = _pickAdaptiveQuestions(
            questions: targetQuestions,
            accuracyPercentage: stats.accuracyPercentage,
            targetCount: 10,
          );

          candidates.add(
            StudyPlanSession(
              id: '${planId}_weak_${target.targetKey}',
              planId: planId,
              subjectId: sId,
              unitId: target.unitId,
              topicId: target.topicId,
              examVariant: targetVariant,
              assessmentStructure: targetStructure,
              contentDomain: target.contentDomain,
              skill: target.skill,
              sessionType: StudySessionType.weakTopicPractice,
              titleEn: target.titleEn,
              titleAm: target.titleAm,
              questionTarget: selectedQIds.length,
              estimatedMinutes:
                  math.max(8, (selectedQIds.length * 1.5).round()),
              priorityScore: priority,
              reasonCode: RecommendationReasonCode.weakTopic,
              reasonDetailEn:
                  'Your accuracy in ${target.displayTargetNameEn} is ${stats.accuracyPercentage.toStringAsFixed(0)}% across ${stats.totalAttempts} questions.',
              reasonDetailAm:
                  'በ${target.displayTargetNameAm} ላይ ውጤትዎ ከ${stats.totalAttempts} ጥያቄዎች ${stats.accuracyPercentage.toStringAsFixed(0)}% ነው።',
              questionIds: selectedQIds,
            ),
          );
        }
        // 2. Curriculum Coverage Gap Check (Never practiced or 0 attempts)
        else if (stats == null || stats.totalAttempts == 0) {
          const coverageWeight = 25.0;
          final double examWeight = policy.coverageProximityWeight;

          final priority =
              coverageWeight + examWeight + subjectBalanceBonus + 15.0;

          final selectedQIds = _pickAdaptiveQuestions(
            questions: targetQuestions,
            accuracyPercentage: 50.0, // Default baseline for new content
            targetCount: 8,
          );

          candidates.add(
            StudyPlanSession(
              id: '${planId}_cov_${target.targetKey}',
              planId: planId,
              subjectId: sId,
              unitId: target.unitId,
              topicId: target.topicId,
              examVariant: targetVariant,
              assessmentStructure: targetStructure,
              contentDomain: target.contentDomain,
              skill: target.skill,
              sessionType: StudySessionType.curriculumCoverage,
              titleEn: target.titleEn,
              titleAm: target.titleAm,
              questionTarget: selectedQIds.length,
              estimatedMinutes:
                  math.max(8, (selectedQIds.length * 1.5).round()),
              priorityScore: priority,
              reasonCode: RecommendationReasonCode.newCurriculum,
              reasonDetailEn:
                  'You have not practiced ${target.displayTargetNameEn} yet. Essential for full national exam curriculum coverage.',
              reasonDetailAm:
                  'የ${target.displayTargetNameAm} ይዘትን እስካሁን አልሰሩትም። ለሀገር አቀፍ ፈተና ሙሉ ዝግጅት አስፈላጊ ነው።',
              questionIds: selectedQIds,
            ),
          );
        }
        // 3. Mastery Maintenance (Mastered topic/skill not reviewed in >10 days)
        else if (stats.accuracyPercentage >= 75.0 &&
            stats.lastAttemptAt != null) {
          final daysSinceLastPractice =
              now.difference(stats.lastAttemptAt!).inDays;
          if (daysSinceLastPractice >= 10) {
            final overdueWeight = math.min(20.0, daysSinceLastPractice * 1.5);
            final priority = overdueWeight + subjectBalanceBonus + 15.0;

            final selectedQIds = _pickAdaptiveQuestions(
              questions: targetQuestions,
              accuracyPercentage: stats.accuracyPercentage,
              targetCount: 6,
            );

            candidates.add(
              StudyPlanSession(
                id: '${planId}_maint_${target.targetKey}',
                planId: planId,
                subjectId: sId,
                unitId: target.unitId,
                topicId: target.topicId,
                examVariant: targetVariant,
                assessmentStructure: targetStructure,
                contentDomain: target.contentDomain,
                skill: target.skill,
                sessionType: StudySessionType.masteryMaintenance,
                titleEn: '${target.titleEn} Quick Recall',
                titleAm: '${target.titleAm} ፈጣን ማስታወሻ',
                questionTarget: selectedQIds.length,
                estimatedMinutes:
                    math.max(5, (selectedQIds.length * 1.2).round()),
                priorityScore: priority,
                reasonCode: RecommendationReasonCode.masteryMaintenance,
                reasonDetailEn:
                    'You scored ${stats.accuracyPercentage.toStringAsFixed(0)}% in ${target.displayTargetNameEn} but have not reviewed it in $daysSinceLastPractice days.',
                reasonDetailAm:
                    'በ${target.displayTargetNameAm} ላይ ${stats.accuracyPercentage.toStringAsFixed(0)}% ውጤት ነበረዎት፣ ነገር ግን ባለፉት $daysSinceLastPractice ቀናት አልከለሱትም።',
                questionIds: selectedQIds,
              ),
            );
          }
        }
      }
    }

    // --- C. Timed Mock Recommendation for Approaching Exam ---
    // Canonical policy: activates strictly during finalReview (0–14 days)
    if (policy.isMockBoostActive && settings.dailyBudgetMinutes >= 45) {
      final mockSubject = resolvedSubjects.first;
      final mockVariant = _resolveVariantForSubject(mockSubject.id, isNatural);
      final mockQuestions = availableQuestions
          .where((q) =>
              q.subjectId == mockSubject.id &&
              _isQuestionEligibleForStudent(
                question: q,
                stream: stream,
                targetVariant: mockVariant,
              ))
          .take(15)
          .map((q) => q.id)
          .toList();

      if (mockQuestions.isNotEmpty) {
        final mockTitleEn = (mockSubject.id == 'math_g12')
            ? (isNatural
                ? 'Mathematics (Natural Science) Timed National Mock Drill'
                : 'Mathematics (Social Science) Timed National Mock Drill')
            : '${mockSubject.nameEn} Timed National Mock Drill';
        final mockTitleAm = (mockSubject.id == 'math_g12')
            ? (isNatural
                ? 'የሒሳብ (የተፈጥሮ ሳይንስ) የጊዜ ገደብ የሙከራ ፈተና'
                : 'የሒሳብ (የማህበራዊ ሳይንስ) የጊዜ ገደብ የሙከራ ፈተና')
            : 'የ${mockSubject.nameAm} የጊዜ ገደብ የሙከራ ፈተና';

        candidates.add(
          StudyPlanSession(
            id: '${planId}_mock_${mockSubject.id}',
            planId: planId,
            subjectId: mockSubject.id,
            examVariant: mockVariant,
            assessmentStructure: mockSubject.assessmentStructure,
            sessionType: StudySessionType.mockExam,
            titleEn: mockTitleEn,
            titleAm: mockTitleAm,
            questionTarget: mockQuestions.length,
            estimatedMinutes: 20,
            priorityScore: 85.0,
            reasonCode: RecommendationReasonCode.examApproaching,
            reasonDetailEn:
                'The national exam is only $daysUntilExam days away. Timed mock sessions build pacing confidence.',
            reasonDetailAm:
                'ሀገር አቀፍ ፈተናው ሊደርስ $daysUntilExam ቀናት ብቻ ቀርተዋል። የጊዜ ገደብ ልምምድ ፍጥነትዎን ያሳድጋል።',
            questionIds: mockQuestions,
          ),
        );
      }
    }

    // 6. Deterministic Sort by Priority Score Descending
    // Secondary tie-breakers: higher questionTarget, then subjectId, topicId, contentDomain, skill
    candidates.sort((a, b) {
      final comp = b.priorityScore.compareTo(a.priorityScore);
      if (comp != 0) return comp;
      final qComp = b.questionTarget.compareTo(a.questionTarget);
      if (qComp != 0) return qComp;
      final sComp = a.subjectId.compareTo(b.subjectId);
      if (sComp != 0) return sComp;
      final tComp = (a.topicId ?? '').compareTo(b.topicId ?? '');
      if (tComp != 0) return tComp;
      return (a.contentDomain ?? '').compareTo(b.contentDomain ?? '');
    });

    // 7. Budget Fitting Algorithm
    // Greedily pick top candidates ensuring:
    // a) Total estimated minutes <= budgetMinutes (or within 5 min tolerance)
    // b) At most 2 sessions from the same subject per day
    final List<StudyPlanSession> chosenSessions = [];
    final Map<String, int> subjectSessionCount = {};
    int accumulatedMinutes = 0;
    final maxBudget = settings.dailyBudgetMinutes;

    for (final candidate in candidates) {
      final sId = candidate.subjectId;
      final currentSubCount = subjectSessionCount[sId] ?? 0;

      // Allow max 2 sessions per subject in the daily plan to guarantee multi-subject rotation
      if (currentSubCount >= 2 && resolvedSubjects.length > 1) {
        continue;
      }

      // Check if adding this session exceeds budget
      if (accumulatedMinutes + candidate.estimatedMinutes > maxBudget) {
        final remainingBudget = maxBudget - accumulatedMinutes;
        // If we have at least 6 minutes left, scale session down to fit remaining budget
        if (remainingBudget >= 6 && candidate.questionIds.length >= 4) {
          final adjustedQCount = math.max(4, (remainingBudget / 1.5).floor());
          final adjustedQIds =
              candidate.questionIds.take(adjustedQCount).toList();
          final adjustedCandidate = candidate.copyWith(
            questionTarget: adjustedQIds.length,
            estimatedMinutes: remainingBudget,
            questionIds: adjustedQIds,
          );
          chosenSessions.add(adjustedCandidate);
          subjectSessionCount[sId] = currentSubCount + 1;
          accumulatedMinutes += remainingBudget;
        } else if (chosenSessions.isEmpty) {
          // Allow single-session budget exception if we have 0 chosen sessions yet
          chosenSessions.add(candidate);
          subjectSessionCount[sId] = currentSubCount + 1;
          accumulatedMinutes += candidate.estimatedMinutes;
        }
        continue;
      }

      chosenSessions.add(candidate);
      subjectSessionCount[sId] = currentSubCount + 1;
      accumulatedMinutes += candidate.estimatedMinutes;

      // Max 4 sessions per day to prevent cognitive overload
      if (chosenSessions.length >= 4) break;
    }

    // 8. Fallback: If no candidate sessions were found (e.g. fresh installation or no stats)
    if (chosenSessions.isEmpty) {
      final fallbackSessions = _buildCurriculumStarterSessions(
        planId: planId,
        stream: stream,
        resolvedSubjects: resolvedSubjects,
        availableQuestions: availableQuestions,
        unitsBySubject: unitsBySubject,
        topicsByUnit: topicsByUnit,
        budgetMinutes: maxBudget,
      );
      chosenSessions.addAll(fallbackSessions);
      accumulatedMinutes =
          fallbackSessions.fold(0, (sum, s) => sum + s.estimatedMinutes);
    }

    return StudyPlan(
      id: planId,
      userId: userId,
      planDate: DateTime(now.year, now.month, now.day),
      targetMinutes: maxBudget,
      estimatedMinutes: accumulatedMinutes,
      sessions: chosenSessions,
      status: SessionCompletionStatus.notStarted,
      algorithmVersion: kAdaptivePlannerAlgorithmVersion,
      generatedAt: now,
    );
  }

  /// Filters curriculum subjects based on student grade and stream.
  List<Subject> _filterStreamSubjects({
    required List<Subject> allSubjects,
    required int grade,
    required String stream,
  }) {
    final eligibleTracks = SubjectResolver.resolveEligibleTracks(
      grade: grade,
      stream: stream,
    );
    final eligibleSubjectIds = eligibleTracks.map((t) => t.subjectId).toSet();

    final filtered = allSubjects.where((s) {
      if (s.grade != grade) return false;
      if (s.scope == SubjectScope.curriculumOnly) {
        return false; // exclude Civics from default primary exam plan
      }
      return eligibleSubjectIds.contains(s.id);
    }).toList();

    return filtered.isNotEmpty
        ? filtered
        : SubjectResolver.resolveSubjectsForStudent(
            grade: grade,
            stream: stream,
          );
  }

  ExamVariantCode? _resolveVariantForSubject(String subjectId, bool isNatural) {
    final sId = subjectId.toLowerCase();
    if (sId.contains('math')) {
      return isNatural
          ? ExamVariantCode.naturalScience
          : ExamVariantCode.socialScience;
    } else if (sId.contains('eng') || sId.contains('apt')) {
      return ExamVariantCode.shared;
    } else if (isNatural) {
      return ExamVariantCode.naturalScience;
    } else {
      return ExamVariantCode.socialScience;
    }
  }

  bool _isQuestionEligibleForStudent({
    required Question question,
    required String stream,
    required ExamVariantCode? targetVariant,
  }) {
    final isNatural = stream.toLowerCase() != 'social';
    if (targetVariant != null && question.examVariant != null) {
      if (question.examVariant != targetVariant) return false;
    }
    if (isNatural) {
      if (question.examVariant == ExamVariantCode.socialScience) return false;
      if (question.stream == 'social') return false;
    } else {
      if (question.examVariant == ExamVariantCode.naturalScience) return false;
      if (question.stream == 'natural') return false;
    }
    return true;
  }

  List<_LearningTarget> _discoverLearningTargets({
    required Subject subject,
    required List<Question> questions,
    required Map<String, List<Unit>> unitsBySubject,
    required Map<String, List<Topic>> topicsByUnit,
    required bool isNatural,
  }) {
    final List<_LearningTarget> targets = [];
    final Set<String> assignedQuestionIds = {};

    final units = unitsBySubject[subject.id] ?? const [];
    for (final unit in units) {
      final topics = topicsByUnit[unit.id] ?? const [];
      for (final topic in topics) {
        final topicQs = questions.where((q) => q.topicId == topic.id).toList();
        if (topicQs.isNotEmpty) {
          assignedQuestionIds.addAll(topicQs.map((q) => q.id));
          final subjectPrefixEn = (subject.id == 'math_g12')
              ? (isNatural ? 'Mathematics (Natural)' : 'Mathematics (Social)')
              : subject.nameEn;
          final subjectPrefixAm = (subject.id == 'math_g12')
              ? (isNatural ? 'ሒሳብ (ተፈጥሮ)' : 'ሒሳብ (ማህበራዊ)')
              : subject.nameAm;
          targets.add(_LearningTarget(
            targetKey: topic.id,
            unitId: unit.id,
            topicId: topic.id,
            contentDomain: topicQs.first.contentDomain,
            skill: topicQs.first.skill,
            titleEn: '$subjectPrefixEn: ${topic.titleEn}',
            titleAm: '$subjectPrefixAm፦ ${topic.titleAm}',
            displayTargetNameEn: topic.titleEn,
            displayTargetNameAm: topic.titleAm,
            questions: topicQs,
          ));
        }
      }
    }

    // For unassigned questions (e.g. English Reading/Grammar/Vocabulary, Aptitude domains/skills)
    final unassigned =
        questions.where((q) => !assignedQuestionIds.contains(q.id)).toList();

    if (unassigned.isNotEmpty) {
      final Map<String, List<Question>> grouped = {};
      for (final q in unassigned) {
        final key = q.skill != null && q.skill!.isNotEmpty
            ? '${q.contentDomain ?? ""}_${q.skill!}'
            : (q.contentDomain ??
                (q.topicId.isNotEmpty ? q.topicId : 'general'));
        grouped.putIfAbsent(key, () => []).add(q);
      }

      for (final entry in grouped.entries) {
        final groupQs = entry.value;
        final sample = groupQs.first;
        final domain = sample.contentDomain;
        final skill = sample.skill;
        final label = skill ?? (domain ?? entry.key);

        final subjectPrefixEn = (subject.id == 'math_g12')
            ? (isNatural ? 'Mathematics (Natural)' : 'Mathematics (Social)')
            : subject.nameEn;
        final subjectPrefixAm = (subject.id == 'math_g12')
            ? (isNatural ? 'ሒሳብ (ተፈጥሮ)' : 'ሒሳብ (ማህበራዊ)')
            : subject.nameAm;

        targets.add(_LearningTarget(
          targetKey: 'gen_${entry.key}',
          unitId: sample.unitId.isNotEmpty ? sample.unitId : null,
          topicId: sample.topicId.isNotEmpty ? sample.topicId : null,
          contentDomain: domain,
          skill: skill,
          titleEn: '$subjectPrefixEn: $label',
          titleAm: '$subjectPrefixAm፦ $label',
          displayTargetNameEn: label,
          displayTargetNameAm: label,
          questions: groupQs,
        ));
      }
    }

    return targets;
  }

  /// Aggregates historical performance metrics per topic or learning target.
  Map<String, _TopicLearningStats> _aggregateLearningStats({
    required List<ExamAttempt> completedAttempts,
    required List<Question> availableQuestions,
  }) {
    final Map<String, Question> questionMap = {
      for (final q in availableQuestions) q.id: q
    };
    final Map<String, _TopicLearningStats> stats = {};

    // Sort attempts chronologically
    final sorted = List<ExamAttempt>.from(completedAttempts)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final attempt in sorted) {
      for (final respEntry in attempt.responses.entries) {
        final qId = respEntry.key;
        final resp = respEntry.value;
        final q = questionMap[qId];
        if (q == null) continue;

        final keys = <String>{};
        if (q.topicId.isNotEmpty) keys.add(q.topicId);
        if (q.skill != null && q.skill!.isNotEmpty) {
          keys.add('${q.contentDomain ?? ""}_${q.skill!}');
          keys.add('gen_${q.contentDomain ?? ""}_${q.skill!}');
        }
        if (q.contentDomain != null && q.contentDomain!.isNotEmpty) {
          keys.add(q.contentDomain!);
          keys.add('gen_${q.contentDomain!}');
        }

        for (final k in keys) {
          final tStats =
              stats.putIfAbsent(k, () => _TopicLearningStats(targetKey: k));
          tStats.totalAttempts++;
          if (resp.isCorrect) {
            tStats.correctCount++;
          } else {
            tStats.mistakeCount++;
          }
          tStats.lastAttemptAt = attempt.startTime;

          // Track last 5 responses for recent error detection
          tStats.recentResponses.add(resp.isCorrect);
          if (tStats.recentResponses.length > 5) {
            tStats.recentResponses.removeAt(0);
          }
        }
      }
    }

    return stats;
  }

  /// Selects questions matching difficulty progression.
  List<String> _pickAdaptiveQuestions({
    required List<Question> questions,
    required double accuracyPercentage,
    required int targetCount,
  }) {
    // Difficulty allocation:
    // < 50% accuracy -> remediation: 60% easy, 40% medium, 0% hard
    // 50-75% accuracy -> balanced: 30% easy, 50% medium, 20% hard
    // > 75% accuracy -> mastery: 10% easy, 40% medium, 50% hard
    final List<Question> easy = [];
    final List<Question> medium = [];
    final List<Question> hard = [];

    for (final q in questions) {
      final diff = q.difficulty.toLowerCase();
      if (diff == 'easy') {
        easy.add(q);
      } else if (diff == 'hard') {
        hard.add(q);
      } else {
        medium.add(q);
      }
    }

    final List<Question> picked = [];

    if (accuracyPercentage < 50.0) {
      picked.addAll(easy);
      picked.addAll(medium);
      picked.addAll(hard);
    } else if (accuracyPercentage <= 75.0) {
      picked.addAll(medium);
      picked.addAll(easy);
      picked.addAll(hard);
    } else {
      picked.addAll(hard);
      picked.addAll(medium);
      picked.addAll(easy);
    }

    return picked.take(targetCount).map((q) => q.id).toList();
  }

  /// Builds a balanced curriculum starter plan for fresh students with no history.
  List<StudyPlanSession> _buildCurriculumStarterSessions({
    required String planId,
    required String stream,
    required List<Subject> resolvedSubjects,
    required List<Question> availableQuestions,
    required Map<String, List<Unit>> unitsBySubject,
    required Map<String, List<Topic>> topicsByUnit,
    required int budgetMinutes,
  }) {
    final List<StudyPlanSession> sessions = [];
    int remainingMinutes = budgetMinutes;
    final isNatural = stream.toLowerCase() != 'social';

    for (final subject in resolvedSubjects) {
      if (remainingMinutes < 10) break;
      final targetVariant = _resolveVariantForSubject(subject.id, isNatural);
      final targetStructure = subject.assessmentStructure;

      final eligibleQuestions = availableQuestions.where((q) {
        if (q.subjectId != subject.id) return false;
        return _isQuestionEligibleForStudent(
          question: q,
          stream: stream,
          targetVariant: targetVariant,
        );
      }).toList();

      if (eligibleQuestions.isEmpty) continue;

      final units = unitsBySubject[subject.id] ?? const [];
      final firstUnit = units.isNotEmpty ? units.first : null;
      final topics = firstUnit != null
          ? (topicsByUnit[firstUnit.id] ?? const [])
          : const <Topic>[];
      final firstTopic = topics.isNotEmpty ? topics.first : null;

      final questions = eligibleQuestions
          .where((q) => firstTopic == null || q.topicId == firstTopic.id)
          .take(8)
          .map((q) => q.id)
          .toList();

      final finalQuestions = questions.isNotEmpty
          ? questions
          : eligibleQuestions.take(8).map((q) => q.id).toList();

      if (finalQuestions.isEmpty) continue;

      const estTime = 12;
      final subjectPrefixEn = (subject.id == 'math_g12')
          ? (isNatural
              ? 'Mathematics (Natural Science)'
              : 'Mathematics (Social Science)')
          : subject.nameEn;
      final subjectPrefixAm = (subject.id == 'math_g12')
          ? (isNatural ? 'ሒሳብ (የተፈጥሮ ሳይንስ)' : 'ሒሳብ (የማህበራዊ ሳይንስ)')
          : subject.nameAm;

      sessions.add(
        StudyPlanSession(
          id: '${planId}_start_${subject.id}',
          planId: planId,
          subjectId: subject.id,
          unitId: firstUnit?.id,
          topicId: firstTopic?.id,
          examVariant: targetVariant,
          assessmentStructure: targetStructure,
          sessionType: StudySessionType.curriculumCoverage,
          titleEn: firstTopic != null
              ? '$subjectPrefixEn: ${firstTopic.titleEn}'
              : '$subjectPrefixEn Diagnostic Drill',
          titleAm: firstTopic != null
              ? '$subjectPrefixAm፦ ${firstTopic.titleAm}'
              : 'የ$subjectPrefixAm መጀመሪያ ልምምድ',
          questionTarget: finalQuestions.length,
          estimatedMinutes: estTime,
          priorityScore: 50.0,
          reasonCode: RecommendationReasonCode.newCurriculum,
          reasonDetailEn:
              'Curriculum introductory practice to establish baseline mastery in $subjectPrefixEn.',
          reasonDetailAm:
              'በ$subjectPrefixAm የመጀመሪያ የብቃት ደረጃን ለመለካት የተዘጋጀ የመግቢያ ልምምድ።',
          questionIds: finalQuestions,
        ),
      );

      remainingMinutes -= estTime;
      if (sessions.length >= 3) break;
    }

    return sessions;
  }
}

class _LearningTarget {
  final String targetKey;
  final String? unitId;
  final String? topicId;
  final String? contentDomain;
  final String? skill;
  final String titleEn;
  final String titleAm;
  final String displayTargetNameEn;
  final String displayTargetNameAm;
  final List<Question> questions;

  const _LearningTarget({
    required this.targetKey,
    this.unitId,
    this.topicId,
    this.contentDomain,
    this.skill,
    required this.titleEn,
    required this.titleAm,
    required this.displayTargetNameEn,
    required this.displayTargetNameAm,
    required this.questions,
  });
}

class _TopicLearningStats {
  final String targetKey;
  int totalAttempts = 0;
  int correctCount = 0;
  int mistakeCount = 0;
  DateTime? lastAttemptAt;
  final List<bool> recentResponses = [];

  _TopicLearningStats({required this.targetKey});

  double get accuracyPercentage =>
      totalAttempts > 0 ? (correctCount / totalAttempts) * 100.0 : 0.0;

  double get recentMistakeRatio {
    if (recentResponses.isEmpty) return 0.0;
    final wrongs = recentResponses.where((c) => !c).length;
    return wrongs / recentResponses.length;
  }
}
