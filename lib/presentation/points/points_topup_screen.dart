import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/app_supabase.dart';
import '../../core/ui/ui.dart';
import '../../domain/repositories/points_repository.dart';
import '../locale/l10n_context.dart';
import 'points_balance_notifier.dart';
import 'points_topup_catalog.dart';

class PointsTopUpScreen extends StatefulWidget {
  const PointsTopUpScreen({super.key});

  @override
  State<PointsTopUpScreen> createState() => _PointsTopUpScreenState();
}

class _PointsTopUpScreenState extends State<PointsTopUpScreen> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _storeAvailable = false;
  bool _loadingProducts = true;
  String? _error;
  String? _pendingProductId;
  final Map<String, ProductDetails> _products = {};
  final Set<String> _processedPurchaseKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _purchaseSub = _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () {
      _purchaseSub?.cancel();
      _purchaseSub = null;
    });
    unawaited(_loadProducts());
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final available = await _iap.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() {
        _storeAvailable = false;
        _loadingProducts = false;
        _error = context.trRead('pointsTopupStoreUnavailable');
      });
      return;
    }

    final ids = pointTopUpPacks.map((e) => e.productId).toSet();
    final res = await _iap.queryProductDetails(ids);
    if (!mounted) return;

    final map = <String, ProductDetails>{};
    for (final p in res.productDetails) {
      map[p.id] = p;
    }
    setState(() {
      _storeAvailable = true;
      _loadingProducts = false;
      _error = res.error?.message;
      _products
        ..clear()
        ..addAll(map);
    });
  }

  String _storeFromPurchase(PurchaseDetails p) {
    final src = p.verificationData.source.toLowerCase();
    if (src.contains('app')) return 'app_store';
    return 'play_store';
  }

  String _receiptKey(PurchaseDetails p) {
    final tx = (p.purchaseID ?? '').trim();
    if (tx.isNotEmpty) return tx;
    final server = p.verificationData.serverVerificationData.trim();
    if (server.isNotEmpty) return server;
    return '${p.productID}:${p.transactionDate ?? ''}';
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      if (p.status == PurchaseStatus.pending) {
        if (!mounted) return;
        setState(() => _pendingProductId = p.productID);
        continue;
      }

      if (p.status == PurchaseStatus.error) {
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
        if (!mounted) return;
        setState(() {
          _pendingProductId = null;
          _error = p.error?.message ?? context.trRead('pointsTopupPurchaseFailed');
        });
        continue;
      }

      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        final pack = pointPackByProductId(p.productID);
        if (pack == null) {
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          continue;
        }
        final receiptKey = _receiptKey(p);
        if (_processedPurchaseKeys.contains(receiptKey)) {
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          continue;
        }
        _processedPurchaseKeys.add(receiptKey);

        final repo = context.read<PointsRepository>();
        final notifier = context.read<PointsBalanceNotifier>();
        final out = await repo.creditIapPoints(
          store: _storeFromPurchase(p),
          transactionId: p.purchaseID ?? receiptKey,
          productId: p.productID,
          purchaseToken: p.verificationData.serverVerificationData,
          points: pack.points,
          usdCents: pack.usdCents,
          rawReceipt: p.verificationData.localVerificationData,
        );
        if (p.pendingCompletePurchase) {
          await _iap.completePurchase(p);
        }
        if (!mounted) return;
        if (out.ok) {
          notifier.setBalance(out.balance);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('pointsTopupSuccess', params: {'points': '${pack.points}'}))),
          );
          setState(() {
            _pendingProductId = null;
            _error = null;
          });
        } else {
          setState(() {
            _pendingProductId = null;
            _error = out.error ?? context.trRead('pointsTopupCreditFailed');
          });
        }
      }
    }
  }

  Future<void> _buy(ProductDetails pd) async {
    final user = AppSupabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('loginRequired'))));
      return;
    }
    setState(() {
      _pendingProductId = pd.id;
      _error = null;
    });
    final param = PurchaseParam(productDetails: pd);
    await _iap.buyConsumable(purchaseParam: param);
  }

  String _fallbackPrice(PointTopUpPack pack) {
    return '\$${(pack.usdCents / 100).toStringAsFixed(2)}';
  }

  String _valueLabel(BuildContext context, PointTopUpPack pack) {
    final pointsPerDollar = (pack.points / (pack.usdCents / 100)).round();
    return context.tr('pointsTopupValueLabel', params: {'points': '$pointsPerDollar'});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppPageScaffold(
      title: context.tr('pointsTopupTitle'),
      subtitle: context.tr('pointsTopupSubtitle'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageH, 8, AppSpacing.pageH, AppSpacing.pageBottom),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Text(
              context.tr('pointsTopupRateHint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingProducts) const Center(child: CircularProgressIndicator()),
          if (!_loadingProducts && _error != null) ...[
            Text(_error!, style: TextStyle(color: scheme.error)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('retry')),
            ),
            const SizedBox(height: 8),
          ],
          for (final pack in pointTopUpPacks)
            Card(
              child: ListTile(
                leading: Icon(Icons.stars_rounded, color: scheme.secondary),
                title: Text(context.tr('pointsTopupPackTitle', params: {'points': '${pack.points}'})),
                subtitle: Text(
                  '${_products[pack.productId]?.price ?? _fallbackPrice(pack)} · ${_valueLabel(context, pack)}',
                ),
                trailing: FilledButton(
                  onPressed: (!_storeAvailable || _pendingProductId != null || !_products.containsKey(pack.productId))
                      ? null
                      : () => _buy(_products[pack.productId]!),
                  child: _pendingProductId == pack.productId
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('pointsTopupBuy')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
