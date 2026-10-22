import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StudentProfileDrawer extends StatefulWidget {
  final String studentName;
  final String studentId;
  final String section;
  final String stream;
  final int accuracyPct;
  final int mistakesCount;
  final String urgencyTier; // 'high', 'medium', 'low', 'none'
  final List<String> reasonCodes;
  final String primaryWeakTopic;
  final int lastActiveDays;
  final int lastSyncDays;
  final String? academicNotes;
  final List<double>? accuracyTrend;
  final VoidCallback? onLogIntervention;
  final VoidCallback? onAssignPractice;
  final VoidCallback? onClose;

  const StudentProfileDrawer({
    super.key,
    required this.studentName,
    required this.studentId,
    required this.section,
    required this.stream,
    required this.accuracyPct,
    required this.mistakesCount,
    required this.urgencyTier,
    required this.reasonCodes,
    required this.primaryWeakTopic,
    required this.lastActiveDays,
    required this.lastSyncDays,
    this.academicNotes,
    this.accuracyTrend,
    this.onLogIntervention,
    this.onAssignPractice,
    this.onClose,
  });

  @override
  State<StudentProfileDrawer> createState() => _StudentProfileDrawerState();
}

class _StudentProfileDrawerState extends State<StudentProfileDrawer> {
  int _selectedTab = 0; // 0: Overview, 1: Weak Topics, 2: Activity

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color urgencyColor;
    Color urgencyBg;
    String urgencyLabel;

    switch (widget.urgencyTier.toLowerCase()) {
      case 'high':
      case 'immediate':
        urgencyColor = AppTheme.protoBad;
        urgencyBg = isDark ? const Color(0xFF4B303A) : AppTheme.protoBadLight;
        urgencyLabel = 'Immediate Support';
        break;
      case 'medium':
        urgencyColor = AppTheme.protoWarn;
        urgencyBg = isDark ? const Color(0xFF4C3B28) : AppTheme.protoWarnLight;
        urgencyLabel = 'Needs Attention';
        break;
      case 'low':
      case 'monitor':
        urgencyColor = const Color(0xFF78859B);
        urgencyBg = isDark ? const Color(0xFF24314F) : const Color(0xFFEFF2F6);
        urgencyLabel = 'Monitor';
        break;
      default:
        urgencyColor = AppTheme.protoGood;
        urgencyBg = isDark ? const Color(0xFF193F3D) : AppTheme.protoGoodLight;
        urgencyLabel = 'On Track';
        break;
    }

    return Container(
      width: 480,
      color: AppTheme.protoSurface(context),
      child: Column(
        children: [
          // 1. Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.protoLine(context)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.studentName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.studentId} · Section ${widget.section} · ${widget.stream}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // 2. Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgency Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242C51) : const Color(0xFFF5F6FF),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: isDark ? const Color(0xFF384878) : const Color(0xFFE2E7FC),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                urgencyLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF384BA1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.reasonCodes.isNotEmpty
                                    ? widget.reasonCodes.join(' · ')
                                    : 'Performance alert based on recent synced diagnostic tests.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: urgencyBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.accuracyPct}% 30d',
                            style: TextStyle(
                              color: urgencyColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Data Tabs
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.protoLine(context)),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('Overview', 0, isDark),
                        _buildTabButton('Weak Topics', 1, isDark),
                        _buildTabButton('Activity', 2, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab Contents
                  if (_selectedTab == 0) _buildOverviewTab(isDark),
                  if (_selectedTab == 1) _buildWeakTopicsTab(isDark),
                  if (_selectedTab == 2) _buildActivityTab(isDark),

                  const SizedBox(height: 24),
                  // Transparency notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF242C51) : const Color(0xFFF0F3FF),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isDark ? const Color(0xFF384878) : const Color(0xFFDFE5FF),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF5B66A8)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Spaced-repetition memory stability stays device-local; cloud figures contain synced attempts only. No private contact or billing information is displayed.',
                            style: TextStyle(fontSize: 10, color: Color(0xFF5B66A8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.protoLine(context)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.favorite_border_rounded, size: 16),
                  label: const Text('Log Intervention'),
                  onPressed: widget.onLogIntervention,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Assign Practice'),
                  onPressed: widget.onAssignPractice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.protoBrand,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, bool isDark) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.protoBrand : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? AppTheme.protoBrand
                : (isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricBlock(
                '30-DAY ACCURACY',
                '${widget.accuracyPct}%',
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricBlock(
                'UNMASTERED MISTAKES',
                '${widget.mistakesCount}',
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Observed Accuracy Over Time',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
          ),
        ),
        const SizedBox(height: 8),
        _buildSparklineChart(isDark),
        const SizedBox(height: 20),
        Text(
          'Recommended Next Action',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.mistakesCount >= 5
              ? 'Review the mistake notebook together and assign a focused drill.'
              : widget.accuracyPct < 70
                  ? 'Assign targeted remedial practice on weak topics.'
                  : 'Monitor recent practice evidence and encourage consistent mock sessions.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBlock(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.protoSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.protoLine(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF72809A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparklineChart(bool isDark) {
    final trend = widget.accuracyTrend ?? [55.0, 58.0, 52.0, 48.0, widget.accuracyPct.toDouble()];
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.protoLine(context)),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 70),
        painter: _SparklinePainter(trend, isDark),
      ),
    );
  }

  Widget _buildWeakTopicsTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Weak Curriculum Unit',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          widget.primaryWeakTopic,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${widget.mistakesCount} active unmastered mistake records recorded for this topic. Assign a targeted 15-question practice set or conduct an in-person notebook review.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab(bool isDark) {
    return Column(
      children: [
        _buildActivityRow(
          Icons.calendar_today_rounded,
          'Last Recorded Practice',
          '${widget.lastActiveDays} days ago',
          isDark,
        ),
        const SizedBox(height: 12),
        _buildActivityRow(
          Icons.sync_rounded,
          'Last Cloud Sync Evidence',
          '${widget.lastSyncDays} days ago',
          isDark,
        ),
        if (widget.academicNotes != null) ...[
          const SizedBox(height: 12),
          _buildActivityRow(
            Icons.notes_rounded,
            'Teacher Academic Observation',
            widget.academicNotes!,
            isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildActivityRow(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2B3869) : AppTheme.protoBrandLight,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AppTheme.protoBrand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final bool isDark;

  _SparklinePainter(this.values, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = AppTheme.protoBrand
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / range) * (size.height - 12) - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.isDark != isDark;
}
