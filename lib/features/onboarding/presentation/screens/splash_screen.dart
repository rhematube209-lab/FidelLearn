import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../school/domain/models/tenant_models.dart';
import '../../../school/presentation/providers/active_school_context_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isSlowResolution = false;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.getCurrentUser();

      if (mounted) {
        if (user != null) {
          try {
            await ref.read(currentUserProvider.notifier).updateProfile(user);
          } catch (_) {}
          if (!mounted) return;

          if (user.role == UserRole.platformAdmin) {
            context.go('/admin');
            return;
          }

          final future = ref
              .read(activeSchoolContextProvider.notifier)
              .resolveContext(user: user);

          ActiveSchoolContext? schoolContext;
          try {
            schoolContext = await future.timeout(const Duration(seconds: 4));
          } on TimeoutException {
            if (mounted) {
              setState(() {
                _isSlowResolution = true;
              });
            }
            // Do not send to /home merely because timeout fired while loading.
            schoolContext = await future;
          }

          if (!mounted) return;

          if (schoolContext.isSchoolAdmin) {
            context.go('/school');
          } else if (schoolContext.isTeacher) {
            context.go('/teacher');
          } else {
            // Context has actually resolved as independent or unauthorized
            context.go('/home');
          }
        } else {
          context.go('/login');
        }
      }
    } catch (e) {
      debugPrint('SplashScreen: error checking initial route: $e');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'ፊ',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'FidelLearn',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'National Exam Preparation',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD1E7DD),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentGold),
              strokeWidth: 3,
            ),
            if (_isSlowResolution) ...[
              const SizedBox(height: 16),
              const Text(
                'Checking school membership...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFD1E7DD),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  if (mounted) context.go('/home');
                },
                child: const Text(
                  'Continue to Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
