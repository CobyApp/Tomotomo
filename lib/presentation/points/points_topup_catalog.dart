class PointTopUpPack {
  final String productId;
  final int points;
  final int usdCents;

  const PointTopUpPack({
    required this.productId,
    required this.points,
    required this.usdCents,
  });
}

const List<PointTopUpPack> pointTopUpPacks = [
  PointTopUpPack(productId: 'tomotomo_points_300', points: 300, usdCents: 100),
  PointTopUpPack(productId: 'tomotomo_points_2000', points: 2000, usdCents: 500),
  PointTopUpPack(productId: 'tomotomo_points_5000', points: 5000, usdCents: 1000),
];

PointTopUpPack? pointPackByProductId(String productId) {
  for (final p in pointTopUpPacks) {
    if (p.productId == productId) return p;
  }
  return null;
}
