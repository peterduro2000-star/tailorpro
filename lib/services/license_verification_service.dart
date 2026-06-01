import 'dart:async';
import '../models/license_model.dart';
import '../services/license_service.dart';
import 'license_persistence_service.dart';

/// Orchestrates periodic server verification and offline fallback.
///
/// Strategy:
///   1. On app launch, immediately attempt a server verification.
///   2. If online → save fresh license, reset offline counter.
///   3. If offline → load cached license and enforce grace ceiling.
///      Once the device has been offline for more than [License.gracePeriodDays],
///      the effective tier is downgraded to Free (locally) until connectivity
///      is restored and the server confirms the license.
///   4. A periodic timer re-runs verification every 24 hours while the app
///      is in the foreground.
class LicenseVerificationService {
  final LicenseService licenseService;
  final LicensePersistenceService persistenceService;

  Timer? _verificationTimer;
  static const Duration _verificationInterval = Duration(hours: 24);

  LicenseVerificationService({
    required this.licenseService,
    required this.persistenceService,
  });

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  /// Call this after the user has successfully authenticated.
  ///
  /// Runs one immediate check and then schedules a repeating 24-hour timer.
  void startPeriodicVerification() {
    _verificationTimer?.cancel();
    _runVerification();
    _verificationTimer = Timer.periodic(_verificationInterval, (_) {
      _runVerification();
    });
  }

  /// Call this on logout or when the app is paused/disposed.
  void stopPeriodicVerification() {
    _verificationTimer?.cancel();
    _verificationTimer = null;
  }

  // ─── Core verification logic ─────────────────────────────────────────────────

  /// Attempt a server round-trip. On failure, falls back to cached data.
  ///
  /// Returns the effective [License] the app should use right now.
  Future<License?> verifyAndGetLicense() async {
    // 1. Try server first.
    try {
      final serverLicense = await licenseService.getCurrentLicense();

      if (serverLicense != null) {
        // Fresh data from server → persist and reset offline counter.
        await persistenceService.saveLicense(serverLicense);
        await persistenceService.saveVerificationDate(DateTime.now());
        await persistenceService.resetOfflineDayCount();
        return serverLicense;
      }
    } catch (_) {
      // Network unavailable — fall through to offline logic.
    }

    // 2. No server response — use cache.
    return _getOfflineLicense();
  }

  /// Returns the cached license, applying the offline grace ceiling.
  ///
  /// If the device has been offline longer than [License.gracePeriodDays],
  /// returns null (treated as no valid license → Free tier in the app).
  License? _getOfflineLicense() {
    final cached = persistenceService.loadLicense();
    if (cached == null) return null;

    // Free tier never needs online verification.
    if (cached.tier == LicenseTier.free) return cached;

    // Increment the offline counter once per verification attempt.
    persistenceService.incrementOfflineDayCount();

    final offlineDays = persistenceService.getOfflineDayCount();

    if (offlineDays > License.gracePeriodDays) {
      // Grace window exhausted offline — downgrade silently.
      // Do NOT clear the cache; as soon as connectivity returns, the
      // next successful verification will restore the real tier.
      return null;
    }

    return cached;
  }

  // ─── Internal timer callback ─────────────────────────────────────────────────

  void _runVerification() {
    // Fire-and-forget; UI listens via LicenseProvider, not this service.
    verifyAndGetLicense();
  }

  // ─── Cached read (synchronous, for quick UI checks) ──────────────────────────

  /// Returns the last locally-stored license without hitting the server.
  ///
  /// Use only for fast UI decisions (e.g., showing a client count badge).
  /// Always prefer [verifyAndGetLicense] for access-control decisions.
  License? getCachedLicense() {
    return persistenceService.loadLicense();
  }

  // ─── Grace period UX helpers ─────────────────────────────────────────────────

  /// True if the app should show a "your license expires soon" banner.
  bool shouldShowGracePeriodWarning(License license) {
    if (!license.isInGracePeriod) return false;
    if (persistenceService.hasGracePeriodWarningShown()) return false;
    return true;
  }

  /// Call when the user has dismissed the grace period banner.
  Future<void> acknowledgeGracePeriodWarning() async {
    await persistenceService.setGracePeriodWarningShown(true);
  }
}