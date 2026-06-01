enum LicenseTier {
  free,
  basic,
  professional,
  monthly,
}

extension LicenseTierExtension on LicenseTier {
  String get displayName {
    switch (this) {
      case LicenseTier.free:
        return 'Free';
      case LicenseTier.basic:
        return 'Basic';
      case LicenseTier.professional:
        return 'Professional';
      case LicenseTier.monthly:
        return 'Monthly';
    }
  }

  int get maxClients {
    switch (this) {
      case LicenseTier.free:
        return 5;
      case LicenseTier.basic:
        return 50;
      case LicenseTier.professional:
        return 500;
      case LicenseTier.monthly:
        return 50; // Same as basic, but expires monthly
    }
  }

  double get price {
    switch (this) {
      case LicenseTier.free:
        return 0.0;
      case LicenseTier.basic:
        return 3000.0; // ₦3000
      case LicenseTier.professional:
        return 6000.0; // ₦6000
      case LicenseTier.monthly:
        return 500.0; // ₦500/month
    }
  }

  String get priceDisplay {
    if (price == 0) return 'Free';
    return '₦${price.toStringAsFixed(0)}';
  }

  bool get isExpirable {
    return this == LicenseTier.monthly;
  }

  List<String> get features {
    switch (this) {
      case LicenseTier.free:
        return [
          'Up to 5 clients',
          'Basic measurements',
          'Local backup only',
          'No cloud sync',
        ];
      case LicenseTier.basic:
        return [
          'Up to 50 clients',
          'Full measurements',
          'Cloud backup',
          'Email support',
        ];
      case LicenseTier.professional:
        return [
          'Up to 500 clients',
          'Advanced reports',
          'Cloud backup & sync',
          'Priority support',
          'Custom fields',
        ];
      case LicenseTier.monthly:
        return [
          'Up to 50 clients (monthly)',
          'Full measurements',
          'Cloud backup',
          'Expires in 30 days',
        ];
    }
  }
}

class License {
  static const int gracePeriodDays = 7;

  final String id;
  final String userId;
  final String? licenseKey;
  final LicenseTier tier;
  final DateTime activatedAt;
  final DateTime? expiresAt; // Only for monthly tier
  final int clientLimit;
  final int clientsUsed;
  final bool isActiveOnServer;

  License({
    required this.id,
    required this.userId,
    this.licenseKey,
    required this.tier,
    required this.activatedAt,
    this.expiresAt,
    required this.clientLimit,
    this.clientsUsed = 0,
    this.isActiveOnServer = true,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isInGracePeriod {
    if (expiresAt == null || !isExpired) return false;
    return DateTime.now().isBefore(
      expiresAt!.add(const Duration(days: gracePeriodDays)),
    );
  }

  int get daysInGracePeriod {
    if (!isInGracePeriod || expiresAt == null) return 0;
    final graceEndsAt = expiresAt!.add(const Duration(days: gracePeriodDays));
    final remaining = graceEndsAt.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  LicenseTier get effectiveTier {
    if (!isActiveOnServer || (isExpired && !isInGracePeriod)) {
      return LicenseTier.free;
    }
    return tier;
  }

  bool get isActive {
    return isActiveOnServer && !isExpired;
  }

  bool get isUsable {
    return isActive || isInGracePeriod || tier == LicenseTier.free;
  }

  bool get canAddMoreClients {
    return clientsUsed < effectiveClientLimit;
  }

  int get remainingClients {
    return effectiveClientLimit - clientsUsed;
  }

  int get effectiveClientLimit {
    if (effectiveTier == LicenseTier.free) {
      return LicenseTier.free.maxClients;
    }
    return clientLimit;
  }

  String get daysUntilExpiry {
    if (expiresAt == null) return 'Never';
    final now = DateTime.now();
    if (isExpired) return 'Expired';
    final difference = expiresAt!.difference(now).inDays;
    return '$difference days';
  }

  String get expiryDateFormatted {
    if (expiresAt == null) return 'Never';
    final date = expiresAt!;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool get needsVerification {
    if (tier == LicenseTier.free) return false;
    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'license_key': licenseKey,
      'tier': tier.toString().split('.').last,
      'activated_at': activatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'client_limit': clientLimit,
      'clients_used': clientsUsed,
      'is_active': isActiveOnServer,
    };
  }

  factory License.fromMap(Map<String, dynamic> map) {
    final tier = LicenseTier.values.firstWhere(
      (e) => e.toString().split('.').last == map['tier'],
      orElse: () => LicenseTier.free,
    );

    return License(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      licenseKey: map['license_key'],
      tier: tier,
      activatedAt: DateTime.tryParse(map['activated_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      clientLimit: map['client_limit'] ?? tier.maxClients,
      clientsUsed: map['clients_used'] ?? 0,
      isActiveOnServer: map['is_active'] ?? true,
    );
  }
}
