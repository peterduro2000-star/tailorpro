import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/license_model.dart';
import 'license_verification_service.dart';

/// Single source of truth for all entitlement decisions.
///
/// This service is the ONLY place that decides:
/// - What tier a user has
/// - If they can add more clients
/// - If their license is expired
/// - What their effective tier is (accounting for expiry + grace period)
///
/// Philosophy:
/// - Supabase is the authority (final truth)
/// - Device cache only used when offline
/// - IAP is a payment proof only, NOT license itself
/// - All client-side logic is replaced by simple reads
class LicenseManager {
  final LicenseVerificationService verificationService;

  LicenseManager({required this.verificationService});

  /// Returns the current effective license.
  ///
  /// Online: fresh from Supabase (via verificationService).
  /// Offline: cached license with grace period ceiling applied.
  /// Never: local IAP override.
  Future<License?> getCurrentEffectiveLicense() async {
    return await verificationService.verifyAndGetLicense();
  }

  /// Returns the cached license without server roundtrip.
  ///
  /// Use only for UI indicators (e.g., badge showing tier name).
  /// Always prefer [getCurrentEffectiveLicense] for access control.
  License? getCachedLicense() {
    return verificationService.getCachedLicense();
  }

  /// The tier the user currently has (may be free due to expiry or offline limits).
  Future<LicenseTier> getEffectiveTier() async {
    final license = await getCurrentEffectiveLicense();
    return license?.effectiveTier ?? LicenseTier.free;
  }

  /// True if user has a paid tier (not free).
  Future<bool> hasPremiumAccess() async {
    final tier = await getEffectiveTier();
    return tier != LicenseTier.free;
  }

  /// The maximum clients this tier allows.
  Future<int> getMaxClients() async {
    final tier = await getEffectiveTier();
    return tier.maxClients;
  }

  /// The number of clients currently used (from server).
  Future<int> getClientsUsed() async {
    final license = await getCurrentEffectiveLicense();
    return license?.clientsUsed ?? 0;
  }

  /// The number of clients still available.
  Future<int> getRemainingClients() async {
    final max = await getMaxClients();
    final used = await getClientsUsed();
    final remaining = max - used;
    return remaining < 0 ? 0 : remaining;
  }

  /// True if user can add another client.
  Future<bool> canAddMoreClients() async {
    final remaining = await getRemainingClients();
    return remaining > 0;
  }

  /// True if the license exists and is usable (including grace period).
  Future<bool> isLicenseUsable() async {
    final license = await getCurrentEffectiveLicense();
    return license?.isUsable ?? false;
  }

  /// True if the license is currently in grace period.
  Future<bool> isInGracePeriod() async {
    final license = await getCurrentEffectiveLicense();
    return license?.isInGracePeriod ?? false;
  }

  /// Days remaining in grace period (0 if not in grace period).
  Future<int> getDaysInGracePeriod() async {
    final license = await getCurrentEffectiveLicense();
    return license?.daysInGracePeriod ?? 0;
  }

  /// Display string for the current license status.
  Future<String> getLicenseStatusDisplay() async {
    final license = await getCurrentEffectiveLicense();

    if (license == null) {
      return 'Free tier (no license)';
    }

    if (license.isExpired && license.isInGracePeriod) {
      return 'Grace period — ${license.daysInGracePeriod} day(s) left';
    } else if (license.isExpired) {
      return 'Expired — downgraded to Free';
    } else if (license.expiresAt == null) {
      return '${license.tier.displayName} (lifetime)';
    } else {
      return '${license.tier.displayName} — expires ${license.expiryDateFormatted}';
    }
  }

  /// Activate a Play Store purchase by verifying it on the server and
  /// refreshing the authoritative license state.
  Future<License> activateIapPurchase({
    required String edgeFunctionUrl,
    required String purchaseToken,
    required String productId,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$edgeFunctionUrl/verify-google-play');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode({
        'purchaseToken': purchaseToken,
        'productId': productId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Activation failed: ${response.statusCode} ${response.body}',
      );
    }

    final verifiedLicense = await verificationService.verifyAndGetLicense();
    if (verifiedLicense == null) {
      throw Exception('Failed to refresh license after purchase activation.');
    }

    return verifiedLicense;
  }

  /// True if should show grace period warning banner.
  bool shouldShowGracePeriodWarning(License license) {
    return verificationService.shouldShowGracePeriodWarning(license);
  }

  /// Call after user dismisses grace period warning.
  Future<void> acknowledgeGracePeriodWarning() async {
    return verificationService.acknowledgeGracePeriodWarning();
  }
}
