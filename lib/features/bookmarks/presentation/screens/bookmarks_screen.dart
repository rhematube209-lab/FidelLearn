import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../question_bank/domain/models/question_models.dart';
import '../../domain/models/bookmark_model.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  List<Bookmark> _bookmarks = [];
  Map<String, Question> _questions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final bookmarkRepo = ref.read(bookmarkRepositoryProvider);
    final contentRepo = ref.read(contentRepositoryProvider);

    if (user != null) {
      final bms = await bookmarkRepo.getBookmarks(user.id);
      final Map<String, Question> qMap = {};
      for (final b in bms) {
        final q = await contentRepo.getQuestionById(b.questionId);
        if (q != null) qMap[b.questionId] = q;
      }

      if (mounted) {
        setState(() {
          _bookmarks = bms;
          _questions = qMap;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeBookmark(Bookmark b) async {
    final bookmarkRepo = ref.read(bookmarkRepositoryProvider);
    await bookmarkRepo.toggleBookmark(
      userId: b.userId,
      questionId: b.questionId,
      subjectId: b.subjectId,
      topicId: b.topicId,
    );
    await _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Bookmarks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppTheme.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Bookmarked Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bookmark tricky questions during exam review to practice them later.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _bookmarks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = _bookmarks[index];
                final q = _questions[b.questionId];
                if (q == null) return const SizedBox.shrink();

                return Card(
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
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                q.subjectId.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.bookmark_remove,
                                color: AppTheme.errorRed,
                                size: 20,
                              ),
                              tooltip: 'Remove Bookmark',
                              onPressed: () => _removeBookmark(b),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.questionTextEn,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.successGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Correct Answer: (${q.correctChoice.label}) ${q.correctChoice.textEn}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
