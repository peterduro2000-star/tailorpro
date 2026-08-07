import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/license_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment/payment_service.dart';
import '../../services/payment/play_billing_payment_service.dart';
import '../../services/payment/payment_service_factory.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  late final PaymentService _paymentService;
  bool _initializing = true;
  bool _purchaseInProgress = false;
  String? _statusMessage;
  String? _displayPrice;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentServiceFactory.create();
    _loadDisplayPrice();
  }

  Future<void> _loadDisplayPrice() async {
    try {
      final price = await _paymentService.getDisplayPrice();
      if (mounted && price != null) {
        setState(() => _displayPrice = price);
      }
    } catch (_) {
      // use fallback price
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  String get _priceLabel => _displayPrice ?? LicenseTier.pro.priceDisplay;

  bool get _isPlayBilling => _paymentService is PlayBillingPaymentService;

  Future<void> _handleUpgrade() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || user.email == null) {
      _showError('Please sign in to upgrade.');
      return;
    }

    setState(() {
      _purchaseInProgress = true;
      _statusMessage = 'Starting payment...';
    });

    try {
      final reference = await _paymentService.purchasePro(email: user.email!);

      if (reference == null || !mounted) {
        setState(() {
          _statusMessage = 'Could not start payment. Please try again.';
          _purchaseInProgress = false;
        });
        return;
      }

      setState(() {
        _purchaseInProgress = false;
        _statusMessage = null;
      });

      final verified = await _showConfirmationDialog(reference);

      if (!mounted || !verified) return;

      setState(() {
        _purchaseInProgress = true;
        _statusMessage = 'Confirming payment...';
      });

      final authProvider = context.read<AuthProvider>();

      bool confirmed = false;
      for (int attempt = 0; attempt < 3; attempt++) {
        await authProvider.refreshLicense();
        if (!mounted) return;
        if (authProvider.effectiveTier == LicenseTier.pro) {
          confirmed = true;
          break;
        }
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (!mounted) return;

      if (!confirmed) {
        setState(() {
          _statusMessage =
              'Payment was received, but we couldn\'t confirm your Pro '
              'license yet. Please close this screen and reopen it in a '
              'moment — if it still shows Free, contact support with your '
              'payment reference.';
          _purchaseInProgress = false;
        });
        return;
      }

      setState(() {
        _statusMessage = '${LicenseTier.pro.displayName} unlocked successfully!';
        _purchaseInProgress = false;
      });

      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error: $e';
        _purchaseInProgress = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(String reference) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentConfirmationDialog(
        onVerify: () => _paymentService.verifyPayment(reference),
        isPlayBilling: _isPlayBilling,
      ),
    );
    return result ?? false;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade TailorPro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _initializing
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isPro = context.watch<AuthProvider>().effectiveLicenseTier == LicenseTier.pro;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPro
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPro
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPro ? Icons.workspace_premium : Icons.lock_open_outlined,
                  color: isPro ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPro
                        ? 'You are on the Pro plan'
                        : 'You are currently on the Free plan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isPro ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose a license to unlock pro limits and premium features.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            title: 'Free',
            subtitle: 'For getting started',
            color: Colors.grey,
            benefits: LicenseTier.free.features,
            isCurrent: !isPro,
          ),
          const SizedBox(height: 12),
          _buildPlanCard(
            title: 'Pro',
            subtitle: 'For professional tailors',
            color: Colors.deepPurple,
            benefits: LicenseTier.pro.features,
            isCurrent: isPro,
          ),
          const SizedBox(height: 16),
          if (!isPro) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Secure Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lifetime Pro license — $_priceLabel.',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _purchaseInProgress ? null : _handleUpgrade,
                        child: Text(
                          _purchaseInProgress
                              ? 'Processing...'
                              : 'Pay $_priceLabel — Upgrade to Pro',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(_statusMessage!, style: const TextStyle(color: Colors.orange)),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required Color color,
    required List<String> benefits,
    required bool isCurrent,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isCurrent ? Border.all(color: color, width: 2) : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: isCurrent ? color.withValues(alpha: 0.05) : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(subtitle, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...benefits.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(f)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    (_paymentService as PlayBillingPaymentService?)?.dispose();
    super.dispose();
  }
}

class _PaymentConfirmationDialog extends StatefulWidget {
  final Future<bool> Function() onVerify;
  final bool isPlayBilling;

  const _PaymentConfirmationDialog({
    required this.onVerify,
    required this.isPlayBilling,
  });

  @override
  State<_PaymentConfirmationDialog> createState() => _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState extends State<_PaymentConfirmationDialog> {
  static const _pollInterval = Duration(seconds: 5);
  static const _maxAutoAttempts = 24;

  Timer? _pollTimer;
  bool _checking = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _check());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);

    bool ok = false;
    try {
      ok = await widget.onVerify();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;

    if (ok) {
      _pollTimer?.cancel();
      Navigator.of(context).pop(true);
      return;
    }

    _attempts++;
    if (_attempts >= _maxAutoAttempts) {
      _pollTimer?.cancel();
    }
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final timedOut = _attempts >= _maxAutoAttempts;

    return AlertDialog(
      title: const Text('Confirming your payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timedOut
                ? 'We still haven\'t seen your payment come through. '
                  'If you completed it, tap "Check now" — otherwise '
                  'you can cancel and try again.'
                : widget.isPlayBilling
                    ? 'Complete your purchase in Google Play. '
                      'This screen will confirm automatically.'
                    : 'Complete the payment in your browser. '
                      'This screen will confirm automatically.',
          ),
          if (!timedOut) ...[
            const SizedBox(height: 20),
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _checking ? null : _check,
          child: Text(_checking ? 'Checking...' : 'Check now'),
        ),
      ],
    );
  }
}