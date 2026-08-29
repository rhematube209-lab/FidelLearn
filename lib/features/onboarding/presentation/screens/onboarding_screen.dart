import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Brand Icon & Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'ፊ',
                        style: TextStyle(
                          fontSize: 26,
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
                      const Text(
                        'FidelLearn',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        _selectedLang == 'am'
                            ? 'የኢትዮጵያ ሀገር አቀፍ ፈተና ዝግጅት'
                            : 'Ethiopian National Exam Prep',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),

              Text(
                _selectedLang == 'am'
                    ? 'የጥናት መገለጫዎን ያዋቅሩ'
                    : 'Personalize Your Exam Preparation',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedLang == 'am'
                    ? 'ያለ ኢንተርኔት የሚሰሩ ፈተናዎች፣ የተረጋገጡ ማብራሪያዎች እና የደረጃ ማሻሻያ ውድድሮች።'
                    : 'Offline mock exams, verified step-by-step solutions, weak-topic diagnostics, and Exam Ghost.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // 1. Language Picker
              _buildSectionTitle(
                _selectedLang == 'am' ? 'ቋንቋ ይምረጡ' : 'Preferred Language',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectCard(
                      title: 'English',
                      subtitle: 'Exam standard',
                      isSelected: _selectedLang == 'en',
                      onTap: () {
                        setState(() => _selectedLang = 'en');
                        ref.read(localeProvider.notifier).state = const Locale(
                          'en',
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSelectCard(
                      title: 'አማርኛ',
                      subtitle: 'የአማርኛ ትርጉም',
                      isSelected: _selectedLang == 'am',
                      onTap: () {
                        setState(() => _selectedLang = 'am');
                        ref.read(localeProvider.notifier).state = const Locale(
                          'am',
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Grade Picker
              _buildSectionTitle(
                _selectedLang == 'am' ? 'ክፍል ይምረጡ' : 'Select Target Grade',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectCard(
                      title: 'Grade 6',
                      subtitle: 'PSLCE Exam',
                      isSelected: _selectedGrade == 6,
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
                      subtitle: 'Ministry Exam',
                      isSelected: _selectedGrade == 8,
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
                      subtitle: 'National Exam',
                      isSelected: _selectedGrade == 12,
                      onTap: () => setState(() {
                        _selectedGrade = 12;
                        _selectedStream = 'natural';
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Stream Picker (if Grade 12)
              if (_selectedGrade == 12) ...[
                _buildSectionTitle(
                  _selectedLang == 'am' ? 'የትምህርት ዘርፍ' : 'Academic Stream',
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
                        onTap: () =>
                            setState(() => _selectedStream = 'natural'),
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
                        onTap: () => setState(() => _selectedStream = 'social'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
              ],

              // Action Buttons
              ElevatedButton(
                onPressed: () {
                  context.push(
                    '/login?grade=$_selectedGrade&stream=$_selectedStream&lang=$_selectedLang',
                  );
                },
                child: Text(
                  _selectedLang == 'am'
                      ? 'ግባ / ተመዝገብ'
                      : 'Continue to Sign In / Register',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  // Instant guest demo profile
                  await ref
                      .read(currentUserProvider.notifier)
                      .register(
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
                child: Text(
                  _selectedLang == 'am'
                      ? 'እንደ እንግዳ ጀምር'
                      : 'Try Demo as Guest (Instant Offline)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildSelectCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : const Color(0xFFCBD5E1),
            width: isSelected ? 2 : 1,
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.textDark,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryGreen,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
