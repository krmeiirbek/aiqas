import 'dart:math';
import 'dart:ui';

class Orientation {
  const Orientation({
    required this.f0,
    required this.f1,
    required this.f2,
    required this.f3,
    required this.b0,
    required this.b1,
    required this.b2,
    required this.b3,
    required this.startAngle,
  });

  final double f0;
  final double f1;
  final double f2;
  final double f3;
  final double b0;
  final double b1;
  final double b2;
  final double b3;
  final double startAngle;
}

const Orientation pointy = Orientation(
  f0: sqrt(3.0),
  f1: sqrt(3.0) / 2.0,
  f2: 0.0,
  f3: 1.5,
  b0: sqrt(3.0) / 3.0,
  b1: -1.0 / 3.0,
  b2: 0.0,
  b3: 2.0 / 3.0,
  startAngle: 0.5,
);

class Hex {
  const Hex(this.q, this.r, [int? s]) : s = s ?? -q - r;

  final int q;
  final int r;
  final int s;

  static const directions = [
    Hex(1, 0, -1),
    Hex(1, -1, 0),
    Hex(0, -1, 1),
    Hex(-1, 0, 1),
    Hex(-1, 1, 0),
    Hex(0, 1, -1),
  ];

  Hex operator +(Hex other) => Hex(q + other.q, r + other.r, s + other.s);

  Iterable<Hex> neighbors() sync* {
    for (final direction in directions) {
      yield this + direction;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Hex && other.q == q && other.r == r && other.s == s;
  }

  @override
  int get hashCode => Object.hash(q, r, s);
}

class FractionalHex {
  const FractionalHex(this.q, this.r, this.s);

  final double q;
  final double r;
  final double s;

  Hex round() {
    var rq = q.round();
    var rr = r.round();
    var rs = s.round();

    final qDiff = (rq - q).abs();
    final rDiff = (rr - r).abs();
    final sDiff = (rs - s).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      rq = -rr - rs;
    } else if (rDiff > sDiff) {
      rr = -rq - rs;
    } else {
      rs = -rq - rr;
    }

    return Hex(rq, rr, rs);
  }
}

class HexLayout {
  HexLayout({
    required this.orientation,
    required this.size,
    required this.origin,
  });

  final Orientation orientation;
  final double size;
  final Offset origin;

  HexLayout copyWith({
    Orientation? orientation,
    double? size,
    Offset? origin,
  }) {
    return HexLayout(
      orientation: orientation ?? this.orientation,
      size: size ?? this.size,
      origin: origin ?? this.origin,
    );
  }

  Offset hexToPixel(Hex hex) {
    final x = (orientation.f0 * hex.q + orientation.f1 * hex.r) * size;
    final y = (orientation.f2 * hex.q + orientation.f3 * hex.r) * size;
    return Offset(x, y) + origin;
  }

  FractionalHex pixelToHex(Offset point) {
    final pt = Offset(
      (point.dx - origin.dx) / size,
      (point.dy - origin.dy) / size,
    );
    final q = orientation.b0 * pt.dx + orientation.b1 * pt.dy;
    final r = orientation.b2 * pt.dx + orientation.b3 * pt.dy;
    return FractionalHex(q, r, -q - r);
  }

  Offset hexCornerOffset(int corner) {
    final angle = 2.0 * pi * (orientation.startAngle + corner) / 6.0;
    return Offset(size * cos(angle), size * sin(angle));
  }

  Path buildHexPath(Hex hex) {
    final center = hexToPixel(hex);
    final path = Path()..moveTo(center.dx + hexCornerOffset(0).dx, center.dy + hexCornerOffset(0).dy);
    for (var i = 1; i < 6; i++) {
      final offset = hexCornerOffset(i);
      path.lineTo(center.dx + offset.dx, center.dy + offset.dy);
    }
    return path..close();
  }
}
