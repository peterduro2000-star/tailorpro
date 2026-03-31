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
  final String id;
  final String userId;
  final String licenseKey;
  final LicenseTier tier;
  final DateTime activatedAt;
  final DateTime? expiresAt; // Only for monthly tier
  final int clientsUsed;

  License({
    required this.id,
    required this.userId,
    required this.licenseKey,
    required this.tier,
    required this.activatedAt,
    this.expiresAt,
    this.clientsUsed = 0,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isActive {
    return !isExpired;
  }

  bool get canAddMoreClients {
    return clientsUsed < tier.maxClients;
  }

  int get remainingClients {
    return tier.maxClients - clientsUsed;
  }

  String get daysUntilExpiry {
    if (expiresAt == null) return 'Never';
    final now = DateTime.now();
    if (isExpired) return 'Expired';
    final difference = expiresAt!.difference(now).inDays;
    return '$difference days';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'license_key': licenseKey,
      'tier': tier.toString().split('.').last,
      'activated_at': activatedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'clients_used': clientsUsed,
    };
  }

  factory License.fromMap(Map<String, dynamic> map) {
    return License(
      id: map['id'],
      userId: map['user_id'],
      licenseKey: map['license_key'],
      tier: LicenseTier.values.firstWhere(
        (e) => e.toString().split('.').last == map['tier'],
      ),
      activatedAt: DateTime.parse(map['activated_at']),
      expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      clientsUsed: map['clients_used'] ?? 0,
    );
  }
}