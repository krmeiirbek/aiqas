import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../theme/app_colors.dart';
import '../widgets/hex_board.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late GameEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(state: createNewGame());
    _engine.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _engine.removeListener(_onStateChanged);
    _engine.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.2),
        title: Text(
          'Turn ${_engine.state.turn} • ${_engine.state.currentPlayer.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text('${_engine.state.currentPlayer.coins} coins'),
              backgroundColor: AppColors.highlight,
              labelStyle: const TextStyle(
                color: AppColors.background,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _PlayersRow(engine: _engine),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColoredBox(
                  color: AppColors.boardBackground,
                  child: HexBoard(engine: _engine),
                ),
              ),
            ),
          ),
          _ActionBar(engine: _engine),
        ],
      ),
    );
  }
}

class _PlayersRow extends StatelessWidget {
  const _PlayersRow({required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          for (final player in engine.state.players)
            Chip(
              backgroundColor: player.color.withOpacity(0.2),
              avatar: CircleAvatar(backgroundColor: player.color),
              label: Text(
                '${player.name} • ${engine.state.ownedCount(player.id)} tiles',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.engine});

  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final selected = engine.state.selected;
    final selectionOwner = selected == null ? null : engine.tileAt(selected)?.ownerId;
    final isOwnTile = selectionOwner == engine.state.currentPlayer.id;
    final neighborActions = selected == null
        ? ''
        : 'Tap adjacent neutral tiles (1 coin) or enemy tiles (2 coins). Fortify costs 1 coin.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1426),
        border: Border(top: BorderSide(color: Colors.black54, width: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected != null)
            Text(
              'Selected: q=${selected.q}, r=${selected.r}',
              style: const TextStyle(color: Colors.white70),
            ),
          if (neighborActions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(neighborActions, style: const TextStyle(color: Colors.white54)),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionButton(
                label: 'Fortify (-1)',
                enabled: isOwnTile && engine.state.currentPlayer.coins > 0,
                onPressed: selected == null ? null : () => engine.fortify(selected),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                label: 'Clear',
                enabled: selected != null,
                onPressed: () => engine.select(null),
              ),
              const Spacer(),
              _ActionButton(
                label: 'End turn',
                enabled: true,
                onPressed: engine.endTurn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? AppColors.highlight : Colors.white12,
        foregroundColor: enabled ? AppColors.background : Colors.white54,
      ),
      child: Text(label),
    );
  }
}
