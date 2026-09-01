import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';

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
  late int _grade;
  late String _stream;
  late String _lang;
  bool _isLoading = false;
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
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .register(
            phone: _phoneController.text.trim(),
            pass: _passController.text.trim(),
            name: _nameController.text.trim().isEmpty
                ? 'Student'
                : _nameController.text.trim(),
            grade: _grade,
            stream: _stream,
            lang: _lang,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('AuthFailure(')) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join FidelLearn',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Get 50 free Study Coins and start practicing offline.',
                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.errorRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.errorRed,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name / Screen Name',
                  hintText: 'e.g. Yonas T.',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+251911223344',
                  prefixIcon: Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (min. 6 characters)',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Account & Earn 50 Coins'),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already registered?',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Sign In'),
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
