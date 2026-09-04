import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/admin_models.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AdminContentOverview? _overview;
  List<Question> _pendingQuestions = [];
  List<ContentAuditLog> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      final ov = await adminRepo.getContentOverview();
      final pend = await adminRepo.getPendingReviewQuestions();
      final logs = await adminRepo.getAuditLogs();

      if (mounted) {
        setState(() {
          _overview = ov;
          _pendingQuestions = pend;
          _auditLogs = logs;
        });
      }
    } catch (e) {
      debugPrint('AdminDashboardScreen: error loading admin data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _approveQuestion(Question question) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final adminRepo = ref.read(adminRepositoryProvider);

    await adminRepo.updateVerificationStatus(
      questionId: question.id,
      status: 'published',
      actorUserId: user?.id ?? 'admin_root',
      actorRole: 'platform_admin',
    );

    await _loadAdminData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Question "${question.id}" Verified and Published! 🎉'),
        ),
      );
    }
  }

  Future<void> _rejectQuestion(Question question) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final adminRepo = ref.read(adminRepositoryProvider);

    await adminRepo.updateVerificationStatus(
      questionId: question.id,
      status: 'rejected',
      actorUserId: user?.id ?? 'admin_root',
      actorRole: 'platform_admin',
      rejectionReason: 'Distractor rationale requires clarification',
    );

    await _loadAdminData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question "${question.id}" returned to draft.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_overview == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Platform Content CMS')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings_outlined,
                  size: 64, color: AppTheme.darkMuted),
              const SizedBox(height: 16),
              const Text('Unable to load content overview.',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadAdminData();
                },
              ),
            ],
          ),
        ),
      );
    }

    final ov = _overview!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Content CMS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            Tab(text: 'Verification Queue (${_pendingQuestions.length})'),
            const Tab(text: 'Audit Trail 📜'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Content Overview Statistics
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  'Total Items',
                  '${ov.totalQuestions}',
                  AppTheme.primaryGreen,
                ),
                _buildMetric(
                  'Published',
                  '${ov.publishedQuestions}',
                  AppTheme.successGreen,
                ),
                _buildMetric(
                  'In Review',
                  '${ov.pendingVerificationQuestions}',
                  AppTheme.accentGoldDark,
                ),
                _buildMetric(
                  'Packages',
                  '${ov.totalPackages}',
                  AppTheme.infoBlue,
                ),
              ],
            ),
          ),

          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildVerificationQueue(), _buildAuditLogList()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/question_editor');
          if (mounted) await _loadAdminData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Author Question'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildVerificationQueue() {
    if (_pendingQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successGreen.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verification Queue Clean!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'All authored questions have been verified & published.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _pendingQuestions.length,
      itemBuilder: (context, index) {
        final q = _pendingQuestions[index];
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'GRADE ${q.grade} • ${q.subjectId.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentGoldDark,
                        ),
                      ),
                    ),
                    Text(
                      'v${q.contentVersion}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  q.questionTextEn,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (q.questionTextAm != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    q.questionTextAm!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Choices & Solution:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...q.choices.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          c.isCorrect
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: c.isCorrect
                              ? AppTheme.successGreen
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '(${c.label}) ${c.textEn}',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.isCorrect
                                  ? AppTheme.successGreen
                                  : AppTheme.textMuted,
                              fontWeight: c.isCorrect
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectQuestion(q),
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.errorRed,
                          size: 18,
                        ),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: AppTheme.errorRed),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveQuestion(q),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Verify & Publish'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _auditLogs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
              child: const Icon(
                Icons.security,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            title: Text(
              log.actionType,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              '${log.detail}\nBy ${log.actorUserId} (${log.actorRole})',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
        );
      },
    );
  }
}
