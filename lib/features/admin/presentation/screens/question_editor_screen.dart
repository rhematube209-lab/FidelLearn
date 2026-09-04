import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../question_bank/domain/models/question_models.dart';

class QuestionEditorScreen extends ConsumerStatefulWidget {
  const QuestionEditorScreen({super.key});

  @override
  ConsumerState<QuestionEditorScreen> createState() =>
      _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends ConsumerState<QuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _promptEnController = TextEditingController(
    text: r'Find the derivative of f(x) = 3x^4 - 5x^2 + 7',
  );
  final TextEditingController _promptAmController = TextEditingController(
    text: r'የ f(x) = 3x^4 - 5x^2 + 7 ዴሪቬቲቭ ፈልጉ',
  );
  final TextEditingController _solutionController = TextEditingController(
    text:
        'Step 1: Apply the power rule: d/dx(x^n) = n*x^(n-1).\nStep 2: f\'(x) = 12x^3 - 10x.\nStep 3: Derivative of constant 7 is 0.',
  );
  final TextEditingController _keyConceptController = TextEditingController(
    text: 'Power Rule of Differentiation',
  );
  final TextEditingController _pitfallController = TextEditingController(
    text: 'Forgetting to decrease exponent by 1.',
  );

  String _selectedSubjectId = 'math_g12';
  int _correctChoiceIndex = 0;

  final List<TextEditingController> _choiceControllers = [
    TextEditingController(text: '12x^3 - 10x'),
    TextEditingController(text: '12x^4 - 10x^2'),
    TextEditingController(text: '7x^3 - 10x'),
    TextEditingController(text: '12x^3 - 10x + 7'),
  ];

  final List<TextEditingController> _rationaleControllers = [
    TextEditingController(text: 'Correct power rule application'),
    TextEditingController(text: 'Forgot to reduce exponents'),
    TextEditingController(text: 'Added coefficients instead of multiplying'),
    TextEditingController(text: 'Forgot derivative of constant is 0'),
  ];

  @override
  void dispose() {
    _promptEnController.dispose();
    _promptAmController.dispose();
    _solutionController.dispose();
    _keyConceptController.dispose();
    _pitfallController.dispose();
    for (final c in _choiceControllers) {
      c.dispose();
    }
    for (final r in _rationaleControllers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    final adminRepo = ref.read(adminRepositoryProvider);

    final choices = List.generate(4, (i) {
      final labelLetter = String.fromCharCode(65 + i);
      return AnswerChoice(
        id: 'c_${i + 1}',
        label: labelLetter,
        textEn: _choiceControllers[i].text.trim(),
        textAm: _choiceControllers[i].text.trim(),
        isCorrect: i == _correctChoiceIndex,
      );
    });

    final now = DateTime.now();
    final question = Question(
      id: 'q_authored_${now.millisecondsSinceEpoch}',
      subjectId: _selectedSubjectId,
      unitId: 'unit_calc',
      topicId: 'math_derivatives',
      grade: 12,
      stream: 'natural',
      difficulty: 'medium',
      questionTextEn: _promptEnController.text.trim(),
      questionTextAm: _promptAmController.text.trim(),
      verificationStatus: VerificationStatus.reviewRequired,
      sourceName: 'FidelLearn Model Exam Prep 2026',
      contentVersion: 1,
      choices: choices,
      explanation: Explanation(
        solutionTextEn: _solutionController.text.trim(),
        solutionTextAm: _solutionController.text.trim(),
        keyConcept: _keyConceptController.text.trim(),
        commonPitfall: _pitfallController.text.trim(),
      ),
    );

    await adminRepo.saveQuestion(
      question: question,
      actorUserId: user?.id ?? 'admin_root',
      actorRole: 'platform_admin',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question submitted for quality verification! 📝'),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Author Verified Question'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Picker
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(labelText: 'Target Subject'),
                items: const [
                  DropdownMenuItem(
                    value: 'math_g12',
                    child: Text('Grade 12 Mathematics'),
                  ),
                  DropdownMenuItem(
                    value: 'aptitude_g12',
                    child: Text('Grade 12 Scholastic Aptitude'),
                  ),
                ],
                onChanged: (val) => setState(
                  () => _selectedSubjectId = val ?? 'math_g12',
                ),
              ),
              const SizedBox(height: 16),

              // Prompts
              TextFormField(
                controller: _promptEnController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Question Prompt (English / LaTeX)',
                  hintText: 'e.g. Find the limit...',
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _promptAmController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Question Prompt (Amharic)',
                  hintText: 'የጥያቄው ጽሁፍ በአማርኛ...',
                ),
              ),
              const SizedBox(height: 24),

              // Answer Choices & Distractors
              const Text(
                'Choices & Distractor Explanations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(4, (i) {
                final isCorrect = _correctChoiceIndex == i;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: _correctChoiceIndex,
                              activeColor: AppTheme.successGreen,
                              onChanged: (val) => setState(
                                () => _correctChoiceIndex = val ?? 0,
                              ),
                            ),
                            Text(
                              isCorrect
                                  ? 'Correct Choice'
                                  : 'Distractor ${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? AppTheme.successGreen
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        TextFormField(
                          controller: _choiceControllers[i],
                          decoration: InputDecoration(
                            labelText:
                                'Choice Label (${String.fromCharCode(65 + i)})',
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _rationaleControllers[i],
                          decoration: const InputDecoration(
                            labelText:
                                'Why is this choice correct / wrong? (Rationale)',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Solutions & Pedagogy
              const Text(
                'Verified Solution & Pedagogy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _solutionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Step-by-Step Solution (LaTeX supported)',
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keyConceptController,
                decoration: const InputDecoration(
                  labelText: 'Key Concept / Theorem',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pitfallController,
                decoration: const InputDecoration(
                  labelText: 'Common Student Pitfall',
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitQuestion,
                  icon: const Icon(Icons.check),
                  label: const Text('Submit to Verification Pipeline'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
