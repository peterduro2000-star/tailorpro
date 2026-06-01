import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/license_model.dart';

/// Persists license data locally using SharedPreferences.
///
/// All keys are scoped per user ID to prevent data leakage when
/// multiple users log in on the same device.
class LicensePersistenceService {
  // Key suffixes — always prefixed with userId
  static const String _licenseSuffix = '_license_cache';
  static const String _verificationSuffix = '_license_verified_at';
  static const String _gracePeriodWarningSuffix = '_grace_warning_shown';
  static const String _offlineCounterSuffix = '_offline_days_counter';

  final SharedPreferences prefs;
  final String userId;

  LicensePersistenceService({
    required this.prefs,
    required this.userId,
  }) : assert(userId.isNotEmpty, 'userId must not be empty');

  // ─── Key builders ────────────────────────────────────────────────────────────

  String get _licenseKey => '${userId}$_licenseSuffix';
  String get _verificationKey => '${userId}$_verificationSuffix';
  String get _gracePeriodWarningKey => '${userId}$_gracePeriodWarningSuffix';
  String get _offlineCounterKey => '${userId}$_offlineCounterSuffix';

  // ─── License cache ───────────────────────────────────────────────────────────

  /// Persist a verified license to local cache.
  Future<void> saveLicense(License license) async {
    final jsonString = jsonEncode(license.toMap());
    await prefs.setString(_licenseKey, jsonString);
  }

  /// Load the most recently cached license, or null if none exists.
  License? loadLicense() {
    final jsonString = prefs.getString(_licenseKey);
    if (jsonString == null) return null;

    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return License.fromMap(map);
    } catch (_) {
      // Corrupted cache — treat as missing
      return null;
    }
  }

  // ─── Verification timestamps ─────────────────────────────────────────────────

  /// Record the moment a successful server verification completed.
  Future<void> saveVerificationDate(DateTime date) async {
    await prefs.setString(_verificationKey, date.toIso8601String());
  }

  /// Return the last successful verification date, or null if never verified.
  DateTime? getLastVerificationDate() {
    final raw = prefs.getString(_verificationKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Number of consecutive days the app has been offline (no successful
  /// verification). Used to enforce the grace-period ceiling.
  int getOfflineDayCount() {
    return prefs.getInt(_offlineCounterKey) ?? 0;
  }

  /// Increment the offline day counter by 1.
  Future<void> incrementOfflineDayCount() async {
    final current = getOfflineDayCount();
    await prefs.setInt(_offlineCounterKey, current + 1);
  }

  /// Reset offline counter to 0 after a successful server verification.
  Future<void> resetOfflineDayCount() async {
    await prefs.setInt(_offlineCounterKey, 0);
  }

  // ─── Grace period warning ─────────────────────────────────────────────────────

  bool hasGracePeriodWarningShown() {
    return prefs.getBool(_gracePeriodWarningKey) ?? false;
  }

  Future<void> setGracePeriodWarningShown(bool shown) async {
    await prefs.setBool(_gracePeriodWarningKey, shown);
  }

  // ─── Cache clearing (on logout / user switch) ────────────────────────────────

  /// Remove all license-related keys for this user.
  ///
  /// Call this on logout or when a different user signs in on the same device.
  Future<void> clearLicense() async {
    await Future.wait([
      prefs.remove(_licenseKey),
      prefs.remove(_verificationKey),
      prefs.remove(_gracePeriodWarningKey),
      prefs.remove(_offlineCounterKey),
    ]);
  }
}