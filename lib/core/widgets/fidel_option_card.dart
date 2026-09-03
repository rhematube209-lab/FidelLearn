import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum FidelOptionState {
  unselected,
  selected,
  correct,
  incorrect,
}

/// Tactile, modern multiple-choice option card for exam runners and solution reviews.
class FidelOptionCard extends StatelessWidget {
  final String label; // A, B, C, D
  final String textEn;
  final String? textAm;
  final FidelOptionState state;
  final VoidCallback? onTap;

  const FidelOptionCard({
    super.key,
    required this.label,
    required this.textEn,
    this.textAm,
    this.state = FidelOptionState.unselected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color border;
    Color letterBg;
    Color letterFg;
    Color textColor;

    switch (state) {
      case FidelOptionState.unselected:
        bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
        border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
        letterBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        letterFg = isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft;
        textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
        break;

      case FidelOptionState.selected:
        bg = isDark ? const Color(0x264F46E5) : const Color(0x124F46E5);
        border = AppTheme.brand;
        letterBg = AppTheme.brandStrong;
        letterFg = Colors.white;
        textColor = isDark ? Colors.white : AppTheme.lightText;
        break;

      case FidelOptionState.correct:
        bg = isDark ? const Color(0x2610B981) : const Color(0x1410B981);
        border = AppTheme.green;
        letterBg = AppTheme.green;
        letterFg = Colors.white;
        textColor = isDark ? Colors.white : const Color(0xFF065F46);
        break;

      case FidelOptionState.incorrect:
        bg = isDark ? const Color(0x26EF4444) : const Color(0x14EF4444);
        border = AppTheme.danger;
        letterBg = AppTheme.danger;
        letterFg = Colors.white;
        textColor = isDark ? Colors.white : const Color(0xFF991B1B);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: border,
                width: state == FidelOptionState.unselected ? 1.0 : 1.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option Letter Badge (A, B, C, D)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: letterBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: letterFg,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Question Choice Text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          textEn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: state == FidelOptionState.selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: textColor,
                            height: 1.4,
                          ),
                        ),
                        if (textAm != null && textAm!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            textAm!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Trailing Icon for correct/incorrect verification
                if (state == FidelOptionState.correct)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Icon(Icons.check_circle, color: AppTheme.green, size: 20),
                  )
                else if (state == FidelOptionState.incorrect)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Icon(Icons.cancel, color: AppTheme.danger, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
