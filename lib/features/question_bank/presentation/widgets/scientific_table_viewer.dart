import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Responsive, theme-aware scientific table viewer for exam results,
/// chemical properties, geographic data, and economic charts.
class ScientificTableViewer extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final String? caption;

  const ScientificTableViewer({
    super.key,
    required this.headers,
    required this.rows,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty && rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final headerTextColor =
        isDark ? AppTheme.darkText : const Color(0xFF0F172A);
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0);
    final rowTextColor =
        isDark ? AppTheme.darkTextSoft : const Color(0xFF334155);
    final zebraBg = isDark ? const Color(0x0DFFFFFF) : const Color(0x05000000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null && caption!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              caption!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(headerBg),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.0,
                color: headerTextColor,
                letterSpacing: 0.3,
              ),
              dataTextStyle: TextStyle(
                fontSize: 13.0,
                color: rowTextColor,
              ),
              horizontalMargin: 16.0,
              columnSpacing: 24.0,
              border: TableBorder(
                horizontalInside: BorderSide(color: borderColor, width: 1),
                verticalInside: BorderSide(color: borderColor, width: 0.6),
              ),
              columns: headers
                  .map(
                    (h) => DataColumn(
                      label: Text(h),
                    ),
                  )
                  .toList(),
              rows: rows.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                final isZebra = idx % 2 == 1;

                return DataRow(
                  color: WidgetStateProperty.all(
                      isZebra ? zebraBg : Colors.transparent),
                  cells: row.map((cellText) {
                    return DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(cellText),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
