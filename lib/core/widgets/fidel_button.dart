import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum FidelButtonVariant {
  primary,
  secondary,
  outline,
  danger,
  ghost,
}

/// Standardized action button supporting icons, loading states, and full-width layouts.
class FidelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FidelButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;

  const FidelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = FidelButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case FidelButtonVariant.primary:
        bg = AppTheme.brandStrong;
        fg = Colors.white;
        break;
      case FidelButtonVariant.secondary:
        bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        fg = isDark ? AppTheme.darkText : AppTheme.lightText;
        break;
      case FidelButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppTheme.darkText : AppTheme.lightText;
        borderSide = BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1.5,
        );
        break;
      case FidelButtonVariant.danger:
        bg = AppTheme.danger;
        fg = Colors.white;
        break;
      case FidelButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppTheme.brand : AppTheme.brandStrong;
        break;
    }

    final buttonHeight = height ?? 46.0;

    Widget child;
    if (isLoading) {
      child = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      child = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ),
        ],
      );
    }

    final btn = Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: borderSide == BorderSide.none ? null : Border.fromBorderSide(borderSide),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Center(child: child),
          ),
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
