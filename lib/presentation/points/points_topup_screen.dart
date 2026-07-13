import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/rewarded_ad_service.dart';
import '../../core/ui/holo/holo_tokens.dart';
import '../../core/ui/holo/holo_widgets.dart';
import '../../core/ui/ui.dart';
import '../../data/repositories/local_points_repository_impl.dart';
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
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onDone: () {
        _purchaseSub?.cancel();
        _purchaseSub = null;
      },
    );
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
          _error =
              p.error?.message ?? context.trRead('pointsTopupPurchaseFailed');
        });
        continue;
      }

      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
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
            SnackBar(
              content: Text(
                context.tr(
                  'pointsTopupSuccess',
                  params: {'points': '${pack.points}'},
                ),
              ),
            ),
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
    setState(() {
      _pendingProductId = pd.id;
      _error = null;
    });
    final param = PurchaseParam(productDetails: pd);
    await _iap.buyConsumable(purchaseParam: param);
  }

  String _formatPriceNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  String _fallbackPrice(PointTopUpPack pack) {
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'ja') return '¥${_formatPriceNumber(pack.jpy)}';
    return '₩${_formatPriceNumber(pack.krw)}';
  }

  String _valueLabel(BuildContext context, PointTopUpPack pack) {
    final lang = Localizations.localeOf(context).languageCode;
    final price = lang == 'ja' ? pack.jpy : pack.krw;
    return context.tr(
      'pointsTopupValueLabel',
      params: {'price': _formatPriceNumber(price)},
    );
  }

  void _showMissingProductMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('pointsTopupProductMissing'))),
    );
    unawaited(_loadProducts());
  }

  String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _watchAd() async {
    final ad = context.read<RewardedAdService>();
    final pts = context.read<LocalPointsRepositoryImpl>();
    final notifier = context.read<PointsBalanceNotifier>();
    final shown = await ad.show(
      onEarned: () async {
        final r = await pts.recordAdReward(today: _today());
        if (r.credited) {
          notifier.setBalance(r.balance);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('+${AdConfig.pointsPerAd}pt')),
            );
          }
        }
      },
    );
    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('adEarnNotReady'))),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.tr('pointsTopupTitle'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageH,
          8,
          AppSpacing.pageH,
          AppSpacing.pageBottom,
        ),
        children: [
          Builder(
            builder: (context) {
              final pts = context.read<LocalPointsRepositoryImpl>();
              final adReady = context.watch<RewardedAdService>().isReady;
              final remaining = pts.adsRemainingToday(today: _today());
              final capReached = remaining == 0;
              return _AdShimmerCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Holo.holoGradient),
                      child: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('adEarnTitle'),
                            style: const TextStyle(color: Holo.inkPlum, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            capReached
                                ? context.tr('adEarnCapReached')
                                : '${context.tr('adEarnSubtitle', params: {
                                      'points': '${AdConfig.pointsPerAd}',
                                    })}\n${context.tr('adEarnRemaining', params: {
                                      'remaining': '$remaining',
                                      'max': '${AdConfig.maxAdsPerDay}',
                                    })}',
                            style: const TextStyle(color: Holo.inkPlumSoft, height: 1.3),
                          ),
                          const SizedBox(height: 12),
                          HoloButton(
                            icon: Icons.play_arrow_rounded,
                            label: !adReady && !capReached ? context.tr('adEarnNotReady') : context.tr('adEarnWatch'),
                            onPressed: (capReached || !adReady) ? null : _watchAd,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (_loadingProducts) const AppLoadingBody(),
          if (!_loadingProducts && _error != null) ...[
            Text(_error!, style: const TextStyle(color: Holo.pink)),
            const SizedBox(height: 8),
            Center(
              child: HoloButton(
                icon: Icons.refresh_rounded,
                label: context.tr('retry'),
                onPressed: _loadProducts,
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (final pack in pointTopUpPacks)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HoloCard(
                child: Builder(
                  builder: (context) {
                    final product = _products[pack.productId];
                    final canAttemptPurchase =
                        _storeAvailable && _pendingProductId == null;
                    return Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Holo.lemon.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.stars_rounded, color: Holo.inkPlum, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  'pointsTopupPackTitle',
                                  params: {'points': '${pack.points}'},
                                ),
                                style: const TextStyle(color: Holo.inkPlum, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${product?.price ?? _fallbackPrice(pack)} · ${_valueLabel(context, pack)}',
                                style: const TextStyle(color: Holo.inkPlumSoft, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _pendingProductId == pack.productId
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Holo.pink),
                              )
                            : HoloButton(
                                label: product == null
                                    ? context.tr('pointsTopupCheckStore')
                                    : context.tr('pointsTopupBuy'),
                                onPressed: !canAttemptPurchase
                                    ? null
                                    : product == null
                                    ? _showMissingProductMessage
                                    : () => _buy(product),
                              ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Holographic shimmer sweep behind the ad-earning card content — the visual
/// hero of the top-up screen. Purely decorative: a diagonal translucent band
/// slides across the card on a gentle 2s repeating loop.
class _AdShimmerCard extends StatefulWidget {
  const _AdShimmerCard({required this.child});

  final Widget child;

  @override
  State<_AdShimmerCard> createState() => _AdShimmerCardState();
}

class _AdShimmerCardState extends State<_AdShimmerCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Holo.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Holo.pink.withValues(alpha: 0.35), width: 2),
        boxShadow: Holo.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(padding: const EdgeInsets.all(14), child: widget.child),
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final dx = -w * 0.6 + _controller.value * (w * 1.9);
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: Transform.rotate(
                            angle: -0.35,
                            child: Container(
                              width: w * 0.45,
                              height: h * 2.2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.45),
                                    Holo.cyan.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.0, 0.45, 0.65, 1.0],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
