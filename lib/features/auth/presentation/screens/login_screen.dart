import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/user_profile.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final int? initialGrade;
  final String? initialStream;
  final String? initialLang;

  const LoginScreen({
    super.key,
    this.initialGrade,
    this.initialStream,
    this.initialLang,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '+251911223344');
  final _passController = TextEditingController(text: 'password123');

  late String _lang;
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _lang = widget.initialLang ?? 'en';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final pass = _passController.text.trim();

    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
      setState(() => _errorMessage = 'Please enter a valid Ethiopian phone number.');
      return;
    }

    if (pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(currentUserProvider.notifier).login(phone, pass);

      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;

      if (mounted) {
        if (user != null) {
          switch (user.role) {
            case UserRole.teacher:
              context.go('/teacher');
              break;
            case UserRole.schoolAdmin:
              context.go('/school_admin');
              break;
            case UserRole.platformAdmin:
              context.go('/admin');
              break;
            case UserRole.student:
              context.go('/home');
              break;
          }
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is AuthFailure) {
          msg = e.message;
        } else if (msg.contains('AuthFailure(')) {
          msg = msg.replaceAll('AuthFailure(', '').replaceAll(')', '');
        } else {
          msg = msg
              .replaceAll('Exception: ', '')
              .replaceAll('Failure: ', '')
              .replaceAll('minified:', '')
              .trim();
        }
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final isAmharic = _lang == 'am';
    final recoveryPhoneController = TextEditingController(text: _phoneController.text);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAmharic ? 'የይለፍ ቃል መልሰው ያግኙ' : 'Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAmharic
                  ? 'የተመዘገቡበትን ስልክ ቁጥር ያስገቡ። የማረጋገጫ ኮድ ይላክልዎታል።'
                  : 'Enter your registered phone number. A verification OTP or recovery link will be provided.',
              style: const TextStyle(fontSize: 13, color: AppTheme.darkMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: recoveryPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: isAmharic ? 'ስልክ ቁጥር' : 'Phone Number',
                prefixIcon: const Icon(Icons.phone_android),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAmharic ? 'ይቅር' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isAmharic
                        ? 'የይለፍ ቃል ማስተካከያ መረጃ ወደ ስልክዎ ተልኳል'
                        : 'Password recovery instructions sent for ${recoveryPhoneController.text.trim()}',
                  ),
                  backgroundColor: AppTheme.brand,
                ),
              );
            },
            child: Text(isAmharic ? 'ላክ' : 'Send Recovery'),
          ),
        ],
      ),
    );
  }

  void _quickFillDemo(String phone, String pass) {
    setState(() {
      _phoneController.text = phone;
      _passController.text = pass;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAmharic = _lang == 'am';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAmharic ? 'ግባ (Log In)' : 'Log In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _lang = isAmharic ? 'en' : 'am';
              });
            },
            child: Text(
              isAmharic ? 'English' : 'አማርኛ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                isAmharic ? 'እንኳን ደህና መጡ' : 'Welcome Back',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAmharic
                    ? 'በስልክ ቁጥርዎ በመግባት የፈተና ውጤትዎንና የጥናት ሳንቲሞችን ያግኙ።'
                    : 'Sign in with your Ethiopian phone number to sync your practice exams and Study Coins.',
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.errorRed.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Phone Number Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isAmharic ? 'ስልክ ቁጥር' : 'Ethiopian Phone Number',
                  hintText: '+251 911 223 344',
                  prefixIcon: const Icon(Icons.phone_android),
                  helperText: isAmharic ? 'ምሳሌ: +251 9... ወይም 09...' : 'e.g. +251 9... or 09...',
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passController,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: isAmharic ? 'የይለፍ ቃል' : 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog(context),
                  child: Text(
                    isAmharic ? 'የይለፍ ቃል ረሱ?' : 'Forgot Password?',
                    style: const TextStyle(fontSize: 13, color: AppTheme.brand),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isAmharic ? 'ግባ (Sign In)' : 'Sign In',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),

              // Quick Fill Test Accounts
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceStrong.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAmharic ? 'የሙከራ መለያዎች (Demo Accounts)' : 'Quick-Fill Demo Accounts',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Text('🎓'),
                          label: const Text('Student', style: TextStyle(fontSize: 11)),
                          onPressed: () => _quickFillDemo('+251911223344', 'password123'),
                        ),
                        ActionChip(
                          avatar: const Text('👩‍🏫'),
                          label: const Text('Teacher', style: TextStyle(fontSize: 11)),
                          onPressed: () => _quickFillDemo('+251922334455', 'teacherPass123'),
                        ),
                        ActionChip(
                          avatar: const Text('🏛️'),
                          label: const Text('School Admin', style: TextStyle(fontSize: 11)),
                          onPressed: () => _quickFillDemo('+251933445566', 'adminPass123'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAmharic ? 'አዲስ ተጠቃሚ ነዎት?' : "Don't have an account?",
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/register?lang=$_lang');
                    },
                    child: Text(
                      isAmharic ? 'አዲስ መለያ ይክፈቱ' : 'Create Account',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
