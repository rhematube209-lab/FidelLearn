import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/domain/models/user_profile.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/bookmarks/data/repositories/supabase_bookmark_repository.dart';
import '../../features/bookmarks/domain/repositories/bookmark_repository.dart';
import '../../features/challenges/data/repositories/local_challenge_repository.dart';
import '../../features/challenges/domain/repositories/challenge_repository.dart';
import '../../features/exams/data/repositories/supabase_exam_repository.dart';
import '../../features/exams/domain/repositories/exam_repository.dart';
import '../../features/mistakes/data/repositories/supabase_mistake_repository.dart';
import '../../features/mistakes/domain/repositories/mistake_repository.dart';
import '../../features/rewards/domain/models/coin_ledger_entry.dart';
import '../../features/rewards/domain/services/coin_ledger_service.dart';
import '../../features/subjects/data/repositories/local_content_repository.dart';
import '../../features/subjects/data/repositories/supabase_content_repository.dart';
import '../../features/subjects/domain/repositories/content_repository.dart';
import '../../features/admin/data/repositories/local_admin_repository.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/school/data/repositories/local_school_repository.dart';
import '../../features/school/domain/repositories/school_repository.dart';
import '../../features/teacher/data/repositories/local_teacher_repository.dart';
import '../../features/teacher/domain/repositories/teacher_repository.dart';
import '../../features/p2p_transfer/data/repositories/local_p2p_repository.dart';
import '../../features/challenges/domain/services/offline_challenge_qr_service.dart';
import '../../features/subjects/domain/services/delta_package_service.dart';
import '../../features/payments/data/repositories/local_payment_repository.dart';
import '../../features/auth/domain/services/sms_gateway_service.dart';
import '../../features/rewards/domain/services/airtime_redemption_service.dart';
import '../config/env_config.dart';
import '../database/app_database.dart';
import '../networking/connectivity_service.dart';
import '../security/auth_session_storage.dart';
import '../sync/models/sync_models.dart';
import '../sync/repositories/drift_sync_queue_repository.dart';
import '../sync/repositories/sync_queue_repository.dart';
import '../sync/services/sync_engine.dart';
import '../../features/exams/data/repositories/drift_exam_repository.dart';
import '../../features/bookmarks/data/repositories/drift_bookmark_repository.dart';
import '../../features/mistakes/data/repositories/drift_mistake_repository.dart';
import '../../features/rewards/data/repositories/drift_coin_ledger_repository.dart';

// --- Database Infrastructure ---
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// --- Connectivity & Offline Sync Infrastructure ---
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityPlusService();
  ref.onDispose(service.dispose);
  return service;
});

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftSyncQueueRepository(db);
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final queue = ref.watch(syncQueueRepositoryProvider);
  final engine = SyncEngine(
    connectivityService: connectivity,
    queueRepository: queue,
  );
  ref.onDispose(engine.dispose);
  return engine;
});

final syncStateProvider =
    StateNotifierProvider<SyncStateNotifier, SyncStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return SyncStateNotifier(engine);
});

class SyncStateNotifier extends StateNotifier<SyncStatus> {
  final SyncEngine _engine;
  late final StreamSubscription<SyncStatus> _sub;

  SyncStateNotifier(this._engine) : super(_engine.currentStatus) {
    _sub = _engine.onStatusChanged.listen((status) {
      state = status;
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// --- Global Repositories ---
final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return AuthSessionStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(authSessionStorageProvider);
  if (EnvConfig.isSupabaseConfigured) {
    try {
      return SupabaseAuthRepository(sessionStorage: storage);
    } catch (_) {}
  }
  return MockAuthRepository(sessionStorage: storage);
});

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  if (EnvConfig.isSupabaseConfigured) {
    try {
      return SupabaseContentRepository();
    } catch (_) {}
  }
  return LocalContentRepository();
});

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  if (EnvConfig.isSupabaseConfigured) {
    try {
      return SupabaseExamRepository();
    } catch (_) {}
  }
  final db = ref.watch(appDatabaseProvider);
  final queue = ref.watch(syncQueueRepositoryProvider);
  return DriftExamRepository(db: db, syncQueue: queue);
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  if (EnvConfig.isSupabaseConfigured) {
    try {
      return SupabaseBookmarkRepository();
    } catch (_) {}
  }
  final db = ref.watch(appDatabaseProvider);
  final queue = ref.watch(syncQueueRepositoryProvider);
  return DriftBookmarkRepository(db: db, syncQueue: queue);
});

final mistakeRepositoryProvider = Provider<MistakeRepository>((ref) {
  if (EnvConfig.isSupabaseConfigured) {
    try {
      return SupabaseMistakeRepository();
    } catch (_) {}
  }
  final db = ref.watch(appDatabaseProvider);
  final queue = ref.watch(syncQueueRepositoryProvider);
  return DriftMistakeRepository(db: db, syncQueue: queue);
});

final coinLedgerRepositoryProvider = Provider<DriftCoinLedgerRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final queue = ref.watch(syncQueueRepositoryProvider);
  return DriftCoinLedgerRepository(db: db, syncQueue: queue);
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return LocalChallengeRepository();
});

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return LocalTeacherRepository();
});

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return LocalSchoolRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return LocalAdminRepository();
});

final localP2pRepositoryProvider = Provider<LocalP2PRepository>((ref) {
  return LocalP2PRepository();
});

final offlineChallengeQrServiceProvider =
    Provider<OfflineChallengeQrService>((ref) {
  return OfflineChallengeQrService();
});

final deltaPackageServiceProvider = Provider<DeltaPackageService>((ref) {
  return DeltaPackageService();
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return LocalPaymentRepository();
});

final smsGatewayServiceProvider = Provider<SmsGatewayService>((ref) {
  return SmsGatewayService();
});

final airtimeRedemptionServiceProvider =
    Provider<AirtimeRedemptionService>((ref) {
  return AirtimeRedemptionService();
});

// --- Theme & Locale State ---
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

// --- Current User State ---
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserProfile?>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return CurrentUserNotifier(authRepo);
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRepository _authRepo;
  StreamSubscription<UserProfile?>? _authSub;

  CurrentUserNotifier(this._authRepo) : super(const AsyncValue.loading()) {
    _init();
    _authSub = _authRepo.authStateChanges().listen((user) {
      if (user != null || state.valueOrNull == null) {
        state = AsyncValue.data(user);
      }
    });
  }

  Future<void> _init() async {
    try {
      final user = await _authRepo.getCurrentUser();
      if (state.isLoading || state.valueOrNull == null) {
        state = AsyncValue.data(user);
      }
    } catch (e, st) {
      if (state.isLoading) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<UserProfile> login(String phone, String pass,
      {bool rememberMe = true}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.loginWithPhone(
        phoneNumber: phone,
        password: pass,
        rememberMe: rememberMe,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserProfile> register({
    required String phone,
    required String pass,
    required String name,
    required int grade,
    required String stream,
    required String lang,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.registerWithPhone(
        phoneNumber: phone,
        password: pass,
        displayName: name,
        grade: grade,
        stream: stream,
        preferredLanguage: lang,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile(UserProfile updated) async {
    await _authRepo.updateProfile(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> logout() async {
    await _authRepo.logout();
    state = const AsyncValue.data(null);
  }
}

// --- Coin Ledger State ---
final coinLedgerProvider =
    StateNotifierProvider<CoinLedgerNotifier, List<CoinLedgerEntry>>((ref) {
  final repo = ref.watch(coinLedgerRepositoryProvider);
  return CoinLedgerNotifier(repo);
});

class CoinLedgerNotifier extends StateNotifier<List<CoinLedgerEntry>> {
  final DriftCoinLedgerRepository? _repository;

  CoinLedgerNotifier([this._repository])
      : super([
          CoinLedgerEntry(
            id: 'init_signup_bonus',
            userId: 'demo-student-001',
            transactionType: CoinTransactionType.credit,
            amount: 50,
            reason: 'Welcome Signup Bonus',
            idempotencyKey: 'welcome_demo-student-001',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          CoinLedgerEntry(
            id: 'daily_goal_1',
            userId: 'demo-student-001',
            transactionType: CoinTransactionType.credit,
            amount: 15,
            reason: 'Completed Daily Study Goal',
            idempotencyKey: 'daily_goal_20260820_demo-student-001',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]) {
    _init();
  }

  Future<void> _init() async {
    if (_repository != null) {
      try {
        final entries = await _repository.getLedger();
        if (entries.isNotEmpty) {
          state = entries;
        } else {
          for (final e in state) {
            await _repository.recordEntry(e);
          }
        }
      } catch (_) {}
    }
  }

  int get balance => CoinLedgerService.calculateBalance(state);

  void awardCoins({
    required String userId,
    required int amount,
    required String reason,
    required String idempotencyKey,
    String? relatedEntityId,
  }) {
    CoinLedgerService.validateIdempotency(
      currentLedger: state,
      idempotencyKey: idempotencyKey,
    );

    final entry = CoinLedgerEntry(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      transactionType: CoinTransactionType.credit,
      amount: amount,
      reason: reason,
      relatedEntityId: relatedEntityId,
      idempotencyKey: idempotencyKey,
      createdAt: DateTime.now(),
    );

    state = [...state, entry];
    if (_repository != null) {
      unawaited(_repository.recordEntry(entry).catchError((_) {}));
    }
  }

  void spendCoins({
    required String userId,
    required int amount,
    required String reason,
    required String idempotencyKey,
    String? relatedEntityId,
  }) {
    CoinLedgerService.validateDebitPermitted(
      currentLedger: state,
      debitAmount: amount,
    );
    CoinLedgerService.validateIdempotency(
      currentLedger: state,
      idempotencyKey: idempotencyKey,
    );

    final entry = CoinLedgerEntry(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      transactionType: CoinTransactionType.debit,
      amount: amount,
      reason: reason,
      relatedEntityId: relatedEntityId,
      idempotencyKey: idempotencyKey,
      createdAt: DateTime.now(),
    );

    state = [...state, entry];
    if (_repository != null) {
      unawaited(_repository.recordEntry(entry).catchError((_) {}));
    }
  }
}
