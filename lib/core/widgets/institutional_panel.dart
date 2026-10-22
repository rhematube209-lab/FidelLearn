import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InstitutionalPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget body;
  final EdgeInsetsGeometry padding;

  const InstitutionalPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.body,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.protoSurface(context),
        borderRadius: BorderRadius.circular(AppTheme.protoRadius),
        border: Border.all(
          color: AppTheme.protoLine(context),
          width: 1,
        ),
        boxShadow: AppTheme.protoCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark ? AppTheme.protoInkDark : AppTheme.protoInkLight,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.protoMutedDark : AppTheme.protoMutedLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.protoLine(context)),
          // Panel Body
          Padding(
            padding: padding,
            child: body,
          ),
        ],
      ),
    );
  }
}
