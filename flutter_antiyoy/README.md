# Flutter Antiyoy

A lightweight Flutter rewrite of the original **Antiyoy** gameplay loop. The new client focuses on a clean hot-seat experience with a hex painter that mirrors the classic look without external dependencies.

## Running the game

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.4+ recommended).
2. From the `flutter_antiyoy` directory run:

   ```bash
   flutter pub get
   flutter run -d <device>
   ```

3. The home screen offers a quick-start hot-seat match. Each turn awards income equal to the number of owned tiles. Expanding into neutral tiles costs 1 coin; attacking enemy tiles costs 2 coins; fortifying the selected tile costs 1 coin.

## Project layout

- `lib/main.dart` – App bootstrap and theme.
- `lib/ui/` – Home page and in-game HUD.
- `lib/game/` – Game state, rules, and hex geometry helpers.
- `lib/widgets/` – Hex board rendering and interaction handling.

The implementation relies solely on Flutter and `collection`; no extra game-engine plugins are required.
