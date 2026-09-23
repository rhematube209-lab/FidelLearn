import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../subjects/domain/models/subject_models.dart';
import '../../../subjects/domain/services/curriculum_coverage_service.dart';

class CurriculumCoverageDashboardWidget extends StatefulWidget {
  final CurriculumCoverageReport report;

  const CurriculumCoverageDashboardWidget({
    super.key,
    required this.report,
  });

  @override
  State<CurriculumCoverageDashboardWidget> createState() =>
      _CurriculumCoverageDashboardWidgetState();
}

class _CurriculumCoverageDashboardWidgetState
    extends State<CurriculumCoverageDashboardWidget> {
  String _selectedStreamFilter =
      'all'; // 'all', 'natural', 'social', 'supplementary'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredMetrics = widget.report.subjectMetrics.where((m) {
      if (_selectedStreamFilter == 'all') return true;
      if (_selectedStreamFilter == 'supplementary') {
        return m.scope == SubjectScope.curriculumOnly ||
            m.subjectId.contains('civ');
      }
      final isCivics =
          m.scope == SubjectScope.curriculumOnly || m.subjectId.contains('civ');
      if (isCivics) return false;

      final isSocial = m.variantCode == ExamVariantCode.socialScience ||
          m.subjectId.contains('hist') ||
          m.subjectId.contains('geo') ||
          m.subjectId.contains('econ');
      final isNatural = m.variantCode == ExamVariantCode.naturalScience ||
          m.subjectId.contains('phys') ||
          m.subjectId.contains('chem') ||
          m.subjectId.contains('bio');
      final isCommon = m.scope == SubjectScope.commonExam ||
          m.variantCode == ExamVariantCode.shared;

      if (_selectedStreamFilter == 'social') {
        return isSocial || (isCommon && !isNatural);
      }
      if (_selectedStreamFilter == 'natural') {
        return isNatural || (isCommon && !isSocial);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Metrics Summary Banner
        Row(
          children: [
            _buildStatCard(
              title: 'Launch Subjects',
              value: '${widget.report.subjectMetrics.length}',
              subtitle: '${widget.report.readySubjectsCount} Ready for Launch',
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              title: 'Total Questions',
              value: '${widget.report.totalQuestions}',
              subtitle: '${widget.report.totalPublished} Published',
              color: const Color(0xFF6366F1),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stream Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Filter Stream:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                ),
              ),
              const SizedBox(width: 10),
              _buildFilterChip('All (Grade 12)', 'all', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Natural Science', 'natural', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('Social Science', 'social', isDark),
              const SizedBox(width: 8),
              _buildFilterChip(
                  'Supplementary (Civics)', 'supplementary', isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Per-Subject Coverage Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredMetrics.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final m = filteredMetrics[index];
            return _buildSubjectCard(m, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedStreamFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedStreamFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandStrong
              : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.brandStrong
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.darkText : AppTheme.lightText),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSubjectCard(SubjectCoverageMetrics m, bool isDark) {
    final readinessColor = _getReadinessColor(m.readiness);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject name + Badges + Readiness Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m.subjectNameEn} (${m.subjectNameAm})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildBadge(m.scope.name.toUpperCase(),
                            const Color(0xFF6366F1), isDark),
                        _buildBadge(m.variantCode.name.toUpperCase(),
                            const Color(0xFF0EA5E9), isDark),
                        _buildBadge(m.assessmentStructure.name.toUpperCase(),
                            const Color(0xFF8B5CF6), isDark),
                        _buildBadge(
                          m.coverageAuthorityLevel.displayName,
                          m.coverageAuthorityLevel ==
                                  CoverageAuthorityLevel.authoritative
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          isDark,
                        ),
                        _buildBadge(
                          m.historicalCoverageStatus.displayName,
                          m.historicalCoverageStatus ==
                                  HistoricalCoverageStatus.complete
                              ? const Color(0xFF10B981)
                              : (m.historicalCoverageStatus ==
                                      HistoricalCoverageStatus.partial
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFF6B7280)),
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${m.subjectId} • ${m.questionBankDepth} Questions (${m.publishedQuestions} Published) • Authority: ${m.sourceAuthority ?? 'FDRE MoE'}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: readinessColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: readinessColor, width: 1),
                ),
                child: Text(
                  m.readiness.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: readinessColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Decoupled Metrics: Curriculum Breadth & Past Paper Depth
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  label:
                      'Curriculum Breadth (${m.unitsWithQuestions}/${m.manifestTotalUnits})',
                  percent: m.curriculumBreadthPercent,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressBar(
                  label:
                      'Past-Paper Depth (${m.questionsPerExamYear.keys.where((y) => m.targetExamYears.contains(y)).length}/${m.targetExamYears.length} Yrs)',
                  percent: m.pastPaperDepthPercent,
                  color: const Color(0xFF0EA5E9),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  label: 'Rationale Quality',
                  percent: m.explanationCoveragePercent,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressBar(
                  label: 'Amharic Translation',
                  percent: m.amharicTranslationPercent,
                  color: const Color(0xFFEC4899),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  label: 'Key Concepts',
                  percent: m.keyConceptCoveragePercent,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 14),

          // Exam Years Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exam Years Status (Target: ${m.targetExamYears.join(', ')} E.C.):',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...m.questionsPerExamYear.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '${e.key} E.C. (${e.value} Qs Verified)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF10B981)
                              : const Color(0xFF047857),
                        ),
                      ),
                    );
                  }),
                  ...m.effectiveMissingTargetYears.map((year) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E24)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Text(
                        '$year E.C. (Awaiting Source)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Source Evidence Inspection Row
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showSourceEvidenceDialog(context, m, isDark),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: m.manifestVerificationStatus.isConfirmed
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Source Evidence: ${m.sourceDocumentTitle ?? 'Official Curriculum'} (${m.curriculumVersion ?? 'Current Grade 12'})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkTextSoft
                            : AppTheme.lightTextSoft,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    'Audit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandStrong,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppTheme.brandStrong,
                  ),
                ],
              ),
            ),
          ),

          // Gaps Callout
          if (m.blockingGaps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: m.blockingGaps.map((g) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            g,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFEF4444),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double percent,
    required Color color,
    required bool isDark,
  }) {
    final clamped = (percent / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
              ),
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 5,
            backgroundColor:
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _getReadinessColor(SubjectLaunchReadiness readiness) {
    switch (readiness) {
      case SubjectLaunchReadiness.readyForLaunch:
        return const Color(0xFF10B981);
      case SubjectLaunchReadiness.qa:
        return const Color(0xFF6366F1);
      case SubjectLaunchReadiness.contentReview:
        return const Color(0xFFF59E0B);
      case SubjectLaunchReadiness.inProgress:
        return const Color(0xFF8B5CF6);
      case SubjectLaunchReadiness.notStarted:
        return const Color(0xFFEF4444);
    }
  }

  void _showSourceEvidenceDialog(
      BuildContext context, SubjectCoverageMetrics m, bool isDark) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          title: Text(
            '${m.subjectNameEn} Curriculum Provenance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAuditRow('Canonical Subject ID', m.subjectId, isDark),
                _buildAuditRow('Source Authority',
                    m.sourceAuthority ?? 'FDRE Ministry of Education', isDark),
                _buildAuditRow(
                    'Source Document',
                    m.sourceDocumentTitle ?? 'Official Syllabus Specification',
                    isDark),
                _buildAuditRow('Curriculum Version',
                    m.curriculumVersion ?? 'current_grade12', isDark),
                _buildAuditRow('Manifest Verification Status',
                    m.manifestVerificationStatus.displayName, isDark),
                _buildAuditRow('Coverage Authority Level',
                    m.coverageAuthorityLevel.displayName, isDark),
                _buildAuditRow('Verified At',
                    m.manifestVerifiedAt ?? 'Verified for Launch', isDark),
                _buildAuditRow('Verified By',
                    m.manifestVerifiedBy ?? 'MoE Curriculum Committee', isDark),
                _buildAuditRow('Historical Depth Status',
                    m.historicalCoverageStatus.displayName, isDark),
                _buildAuditRow('Past Exam Target Window',
                    '${m.targetExamYears.join(', ')} E.C.', isDark),
                _buildAuditRow(
                    'Verified Exam Years',
                    m.effectiveVerifiedYears.isEmpty
                        ? 'None (Awaiting Source)'
                        : '${m.effectiveVerifiedYears.join(', ')} E.C.',
                    isDark),
                _buildAuditRow(
                    'Missing Target Years',
                    m.effectiveMissingTargetYears.isEmpty
                        ? 'None (All Target Years Ingested)'
                        : '${m.effectiveMissingTargetYears.join(', ')} E.C.',
                    isDark),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuditRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
