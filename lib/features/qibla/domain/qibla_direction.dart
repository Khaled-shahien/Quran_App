import 'dart:math' as math;

/// Initial great-circle bearing, clockwise from geographic (true) north.
double qiblaBearing(double latitude, double longitude) {
  const kaabaLatitude = 21.422487;
  const kaabaLongitude = 39.826206;
  final lat = latitude * math.pi / 180;
  const target = kaabaLatitude * math.pi / 180;
  final delta = (kaabaLongitude - longitude) * math.pi / 180;
  final y = math.sin(delta) * math.cos(target);
  final x =
      math.cos(lat) * math.sin(target) -
      math.sin(lat) * math.cos(target) * math.cos(delta);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Signed shortest turn; positive means turn clockwise (right).
double qiblaTurn(double bearing, double heading) =>
    (bearing - heading + 540) % 360 - 180;
