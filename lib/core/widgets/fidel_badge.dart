import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum FidelBadgeVariant {
  primary,
  secondary,
  success,
  warning,
  danger,
  info,
  gold,
  neutral,
}

/// A compact, modern status badge pill with color tints.
class FidelBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final FidelBadgeVariant variant;
  final bool isSmall;

  const FidelBadge({
    super.key,
    required this.text,
    this.icon,
    this.variant = FidelBadgeVariant.primary,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color fg;
    Color bg;
    Color border;

    switch (variant) {
      case FidelBadgeVariant.primary:
        fg = isDark ? const Color(0xFFA5B4FC) : AppTheme.brandStrong;
        bg = isDark ? const Color(0x264F46E5) : const Color(0x1A4F46E5);
        border = isDark ? const Color(0x404F46E5) : const Color(0x334F46E5);
        break;
      case FidelBadgeVariant.success:
        fg = isDark ? const Color(0xFF6EE7B7) : AppTheme.greenDark;
        bg = isDark ? const Color(0x2610B981) : const Color(0x1A10B981);
        border = isDark ? const Color(0x4010B981) : const Color(0x3310B981);
        break;
      case FidelBadgeVariant.warning:
        fg = isDark ? const Color(0xFFFCD34D) : AppTheme.accentDark;
        bg = isDark ? const Color(0x26F59E0B) : const Color(0x1AF59E0B);
        border = isDark ? const Color(0x40F59E0B) : const Color(0x33F59E0B);
        break;
      case FidelBadgeVariant.danger:
        fg = isDark ? const Color(0xFFFCA5A5) : AppTheme.dangerDark;
        bg = isDark ? const Color(0x26EF4444) : const Color(0x1AEF4444);
        border = isDark ? const Color(0x40EF4444) : const Color(0x33EF4444);
        break;
      case FidelBadgeVariant.info:
        fg = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
        bg = isDark ? const Color(0x263B82F6) : const Color(0x1A3B82F6);
        border = isDark ? const Color(0x403B82F6) : const Color(0x333B82F6);
        break;
      case FidelBadgeVariant.gold:
        fg = isDark ? const Color(0xFFFDE68A) : AppTheme.accentDark;
        bg = isDark ? const Color(0x26F59E0B) : const Color(0x24F59E0B);
        border = isDark ? const Color(0x4DF59E0B) : const Color(0x40F59E0B);
        break;
      case FidelBadgeVariant.secondary:
      case FidelBadgeVariant.neutral:
        fg = isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft;
        bg = isDark ? const Color(0x2664748B) : const Color(0x1A64748B);
        border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
        break;
    }

    final verticalPadding = isSmall ? 2.5 : 4.0;
    final horizontalPadding = isSmall ? 8.0 : 10.0;
    final fontSize = isSmall ? 10.5 : 11.5;
    final iconSize = isSmall ? 12.0 : 13.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
