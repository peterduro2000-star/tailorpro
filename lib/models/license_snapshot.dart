import 'license_model.dart';

/// Lightweight snapshot of a license plus cache timestamp for UI use.
class LicenseSnapshot {
  final License? license;
  final DateTime? cachedAt;

  LicenseSnapshot(this.license, this.cachedAt);

  bool get isPro => license?.effectiveTier == LicenseTier.pro;

  bool get isExpired {
    if (license?.expiresAt == null) return false;
    return DateTime.now().isAfter(license!.expiresAt!);
  }

  bool get inGracePeriod {
    if (!isExpired) return false;
    if (license?.expiresAt == null) return false;
    final diff = DateTime.now().difference(license!.expiresAt!).inDays;
    return diff <= License.gracePeriodDays;
  }

  int get maxClients => license?.clientLimit ?? LicenseTier.free.maxClients;

  int get usedClients => license?.clientsUsed ?? 0;

  int get remainingClients {
    final remaining = maxClients - usedClients;
    return remaining < 0 ? 0 : remaining;
  }
}
