import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable modern card with subtle border, theme-adaptive surface, and optional tap interaction.
class FidelCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Widget? header;

  const FidelCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.boxShadow,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppTheme.radiusMd;
    final bg = backgroundColor ??
        (isDark ? AppTheme.darkSurface : AppTheme.lightSurface);
    final border = borderColor ??
        (isDark ? AppTheme.darkBorder : AppTheme.lightBorder);
    final shadows = boxShadow ??
        (isDark ? AppTheme.cardShadowDark : AppTheme.cardShadowLight);

    final content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(18.0),
            child: header == null
                ? child
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      header!,
                      const SizedBox(height: 14),
                      child,
                    ],
                  ),
          ),
        ),
      ),
    );

    return content;
  }
}
