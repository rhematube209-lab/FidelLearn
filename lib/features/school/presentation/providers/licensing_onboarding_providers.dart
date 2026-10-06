import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_licensing_onboarding_repository.dart';
import '../../data/repositories/supabase_licensing_onboarding_repository.dart';
import '../../domain/models/licensing_onboarding_models.dart';
import '../../domain/repositories/licensing_onboarding_repository.dart';
import 'active_school_context_provider.dart';

/// Provider for the [LicensingOnboardingRepository].
/// Uses Supabase in production and falls back to Local in tests/mock setups.
final licensingOnboardingRepositoryProvider =
    Provider<LicensingOnboardingRepository>((ref) {
  try {
    return SupabaseLicensingOnboardingRepository();
  } catch (_) {
    return LocalLicensingOnboardingRepository();
  }
});

/// Current school license provider tied to [activeSchoolContextProvider].
final currentSchoolLicenseProvider =
    FutureProvider<SchoolLicense?>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  final schoolId = activeContext.school?.id;
  if (schoolId == null) return null;

  final repo = ref.watch(licensingOnboardingRepositoryProvider);
  return repo.getSchoolLicense(schoolId);
});

/// Current school seat usage provider tied to [activeSchoolContextProvider].
final currentSchoolSeatUsageProvider =
    FutureProvider<SchoolSeatUsage?>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  final schoolId = activeContext.school?.id;
  if (schoolId == null) return null;

  final repo = ref.watch(licensingOnboardingRepositoryProvider);
  return repo.getSchoolSeatUsage(schoolId);
});

/// Current school feature entitlements provider tied to [activeSchoolContextProvider].
final currentSchoolEntitlementsProvider =
    FutureProvider<SchoolEntitlements?>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  final schoolId = activeContext.school?.id;
  if (schoolId == null) return null;

  final repo = ref.watch(licensingOnboardingRepositoryProvider);
  return repo.getSchoolEntitlements(schoolId);
});

/// Current school onboarding state provider tied to [activeSchoolContextProvider].
final currentSchoolOnboardingStateProvider =
    FutureProvider<SchoolOnboardingState?>((ref) async {
  final activeContext = ref.watch(activeSchoolContextProvider);
  final schoolId = activeContext.school?.id;
  if (schoolId == null) return null;

  final repo = ref.watch(licensingOnboardingRepositoryProvider);
  return repo.getSchoolOnboardingState(schoolId);
});

/// Family provider for school license by ID.
final schoolLicenseFamilyProvider =
    FutureProvider.family<SchoolLicense, String>((ref, schoolId) async {
  final repo = ref.watch(licensingOnboardingRepositoryProvider);
  return repo.getSchoolLicense(schoolId);
});

/// Family provider for school seat usage by ID.
final schoolSeatUsageFamilyProvider =
    FutureProvider.family<SchoolSeatUsage, String>((ref, schoolId) async {
  final repo = ref.watch(licensingOnboardingRepositoryProvider);
  return repo.getSchoolSeatUsage(schoolId);
});

/// Family provider for school onboarding state by ID.
final schoolOnboardingFamilyProvider =
    FutureProvider.family<SchoolOnboardingState, String>((ref, schoolId) async {
  final repo = ref.watch(licensingOnboardingRepositoryProvider);
  return repo.getSchoolOnboardingState(schoolId);
});

/// Catalog of active institutional plans.
final institutionalPlansProvider =
    FutureProvider<List<InstitutionalPlan>>((ref) async {
  final repo = ref.watch(licensingOnboardingRepositoryProvider);
  return repo.getInstitutionalPlans();
});
