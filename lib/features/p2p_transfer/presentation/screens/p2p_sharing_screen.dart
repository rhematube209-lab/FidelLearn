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
          content: Text('Please enter the 6-digit PIN shown on the sender device.'),
        ),
      );
      return;
    }

    final repo = ref.read(p2pRepositoryProvider);
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8088;
    final pin = _pinController.text.trim();

    // Reconstruct beacon info for peer connection
    final mockBeacon = _activeBeacon ??
        P2PSenderBeacon(
          sessionId: 'client_peer_${DateTime.now().millisecondsSinceEpoch}',
          hostAddress: host,
          port: port,
          pairingPin: pin,
          availablePackages: _availablePackages,
          startedAt: DateTime.now(),
        );

    setState(() {
      _isReceiving = true;
      _transferProgress = const P2PTransferProgress(
        status: P2PTransferStatus.connecting,
      );
    });

    final targetPackageId = _availablePackages.isNotEmpty
        ? _availablePackages.first.packageId
        : 'pkg_g12_math';

    repo
        .receivePackage(
          beacon: mockBeacon,
          packageId: targetPackageId,
          pin: pin,
        )
        .listen(
          (progress) {
            if (mounted) {
              setState(() {
                _transferProgress = progress;
                if (progress.status == P2PTransferStatus.completed ||
                    progress.status == P2PTransferStatus.failed) {
                  _isReceiving = false;
                }
              });
            }
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline P2P Package Sharing'),
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
            Tab(icon: Icon(Icons.upload), text: 'Share (Send)'),
            Tab(icon: Icon(Icons.download), text: 'Receive'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSendTab(), _buildReceiveTab()],
      ),
    );
  }

  Widget _buildSendTab() {
    if (_isLoadingPackages) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.wifi_tethering,
                  color: AppTheme.primaryGreen,
                  size: 32,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zero Cellular Data Transfer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Turn on your Wi-Fi Hotspot. Peers nearby can connect and download verified exam packages with high speed.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Active Beacon Card
          if (_activeBeacon != null) ...[
            Card(
              color: AppTheme.accentGold.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: AppTheme.accentGold.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radar, color: AppTheme.accentGoldDark),
                        SizedBox(width: 8),
                        Text(
                          'P2P HOTSPOT ACTIVE & BROADCASTING',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentGoldDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Share this 6-Digit Pairing PIN with your peer:',
                      style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.accentGoldDark,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        _activeBeacon!.pairingPin,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: AppTheme.accentGoldDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Host Address: ${_activeBeacon!.hostAddress}:${_activeBeacon!.port}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Text(
            'Select Packages to Share:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Packages List
          ..._availablePackages.map((pkg) {
            final isSelected = _selectedPackageIds.contains(pkg.packageId);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: CheckboxListTile(
                value: isSelected,
                activeColor: AppTheme.primaryGreen,
                onChanged: _activeBeacon == null
                    ? (val) {
                        setState(() {
                          if (val == true) {
                            _selectedPackageIds.add(pkg.packageId);
                          } else {
                            _selectedPackageIds.remove(pkg.packageId);
                          }
                        });
                      }
                    : null,
                title: Text(
                  pkg.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${pkg.questionCount} Questions • ${(pkg.fileSizeBytes / 1024).toStringAsFixed(0)} KB • v${pkg.version}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Start / Stop Button
          ElevatedButton.icon(
            onPressed: _toggleSharing,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _activeBeacon != null ? AppTheme.errorRed : AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(_activeBeacon != null ? Icons.stop : Icons.sensors),
            label: Text(
              _activeBeacon != null ? 'Stop P2P Sharing' : 'Start P2P Hotspot Sharing',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection instructions
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.infoBlue),
                      SizedBox(width: 8),
                      Text(
                        'How to Receive Packages:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Connect to the sender\'s Wi-Fi Hotspot.\n2. Ask the sender for their 6-Digit Pairing PIN.\n3. Tap "Connect & Download Package".',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Inputs
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              labelText: 'Sender Hotspot IP',
              prefixIcon: Icon(Icons.router),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 6,
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              labelText: '6-Digit Pairing PIN',
              counterText: '',
              prefixIcon: Icon(Icons.pin),
            ),
          ),
          const SizedBox(height: 20),

          // Transfer Progress Display
          if (_transferProgress.status != P2PTransferStatus.idle) ...[
            Card(
              color: _transferProgress.status == P2PTransferStatus.failed
                  ? AppTheme.errorRed.withOpacity(0.06)
                  : AppTheme.primaryGreen.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _transferProgress.status == P2PTransferStatus.failed
                      ? AppTheme.errorRed.withOpacity(0.3)
                      : AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _transferProgress.status == P2PTransferStatus.completed
                              ? Icons.check_circle
                              : _transferProgress.status ==
                                      P2PTransferStatus.failed
                                  ? Icons.error
                                  : Icons.sync,
                          color: _transferProgress.status ==
                                  P2PTransferStatus.completed
                              ? AppTheme.successGreen
                              : _transferProgress.status ==
                                      P2PTransferStatus.failed
                                  ? AppTheme.errorRed
                                  : AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _transferProgress.status.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_transferProgress.speedKbps > 0)
                          Text(
                            '${_transferProgress.speedKbps.toStringAsFixed(0)} KB/s',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _transferProgress.progressRatio > 0
                          ? _transferProgress.progressRatio
                          : null,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _transferProgress.status == P2PTransferStatus.failed
                            ? AppTheme.errorRed
                            : AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_transferProgress.bytesTransferred / 1024).toStringAsFixed(0)} KB / ${(_transferProgress.totalBytes / 1024).toStringAsFixed(0)} KB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          '${(_transferProgress.progressRatio * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_transferProgress.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _transferProgress.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          ElevatedButton.icon(
            onPressed: _isReceiving ? null : _startReceiving,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.download),
            label: const Text(
              'Connect & Download Package',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
