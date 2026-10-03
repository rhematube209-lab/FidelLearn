import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../domain/models/institutional_reporting_models.dart';

/// Formatter for human-readable, printable, and downloadable institutional reports.
/// Follows Sections 78 & 79: deterministic templates, methodology footers, and non-causal observations.
class InstitutionalDocumentExporter {
  /// Calculate SHA-256 hash of document payload.
  static String calculateSha256(String content) {
    final bytes = utf8.encode(content);
    return sha256.convert(bytes).toString();
  }

  /// Generate a clean, structured printable document for the Executive Report.
  static String formatExecutiveReport(ExecutiveReport r) {
    final buf = StringBuffer();
    buf.writeln(
        '================================================================================');
    buf.writeln('FIDELLEARN INSTITUTIONAL REPORTING SYSTEM');
    buf.writeln('SCHOOL EXECUTIVE REPORT');
    buf.writeln(
        '================================================================================\n');

    buf.writeln('Institutional Metadata');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln('School Name:            ${r.schoolName}');
    buf.writeln('School ID:              ${r.schoolId}');
    buf.writeln('Academic Year:          ${r.academicYear}');
    buf.writeln(
        'Reporting Period:       ${r.periodStart.toIso8601String().substring(0, 10)} to ${r.periodEnd.toIso8601String().substring(0, 10)}');
    buf.writeln('Data As-Of Timestamp:   ${r.dataAsOf.toIso8601String()}');
    buf.writeln('Analytics Engine:       ${r.analyticsVersion}');
    buf.writeln('Report Schema:          ${r.reportSchemaVersion}\n');

    buf.writeln('1. Institutional Population Overview');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln('Active Enrolled Students: ${r.activeEnrolledStudents}');
    buf.writeln('Students with Evidence:   ${r.studentsWithAcademicEvidence}');
    buf.writeln(
        '  - Natural Science:    ${r.naturalStreamStudents} (${r.studentPopulation > 0 ? (r.naturalStreamStudents / r.studentPopulation * 100).toStringAsFixed(1) : 0}%)');
    buf.writeln(
        '  - Social Science:     ${r.socialStreamStudents} (${r.studentPopulation > 0 ? (r.socialStreamStudents / r.studentPopulation * 100).toStringAsFixed(1) : 0}%)');
    buf.writeln('Total Active Teachers:  ${r.teacherPopulation}');
    buf.writeln('Total Active Classes:   ${r.classPopulation}\n');

    buf.writeln('2. National Exam Preparation & Simulation Evidence');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln(
        'Overall Assessment Participation: ${r.assessmentParticipationRate}% (${r.assessmentParticipants} / ${r.assessmentEligibleStudents} students)');
    buf.writeln(
        'Recent Assessment Average:        ${r.recentAssessmentAverage}%');
    buf.writeln(
        'Recent Assessment Median:         ${r.recentAssessmentMedian}%');
    buf.writeln(
        'National Simulation Participation:${r.simulationParticipationRate}% (${r.simulationParticipants} / ${r.assessmentEligibleStudents} students)');
    buf.writeln('Simulation Average Score:         ${r.simulationAverage}%');
    buf.writeln('Simulation Median Score:          ${r.simulationMedian}%\n');

    buf.writeln('3. Instructional Workflow & Assignment Follow-Through');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln(
        'Required Denominator (P9):        ${r.requiredForCompletion} students');
    buf.writeln('Submitted Submissions:            ${r.submittedCount}');
    buf.writeln('Assignment Completion Rate:       ${r.completionRate}%');
    buf.writeln(
        'Verified On-Time Submissions:     ${r.verifiedOnTimeRate}% of verified submissions');
    buf.writeln(
        'Verified Late Submissions:        ${r.verifiedLateCount} (${r.lateRateVerified}% of verified submissions)');
    buf.writeln('Timing Unverified Submissions:    ${r.timingUnverifiedCount}');
    buf.writeln('Clock Anomaly Submissions:        ${r.clockAnomalyCount}\n');

    buf.writeln('4. Student Academic Interventions & Follow-Up Evidence');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln(
        'Methodology Version:              ${r.interventionMethodologyVersion}');
    buf.writeln('Interventions Created:            ${r.interventionsCreated}');
    buf.writeln(
        'Interventions Completed:          ${r.interventionsCompleted}');
    buf.writeln(
        'Interventions with Follow-Up:     ${r.interventionsWithFollowupEvidence}');
    buf.writeln('Notice:                           ${r.nonCausalNotice}\n');

    buf.writeln('5. Data Coverage & Synchronization Quality');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln('Teacher Assignment Coverage:      ${r.teacherCoverageRate}%');
    buf.writeln(
        'Fresh Data Coverage (<= 14 days): ${r.freshDataCoverageRate}%');
    buf.writeln('  - Fresh Sync (<= 7 days):       ${r.freshSyncCount}');
    buf.writeln('  - Moderate Sync (8-14 days):    ${r.moderateSyncCount}');
    buf.writeln('  - Stale Sync (15-30 days):      ${r.staleSyncCount}');
    buf.writeln('  - Very Stale Sync (> 30 days):  ${r.veryStaleSyncCount}');
    buf.writeln('Caveat:                           ${r.freshnessCaveat}\n');

    buf.writeln(
        '================================================================================');
    buf.writeln('METHODOLOGY FOOTER & DISCLAIMERS');
    buf.writeln(
        '================================================================================');
    buf.writeln(
        '1. FidelLearn P4 adaptive spaced mastery and composite national readiness scores');
    buf.writeln(
        '   are device-local and are not fabricated or synthesized into cloud reports.');
    buf.writeln(
        '2. Observed changes in academic evidence following an intervention do not establish');
    buf.writeln(
        '   causation. All reported metrics reflect synchronized cloud assessments only.');
    buf.writeln(
        '3. Mathematics Natural and Social Science variants are strictly segregated without');
    buf.writeln('   cross-stream blending.');
    buf.writeln(
        '================================================================================');

    return buf.toString();
  }

  /// Generate a clean, structured printable document for the Teacher Coverage Report.
  static String formatTeacherCoverageReport(TeacherCoverageReport r) {
    final buf = StringBuffer();
    buf.writeln(
        '================================================================================');
    buf.writeln('FIDELLEARN INSTITUTIONAL REPORTING SYSTEM');
    buf.writeln('TEACHER COVERAGE REPORT');
    buf.writeln(
        '================================================================================\n');

    buf.writeln('Institutional Metadata');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln('School ID:              ${r.schoolId}');
    buf.writeln('Academic Year:          ${r.academicYear}');
    buf.writeln('Data As-Of Timestamp:   ${r.dataAsOf.toIso8601String()}\n');

    buf.writeln('1. Instructional Coverage Summary');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln('Total Active Classrooms:          ${r.totalClassrooms}');
    buf.writeln('Curriculum Subjects:              ${r.totalSubjects}');
    buf.writeln('Total Required Slots:             ${r.totalRequiredSlots}');
    buf.writeln('Assigned Slots:                   ${r.assignedSlots}');
    buf.writeln('Unassigned Slots:                 ${r.unassignedSlots}');
    buf.writeln('Overall Coverage Rate:            ${r.coveragePercentage}%\n');

    buf.writeln('2. Classroom-Subject Assignment Slots');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    for (final slot in r.slots) {
      final status = slot.isAssigned ? 'ASSIGNED' : 'UNASSIGNED';
      final teacher = slot.isAssigned
          ? (slot.teacherName ?? 'Assigned')
          : 'NO TEACHER ASSIGNED';
      buf.writeln(
          '${slot.classroomName.padRight(16)} | ${slot.subjectName.padRight(24)} | ${status.padRight(10)} | $teacher');
    }

    buf.writeln(
        '\n================================================================================');
    buf.writeln('METHODOLOGY FOOTER & DISCLAIMERS');
    buf.writeln(
        '--------------------------------------------------------------------------------');
    buf.writeln(
        'Teacher coverage is derived strictly from public.teacher_subject_assignments.');
    buf.writeln(
        'No teacher ranking or evaluation score is computed or implied.\n');
    buf.writeln(
        '================================================================================');

    return buf.toString();
  }
}
