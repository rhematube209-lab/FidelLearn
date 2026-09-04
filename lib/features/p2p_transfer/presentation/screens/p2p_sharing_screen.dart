import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fidel_learn/core/providers/app_providers.dart';
import 'package:fidel_learn/core/theme/app_theme.dart';
import 'package:fidel_learn/features/p2p_transfer/domain/models/p2p_models.dart';

final p2pRepositoryProvider = Provider((ref) {
  return ref.watch(localP2pRepositoryProvider);
});

class P2PSharingScreen extends ConsumerStatefulWidget {
  const P2PSharingScreen({super.key});

  @override
  ConsumerState<P2PSharingScreen> createState() => _P2PSharingScreenState();
}

class _P2PSharingScreenState extends ConsumerState<P2PSharingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Send Tab State
  List<P2PPackageManifest> _availablePackages = [];
  final Set<String> _selectedPackageIds = {};
  P2PSenderBeacon? _activeBeacon;
  bool _isLoadingPackages = true;

  // Receive Tab State
  final TextEditingController _hostController =
      TextEditingController(text: '192.168.43.1');
  final TextEditingController _portController =
      TextEditingController(text: '8088');
  final TextEditingController _pinController = TextEditingController();
  P2PTransferProgress _transferProgress = const P2PTransferProgress();
  bool _isReceiving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShareablePackages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadShareablePackages() async {
    final repo = ref.read(p2pRepositoryProvider);
    final packages = await repo.getShareablePackages();
    if (mounted) {
      setState(() {
        _availablePackages = packages;
        _selectedPackageIds.addAll(packages.map((p) => p.packageId));
        _isLoadingPackages = false;
      });
    }
  }

  Future<void> _toggleSharing() async {
    final repo = ref.read(p2pRepositoryProvider);

    if (_activeBeacon != null) {
      await repo.stopSharing(_activeBeacon!.sessionId);
      setState(() {
        _activeBeacon = null;
      });
    } else {
      if (_selectedPackageIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one package to share.'),
          ),
        );
        return;
      }
      final beacon = await repo.startSharing(
        packageIds: _selectedPackageIds.toList(),
      );
      setState(() {
        _activeBeacon = beacon;
      });
    }
  }

  void _startReceiving() {
    if (_pinController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter the 6-digit PIN shown on the sender device.'),
        ),
      );
      return;
    }

    final repo = ref.read(p2pRepositoryProvider);
    final port = int.tryParse(_portController.text.trim()) ?? 8088;
    final enteredPin = _pinController.text.trim();
    final host = _hostController.text.trim();

    setState(() {
      _isReceiving = true;
      _transferProgress =
          const P2PTransferProgress(status: P2PTransferStatus.connecting);
    });

    // Build a minimal beacon from manually entered connection details
    final beacon = P2PSenderBeacon(
      sessionId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      hostAddress: host,
      port: port,
      pairingPin: enteredPin,
      availablePackages: const [],
      startedAt: DateTime.now(),
    );

    final stream = repo.receivePackage(
      beacon: beacon,
      packageId: 'unknown',
      pin: enteredPin,
    );

    stream.listen(
      (P2PTransferProgress progress) {
        if (!mounted) return;
        setState(() {
          _transferProgress = progress;
          if (progress.status == P2PTransferStatus.completed ||
              progress.status == P2PTransferStatus.failed) {
            _isReceiving = false;
          }
        });

        if (progress.status == P2PTransferStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.green,
              content: Text(
                  'Offline packages transferred and verified successfully!'),
            ),
          );
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isReceiving = false;
          _transferProgress = const P2PTransferProgress(
            status: P2PTransferStatus.failed,
            errorMessage: 'Connection failed',
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline P2P Hotspot Sharing',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.brand,
          labelColor: AppTheme.brand,
          unselectedLabelColor: AppTheme.darkMuted,
          tabs: const [
            Tab(
                icon: Icon(Icons.wifi_tethering_rounded),
                text: 'Send Packages'),
            Tab(icon: Icon(Icons.download_rounded), text: 'Receive Packages'),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSendTab(isDesktop),
              _buildReceiveTab(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendTab(bool isDesktop) {
    if (_isLoadingPackages) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.brand));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48.0 : 20.0, vertical: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Beacon Status Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _activeBeacon != null
                    ? [const Color(0xFF064E3B), AppTheme.darkSurfaceStrong]
                    : [const Color(0xFF1E1B4B), AppTheme.darkSurfaceStrong],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: _activeBeacon != null
                    ? AppTheme.green
                    : AppTheme.brand.withOpacity(0.4),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activeBeacon != null
                              ? 'P2P BEACON ACTIVE 🟢'
                              : 'P2P BEACON READY',
                          style: TextStyle(
                            color: _activeBeacon != null
                                ? AppTheme.green
                                : AppTheme.brand,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activeBeacon != null
                              ? 'Broadcasting Exam Seed Packages'
                              : 'Select Packages to Share',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _toggleSharing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeBeacon != null
                            ? AppTheme.danger
                            : AppTheme.green,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(_activeBeacon != null
                          ? 'Stop Sharing'
                          : 'Start P2P Hotspot'),
                    ),
                  ],
                ),
                if (_activeBeacon != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.green),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('6-Digit Secret PIN',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.darkMuted)),
                            const SizedBox(height: 4),
                            Text(
                              _activeBeacon!.pairingPin,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  color: AppTheme.green),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Local IP Address',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.darkMuted)),
                            const SizedBox(height: 4),
                            Text(
                              '${_activeBeacon!.hostAddress}:${_activeBeacon!.port}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Select Packages to Broadcast:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availablePackages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final pkg = _availablePackages[index];
              final isSelected = _selectedPackageIds.contains(pkg.packageId);

              return CheckboxListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  side: const BorderSide(color: AppTheme.darkBorder),
                ),
                tileColor: Theme.of(context).cardTheme.color,
                title: Text(pkg.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Grade ${pkg.grade} • ${(pkg.fileSizeBytes / 1024).toStringAsFixed(0)} KB • SHA-256 Verified'),
                value: isSelected,
                activeColor: AppTheme.brandStrong,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedPackageIds.add(pkg.packageId);
                    } else {
                      _selectedPackageIds.remove(pkg.packageId);
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 48.0 : 20.0, vertical: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connect to Sender Device',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                    'Connect your device to the sender\'s Wi-Fi hotspot, then enter the 6-digit PIN.',
                    style: TextStyle(fontSize: 12, color: AppTheme.darkMuted)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      flex: 65,
                      child: TextField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                            labelText: 'Sender IP Address',
                            prefixIcon: Icon(Icons.router_outlined)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 35,
                      child: TextField(
                        controller: _portController,
                        decoration: const InputDecoration(
                            labelText: 'Port',
                            prefixIcon: Icon(Icons.settings_ethernet_outlined)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '6-Digit Sender PIN Code',
                    prefixIcon: Icon(Icons.pin_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isReceiving ? null : _startReceiving,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Start Zero-Data Transfer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandStrong,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_transferProgress.status != P2PTransferStatus.idle) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.brand),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transfer Status: ${_transferProgress.status.name.toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppTheme.brand),
                      ),
                      Text(
                        '${(_transferProgress.progressRatio * 100).toInt()}%',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, color: AppTheme.brand),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _transferProgress.progressRatio,
                      backgroundColor: const Color(0x1AFFFFFF),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.brand),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
