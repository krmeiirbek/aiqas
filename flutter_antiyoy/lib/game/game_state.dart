import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'geometry.dart';

enum TileState { neutral, owned }

class PlayerState {
  PlayerState({
    required this.id,
    required this.name,
    required this.color,
    this.coins = 5,
  });

  final int id;
  final String name;
  final int coins;
  final Color color;

  PlayerState copyWith({int? coins}) {
    return PlayerState(
      id: id,
      name: name,
      color: color,
      coins: coins ?? this.coins,
    );
  }
}

class HexTile {
  HexTile({
    required this.hex,
    this.ownerId,
    this.unitLevel = 0,
  });

  final Hex hex;
  final int? ownerId;
  final int unitLevel;

  bool get isNeutral => ownerId == null;

  HexTile copyWith({
    int? ownerId,
    int? unitLevel,
  }) {
    return HexTile(
      hex: hex,
      ownerId: ownerId ?? this.ownerId,
      unitLevel: unitLevel ?? this.unitLevel,
    );
  }
}

class GameState {
  GameState({
    required this.tiles,
    required this.players,
    required this.currentPlayerIndex,
    this.selected,
    this.turn = 1,
  });

  final Map<Hex, HexTile> tiles;
  final List<PlayerState> players;
  final int currentPlayerIndex;
  final Hex? selected;
  final int turn;

  PlayerState get currentPlayer => players[currentPlayerIndex];

  int ownedCount(int playerId) {
    return tiles.values.where((tile) => tile.ownerId == playerId).length;
  }

  GameState copyWith({
    Map<Hex, HexTile>? tiles,
    List<PlayerState>? players,
    int? currentPlayerIndex,
    Hex? selected,
    bool clearSelection = false,
    int? turn,
  }) {
    return GameState(
      tiles: tiles ?? this.tiles,
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      selected: clearSelection ? null : (selected ?? this.selected),
      turn: turn ?? this.turn,
    );
  }
}

class GameEngine extends ChangeNotifier {
  GameEngine({
    required this.state,
  });

  final Random _random = Random();
  GameState state;

  HexTile? tileAt(Hex hex) => state.tiles[hex];

  void select(Hex? hex) {
    if (hex == null) {
      state = state.copyWith(clearSelection: true);
      notifyListeners();
      return;
    }
    final tile = tileAt(hex);
    if (tile == null) return;
    state = state.copyWith(selected: hex);
    notifyListeners();
  }

  bool canActFrom(Hex hex) {
    final tile = tileAt(hex);
    return tile != null && tile.ownerId == state.currentPlayer.id;
  }

  bool _spendCoins(int amount) {
    final current = state.currentPlayer;
    if (current.coins < amount) return false;
    final updatedPlayers = List<PlayerState>.from(state.players);
    updatedPlayers[state.currentPlayerIndex] = current.copyWith(coins: current.coins - amount);
    state = state.copyWith(players: updatedPlayers);
    return true;
  }

  void _updateTile(HexTile updated) {
    final updatedTiles = Map<Hex, HexTile>.from(state.tiles);
    updatedTiles[updated.hex] = updated;
    state = state.copyWith(tiles: updatedTiles);
  }

  Iterable<HexTile> neighborsOf(Hex hex) {
    return hex.neighbors().map((neighbor) => tileAt(neighbor)).whereType<HexTile>();
  }

  bool canExpandTo(Hex from, Hex to) {
    final fromTile = tileAt(from);
    final targetTile = tileAt(to);
    return fromTile != null &&
        targetTile != null &&
        fromTile.ownerId == state.currentPlayer.id &&
        targetTile.isNeutral;
  }

  bool canAttack(Hex from, Hex to) {
    final fromTile = tileAt(from);
    final targetTile = tileAt(to);
    return fromTile != null &&
        targetTile != null &&
        fromTile.ownerId == state.currentPlayer.id &&
        targetTile.ownerId != null &&
        targetTile.ownerId != state.currentPlayer.id;
  }

  bool expand(Hex from, Hex to) {
    if (!canExpandTo(from, to)) return false;
    if (!_spendCoins(1)) return false;
    final targetTile = tileAt(to)!;
    _updateTile(targetTile.copyWith(ownerId: state.currentPlayer.id, unitLevel: 1));
    state = state.copyWith(selected: to);
    notifyListeners();
    return true;
  }

  bool attack(Hex from, Hex to) {
    if (!canAttack(from, to)) return false;
    if (!_spendCoins(2)) return false;
    final targetTile = tileAt(to)!;
    _updateTile(targetTile.copyWith(ownerId: state.currentPlayer.id, unitLevel: max(1, targetTile.unitLevel)));
    state = state.copyWith(selected: to);
    notifyListeners();
    return true;
  }

  bool fortify(Hex hex) {
    final tile = tileAt(hex);
    if (tile == null || tile.ownerId != state.currentPlayer.id) return false;
    if (!_spendCoins(1)) return false;
    _updateTile(tile.copyWith(unitLevel: tile.unitLevel + 1));
    notifyListeners();
    return true;
  }

  void endTurn() {
    final updatedPlayers = List<PlayerState>.from(state.players);
    for (var i = 0; i < updatedPlayers.length; i++) {
      final income = state.ownedCount(updatedPlayers[i].id);
      updatedPlayers[i] = updatedPlayers[i].copyWith(coins: updatedPlayers[i].coins + income);
    }

    final nextIndex = (state.currentPlayerIndex + 1) % state.players.length;
    state = state.copyWith(
      players: updatedPlayers,
      currentPlayerIndex: nextIndex,
      selected: null,
      turn: state.turn + (nextIndex == 0 ? 1 : 0),
    );
    notifyListeners();
  }

  void autoPlayNeutral() {
    final neutralTiles = state.tiles.values.where((tile) => tile.ownerId == null).toList();
    if (neutralTiles.isEmpty) return;
    final target = neutralTiles[_random.nextInt(neutralTiles.length)];
    _updateTile(target.copyWith(ownerId: state.currentPlayer.id));
    notifyListeners();
  }
}

GameState createNewGame({int radius = 4, int playerCount = 2}) {
  final tiles = <Hex, HexTile>{};
  for (var q = -radius; q <= radius; q++) {
    final r1 = max(-radius, -q - radius);
    final r2 = min(radius, -q + radius);
    for (var r = r1; r <= r2; r++) {
      final hex = Hex(q, r);
      tiles[hex] = HexTile(hex: hex);
    }
  }

  final players = List<PlayerState>.generate(
    playerCount,
    (index) => PlayerState(
      id: index,
      name: 'Player ${index + 1}',
      color: AppColors.playerPalette[index % AppColors.playerPalette.length],
    ),
  );

  final startPositions = [
    Hex(-radius, 0),
    Hex(radius, 0),
    Hex(0, -radius),
    Hex(0, radius),
  ];

  final updatedTiles = Map<Hex, HexTile>.from(tiles);
  for (var i = 0; i < playerCount; i++) {
    final startHex = startPositions[i % startPositions.length];
    updatedTiles[startHex] = updatedTiles[startHex]!.copyWith(ownerId: i, unitLevel: 1);
  }

  return GameState(
    tiles: updatedTiles,
    players: players,
    currentPlayerIndex: 0,
  );
}
