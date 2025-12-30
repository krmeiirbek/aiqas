import 'dart:ui';

import '../game/game_state.dart';
import '../game/geometry.dart';
import '../theme/app_colors.dart';

class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.state,
    required this.layout,
    required this.highlighted,
  });

  final GameState state;
  final HexLayout layout;
  final Set<Hex> highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF0E162B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final tile in state.tiles.values) {
      final fill = Paint()
        ..color = tile.ownerId == null
            ? AppColors.neutralHex
            : state.players[tile.ownerId!].color.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      final path = layout.buildHexPath(tile.hex);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, borderPaint);

      if (tile.unitLevel > 0) {
        _drawUnitLevel(canvas, layout.hexToPixel(tile.hex), tile.unitLevel);
      }
    }

    if (state.selected != null) {
      _drawSelection(canvas, state.selected!, const Color(0xFF74EBD5));
    }

    for (final hex in highlighted) {
      if (hex == state.selected) continue;
      _drawSelection(canvas, hex, AppColors.highlight.withOpacity(0.55));
    }
  }

  void _drawUnitLevel(Canvas canvas, Offset center, int value) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$value',
        style: const TextStyle(
          color: Color(0xFF0C1226),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCenter(center: center, width: 24, height: 24);
    final bgPaint = Paint()
      ..color = const Color(0xFFEFF3F9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawSelection(Canvas canvas, Hex hex, Color color) {
    final center = layout.hexToPixel(hex);
    final path = layout.buildHexPath(hex);
    final glow = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawPath(path, glow);

    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, border);

    canvas.drawCircle(center, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.layout != layout || oldDelegate.highlighted != highlighted;
  }
}
