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
  String _selectedFilter = 'all'; // 'all' | 'natural' | 'social' | 'downloaded'
  final Set<String> _downloadingIds = {};
  final Set<String> _patchingIds = {};

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
      setState(() => _downloadingIds.add(pkg.packageId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading ${pkg.nameEn} package...')),
      );
      // Realistic brief offline transfer delay
      await Future<void>.delayed(const Duration(milliseconds: 650));
      await contentRepo.downloadPackage(pkg.packageId);
      setState(() => _downloadingIds.remove(pkg.packageId));
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

  Future<void> _applyDeltaPatch(ContentPackage pkg) async {
    final contentRepo = ref.read(contentRepositoryProvider);
    setState(() => _patchingIds.add(pkg.packageId));

    try {
      final delta = await contentRepo.checkPackageUpdate(pkg.packageId);
      if (delta != null) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await contentRepo.applyDeltaUpdate(pkg.packageId, delta);
        await _loadPackages();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.green,
              content: Text(
                'Delta patch applied! ${pkg.nameEn} updated to version ${delta.toVersion}.',
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _patchingIds.remove(pkg.packageId));
      }
    }
  }

  List<ContentPackage> get _filteredPackages {
    if (_selectedFilter == 'downloaded') {
      return _packages.where((p) => p.isDownloaded).toList();
    } else if (_selectedFilter == 'natural') {
      return _packages
          .where((p) => p.stream == 'natural' || p.stream == 'common')
          .toList();
    } else if (_selectedFilter == 'social') {
      return _packages
          .where((p) => p.stream == 'social' || p.stream == 'common')
          .toList();
    }
    return _packages;
  }

  double get _totalDownloadedMb {
    final bytes = _packages
        .where((p) => p.isDownloaded)
        .fold<int>(0, (sum, p) => sum + p.sizeBytes);
    return bytes / (1024 * 1024);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offline Subject Packages Hub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brand),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48.0 : 20.0,
                vertical: 24.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Storage & Package Manager Banner
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0F766E),
                              AppTheme.darkSurfaceStrong
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(
                            color: AppTheme.green.withValues(alpha: 0.4),
                          ),
                          boxShadow: AppTheme.cardShadowDark,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.green
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'OFFLINE-FIRST STORAGE MANAGER',
                                          style: TextStyle(
                                            color: AppTheme.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Download Once, Practice Forever Without Internet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Exam questions, vector diagrams, and step-by-step solutions are stored inside local SQLite database.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppTheme.darkTextSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isDesktop) ...[
                                  const SizedBox(width: 20),
                                  ElevatedButton.icon(
                                    onPressed: () => context.push('/p2p_share'),
                                    icon: const Icon(
                                      Icons.wifi_tethering_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Share via P2P'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.brandStrong,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Storage Usage Gauge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Offline Storage Used: ${_totalDownloadedMb.toStringAsFixed(1)} MB',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${_packages.where((p) => p.isDownloaded).length}/${_packages.length} Packages Cached',
                                  style: const TextStyle(
                                    color: AppTheme.darkTextSoft,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _packages.isEmpty
                                    ? 0.0
                                    : (_packages
                                            .where((p) => p.isDownloaded)
                                            .length /
                                        _packages.length),
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(
                                    AppTheme.green),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Filter Chips Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                                'all', 'All Packages (${_packages.length})'),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'downloaded',
                              'Downloaded (${_packages.where((p) => p.isDownloaded).length})',
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip('natural', 'Natural Stream'),
                            const SizedBox(width: 8),
                            _buildFilterChip('social', 'Social Stream'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Package Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isDesktop ? 380 : 500,
                          mainAxisExtent: 245,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: _filteredPackages.length,
                        itemBuilder: (context, index) {
                          final pkg = _filteredPackages[index];
                          final isDownloading =
                              _downloadingIds.contains(pkg.packageId);
                          final isPatching =
                              _patchingIds.contains(pkg.packageId);

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(
                                color: pkg.hasUpdate
                                    ? AppTheme.accent.withValues(alpha: 0.5)
                                    : (pkg.isDownloaded
                                        ? AppTheme.green.withValues(alpha: 0.35)
                                        : (isDark
                                            ? AppTheme.darkBorder
                                            : AppTheme.lightBorder)),
                                width: pkg.hasUpdate ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (pkg.isDownloaded
                                                ? AppTheme.green
                                                : AppTheme.brand)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pkg.isDownloaded
                                            ? 'DOWNLOADED ✅'
                                            : 'CLOUD AVAILABLE',
                                        style: TextStyle(
                                          color: pkg.isDownloaded
                                              ? AppTheme.green
                                              : AppTheme.brand,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'v${pkg.version}.0',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.darkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pkg.nameEn,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Grade ${pkg.grade} • ${pkg.stream.toUpperCase()} Stream • ${(pkg.sizeBytes / 1024).toStringAsFixed(0)} KB',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.darkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (pkg.hasUpdate)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.accent
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.system_update_alt_rounded,
                                          color: AppTheme.accent,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Delta Patch v${pkg.availableVersion ?? (pkg.version + 1)}.0 available (${((pkg.updateSizeBytes ?? 120000) / 1024).toStringAsFixed(0)} KB)',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (isDownloading)
                                  const ClipRRect(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(2)),
                                    child: LinearProgressIndicator(
                                      minHeight: 4,
                                      color: AppTheme.brand,
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (pkg.hasUpdate)
                                      ElevatedButton.icon(
                                        onPressed: isPatching
                                            ? null
                                            : () => _applyDeltaPatch(pkg),
                                        icon: isPatching
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.auto_fix_high_rounded,
                                                size: 14,
                                              ),
                                        label: Text(
                                          isPatching ? 'Patching...' : 'Update',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accentDark,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                        ),
                                      )
                                    else
                                      OutlinedButton(
                                        onPressed: isDownloading
                                            ? null
                                            : () => _toggleDownload(pkg),
                                        child: Text(
                                          pkg.isDownloaded
                                              ? 'Remove'
                                              : (isDownloading
                                                  ? 'Fetching...'
                                                  : 'Download'),
                                        ),
                                      ),
                                    ElevatedButton(
                                      onPressed: () => context.push(
                                        '/exam_builder?subjectId=${pkg.subjectId}',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.brandStrong,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
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

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = filterKey);
      },
      selectedColor: AppTheme.brand.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.brand : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12.5,
      ),
    );
  }
}
