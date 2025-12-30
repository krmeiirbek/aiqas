import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/geometry.dart';
import '../theme/app_colors.dart';
import 'board_painter.dart';

class HexBoard extends StatelessWidget {
  const HexBoard({
    required this.engine,
    super.key,
  });

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layout = _computeLayout(size, engine.state.tiles.keys);
        final highlighted = _highlightedHexes();

        return GestureDetector(
          onTapDown: (details) {
            final fractional = layout.pixelToHex(details.localPosition);
            final tapped = fractional.round();
            if (engine.tileAt(tapped) != null) {
              _handleTap(tapped);
            }
          },
          child: CustomPaint(
            painter: BoardPainter(
              state: engine.state,
              layout: layout,
              highlighted: highlighted,
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Hex hex) {
    final selected = engine.state.selected;
    final tile = engine.tileAt(hex);
    if (tile == null) return;

    if (selected == null) {
      if (tile.ownerId == engine.state.currentPlayer.id) {
        engine.select(hex);
      }
      return;
    }

    if (hex == selected) {
      engine.select(null);
      return;
    }

    if (engine.canExpandTo(selected, hex)) {
      engine.expand(selected, hex);
      return;
    }

    if (engine.canAttack(selected, hex)) {
      engine.attack(selected, hex);
      return;
    }

    if (tile.ownerId == engine.state.currentPlayer.id) {
      engine.select(hex);
    }
  }

  Set<Hex> _highlightedHexes() {
    final selected = engine.state.selected;
    if (selected == null) return const <Hex>{};
    final neighbors = engine.neighborsOf(selected).map((tile) => tile.hex);
    return neighbors.toSet();
  }
}

HexLayout _computeLayout(Size size, Iterable<Hex> hexes) {
  const padding = 16.0;
  final baseLayout = HexLayout(orientation: pointy, size: 1, origin: Offset.zero);
  final points = hexes.map(baseLayout.hexToPixel).toList();

  final minX = points.map((p) => p.dx).reduce(min);
  final maxX = points.map((p) => p.dx).reduce(max);
  final minY = points.map((p) => p.dy).reduce(min);
  final maxY = points.map((p) => p.dy).reduce(max);

  final mapWidth = maxX - minX + 2;
  final mapHeight = maxY - minY + 2;

  final usableWidth = size.width - padding * 2;
  final usableHeight = size.height - padding * 2;

  final scale = max(8.0, min(usableWidth / mapWidth, usableHeight / mapHeight));

  final origin = Offset(
    size.width / 2 - ((minX + maxX) / 2) * scale,
    size.height / 2 - ((minY + maxY) / 2) * scale,
  );

  return baseLayout.copyWith(size: scale, origin: origin);
}
