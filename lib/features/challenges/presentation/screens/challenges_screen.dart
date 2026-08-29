import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../exams/domain/models/exam_models.dart';
import '../../../exams/domain/services/exam_engine.dart';
import '../../domain/models/challenge_models.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  List<Challenge> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final repo = ref.read(challengeRepositoryProvider);

    if (user != null) {
      final list = await repo.getActiveChallenges(grade: user.grade);
      if (mounted) {
        setState(() {
          _challenges = list;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final repo = ref.read(challengeRepositoryProvider);
    final challenge = await repo.getChallengeByInviteCode(code);

    if (!mounted) return;

    if (challenge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No challenge found with that code.')),
      );
      return;
    }

    await repo.joinChallenge(
      challengeId: challenge.id,
      userId: user.id,
      displayName: user.displayName,
    );

    _codeController.clear();
    await _loadChallenges();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${challenge.titleEn}"!')),
      );
    }
  }

  Future<void> _startChallenge(Challenge challenge) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final contentRepo = ref.read(contentRepositoryProvider);
    final examRepo = ref.read(examRepositoryProvider);
    if (user == null) return;

    // Fetch questions for challenge
    final questions = await contentRepo.getQuestions(
      grade: challenge.grade,
      subjectId: challenge.subjectId,
      limit: challenge.totalQuestions,
    );

    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions available for this challenge.')),
        );
      }
      return;
    }

    final exam = Exam(
      id: challenge.id,
      title: challenge.titleEn,
      examType: ExamType.practice,
      grade: challenge.grade,
      stream: user.stream,
      subjectId: challenge.subjectId,
      timeLimitMinutes: challenge.timeLimitMinutes,
      totalQuestions: questions.length,
      questions: questions,
      createdAt: DateTime.now(),
    );

    final attempt = ExamEngine.startAttempt(
      attemptId: 'att_chal_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      exam: exam,
    );

    await examRepo.saveActiveAttempt(attempt);

    if (mounted) {
      await context.push(
        '/exam_runner',
        extra: {'exam': exam, 'attempt': attempt},
      );
      if (mounted) {
        await _loadChallenges();
      }
    }
  }

  void _showCreateChallengeDialog() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final titleController = TextEditingController(text: 'Math Speed Duel');
    String selectedSubject = 'math_g12';
    String selectedSubjectName = 'Mathematics';
    int questionCount = 10;
    int timeLimit = 10;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Friend Challenge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Title',
                    hintText: 'e.g. Calculus Showdown',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButton<String>(
                  value: selectedSubject,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'math_g12', child: Text('Grade 12 Mathematics')),
                    DropdownMenuItem(value: 'aptitude_g12', child: Text('Grade 12 Scholastic Aptitude')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        selectedSubject = val;
                        selectedSubjectName =
                            val == 'math_g12' ? 'Mathematics' : 'Scholastic Aptitude';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          DropdownButton<int>(
                            value: questionCount,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 5, child: Text('5 Questions')),
                              DropdownMenuItem(value: 10, child: Text('10 Questions')),
                              DropdownMenuItem(value: 15, child: Text('15 Questions')),
                            ],
                            onChanged: (val) => setDialogState(() => questionCount = val ?? 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          DropdownButton<int>(
                            value: timeLimit,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 5, child: Text('5 Mins')),
                              DropdownMenuItem(value: 10, child: Text('10 Mins')),
                              DropdownMenuItem(value: 15, child: Text('15 Mins')),
                            ],
                            onChanged: (val) => setDialogState(() => timeLimit = val ?? 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(challengeRepositoryProvider);
                final created = await repo.createFriendChallenge(
                  creatorUserId: user.id,
                  creatorName: user.displayName,
                  title: titleController.text.trim(),
                  subjectId: selectedSubject,
                  subjectName: selectedSubjectName,
                  grade: user.grade,
                  totalQuestions: questionCount,
                  timeLimitMinutes: timeLimit,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadChallenges();
                _showCreatedSuccessDialog(created.inviteCode ?? '');
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatedSuccessDialog(String inviteCode) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (alertCtx) => AlertDialog(
        title: const Text('Challenge Created! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with your classmates:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen),
              ),
              child: SelectableText(
                inviteCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(alertCtx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Challenges'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Sponsored 🏆'),
            Tab(text: 'Friend Duels ⚔️'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Join by code banner
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter Invite Code (e.g. FIDEL99)',
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _joinByCode,
                        child: const Text('Join'),
                      ),
                    ],
                  ),
                ),

                // Challenge Lists
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChallengeList(_challenges),
                      _buildChallengeList(
                        _challenges.where((c) => c.challengeType == ChallengeType.sponsored).toList(),
                      ),
                      _buildChallengeList(
                        _challenges.where((c) => c.challengeType == ChallengeType.friend).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateChallengeDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Duel'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildChallengeList(List<Challenge> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No Active Challenges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Create a friend challenge or join via an invite code!', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final chal = list[index];
        final isSponsored = chal.challengeType == ChallengeType.sponsored;

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSponsored
                            ? AppTheme.accentGold.withValues(alpha: 0.15)
                            : AppTheme.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSponsored ? Icons.workspace_premium : Icons.people_outline,
                            size: 14,
                            color: isSponsored ? const Color(0xFFB45309) : AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSponsored ? 'SPONSORED CHAMPIONSHIP' : 'FRIEND DUEL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSponsored ? const Color(0xFFB45309) : AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: AppTheme.accentGold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${chal.prizeCoinPool} Coins',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.accentGoldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  chal.titleEn,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (chal.sponsorName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sponsored by ${chal.sponsorName}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.accentGoldDark, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  chal.descriptionEn,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.quiz_outlined, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${chal.totalQuestions} Questions', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(width: 16),
                    const Icon(Icons.timer_outlined, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${chal.timeLimitMinutes} Mins', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(width: 16),
                    const Icon(Icons.group_outlined, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${chal.participants.length} Players', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _startChallenge(chal),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Enter Challenge'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
