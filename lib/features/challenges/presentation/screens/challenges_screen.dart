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

    final questions = await contentRepo.getQuestions(
      grade: challenge.grade,
      subjectId: challenge.subjectId,
    );

    if (questions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions found for this challenge.')),
        );
      }
      return;
    }

    final selected = questions.take(10).toList();
    final exam = Exam(
      id: 'exam_${challenge.id}',
      title: challenge.titleEn,
      examType: ExamType.practice,
      grade: challenge.grade,
      stream: user.stream,
      subjectId: challenge.subjectId,
      timeLimitMinutes: 15,
      totalQuestions: selected.length,
      questions: selected,
      createdAt: DateTime.now(),
    );

    final attempt = ExamEngine.startAttempt(
      attemptId: 'att_chal_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      exam: exam,
    );

    await examRepo.saveActiveAttempt(attempt);

    if (mounted) {
      await context.push('/exam_runner', extra: {'exam': exam, 'attempt': attempt});
      if (mounted) await _loadChallenges();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Championship Duels & Tournaments', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 20.0,
                vertical: 28.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Championship Hero Banner
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4C1D95), AppTheme.darkSurfaceStrong],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.brand.withOpacity(0.4)),
                          boxShadow: AppTheme.cardShadowDark,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ETHIO TELECOM NATIONAL STEM GRAND PRIX',
                                      style: TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Compete for 10,000 ETB in Airtime & Study Coins',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Compete against top-ranked secondary students in 15-minute high-intensity national exam duels.',
                                    style: TextStyle(fontSize: 13, color: AppTheme.darkTextSoft),
                                  ),
                                ],
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 24),
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.accent),
                                ),
                                child: const Center(
                                  child: Icon(Icons.emoji_events_rounded, color: AppTheme.accent, size: 48),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Join with Code & Active Duels (50%)
                            Expanded(
                              flex: 50,
                              child: Column(
                                children: [
                                  _buildJoinWithCodeCard(),
                                  const SizedBox(height: 24),
                                  _buildActiveChallengesList(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 28),

                            // Right: Leaderboard & Sponsored Events (50%)
                            Expanded(
                              flex: 50,
                              child: _buildLeaderboardCard(),
                            ),
                          ],
                        )
                      else ...[
                        _buildJoinWithCodeCard(),
                        const SizedBox(height: 20),
                        _buildActiveChallengesList(),
                        const SizedBox(height: 20),
                        _buildLeaderboardCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildJoinWithCodeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter Friend Battle Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Type a 6-digit match code to enter private 1v1 student challenges.', style: TextStyle(fontSize: 12, color: AppTheme.darkMuted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. DUEL-99',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _joinByCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandStrong,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                child: const Text('Join Duel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChallengesList() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live National Match Lobby', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          if (_challenges.isEmpty)
            const Text('No public duels currently waiting in queue.', style: TextStyle(fontSize: 12, color: AppTheme.darkMuted))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _challenges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = _challenges[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.titleEn, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${c.participants.length} Students Joined • Code: ${c.inviteCode}', style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => _startChallenge(c),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.green,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Enter Match'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('National Student Leaderboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Icon(Icons.military_tech_rounded, color: AppTheme.accent, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          _buildRankTile(1, 'Robel M. (Addis Ababa)', '98.5% Accuracy', '1,420 🪙', AppTheme.accent),
          const SizedBox(height: 8),
          _buildRankTile(2, 'Selamawit T. (Hawassa)', '96.0% Accuracy', '1,280 🪙', Colors.grey.shade400),
          const SizedBox(height: 8),
          _buildRankTile(3, 'Natnael K. (Bahir Dar)', '94.2% Accuracy', '1,150 🪙', const Color(0xFFCD7F32)),
          const SizedBox(height: 8),
          _buildRankTile(4, 'Meklit B. (Adama)', '92.8% Accuracy', '980 🪙', AppTheme.darkMuted),
        ],
      ),
    );
  }

  Widget _buildRankTile(int rank, String name, String accuracy, String coins, Color rankColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(fontWeight: FontWeight.bold, color: rankColor, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(accuracy, style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted)),
              ],
            ),
          ),
          Text(coins, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent, fontSize: 13)),
        ],
      ),
    );
  }
}
