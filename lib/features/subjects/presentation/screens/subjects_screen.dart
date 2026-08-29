import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/subject_models.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  List<ContentPackage> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final contentRepo = ref.read(contentRepositoryProvider);

    if (user != null) {
      final pkgs = await contentRepo.getPackages(
        grade: user.grade,
        stream: user.stream,
      );
      if (mounted) {
        setState(() {
          _packages = pkgs;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDownload(ContentPackage pkg) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    if (pkg.isDownloaded) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Package?'),
          content: Text(
            'Do you want to remove ${pkg.nameEn} from offline storage?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
              ),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await contentRepo.removePackage(pkg.packageId);
        await _loadPackages();
      }
    } else {
      // Simulate download
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading ${pkg.nameEn} package...')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await contentRepo.downloadPackage(pkg.packageId);
      await _loadPackages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.successGreen,
            content: Text('${pkg.nameEn} is now ready for offline practice!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Packages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            tooltip: 'P2P Share & Receive',
            onPressed: () => context.push('/p2p_share'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final pkg = _packages[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.inventory_2,
                                color: AppTheme.primaryGreen,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pkg.nameEn,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pkg.nameAm,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'v${pkg.version} • ${(pkg.sizeBytes / 1024).toStringAsFixed(0)} KB • ${pkg.attribution}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: pkg.isDownloaded
                                    ? AppTheme.successGreen.withOpacity(0.12)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    pkg.isDownloaded
                                        ? Icons.offline_pin
                                        : Icons.cloud_download_outlined,
                                    size: 16,
                                    color: pkg.isDownloaded
                                        ? AppTheme.successGreen
                                        : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pkg.isDownloaded
                                        ? 'Downloaded (Offline)'
                                        : 'Available Online',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: pkg.isDownloaded
                                          ? AppTheme.successGreen
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (pkg.isDownloaded) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.share,
                                      size: 20,
                                      color: AppTheme.primaryGreen,
                                    ),
                                    tooltip: 'Share via P2P',
                                    onPressed: () => context.push('/p2p_share'),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                OutlinedButton(
                                  onPressed: () => _toggleDownload(pkg),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: pkg.isDownloaded
                                        ? AppTheme.errorRed
                                        : AppTheme.primaryGreen,
                                    side: BorderSide(
                                      color: pkg.isDownloaded
                                          ? AppTheme.errorRed
                                          : AppTheme.primaryGreen,
                                    ),
                                  ),
                                  child: Text(
                                    pkg.isDownloaded ? 'Remove' : 'Download',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => context.push(
                                    '/exam_builder?subjectId=${pkg.subjectId}',
                                  ),
                                  child: const Text('Start'),
                                ),
                              ],
                            ),
                          ],
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
