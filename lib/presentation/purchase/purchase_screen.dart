import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../models/license_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/in_app_purchase_service.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final InAppPurchaseService _iapService = InAppPurchaseService();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _initializing = true;
  bool _purchaseInProgress = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _subscription = _iapService.purchaseUpdates.listen(_listenToPurchaseUpdated,
        onError: _handlePurchaseError);
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    try {
      await _iapService.init();
    } catch (e) {
      _statusMessage = 'Failed to initialize purchases: $e';
    }
    if (mounted) {
      setState(() {
        _initializing = false;
      });
    }
  }

  void _handlePurchaseError(Object error) {
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Purchase error: $error';
      _purchaseInProgress = false;
    });
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Purchase pending...';
          _purchaseInProgress = true;
        });
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handlePurchaseError(purchaseDetails.error ?? 'Unknown purchase error');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        await _deliverPurchase(purchaseDetails);
      }
    }
  }

  Future<void> _deliverPurchase(PurchaseDetails purchaseDetails) async {
    final tier = _iapService.tierForProductId(purchaseDetails.productID);
    if (tier == null) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Unsupported product purchased: ${purchaseDetails.productID}';
          _purchaseInProgress = false;
        });
      }
      await _iapService.completePurchase(purchaseDetails);
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.applyIapPurchase(tier);
      await _iapService.completePurchase(purchaseDetails);

      if (!mounted) return;
      setState(() {
        _statusMessage = '${tier.displayName} unlocked successfully!';
        _purchaseInProgress = false;
      });
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Purchase completed but could not unlock license: $e';
        _purchaseInProgress = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
    if (!_iapService.available) {
      return Center(
        child: Text(
          'In-app purchases are not available on this device.\nTry again on a Google Play-enabled device.',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_iapService.products.isEmpty) {
      return Center(
        child: Text(
          _iapService.lastError ?? 'No purchase products are configured yet.',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Choose a license to unlock pro limits and premium features.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: _iapService.products.map(_buildProductCard).toList(),
          ),
        ),
        if (_statusMessage != null) ...[
          Text(_statusMessage!, style: const TextStyle(color: Colors.orange)),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed: _purchaseInProgress ? null : _restorePurchases,
          icon: const Icon(Icons.refresh),
          label: const Text('Restore purchases'),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductDetails product) {
    final tier = _iapService.tierForProductId(product.id);
    if (tier == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tier.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(product.price, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ...tier.features.map((feature) => Text('• $feature')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _purchaseInProgress
                    ? null
                    : () => _buyProduct(product),
                child: Text('Buy ${tier.displayName}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyProduct(ProductDetails product) async {
    if (_purchaseInProgress || !_iapService.available) return;
    setState(() {
      _purchaseInProgress = true;
      _statusMessage = 'Starting purchase...';
    });
    try {
      await _iapService.buyProduct(product);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchaseInProgress = false;
        _statusMessage = 'Failed to begin purchase: $e';
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (!_iapService.available) return;
    setState(() {
      _purchaseInProgress = true;
      _statusMessage = 'Restoring purchases...';
    });
    try {
      await _iapService.restorePurchases();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _purchaseInProgress = false;
        _statusMessage = 'Restore failed: $e';
      });
    }
  }
}
