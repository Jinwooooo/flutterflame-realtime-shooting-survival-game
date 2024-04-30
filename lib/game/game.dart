// dart imports
import 'dart:async';

// flutter imports
import 'package:flutter/material.dart';

// flame imports
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart' as flame_image;

// self imports
import 'package:flame_realtime_shooting/game/bullet.dart';
import 'package:flame_realtime_shooting/game/player.dart';
import 'package:flame_realtime_shooting/components/time.dart';
import 'package:flame_realtime_shooting/components/joypad.dart';
import 'package:flame_realtime_shooting/components/pattern_1.dart';
import 'package:flame_realtime_shooting/components/raid_1.dart';

late Vector2 worldSize;

class MyGame extends FlameGame with HasCollisionDetection {
  late final TextComponent _timerText;
  late GameTimer _gameTimer;
  late Player _player, _opponent;
  late CameraComponent _camera;
  static const _initialHealthPoints = 100;
  int _playerHealthPoint = _initialHealthPoints;
  bool isGameOver = true;
  Direction _currentJoypadDirection = Direction.none;
  late final Pattern1 _pattern1;
  late final Raid1 _raid1;

  final void Function(bool didWin) onGameOver;
  final void Function(Vector2 position, int health, Direction direction) onGameStateUpdate;

  MyGame({
    required this.onGameOver,
    required this.onGameStateUpdate,
  });

  late final flame_image.Image _playerBulletImage;
  late final flame_image.Image _opponentBulletImage;

  @override
  Color backgroundColor() {
    return Colors.transparent;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _timerText = TextComponent(
      text: "00:00",
      position: Vector2(10, 10), // Position it at the top left corner
      textRenderer: TextPaint(style: TextStyle(color: Colors.white, fontSize: 24)),
    );
    add(_timerText);

    _gameTimer = GameTimer(onTick: handleTimeTick);

    await setupPlayers();
    await setupBackground();
    setupCamera();

    _playerBulletImage = await images.load('player-bullet.png');
    _opponentBulletImage = await images.load('opponent-bullet.png');
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    worldSize = canvasSize;
  }

  void handleTimeTick(int elapsedSeconds) {
    _timerText.text = _gameTimer.formattedTime;
    if (elapsedSeconds == 2) {
      _pattern1 = Pattern1(patternsData: [
                  PatternData1(0, 500, 1),
                  PatternData1(500, 1000, 2),
                  PatternData1(1000, 1500, 3),
                  PatternData1(1500, 2000, 4),
                  PatternData1(2000, 2500, 5),
                ]);
      _pattern1.elapsedMilliseconds = 0;
      _pattern1.priority = 2;
      _pattern1.debugMode = true;
      add(_pattern1);
    } 
    if (elapsedSeconds == 5) {
      remove(_pattern1);
    }

    if (elapsedSeconds == 5) {
      _raid1 = Raid1(raidsData: [
                RaidData1(0, 700, 1),
                RaidData1(700, 1400, 2),
                RaidData1(1400, 2100, 3),
                RaidData1(2100, 2800, 4),
                RaidData1(2800, 3500, 5),
      ]);
      _raid1.priority = 2;
      _raid1.debugMode = true;
      add(_raid1);
    } 
    if (elapsedSeconds == 10) {
      remove(_raid1);
    }
  }

  Future<void> setupPlayers() async {
    _player = await createPlayer('player-bg.png', true);
    _opponent = await createPlayer('opponent-bg.png', false);
    _player.priority = 5;
    _opponent.priority = 5;
    _player.debugMode = true;
    _opponent.debugMode = true;
    add(_player);
    add(_opponent);
  }

  Future<Player> createPlayer(String imagePath, bool isMe) async {
    final flame_image.Image playerImage = await images.load(imagePath);
    final spriteSize = Vector2.all(Player.radius * 2);
    return Player(isMe: isMe)..add(SpriteComponent(sprite: Sprite(playerImage), size: spriteSize));
  }

  Future<void> setupBackground() async {
    final backgroundImage = await images.load('brown-background.avif');
    final background = SpriteComponent(sprite: Sprite(backgroundImage), size: Vector2(worldSize[0], worldSize[1]));
    background.priority = -1;
    add(background);
  }

  void setupCamera() {
    _camera = CameraComponent()..follow(_player);
    add(_camera);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) {
      return;
    }
    for (final child in children) {
      if (child is Bullet && child.hasBeenHit && !child.isMine) {
        _playerHealthPoint = _playerHealthPoint - child.damage;
        onGameStateUpdate(_player.position, _playerHealthPoint, _player.currentDirection);
        _player.updateHealth(_playerHealthPoint / _initialHealthPoints);
      }
    }
    if (_playerHealthPoint <= 0) {
      endGame(false);
    }
  }

  void startNewGame() {
    isGameOver = false;
    _gameTimer.start();
    _playerHealthPoint = _initialHealthPoints;

    for (final child in children) {
      if (child is Player) {
        child.position = child.initialPosition;
      } else if (child is Bullet) {
        child.removeFromParent();
      }
    }

    // _shootBullets();
  }

  Future<void> _shootBullets() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final playerBulletInitialPosition = Vector2.copy(_player.position)
      ..y -= Player.radius;
    final playerBulletVelocities = [
      Vector2(0, -100),
      Vector2(60, -80),
      Vector2(-60, -80),
    ];
    for (final bulletVelocity in playerBulletVelocities) {
      add((Bullet(
        isMine: true,
        velocity: bulletVelocity,
        image: _playerBulletImage,
        initialPosition: playerBulletInitialPosition,
      )));
    }

    final opponentBulletInitialPosition = Vector2.copy(_opponent.position)
      ..y += Player.radius;
    final opponentBulletVelocities = [
      Vector2(0, 100),
      Vector2(60, 80),
      Vector2(-60, 80),
    ];
    for (final bulletVelocity in opponentBulletVelocities) {
      add((Bullet(
        isMine: false,
        velocity: bulletVelocity,
        image: _opponentBulletImage,
        initialPosition: opponentBulletInitialPosition,
      )));
    }

    _shootBullets();
  }

  void updateOpponent({required Vector2 position, required int health, required Direction direction}) {
    _opponent.position = Vector2(size.x * position.x, size.y * position.y);
    _opponent.updateHealth(health / _initialHealthPoints);
    _opponent.updateDirection(direction);
  }

  void endGame(bool playerWon) {
    isGameOver = true;
    _gameTimer.stop();
    onGameOver(playerWon);
  }

  void handleJoypadDirection(Direction direction) {
    const double speed = 2;
    Vector2 movementVector;

    if(direction != Direction.none) {
      _currentJoypadDirection = direction;
    }

    switch (direction) {
      case Direction.up:
        movementVector = Vector2(0, -speed);
        break;
      case Direction.down:
        movementVector = Vector2(0, speed);
        break;
      case Direction.left:
        movementVector = Vector2(-speed, 0);
        break;
      case Direction.right:
        movementVector = Vector2(speed, 0);
        break;
      case Direction.upLeft:
        movementVector = Vector2(-speed, -speed);
        break;
      case Direction.upRight:
        movementVector = Vector2(speed, -speed);
        break;
      case Direction.downLeft:
        movementVector = Vector2(-speed, speed);
        break;
      case Direction.downRight:
        movementVector = Vector2(speed, speed);
        break;
      case Direction.none:
        movementVector = Vector2.zero();
        break;
    }

    Vector2 newPosition = _player.position + movementVector;
    newPosition.clamp(Vector2.zero(), worldSize - Vector2.all(_player.width));
    _player.position = newPosition;
    if (direction != Direction.none) {
      _player.updateDirection(direction);
    }
    onGameStateUpdate(_player.position, _playerHealthPoint, _player.currentDirection);
  }
}