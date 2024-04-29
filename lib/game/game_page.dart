// flutter imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// flame imports
import 'package:flame/game.dart';

// realtime sync imports
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// self imports
import 'package:flame_realtime_shooting/main.dart';
import 'package:flame_realtime_shooting/game/game.dart';
import 'package:flame_realtime_shooting/components/joypad.dart';
import 'package:flame_realtime_shooting/components/fire_button.dart';


class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final MyGame _game;
  RealtimeChannel? _gameChannel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game),
          Positioned(
            left: 20,
            bottom: 20,
            child: Joypad(onDirectionChanged: (direction) {
              _game.handleJoypadDirection(direction);
            }),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FireButton(
              onFirePressed: _fire,
            ),
          ),
        ],
      ),
    );
  }

  void _fire() {
    if (_game != null) {
      _game.fireBullets(5);
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _game = MyGame(
      onGameStateUpdate: (position, health) async {
        // Ensure position is not null and channel is initialized
        if (_gameChannel != null && position != null) {
          double x = position.x ?? 0.0; // Provide a default value if null
          double y = position.y ?? 0.0; // Provide a default value if null
          ChannelResponse? response;

          do {
            response = await _gameChannel?.sendBroadcastMessage(
              event: 'game_state',
              payload: {'x': x, 'y': y, 'health': health},
            );
            // Handle a brief pause to mitigate rapid send rate
            await Future.delayed(Duration.zero);
            if (mounted) {
              setState(() {});
            }
          } while (response == ChannelResponse.rateLimited && health > 0);
        }
      },
      onGameOver: (playerWon) async {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(playerWon ? 'You Won!' : 'You lost...'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (_gameChannel != null) {
                    await supabase.removeChannel(_gameChannel!);
                  }
                  _openLobbyDialog();
                },
                child: const Text('Back to Lobby'),
              ),
            ],
          ),
        );
      },
    );

    await Future.delayed(Duration.zero); // Ensures UI is ready or other initial setup
    if (mounted) {
      _openLobbyDialog(); // Opens the lobby dialog post-initialization
    }
  }

  void _openLobbyDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _LobbyDialog(
            onGameStarted: (String gameId) async {
              // Setup the channel for the game based on gameId
              _gameChannel = supabase.channel(gameId, opts: const RealtimeChannelConfig(ack: true));
              await _gameChannel!.subscribe();

              // Handling broadcasts of game state
              _gameChannel!.onBroadcast(event: 'game_state', callback: (payload, [_]) {
                if (payload != null) {
                  double x = (payload['x'] as num?)?.toDouble() ?? 0.0; // Safely cast to double with default
                  double y = (payload['y'] as num?)?.toDouble() ?? 0.0; // Safely cast to double with default
                  int health = payload['health'] as int? ?? 100; // Default health if not provided

                  // Updating opponent's position and health
                  _game.updateOpponent(position: Vector2(x, y), health: health);

                  // Check if the game should end
                  if (health <= 0 && !_game.isGameOver) {
                    _game.isGameOver = true;
                    _game.onGameOver(true);
                  }
                }
              });

              // Ensure the game starts with a clean state
              await Future.delayed(Duration.zero); // Ensure all asynchronous initializations are complete
              setState(() {
                _game.startNewGame(); // Start or restart the game
              });
            },
          );
        }
    );
  }
}

class _LobbyDialog extends StatefulWidget {
  const _LobbyDialog({
    required this.onGameStarted,
  });

  final void Function(String gameId) onGameStarted;

  @override
  State<_LobbyDialog> createState() => _LobbyDialogState();
}

class _LobbyDialogState extends State<_LobbyDialog> {
  List<String> _userids = [];
  bool _loading = false;
  final myUserId = const Uuid().v4();
  late final RealtimeChannel _lobbyChannel;

  @override
  void initState() {
    super.initState();
    _lobbyChannel = supabase.channel(
      'lobby',
      opts: const RealtimeChannelConfig(self: true),
    );

    _lobbyChannel
        .onPresenceSync((payload, [ref]) {
      final presenceStates = _lobbyChannel.presenceState();
      setState(() {
        _userids = presenceStates
            .map((presenceState) =>
        presenceState.presences.first.payload['user_id'] as String)
            .toList();
      });
    })
        .onBroadcast(
        event: 'game_start',
        callback: (payload, [_]) {
          final participantIds = List<String>.from(payload['participants']);
          if (participantIds.contains(myUserId)) {
            final gameId = payload['game_id'] as String;
            widget.onGameStarted(gameId);
            Navigator.of(context).pop();
          }
        })
        .subscribe((status, _) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _lobbyChannel.track({'user_id': myUserId});
      }
    });
  }

  @override
  void dispose() {
    supabase.removeChannel(_lobbyChannel);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lobby'),
      content: _loading
          ? const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      )
          : Text('${_userids.length} users waiting'),
      actions: [
        TextButton(
          onPressed: _userids.length < 2
              ? null
              : () async {
            setState(() {
              _loading = true;
            });

            final opponentId =
            _userids.firstWhere((userId) => userId != myUserId);
            final gameId = const Uuid().v4();
            await _lobbyChannel.sendBroadcastMessage(
              event: 'game_start',
              payload: {
                'participants': [opponentId, myUserId],
                'game_id': gameId,
              },
            );
          },
          child: const Text('Start Game'),
        ),
      ],
    );
  }
}