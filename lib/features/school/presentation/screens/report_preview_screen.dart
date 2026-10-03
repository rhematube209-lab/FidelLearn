import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/supabase_institutional_reporting_repository.dart';
import '../../data/services/institutional_csv_exporter.dart';
import '../../data/services/institutional_document_exporter.dart';
import '../../data/services/institutional_pdf_exporter.dart';
import '../../domain/models/institutional_reporting_models.dart';
import '../providers/institutional_reporting_providers.dart';

/// Screen allowing detailed preview and export (CSV or Printable Document) of an institutional report.
class ReportPreviewScreen extends ConsumerStatefulWidget {
  final String schoolId;
  final InstitutionalReportType reportType;
  final ExecutiveReport? passedExecutiveReport;

  const ReportPreviewScreen({
    super.key,
    required this.schoolId,
    required this.reportType,
    this.passedExecutiveReport,
  });

  @override
  ConsumerState<ReportPreviewScreen> createState() =>
      _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends ConsumerState<ReportPreviewScreen> {
  bool _isExporting = false;
  String? _exportSuccessMessage;

  void _exportCsv(ExecutiveReport report) async {
    setState(() => _isExporting = true);
    final csv = InstitutionalCsvExporter.exportExecutive(report);
    final hash = InstitutionalCsvExporter.calculateSha256(csv);

    // Copy to clipboard or trigger file download simulation
    await Clipboard.setData(ClipboardData(text: csv));

    if (mounted) {
      setState(() {
        _isExporting = false;
        _exportSuccessMessage =
            'CSV generated & copied to clipboard! (SHA-256: ${hash.substring(0, 12)}...)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'CSV Export Ready! Hash: ${hash.substring(0, 16)}... (Copied to clipboard)'),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }
  }

  void _exportDocument(ExecutiveReport report) async {
    setState(() => _isExporting = true);
    final doc = InstitutionalDocumentExporter.formatExecutiveReport(report);
    final hash = InstitutionalDocumentExporter.calculateSha256(doc);

    await Clipboard.setData(ClipboardData(text: doc));

    if (mounted) {
      setState(() {
        _isExporting = false;
        _exportSuccessMessage =
            'Printable Report copied to clipboard! (SHA-256: ${hash.substring(0, 12)}...)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Printable Report Document Ready! Hash: ${hash.substring(0, 16)}... (Copied to clipboard)'),
          backgroundColor: Colors.indigo.shade800,
        ),
      );
    }
  }

  void _exportPdf(ExecutiveReport report) async {
    setState(() => _isExporting = true);
    final bytes = InstitutionalPdfExporter.exportExecutive(report);
    final hash = InstitutionalPdfExporter.calculateSha256(bytes);

    if (mounted) {
      setState(() {
        _isExporting = false;
        _exportSuccessMessage =
            'PDF generated (${bytes.lengthInBytes} bytes, SHA-256: ${hash.substring(0, 12)}...)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'PDF Export Ready! ${bytes.lengthInBytes} bytes, SHA-256: ${hash.substring(0, 16)}...'),
          backgroundColor: Colors.deepPurple.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If passed directly, use it; otherwise read provider
    final execAsync = widget.passedExecutiveReport != null
        ? AsyncValue.data(widget.passedExecutiveReport!)
        : ref.watch(
            schoolExecutiveReportProvider((
              schoolId: widget.schoolId,
              academicYear: '2026/27',
              start: DateTime.now().toUtc().subtract(const Duration(days: 90)),
              end: DateTime.now().toUtc(),
            )),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportType.titleEn),
        actions: [
          if (execAsync.hasValue) ...[
            TextButton.icon(
              icon:
                  const Icon(Icons.file_download_outlined, color: Colors.white),
              label: const Text('Export CSV',
                  style: TextStyle(color: Colors.white)),
              onPressed:
                  _isExporting ? null : () => _exportCsv(execAsync.value!),
            ),
            TextButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  color: Colors.white),
              label: const Text('Export PDF',
                  style: TextStyle(color: Colors.white)),
              onPressed:
                  _isExporting ? null : () => _exportPdf(execAsync.value!),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Export Printable Document',
              onPressed:
                  _isExporting ? null : () => _exportDocument(execAsync.value!),
            ),
          ],
        ],
      ),
      body: execAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    size: 48, color: Colors.blueGrey),
                const SizedBox(height: 12),
                Text(
                  e is ReportingOfflineException ||
                          e.toString().contains('internet connection')
                      ? 'Institutional reports require an internet connection.\nReconnect to load current synchronized analytics.'
                      : 'Failed to load preview: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        data: (report) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_exportSuccessMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _exportSuccessMessage!,
                            style: TextStyle(
                                color: Colors.green.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Report Header
                Text(
                  report.schoolName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Academic Year ${report.academicYear} • Reporting Period: ${report.periodStart.toIso8601String().substring(0, 10)} to ${report.periodEnd.toIso8601String().substring(0, 10)}',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  'Data As-Of: ${report.dataAsOf.toLocal().toString().substring(0, 16)} UTC • Version: ${report.analyticsVersion}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const Divider(height: 32),

                // Table 1: Population Overview
                _buildSectionHeader('1. School Population & Coverage'),
                _buildDataTable([
                  ['Active Students', '${report.studentPopulation}'],
                  [
                    'Natural Science Students',
                    '${report.naturalStreamStudents}'
                  ],
                  ['Social Science Students', '${report.socialStreamStudents}'],
                  ['Active Teachers', '${report.teacherPopulation}'],
                  ['Classrooms', '${report.classPopulation}'],
                  [
                    'Teacher Subject Assignment Coverage',
                    '${report.teacherCoverageRate}%'
                  ],
                  [
                    'Fresh Data Coverage (<= 14 days)',
                    '${report.freshDataCoverageRate}%'
                  ],
                ]),
                const SizedBox(height: 24),

                // Table 2: National Exam Preparation & Simulation Evidence
                _buildSectionHeader(
                    '2. National Exam Preparation & Simulation Evidence'),
                _buildDataTable([
                  [
                    'Assessment Eligible Students',
                    '${report.assessmentEligibleStudents}'
                  ],
                  [
                    'Assessment Participants',
                    '${report.assessmentParticipants} (${report.assessmentParticipationRate}%)'
                  ],
                  [
                    'Recent Assessment Mean Score',
                    '${report.recentAssessmentAverage}%'
                  ],
                  [
                    'Recent Assessment Median Score',
                    '${report.recentAssessmentMedian}%'
                  ],
                  [
                    'National Simulation Participants',
                    '${report.simulationParticipants} (${report.simulationParticipationRate}%)'
                  ],
                  ['Simulation Mean Score', '${report.simulationAverage}%'],
                  ['Simulation Median Score', '${report.simulationMedian}%'],
                ]),
                const SizedBox(height: 24),

                // Table 3: Assignment Follow-Through
                _buildSectionHeader(
                    '3. Instructional Workflow: Assignment Follow-Through'),
                _buildDataTable([
                  [
                    'Required for Completion Denominator (P9)',
                    '${report.requiredForCompletion} students'
                  ],
                  ['Submitted Submissions', '${report.submittedCount}'],
                  ['Assignment Completion Rate', '${report.completionRate}%'],
                  [
                    'Verified Late Submissions',
                    '${report.verifiedLateCount} (${report.lateRateVerified}%)'
                  ],
                  [
                    'Timing Unverified Submissions',
                    '${report.timingUnverifiedCount}'
                  ],
                  ['Clock Anomaly Submissions', '${report.clockAnomalyCount}'],
                ]),
                const SizedBox(height: 24),

                // Table 4: Student Support & Interventions
                _buildSectionHeader(
                    '4. Academic Interventions & Follow-Up Evidence'),
                _buildDataTable([
                  [
                    'Interventions Registered',
                    '${report.interventionsCreated}'
                  ],
                  [
                    'Interventions Completed',
                    '${report.interventionsCompleted}'
                  ],
                  [
                    'Interventions with Comparable Follow-Up',
                    '${report.interventionsWithFollowupEvidence}'
                  ],
                  [
                    'Follow-Up Methodology Version',
                    report.interventionMethodologyVersion
                  ],
                ]),
                const SizedBox(height: 24),

                // Methodology Disclaimer Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 20, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text(
                            'Analytical Principles & Disclaimers',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Non-Causality: ${report.nonCausalNotice}\n\n'
                        '2. Offline Synchronization: ${report.freshnessCaveat}\n\n'
                        '3. P4 & National Readiness: FidelLearn adaptive spaced mastery (P4 fidel_spaced_v1.0) and national readiness composite scores remain device-local and are not synthesized into cloud aggregates.\n\n'
                        '4. Math Variants: Natural and Social Science Mathematics variants are strictly segregated with zero cross-stream contamination.',
                        style: const TextStyle(
                            fontSize: 12, height: 1.4, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.brand),
      ),
    );
  }

  Widget _buildDataTable(List<List<String>> pairs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
        },
        border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200)),
        children: pairs.map((pair) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Text(pair[0], style: const TextStyle(fontSize: 13)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Text(
                  pair[1],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
