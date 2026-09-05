import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/user_profile.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final int? initialGrade;
  final String? initialStream;
  final String? initialLang;

  const RegisterScreen({
    super.key,
    this.initialGrade,
    this.initialStream,
    this.initialLang,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+2519');
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  late int _grade;
  late String _stream;
  late String _lang;
  UserRole _role = UserRole.student;

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _grade = widget.initialGrade ?? 12;
    _stream = widget.initialStream ?? 'natural';
    _lang = widget.initialLang ?? 'en';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final pass = _passController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (name.isEmpty) {
      setState(
          () => _errorMessage = 'Please enter your full name or screen name.');
      return;
    }

    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
      setState(() => _errorMessage =
          'Please enter a valid Ethiopian phone number (e.g. +251 911 223 344).');
      return;
    }

    if (pass.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (pass != confirmPass) {
      setState(
          () => _errorMessage = 'Passwords do not match. Please re-enter.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref
          .read(currentUserProvider.notifier)
          .register(
            phone: phone,
            pass: pass,
            name: name,
            grade: _grade,
            stream: _stream,
            lang: _lang,
          )
          .timeout(const Duration(seconds: 8));

      if (mounted) {
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
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAmharic = _lang == 'am';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAmharic ? 'አዲስ መለያ ይክፈቱ' : 'Create Account'),
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
              // Hero Welcome Pill
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.brandStrong.withOpacity(0.15),
                      AppTheme.brand.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.brand.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAmharic
                                ? 'የ50 የጥናት ሳንቲሞች ስጦታ!'
                                : '50 Free Study Coins!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.brand,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAmharic
                                ? 'መለያ በመክፈት ፈተናዎችን በነፃ ይለማመዱ'
                                : 'Sign up to unlock offline exams & step-by-step solutions.',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.darkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.errorRed.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.errorRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppTheme.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Full Name Field
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText:
                      isAmharic ? 'ሙሉ ስም / ስክሪን ስም' : 'Full Name / Screen Name',
                  hintText: 'e.g. Abebe Balcha',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isAmharic ? 'ስልክ ቁጥር' : 'Ethiopian Phone Number',
                  hintText: '+251 911 223 344',
                  prefixIcon: const Icon(Icons.phone_android),
                  helperText: isAmharic
                      ? 'የኢትዮጵያ ስልክ ቁጥር (+251 ወይም 09...)'
                      : 'Format: +251 9... or 09...',
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passController,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: isAmharic
                      ? 'የይለፍ ቃል (ቢያንስ 6 ፊደላት)'
                      : 'Password (min. 6 characters)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextField(
                controller: _confirmPassController,
                obscureText: _obscureConfirmPass,
                decoration: InputDecoration(
                  labelText: isAmharic ? 'የይለፍ ቃል ያረጋግጡ' : 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPass
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => _obscureConfirmPass = !_obscureConfirmPass),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Educational Grade Selector
              Text(
                isAmharic ? 'የትምህርት ደረጃ ይምረጡ' : 'Select Academic Grade',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [6, 8, 12].map((g) {
                  final isSelected = _grade == g;
                  final label = g == 6
                      ? 'Grade 6\n(PSLCE)'
                      : (g == 8 ? 'Grade 8\n(MSLCE)' : 'Grade 12\n(ESSLCE)');
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.brand.withOpacity(0.2),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _grade = g;
                              if (g != 12) _stream = 'common';
                            });
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Stream Selector (Only for Grade 12)
              if (_grade == 12) ...[
                Text(
                  isAmharic ? 'የትምህርት ዘርፍ (ስትሪም)' : 'Grade 12 Academic Stream',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Text('🧪'),
                        label:
                            Text(isAmharic ? 'የተፈጥሮ ሳይንስ' : 'Natural Science'),
                        selected: _stream == 'natural',
                        selectedColor: AppTheme.green.withOpacity(0.25),
                        onSelected: (val) {
                          if (val) setState(() => _stream = 'natural');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Text('📚'),
                        label:
                            Text(isAmharic ? 'የማህበራዊ ሳይንስ' : 'Social Science'),
                        selected: _stream == 'social',
                        selectedColor: AppTheme.accent.withOpacity(0.25),
                        onSelected: (val) {
                          if (val) setState(() => _stream = 'social');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // Role Selector (Student vs Teacher)
              Text(
                isAmharic ? 'የመለያ ዓይነት' : 'Account Type',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.school, size: 16),
                      label: Text(isAmharic ? 'ተማሪ' : 'Student'),
                      selected: _role == UserRole.student,
                      onSelected: (val) {
                        if (val) setState(() => _role = UserRole.student);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.cast_for_education, size: 16),
                      label: Text(isAmharic ? 'መምህር' : 'Teacher'),
                      selected: _role == UserRole.teacher,
                      onSelected: (val) {
                        if (val) setState(() => _role = UserRole.teacher);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isAmharic
                            ? 'መለያ ክፈትና 50 ሳንቲሞች አግኝ'
                            : 'Create Account & Earn 50 Coins',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAmharic ? 'መለያ አለዎት?' : 'Already have an account?',
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  TextButton(
                    onPressed: () {
                      context.push(
                          '/login?grade=$_grade&stream=$_stream&lang=$_lang');
                    },
                    child: Text(
                      isAmharic ? 'ይግቡ (Sign In)' : 'Sign In',
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
