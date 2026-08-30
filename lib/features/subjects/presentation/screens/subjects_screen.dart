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
          title: const Text('Remove Offline Package?'),
          content: Text(
            'Do you want to remove ${pkg.nameEn} from local offline storage to free up space?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Remove Package'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await contentRepo.removePackage(pkg.packageId);
        await _loadPackages();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading ${pkg.nameEn} package...')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await contentRepo.downloadPackage(pkg.packageId);
      await _loadPackages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.green,
            content: Text('${pkg.nameEn} is ready for 100% offline practice!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Subject Packages Hub', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      // Storage & Package Manager Banner
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), AppTheme.darkSurfaceStrong],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.green.withOpacity(0.4)),
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
                                      color: AppTheme.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('OFFLINE-FIRST RESILIENCE', style: TextStyle(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Download Once, Practice Forever Without Internet',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Exam questions, vector diagrams, and step-by-step solutions are stored securely inside local Drift SQLite database.',
                                    style: TextStyle(fontSize: 13, color: AppTheme.darkTextSoft),
                                  ),
                                ],
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 24),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/p2p_share'),
                                icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                                label: const Text('Share via Offline P2P'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandStrong,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Packages (${_packages.length})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Total Storage: ~4.2 MB',
                            style: TextStyle(fontSize: 13, color: AppTheme.darkMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Package Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isDesktop ? 380 : 500,
                          mainAxisExtent: 220,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: _packages.length,
                        itemBuilder: (context, index) {
                          final pkg = _packages[index];
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: pkg.isDownloaded ? AppTheme.green.withOpacity(0.35) : AppTheme.darkBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (pkg.isDownloaded ? AppTheme.green : AppTheme.accent).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pkg.isDownloaded ? 'DOWNLOADED ✅' : 'CLOUD AVAILABLE',
                                        style: TextStyle(
                                          color: pkg.isDownloaded ? AppTheme.green : AppTheme.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text('v${pkg.version}.0', style: const TextStyle(fontSize: 11, color: AppTheme.darkMuted)),
                                  ],
                                ),
                                Text(
                                  pkg.nameEn,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Grade ${pkg.grade} • ${pkg.stream.toUpperCase()} Stream • ${(pkg.sizeBytes / 1024).toStringAsFixed(0)} KB',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.darkMuted),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _toggleDownload(pkg),
                                      child: Text(pkg.isDownloaded ? 'Remove' : 'Download'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => context.push('/exam_builder?subjectId=${pkg.subjectId}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.brandStrong,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                      child: const Text('Practice'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
