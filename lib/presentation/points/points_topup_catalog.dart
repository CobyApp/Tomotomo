class PointTopUpPack {
  final String productId;
  final int points;
  final int usdCents;
  final int krw;
  final int jpy;

  const PointTopUpPack({
    required this.productId,
    required this.points,
    required this.usdCents,
    required this.krw,
    required this.jpy,
  });
}

const List<PointTopUpPack> pointTopUpPacks = [
  PointTopUpPack(
    productId: 'tomotomo_points_300',
    points: 300,
    usdCents: 100,
    krw: 1500,
    jpy: 150,
  ),
  PointTopUpPack(
    productId: 'tomotomo_points_2000',
    points: 2000,
    usdCents: 500,
    krw: 7500,
    jpy: 800,
  ),
  PointTopUpPack(
    productId: 'tomotomo_points_5000',
    points: 5000,
    usdCents: 1000,
    krw: 15000,
    jpy: 1500,
  ),
];

PointTopUpPack? pointPackByProductId(String productId) {
  for (final p in pointTopUpPacks) {
    if (p.productId == productId) return p;
  }
  return null;
}
