import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/license_model.dart';

class LicenseKeyManager {
  // Generate a valid license key for a given tier
  static String generateLicenseKey(String userId, LicenseTier tier) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final tierCode = _getTierCode(tier);
    
    // Format: TP-{TIERCODE}-{USERID}-{TIMESTAMP}-{CHECKSUM}
    final keyWithoutChecksum = 'TP-$tierCode-${userId.substring(0, 8).toUpperCase()}-$timestamp';
    final checksum = _generateChecksum(keyWithoutChecksum);
    
    return '$keyWithoutChecksum-$checksum';
  }

  // Validate a license key format and authenticity
  static bool validateLicenseKey(String licenseKey) {
    try {
      final parts = licenseKey.split('-');
      if (parts.length != 5) return false;
      
      // Check prefix
      if (parts[0] != 'TP') return false;
      
      // Check tier code
      if (!['FR', 'BS', 'PR', 'MO'].contains(parts[1])) return false;
      
      // Reconstruct and verify checksum
      final keyWithoutChecksum = '${parts[0]}-${parts[1]}-${parts[2]}-${parts[3]}';
      final expectedChecksum = _generateChecksum(keyWithoutChecksum);
      
      return parts[4] == expectedChecksum;
    } catch (e) {
      return false;
    }
  }

  // Extract tier from license key
  static LicenseTier? getTierFromKey(String licenseKey) {
    try {
      final parts = licenseKey.split('-');
      if (parts.length < 2) return null;
      
      return _getTierFromCode(parts[1]);
    } catch (e) {
      return null;
    }
  }

  // Private helper: Get tier code
  static String _getTierCode(LicenseTier tier) {
    switch (tier) {
      case LicenseTier.free:
        return 'FR';
      case LicenseTier.basic:
        return 'BS';
      case LicenseTier.professional:
        return 'PR';
      case LicenseTier.monthly:
        return 'MO';
    }
  }

  // Private helper: Get tier from code
  static LicenseTier? _getTierFromCode(String code) {
    switch (code) {
      case 'FR':
        return LicenseTier.free;
      case 'BS':
        return LicenseTier.basic;
      case 'PR':
        return LicenseTier.professional;
      case 'MO':
        return LicenseTier.monthly;
      default:
        return null;
    }
  }

  // Generate checksum using SHA256
  static String _generateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8).toUpperCase();
  }

  // Create a demo/test license key (for free tier)
  static String generateFreeTierKey(String userId) {
    return generateLicenseKey(userId, LicenseTier.free);
  }
}