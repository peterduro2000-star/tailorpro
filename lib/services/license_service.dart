import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/license_model.dart';

/// Communicates with Supabase RPCs for all license operations.
///
/// All business logic (expiry, grace period, tier limits) lives on the
/// server inside Postgres functions. This class is a thin transport layer.
class LicenseService {
  final SupabaseClient client;

  LicenseService({required this.client});

  // ─── Auth helpers ─────────────────────────────────────────────────────────────

  String get _currentUserId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw Exception('No authenticated user');
    return id;
  }

  // ─── Row normalisation ────────────────────────────────────────────────────────

  /// Supabase RPC calls that return a single row come back as either
  /// a [Map] or a [List] with one element, depending on the function
  /// definition. This normalises both into a plain [Map].
  Map<String, dynamic> _normalizeRow(dynamic result) {
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return const {};
  }

  License _licenseFromRow(Map<String, dynamic> row) {
    return License.fromMap({
      'id': row['id'] ?? _currentUserId,
      'user_id': _currentUserId,
      'license_key': row['license_key'],
      'tier': row['tier'],
      'activated_at': row['activated_at'] ?? DateTime.now().toIso8601String(),
      'expires_at': row['expires_at'],
      'client_limit': row['client_limit'],
      'clients_used': row['clients_used'] ?? 0,
      'is_active': row['is_active'] ?? true,
    });
  }

  // ─── Core license reads ───────────────────────────────────────────────────────

  /// Fetch the current user's active license from Supabase.
  ///
  /// Returns null if the user has no license row yet (first-time signup
  /// before [ensureFreeLicense] has run).
  Future<License?> getCurrentLicense() async {
    final result = await client.rpc('get_current_license');

    if (result is List && result.isEmpty) return null;

    final row = _normalizeRow(result);
    if (row.isEmpty) return null;

    return _licenseFromRow(row);
  }

  /// Ensure a free-tier license row exists for a new user.
  ///
  /// Safe to call on every login — the RPC is idempotent.
  Future<License?> ensureFreeLicense() async {
    final result = await client.rpc('create_free_license');
    final row = _normalizeRow(result);

    if (row.isNotEmpty && row['success'] == false) {
      throw Exception(row['message'] ?? 'Failed to create free license');
    }

    return getCurrentLicense();
  }

  // ─── License key activation ───────────────────────────────────────────────────

  /// Activate a license key purchased outside the app (e.g. sold manually).
  ///
  /// Throws if the key is invalid, already redeemed, or the RPC returns an
  /// error payload.
  Future<License> activateLicenseKey(String licenseKey) async {
    final result = await client.rpc(
      'activate_license_key',
      params: {'p_key_code': licenseKey.trim()},
    );

    final row = _normalizeRow(result);

    if (row.isEmpty) {
      throw Exception('Empty response from license activation');
    }

    if (row['success'] != true) {
      throw Exception(row['message'] ?? 'Failed to activate license');
    }

    return _licenseFromRow(row);
  }

  // ─── Client count management ──────────────────────────────────────────────────

  /// Returns true if the user is still within their tier's client limit.
  Future<bool> canAddMoreClients() async {
    final license = await getCurrentLicense();
    return license?.canAddMoreClients ?? false;
  }

  /// Increment the `clients_used` counter on the server.
  ///
  /// Call this immediately after a new customer is saved.
  Future<void> incrementClientCount() async {
    await _executeCountRpc('increment_license_client_count');
  }

  /// Decrement the `clients_used` counter on the server.
  ///
  /// Call this after a customer record is permanently deleted.
  Future<void> decrementClientCount() async {
    await _executeCountRpc('decrement_license_client_count');
  }

  Future<void> _executeCountRpc(String functionName) async {
    final result = await client.rpc(functionName);
    final row = _normalizeRow(result);

    if (row.isEmpty) throw Exception('Empty response from $functionName');
    if (row['success'] != true) {
      throw Exception(row['message'] ?? 'Failed in $functionName');
    }
  }

  // ─── Status summary ───────────────────────────────────────────────────────────

  /// Convenience method for displaying license info in the UI.
  Future<Map<String, dynamic>> checkLicenseStatus() async {
    final license = await getCurrentLicense();

    if (license == null) {
      return {'valid': false, 'message': 'No active license'};
    }

    final expired = license.isExpired && !license.isInGracePeriod;

    if (expired && license.tier != LicenseTier.free) {
      return {
        'valid': false,
        'message': 'License expired',
        'tier': license.tier.displayName,
      };
    }

    return {
      'valid': true,
      'tier': license.tier.displayName,
      'clients_used': license.clientsUsed,
      'max_clients': license.effectiveClientLimit,
      'remaining_clients': license.remainingClients,
      'expires_at': license.daysUntilExpiry,
    };
  }
}