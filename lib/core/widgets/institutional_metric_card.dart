import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum InstitutionalMetricTone {
  brand,
  gold,
  red,
  green,
}

class InstitutionalMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final InstitutionalMetricTone tone;
  final VoidCallback? onTap;

  const InstitutionalMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.tone = InstitutionalMetricTone.brand,
    this.onTap,
  });

  @override
  State<InstitutionalMetricCard> createState() =>
      _InstitutionalMetricCardState();
}

class _InstitutionalMetricCardState extends State<InstitutionalMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.protoSurface(context);
    final borderColor = AppTheme.protoLine(context);

    Color iconBg;
    Color iconColor;

    switch (widget.tone) {
      case InstitutionalMetricTone.gold:
        iconBg = isDark
            ? const Color(0xFF4C3B28)
            : AppTheme.protoWarnLight;
        iconColor = AppTheme.protoWarn;
        break;
      case InstitutionalMetricTone.red:
        iconBg = isDark
            ? const Color(0xFF4B303A)
            : AppTheme.protoBadLight;
        iconColor = AppTheme.protoBad;
        break;
      case InstitutionalMetricTone.green:
        iconBg = isDark
            ? const Color(0xFF193F3D)
            : AppTheme.protoGoodLight;
        iconColor = AppTheme.protoGood;
        break;
      case InstitutionalMetricTone.brand:
        iconBg = isDark
            ? const Color(0xFF2B3869)
            : AppTheme.protoBrandLight;
        iconColor = AppTheme.protoBrand;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          transform: _isHovered && widget.onTap != null
              ? (Matrix4.identity()..translate(0, -2, 0))
              : Matrix4.identity(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 110),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.protoRadius),
            border: Border.all(
              color: _isHovered && widget.onTap != null
                  ? AppTheme.protoBrand.withOpacity(0.5)
                  : borderColor,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: isDark
                          ? const Color(0x330B1024)
                          : const Color(0x132B3874),
                      blurRadius: 26,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : AppTheme.protoCardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Metric Head (Title + Tinted Icon Box)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.protoMutedDark : const Color(0xFF66738E),
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 2. Metric Number
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // 3. Metric Subtext
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
