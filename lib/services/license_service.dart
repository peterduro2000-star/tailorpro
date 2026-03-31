import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/license_model.dart';
import 'license_key_manager.dart';

class LicenseService {
  final SupabaseClient client;

  LicenseService({required this.client});

  /// Activate a license key for the current user
  Future<License?> activateLicenseKey(String userId, String licenseKey) async {
    try {
      // Validate the key format
      if (!LicenseKeyManager.validateLicenseKey(licenseKey)) {
        throw Exception('Invalid license key format');
      }

      // Get tier from key
      final tier = LicenseKeyManager.getTierFromKey(licenseKey);
      if (tier == null) {
        throw Exception('Could not determine license tier');
      }

      final now = DateTime.now();
      final expiresAt = tier.isExpirable ? now.add(Duration(days: 30)) : null;

      final license = License(
        id: const Uuid().v4(),
        userId: userId,
        licenseKey: licenseKey,
        tier: tier,
        activatedAt: now,
        expiresAt: expiresAt,
        clientsUsed: 0,
      );

      // Save to Supabase
      await client.from('user_licenses').upsert(license.toMap());

      return license;
    } catch (e) {
      throw Exception('Failed to activate license: $e');
    }
  }

  /// Get current license for user
  Future<License?> getLicense(String userId) async {
    try {
      final response = await client
          .from('user_licenses')
          .select()
          .eq('user_id', userId)
          .order('activated_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return License.fromMap(response[0]);
    } catch (e) {
      print('Error fetching license: $e');
      return null;
    }
  }

  /// Create a free tier license for new users
  Future<License?> createFreeTierLicense(String userId) async {
    try {
      final licenseKey = LicenseKeyManager.generateFreeTierKey(userId);

      final license = License(
        id: const Uuid().v4(),
        userId: userId,
        licenseKey: licenseKey,
        tier: LicenseTier.free,
        activatedAt: DateTime.now(),
        clientsUsed: 0,
      );

      await client.from('user_licenses').upsert(license.toMap());
      return license;
    } catch (e) {
      throw Exception('Failed to create free tier license: $e');
    }
  }

  /// Check if user can add more clients
  Future<bool> canAddMoreClients(String userId) async {
    try {
      final license = await getLicense(userId);
      if (license == null) return false;
      return license.canAddMoreClients;
    } catch (e) {
      return false;
    }
  }

  /// Increment clients used count
  Future<void> incrementClientCount(String userId) async {
    try {
      final license = await getLicense(userId);
      if (license == null) throw Exception('No active license');

      final newCount = license.clientsUsed + 1;
      if (newCount > license.tier.maxClients) {
        throw Exception('Client limit reached for ${license.tier.displayName} tier');
      }

      await client
          .from('user_licenses')
          .update({'clients_used': newCount})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update client count: $e');
    }
  }

  /// Decrement clients used count
  Future<void> decrementClientCount(String userId) async {
    try {
      final license = await getLicense(userId);
      if (license == null) throw Exception('No active license');

      final newCount = (license.clientsUsed - 1).clamp(0, license.tier.maxClients);

      await client
          .from('user_licenses')
          .update({'clients_used': newCount})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update client count: $e');
    }
  }

  /// Renew monthly license
  Future<License?> renewMonthlyLicense(String userId) async {
    try {
      final license = await getLicense(userId);
      if (license == null || license.tier != LicenseTier.monthly) {
        throw Exception('No monthly license to renew');
      }

      final newExpiresAt = DateTime.now().add(const Duration(days: 30));

      await client
          .from('user_licenses')
          .update({
            'expires_at': newExpiresAt.toIso8601String(),
            'clients_used': 0, // Reset client count on renewal
          })
          .eq('user_id', userId);

      return await getLicense(userId);
    } catch (e) {
      throw Exception('Failed to renew monthly license: $e');
    }
  }

  /// Check license validity and status
  Future<Map<String, dynamic>> checkLicenseStatus(String userId) async {
    try {
      final license = await getLicense(userId);

      if (license == null) {
        return {
          'valid': false,
          'message': 'No active license',
        };
      }

      if (!license.isActive) {
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
        'max_clients': license.tier.maxClients,
        'remaining_clients': license.remainingClients,
        'expires_at': license.daysUntilExpiry,
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Error checking license: $e',
      };
    }
  }
}