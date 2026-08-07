import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_service.dart';

class PaystackPaymentService implements PaymentService {
  static const String _functionName = 'create-paystack-payment';
  static const String _verifyFunctionName = 'verify-paystack';

  @override
  Future<String?> purchasePro({required String email}) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('=== PaystackPaymentService: session is null');
        return null;
      }

      debugPrint('=== PaystackPaymentService: calling $_functionName');

      final response = await Supabase.instance.client.functions.invoke(
        _functionName,
        body: {'email': email},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      debugPrint('=== PaystackPaymentService: status=${response.status}');
      debugPrint('=== PaystackPaymentService: data=${response.data}');

      if (response.status != 200) return null;

      final raw = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final authUrl = raw['authorization_url'] as String?;
      final reference = raw['reference'] as String?;

      if (authUrl == null || reference == null) {
        debugPrint('=== PaystackPaymentService: missing authUrl or reference');
        return null;
      }

      await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );

      return reference;
    } catch (e, st) {
      debugPrint('=== PaystackPaymentService ERROR: $e');
      debugPrint('$st');
      return null;
    }
  }

  @override
  Future<bool> verifyPayment(String reference) async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;

      final response = await Supabase.instance.client.functions.invoke(
        _verifyFunctionName,
        body: {'reference': reference},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      debugPrint('=== PaystackPaymentService: verify status=${response.status}');

      return response.status == 200;
    } catch (e, st) {
      debugPrint('=== PaystackPaymentService verifyPayment ERROR: $e\n$st');
      return false;
    }
  }

  @override
  Future<String?> getDisplayPrice() async => '₦4,000';
}
