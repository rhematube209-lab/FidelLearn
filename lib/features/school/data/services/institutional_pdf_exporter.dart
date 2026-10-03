import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../../domain/models/institutional_reporting_models.dart';

/// Pure Dart PDF 1.4 Generator for FidelLearn Institutional Reports.
/// Produces binary-compliant PDF documents with valid headers, cross-reference tables,
/// catalog structures, fonts, multi-page layout, tables, and methodology disclaimers.
///
/// NOTE regarding Ethiopic / Amharic rendering:
/// Standard Type 1 PDF fonts (Helvetica) render Latin-1 characters. Ethiopic Unicode
/// glyphs require TrueType font embedding (documented as a known limitation in P10).
class InstitutionalPdfExporter {
  /// Calculate SHA-256 checksum over the raw PDF binary bytes.
  static String calculateSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Sanitize text for PDF Type 1 WinAnsi encoding.
  static String _escapePdfText(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (text[i] == '(') {
        buffer.write(r'\(');
      } else if (text[i] == ')') {
        buffer.write(r'\)');
      } else if (text[i] == '\\') {
        buffer.write(r'\\');
      } else if (code >= 32 && code <= 126) {
        buffer.write(text[i]);
      } else if (code == 10 || code == 13 || code == 9) {
        buffer.write(' ');
      } else {
        // Fallback for non-ASCII (e.g. Amharic glyphs or special symbols)
        buffer.write('?');
      }
    }
    return buffer.toString();
  }

  /// Generate a valid PDF binary document for the School Executive Report.
  static Uint8List exportExecutive(ExecutiveReport report) {
    final doc = _PdfDocument(
      title: 'FidelLearn Institutional Executive Report',
      schoolName: report.schoolName,
      academicYear: report.academicYear,
      dataAsOf: report.dataAsOf,
    );

    // Page 1: Populations and National Exam Preparation Evidence
    doc.addHeaderSection('1. INSTITUTIONAL POPULATION OVERVIEW');
    doc.addTableRow('Active Enrolled Students (Canonical)',
        '${report.studentPopulation}', 'Total verified student memberships');
    doc.addTableRow(
        '  - Natural Science Stream',
        '${report.naturalStreamStudents}',
        '${report.studentPopulation > 0 ? (report.naturalStreamStudents / report.studentPopulation * 100).toStringAsFixed(1) : 0}% of cohort');
    doc.addTableRow(
        '  - Social Science Stream',
        '${report.socialStreamStudents}',
        '${report.studentPopulation > 0 ? (report.socialStreamStudents / report.studentPopulation * 100).toStringAsFixed(1) : 0}% of cohort');
    doc.addTableRow('Active Teaching Staff', '${report.teacherPopulation}',
        'Verified active teacher memberships');
    doc.addTableRow('Active Classrooms / Sections', '${report.classPopulation}',
        'Configured academic cohorts');

    doc.addSpacing(12);
    doc.addHeaderSection('2. NATIONAL EXAM PREPARATION EVIDENCE');
    doc.addTableRow(
        'Assessment Participation Rate',
        '${report.assessmentParticipationRate}%',
        '${report.assessmentParticipants} / ${report.assessmentEligibleStudents} eligible students');
    doc.addTableRow('Recent Assessment Average Score',
        '${report.recentAssessmentAverage}%', 'Mean score of latest attempts');
    doc.addTableRow(
        'Recent Assessment Median Score',
        '${report.recentAssessmentMedian}%',
        '50th percentile (reduces outlier distortion)');
    doc.addTableRow(
        'National Simulation Participation',
        '${report.simulationParticipationRate}%',
        '${report.simulationParticipants} / ${report.assessmentEligibleStudents} eligible students');
    doc.addTableRow('Simulation Average Score', '${report.simulationAverage}%',
        'Full ESSLCE timed simulation mean');
    doc.addTableRow('Simulation Median Score', '${report.simulationMedian}%',
        '50th percentile simulation score');

    doc.addSpacing(12);
    doc.addHeaderSection('3. ASSIGNMENT FOLLOW-THROUGH & TIMELINESS (P9)');
    doc.addTableRow('Required Completion Denominator',
        '${report.requiredForCompletion}', 'Eligible assignment recipients');
    doc.addTableRow('Assignment Completion Rate', '${report.completionRate}%',
        '${report.completedCount} completed submissions');
    doc.addTableRow('Verified Late Submissions', '${report.verifiedLateCount}',
        '${report.lateRateVerified}% of verified submissions');
    doc.addTableRow('Timing Unverified Submissions',
        '${report.timingUnverifiedCount}', 'Excluded from timeliness rates');
    doc.addTableRow('Clock Anomaly Submissions', '${report.clockAnomalyCount}',
        'Drift or invalid timestamp flag');

    // Page 2: Interventions, Data Quality, and Disclaimers
    doc.startNewPage();
    doc.addHeaderSection('4. STUDENT ACADEMIC INTERVENTIONS & FOLLOW-UP (P10)');
    doc.addTableRow(
        'Methodology Version',
        report.interventionMethodologyVersion,
        'Fixed action completion anchor');
    doc.addTableRow('Interventions Created', '${report.interventionsCreated}',
        'Educator registered actions');
    doc.addTableRow(
        'Interventions Completed',
        '${report.interventionsCompleted}',
        'Actions marked completed by teacher');
    doc.addTableRow(
        'Interventions with Follow-Up',
        '${report.interventionsWithFollowupEvidence}',
        'Qualifying 30-day post-action evidence');
    doc.addSpacing(8);
    doc.addCalloutBox(
        'Non-Causal Academic Evidence Notice', report.nonCausalNotice);

    doc.addSpacing(14);
    doc.addHeaderSection('5. DATA COVERAGE & SYNCHRONIZATION QUALITY');
    doc.addTableRow(
        'Teacher Assignment Coverage',
        '${report.teacherCoverageRate}%',
        'Curriculum slots with active teachers');
    doc.addTableRow('Fresh Academic Sync (<= 2 days)',
        '${report.freshSyncCount}', 'Devices synced recently');
    doc.addTableRow('Moderate Academic Sync (3-7 days)',
        '${report.moderateSyncCount}', 'Active within past week');
    doc.addTableRow('Stale Academic Sync (8-14 days)',
        '${report.staleSyncCount}', 'Sync required for fresh review');
    doc.addTableRow('Very Stale Academic Sync (> 14 days)',
        '${report.veryStaleSyncCount}', 'Offline usage or network gap');
    doc.addTableRow('Fresh Data Coverage Rate',
        '${report.freshDataCoverageRate}%', 'Proportion synced <= 14 days');
    doc.addSpacing(8);
    doc.addCalloutBox('Offline Data Notice', report.freshnessCaveat);

    doc.addSpacing(14);
    doc.addHeaderSection('6. METHODOLOGY & PRIVACY COMPLIANCE');
    doc.addBullet(
        'Privacy Suppression: Aggregate cells with fewer than 5 students (k=5) are masked.');
    doc.addBullet(
        'P4 Mastery Limitation: Adaptive spaced mastery and national readiness remain device-local.');
    doc.addBullet(
        'Data Reproducibility: Generated reports reflect snapshot evidence at the data-as-of timestamp.');

    return doc.buildBytes();
  }

  /// Generate a valid PDF binary document for the Teacher Coverage Report.
  static Uint8List exportTeacherCoverage(TeacherCoverageReport report) {
    final doc = _PdfDocument(
      title: 'FidelLearn Teacher Coverage Report',
      schoolName: 'School ID: ${report.schoolId}',
      academicYear: report.academicYear,
      dataAsOf: report.dataAsOf,
    );

    doc.addHeaderSection('1. INSTRUCTIONAL COVERAGE SUMMARY');
    doc.addTableRow('Total Active Classrooms', '${report.totalClassrooms}',
        'Configured cohorts');
    doc.addTableRow('Curriculum Subjects', '${report.totalSubjects}',
        'National stream subjects');
    doc.addTableRow('Total Required Instructional Slots',
        '${report.totalRequiredSlots}', 'Classrooms x Subjects');
    doc.addTableRow('Assigned Slots', '${report.assignedSlots}',
        'Active teacher assignments');
    doc.addTableRow('Unassigned Slots', '${report.unassignedSlots}',
        'Awaiting educator assignment');
    doc.addTableRow('Overall Coverage Percentage',
        '${report.coveragePercentage}%', 'Assigned / Required');

    doc.addSpacing(14);
    doc.addHeaderSection('2. CLASSROOM-SUBJECT ASSIGNMENT SLOTS');
    for (final slot in report.slots) {
      final status = slot.isAssigned ? 'ASSIGNED' : 'UNASSIGNED';
      final detail = slot.isAssigned
          ? 'Teacher: ${slot.teacherName ?? 'Assigned'}'
          : 'NO TEACHER ASSIGNED';
      doc.addTableRow(
        '${slot.classroomName} - ${slot.subjectName}',
        status,
        detail,
      );
    }

    doc.addSpacing(14);
    doc.addCalloutBox(
      'Administrative Authority Notice',
      'Teacher coverage is derived strictly from public.teacher_subject_assignments. No teacher ranking or evaluation score is computed.',
    );

    return doc.buildBytes();
  }
}

/// Internal builder that coordinates PDF objects, streams, pages, and cross-reference offsets.
class _PdfDocument {
  final String title;
  final String schoolName;
  final String academicYear;
  final DateTime dataAsOf;

  final List<_PdfPage> _pages = [];
  _PdfPage? _currentPage;

  _PdfDocument({
    required this.title,
    required this.schoolName,
    required this.academicYear,
    required this.dataAsOf,
  }) {
    startNewPage();
  }

  void startNewPage() {
    final page = _PdfPage(
      pageNumber: _pages.length + 1,
      title: title,
      schoolName: schoolName,
      academicYear: academicYear,
      dataAsOf: dataAsOf,
    );
    _pages.add(page);
    _currentPage = page;
  }

  void addHeaderSection(String heading) {
    if (_currentPage!.cursorY < 120) {
      startNewPage();
    }
    _currentPage!.writeSectionHeader(heading);
  }

  void addTableRow(String label, String value, String note) {
    if (_currentPage!.cursorY < 80) {
      startNewPage();
    }
    _currentPage!.writeTableRow(label, value, note);
  }

  void addBullet(String text) {
    if (_currentPage!.cursorY < 70) {
      startNewPage();
    }
    _currentPage!.writeBullet(text);
  }

  void addCalloutBox(String title, String body) {
    if (_currentPage!.cursorY < 100) {
      startNewPage();
    }
    _currentPage!.writeCalloutBox(title, body);
  }

  void addSpacing(double points) {
    _currentPage!.cursorY -= points;
  }

  Uint8List buildBytes() {
    // Collect all PDF objects in order
    // 1: Catalog
    // 2: Pages
    // For each page:
    //   Page object: index 3 + 2*i
    //   Contents stream: index 4 + 2*i
    // Font F1 (Helvetica): index 3 + 2*pageCount
    // Font F2 (Helvetica-Bold): index 4 + 2*pageCount

    final totalPages = _pages.length;
    final fontF1Id = 3 + 2 * totalPages;
    final fontF2Id = fontF1Id + 1;
    final totalObjects = fontF2Id;

    final buffer = BytesBuilder();

    // 1. PDF Header with binary indicator comment
    const headerStr = '%PDF-1.4\n%\xE2\xE3\xCF\xD3\n';
    buffer.add(utf8.encode(headerStr));

    final offsets = <int>[0]; // 1-indexed for objects

    void addObject(int objId, String body) {
      offsets.add(buffer.length);
      final entry = '$objId 0 obj\n$body\nendobj\n';
      buffer.add(utf8.encode(entry));
    }

    // Obj 1: Catalog
    addObject(1, '<< /Type /Catalog /Pages 2 0 R >>');

    // Obj 2: Pages Tree
    final kids = List.generate(totalPages, (i) => '${3 + 2 * i} 0 R').join(' ');
    addObject(2, '<< /Type /Pages /Kids [ $kids ] /Count $totalPages >>');

    // Pages & Streams
    for (int i = 0; i < totalPages; i++) {
      final pageObjId = 3 + 2 * i;
      final streamObjId = pageObjId + 1;
      final page = _pages[i];

      // Page Object
      addObject(
        pageObjId,
        '<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 595.28 841.89 ] /Contents $streamObjId 0 R /Resources << /Font << /F1 $fontF1Id 0 R /F2 $fontF2Id 0 R >> >> >>',
      );

      // Page Content Stream
      final contentStr = page.buildStreamContent(totalPages);
      final streamBytes = utf8.encode(contentStr);
      final streamObjBody =
          '<< /Length ${streamBytes.length} >>\nstream\n$contentStr\nendstream';
      addObject(streamObjId, streamObjBody);
    }

    // Font Objects (Type 1 Standard 14 Fonts)
    addObject(
      fontF1Id,
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>',
    );
    addObject(
      fontF2Id,
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>',
    );

    // Cross-Reference Table (xref)
    final xrefOffset = buffer.length;
    final xrefBuf = StringBuffer();
    xrefBuf.writeln('xref');
    xrefBuf.writeln('0 ${totalObjects + 1}');
    xrefBuf.writeln('0000000000 65535 f ');

    for (int i = 1; i <= totalObjects; i++) {
      final offset = offsets[i];
      final offsetStr = offset.toString().padLeft(10, '0');
      xrefBuf.writeln('$offsetStr 00000 n ');
    }

    xrefBuf.writeln('trailer');
    xrefBuf.writeln('<< /Size ${totalObjects + 1} /Root 1 0 R >>');
    xrefBuf.writeln('startxref');
    xrefBuf.writeln('$xrefOffset');
    xrefBuf.writeln('%%EOF');

    buffer.add(utf8.encode(xrefBuf.toString()));
    return buffer.toBytes();
  }
}

/// Represents drawing commands for a single A4 page (595.28 x 841.89 points).
class _PdfPage {
  final int pageNumber;
  final String title;
  final String schoolName;
  final String academicYear;
  final DateTime dataAsOf;

  double cursorY = 780;
  final StringBuffer _commands = StringBuffer();

  _PdfPage({
    required this.pageNumber,
    required this.title,
    required this.schoolName,
    required this.academicYear,
    required this.dataAsOf,
  }) {
    _renderPageHeader();
  }

  void _renderPageHeader() {
    // Header banner line
    _commands.writeln('0.3 0.4 0.5 RG'); // Slate border
    _commands.writeln('1.5 w');
    _commands.writeln('40 800 m 555 800 l S');

    // Title
    _commands.writeln('BT');
    _commands.writeln('/F2 14 Tf');
    _commands.writeln('0.1 0.2 0.3 rg'); // Dark navy
    _commands.writeln('40 806 Td');
    _commands.writeln('(${InstitutionalPdfExporter._escapePdfText(title)}) Tj');
    _commands.writeln('ET');

    // Metadata line
    _commands.writeln('BT');
    _commands.writeln('/F1 9 Tf');
    _commands.writeln('0.4 0.4 0.4 rg'); // Grey
    _commands.writeln('40 788 Td');
    final asOfStr = dataAsOf.toIso8601String().substring(0, 16);
    final metaStr =
        'School: ${InstitutionalPdfExporter._escapePdfText(schoolName)}  |  Academic Year: $academicYear  |  Data as of: $asOfStr UTC';
    _commands.writeln('($metaStr) Tj');
    _commands.writeln('ET');

    cursorY = 765;
  }

  void writeSectionHeader(String heading) {
    cursorY -= 16;
    _commands.writeln('BT');
    _commands.writeln('/F2 11 Tf');
    _commands.writeln('0.15 0.25 0.45 rg');
    _commands.writeln('40 $cursorY Td');
    _commands
        .writeln('(${InstitutionalPdfExporter._escapePdfText(heading)}) Tj');
    _commands.writeln('ET');

    cursorY -= 4;
    _commands.writeln('0.85 0.85 0.88 RG');
    _commands.writeln('0.8 w');
    _commands.writeln('40 $cursorY m 555 $cursorY l S');
    cursorY -= 12;
  }

  void writeTableRow(String label, String value, String note) {
    // Row background alternating
    _commands.writeln('0.96 0.97 0.98 rg');
    _commands.writeln('40 ${cursorY - 2} 515 15 re f');

    // Border line under row
    _commands.writeln('0.90 0.90 0.92 RG');
    _commands.writeln('0.5 w');
    _commands.writeln('40 ${cursorY - 2} m 555 ${cursorY - 2} l S');

    // Label column
    _commands.writeln('BT');
    _commands.writeln('/F1 9 Tf');
    _commands.writeln('0.2 0.2 0.2 rg');
    _commands.writeln('45 ${cursorY + 2} Td');
    _commands.writeln('(${InstitutionalPdfExporter._escapePdfText(label)}) Tj');
    _commands.writeln('ET');

    // Value column
    _commands.writeln('BT');
    _commands.writeln('/F2 9 Tf');
    _commands.writeln('0.1 0.2 0.4 rg');
    _commands.writeln('250 ${cursorY + 2} Td');
    _commands.writeln('(${InstitutionalPdfExporter._escapePdfText(value)}) Tj');
    _commands.writeln('ET');

    // Note column
    _commands.writeln('BT');
    _commands.writeln('/F1 8 Tf');
    _commands.writeln('0.45 0.45 0.50 rg');
    _commands.writeln('340 ${cursorY + 2} Td');
    _commands.writeln('(${InstitutionalPdfExporter._escapePdfText(note)}) Tj');
    _commands.writeln('ET');

    cursorY -= 16;
  }

  void writeBullet(String text) {
    cursorY -= 12;
    _commands.writeln('BT');
    _commands.writeln('/F1 8.5 Tf');
    _commands.writeln('0.3 0.3 0.35 rg');
    _commands.writeln('45 $cursorY Td');
    _commands
        .writeln('(• ${InstitutionalPdfExporter._escapePdfText(text)}) Tj');
    _commands.writeln('ET');
  }

  void writeCalloutBox(String title, String body) {
    cursorY -= 36;
    // Box fill & border
    _commands.writeln('0.97 0.98 1.0 rg');
    _commands.writeln('0.7 0.8 0.9 RG');
    _commands.writeln('0.8 w');
    _commands.writeln('40 $cursorY 515 32 re B');

    // Callout title
    _commands.writeln('BT');
    _commands.writeln('/F2 8.5 Tf');
    _commands.writeln('0.1 0.3 0.6 rg');
    _commands.writeln('48 ${cursorY + 18} Td');
    _commands.writeln('(${InstitutionalPdfExporter._escapePdfText(title)}) Tj');
    _commands.writeln('ET');

    // Callout body
    _commands.writeln('BT');
    _commands.writeln('/F1 8 Tf');
    _commands.writeln('0.25 0.30 0.35 rg');
    _commands.writeln('48 ${cursorY + 6} Td');
    _commands.writeln('(${InstitutionalPdfExporter._escapePdfText(body)}) Tj');
    _commands.writeln('ET');

    cursorY -= 8;
  }

  String buildStreamContent(int totalPages) {
    // Footer line
    _commands.writeln('0.8 0.8 0.8 RG');
    _commands.writeln('0.5 w');
    _commands.writeln('40 40 m 555 40 l S');

    // Footer text
    _commands.writeln('BT');
    _commands.writeln('/F1 8 Tf');
    _commands.writeln('0.5 0.5 0.5 rg');
    _commands.writeln('40 28 Td');
    _commands.writeln(
        '(FidelLearn Institutional Analytics • Private & Confidential) Tj');
    _commands.writeln('480 28 Td');
    _commands.writeln('(Page $pageNumber of $totalPages) Tj');
    _commands.writeln('ET');

    return _commands.toString();
  }
}
