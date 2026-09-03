import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/fidel_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _selectedGrade = 12;
  String _selectedStream = 'natural';
  String _selectedLang = 'en';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Brand Icon & Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.brandStrong,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: const Center(
                          child: Text(
                            'ፊ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FidelLearn',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkText : AppTheme.lightText,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            _selectedLang == 'am'
                                ? 'የኢትዮጵያ ሀገር አቀፍ ፈተና ዝግጅት'
                                : 'Ethiopian National Exam Preparation Platform',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text(
                    _selectedLang == 'am'
                        ? 'የጥናት መገለጫዎን ያዋቅሩ'
                        : 'Personalize Your Study Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedLang == 'am'
                        ? 'ያለ ኢንተርኔት የሚሰሩ ፈተናዎች፣ የተረጋገጡ ማብራሪያዎች እና የደረጃ ማሻሻያ ውድድሮች።'
                        : 'Offline national mock exams, step-by-step verified explanations, weak-topic diagnostics, and Exam Ghost.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? AppTheme.darkTextSoft : AppTheme.lightTextSoft,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 1. Language Picker
                  _buildSectionTitle(
                    _selectedLang == 'am' ? 'ቋንቋ ይምረጡ' : 'Preferred Language',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectCard(
                          title: 'English',
                          subtitle: 'Standard exam terminology',
                          isSelected: _selectedLang == 'en',
                          isDark: isDark,
                          onTap: () {
                            setState(() => _selectedLang = 'en');
                            ref.read(localeProvider.notifier).state = const Locale('en');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSelectCard(
                          title: 'አማርኛ',
                          subtitle: 'የአማርኛ ትርጉም እና ማብራሪያ',
                          isSelected: _selectedLang == 'am',
                          isDark: isDark,
                          onTap: () {
                            setState(() => _selectedLang = 'am');
                            ref.read(localeProvider.notifier).state = const Locale('am');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Target Grade Picker
                  _buildSectionTitle(
                    _selectedLang == 'am' ? 'ክፍል ይምረጡ' : 'Select Target Grade',
                    isDark,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSelectCard(
                          title: 'Grade 6',
                          subtitle: 'PSLCE Exam',
                          isSelected: _selectedGrade == 6,
                          isDark: isDark,
                          onTap: () => setState(() {
                            _selectedGrade = 6;
                            _selectedStream = 'general';
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSelectCard(
                          title: 'Grade 8',
                          subtitle: 'Regional Exam',
                          isSelected: _selectedGrade == 8,
                          isDark: isDark,
                          onTap: () => setState(() {
                            _selectedGrade = 8;
                            _selectedStream = 'general';
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSelectCard(
                          title: 'Grade 12',
                          subtitle: 'ESSLCE Exam',
                          isSelected: _selectedGrade == 12,
                          isDark: isDark,
                          onTap: () => setState(() {
                            _selectedGrade = 12;
                            _selectedStream = 'natural';
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Stream Picker (Grade 12)
                  if (_selectedGrade == 12) ...[
                    _buildSectionTitle(
                      _selectedLang == 'am' ? 'የትምህርት ዘርፍ' : 'Academic Stream',
                      isDark,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSelectCard(
                            title: _selectedLang == 'am'
                                ? 'የተፈጥሮ ሳይንስ'
                                : 'Natural Science',
                            subtitle: 'Math, Physics, Chem, Bio, Apt.',
                            isSelected: _selectedStream == 'natural',
                            isDark: isDark,
                            onTap: () => setState(() => _selectedStream = 'natural'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectCard(
                            title: _selectedLang == 'am'
                                ? 'የማህበራዊ ሳይንስ'
                                : 'Social Science',
                            subtitle: 'Math, Hist, Geo, Econ, Apt.',
                            isSelected: _selectedStream == 'social',
                            isDark: isDark,
                            onTap: () => setState(() => _selectedStream = 'social'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ] else
                    const SizedBox(height: 16),

                  // Action Buttons
                  FidelButton(
                    label: _selectedLang == 'am'
                        ? 'ግባ / ተመዝገብ'
                        : 'Continue to Sign In / Register',
                    onPressed: () {
                      context.push(
                        '/login?grade=$_selectedGrade&stream=$_selectedStream&lang=$_selectedLang',
                      );
                    },
                    isFullWidth: true,
                    height: 48,
                  ),
                  const SizedBox(height: 12),
                  FidelButton(
                    label: _selectedLang == 'am'
                        ? 'እንደ እንግዳ ጀምር'
                        : 'Try Demo as Guest (Instant Offline)',
                    variant: FidelButtonVariant.outline,
                    onPressed: () async {
                      await ref.read(currentUserProvider.notifier).register(
                        phone: '+251911000000',
                        pass: 'demo123',
                        name: 'Guest Student',
                        grade: _selectedGrade,
                        stream: _selectedStream,
                        lang: _selectedLang,
                      );
                      if (context.mounted) {
                        context.go('/home');
                      }
                    },
                    isFullWidth: true,
                    height: 48,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkText : AppTheme.lightText,
      ),
    );
  }

  Widget _buildSelectCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bg = isSelected
        ? (isDark ? const Color(0x264F46E5) : const Color(0xFFEEF2FF))
        : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface);

    final border = isSelected
        ? AppTheme.brand
        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : AppTheme.brandStrong)
                            : (isDark ? AppTheme.darkText : AppTheme.lightText),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.brand,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
