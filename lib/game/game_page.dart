// flame imports
import 'package:flame/game.dart';

// flutter imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// realtime sync imports
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// self imports
import 'package:flame_realtime_shooting/main.dart';
import 'package:flame_realtime_shooting/game/game.dart';
import 'package:flame_realtime_shooting/components/joypad.dart';

import '../components/fire_button.dart';
import '../components/item_button.dart';

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
          Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
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
            bottom: 10,
            child: FireButton(
              // onFirePressed: () {
              //   _game.shootBullets();
              //   Future.delayed(const Duration(milliseconds: 500), () {
              //   });
              // },
            ),
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _game = MyGame(
      onGameStateUpdate:
          (Vector2 position, int health, Direction direction) async {
        ChannelResponse response;
        do {
          response = await _gameChannel!.sendBroadcastMessage(
            event: 'game_state',
            payload: {
              'x': position.x / worldSize.x,
              'y': position.y / worldSize.y,
              'health': health,
              'direction': direction.index
            },
          );
          await Future.delayed(Duration.zero);
          setState(() {});
        } while (response == ChannelResponse.rateLimited && health <= 0);
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
                  await supabase.removeChannel(_gameChannel!);
                  _openLobbyDialog();
                },
                child: const Text('Back to Lobby'),
              ),
            ],
          ),
        );
      },
    );

    await Future.delayed(Duration.zero);
    if (mounted) {
      _openLobbyDialog();
    }
  }

  void _openLobbyDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _LobbyDialog(
              onGameStarted: (gameId) async {
                await Future.delayed(Duration.zero);
                setState(() {});
                _game.startNewGame();
                _gameChannel = supabase.channel(gameId,
                    opts: const RealtimeChannelConfig(ack: true));

                _gameChannel!
                    .onBroadcast(
                      event: 'game_state',
                      callback: (payload, [_]) {
                        // final position = Vector2((payload['x'] as double) * worldSize.x, (payload['y'] as double) * worldSize.y);
                        final position = Vector2(
                            (payload['x'] as double), (payload['y'] as double));
                        final opponentHealth = payload['health'] as int;
                        final directionIndex = payload['direction'] as int;
                        final direction = Direction.values[directionIndex];
                        _game.updateOpponent(
                          position: position,
                          health: opponentHealth,
                          direction: direction,
                        );
                        if (opponentHealth <= 0 && !_game.isGameOver) {
                          _game.isGameOver = true;
                          _game.onGameOver(true);
                        }
                      },
                    )
                    .subscribe();
              },
            ));
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
