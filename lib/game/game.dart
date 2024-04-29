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
import 'package:flame_realtime_shooting/components/joypad.dart';

late Vector2 worldSize;

class MyGame extends FlameGame with HasCollisionDetection {
  // late Vector2 worldSize;
  late Player _player, _opponent;
  late CameraComponent _camera;
  static const _initialHealthPoints = 100;
  int _playerHealthPoint = _initialHealthPoints;
  bool isGameOver = true;
  Direction _currentJoypadDirection = Direction.none;

  final void Function(bool didWin) onGameOver;
  final void Function(Vector2 position, int health) onGameStateUpdate;

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

  Future<void> setupPlayers() async {
    _player = await createPlayer('player.png', true);
    _opponent = await createPlayer('opponent.png', false);
    add(_player);
    add(_opponent);
  }

  Future<Player> createPlayer(String imagePath, bool isMe) async {
    final flame_image.Image playerImage = await images.load(imagePath);
    final spriteSize = Vector2.all(Player.radius * 2);
    return Player(isMe: isMe)..add(SpriteComponent(sprite: Sprite(playerImage), size: spriteSize));
  }

  Future<void> setupBackground() async {
    final backgroundImage = await images.load('background.jpg');
    final background = SpriteComponent(sprite: Sprite(backgroundImage), size: Vector2(1000, 1000));
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
        // final mirroredPosition = _player.getMirroredPercentPosition();
        // onGameStateUpdate(mirroredPosition, _playerHealthPoint);
        onGameStateUpdate(_player.position, _playerHealthPoint);
        _player.updateHealth(_playerHealthPoint / _initialHealthPoints);
      }
    }
    if (_playerHealthPoint <= 0) {
      endGame(false);
    }
  }

  void startNewGame() {
    isGameOver = false;
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

  void updateOpponent({required Vector2 position, required int health}) {
    _opponent.position = Vector2(size.x * position.x, size.y * position.y);
    _opponent.updateHealth(health / _initialHealthPoints);
  }

  void endGame(bool playerWon) {
    isGameOver = true;
    onGameOver(playerWon);
  }

  void handleJoypadDirection(Direction direction) {
    const double speed = 2;
    Vector2 movementVector;

    _currentJoypadDirection = direction;

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
    newPosition.clamp(Vector2.zero(), worldSize - Vector2.all(_player.width));  // Assuming the player is a square for simplicity
    _player.position = newPosition;
    onGameStateUpdate(_player.position, _playerHealthPoint);

    // final mirroredPosition = _player.getMirroredPercentPosition();
    // onGameStateUpdate(mirroredPosition, _playerHealthPoint);
  }

  // void handleMovementBasedOnJoypadDirection(double dt) {
  //   final double speed = 2 * dt;
  //   Vector2 movementVector = Vector2.zero();

  //   switch (_currentJoypadDirection) {
  //     case Direction.up:
  //       movementVector = Vector2(0, -speed);
  //       break;
  //     case Direction.down:
  //       movementVector = Vector2(0, speed);
  //       break;
  //     case Direction.left:
  //       movementVector = Vector2(-speed, 0);
  //       break;
  //     case Direction.right:
  //       movementVector = Vector2(speed, 0);
  //       break;
  //     case Direction.upLeft:
  //       movementVector = Vector2(-speed, -speed);
  //       break;
  //     case Direction.upRight:
  //       movementVector = Vector2(speed, -speed);
  //       break;
  //     case Direction.downLeft:
  //       movementVector = Vector2(-speed, speed);
  //       break;
  //     case Direction.downRight:
  //       movementVector = Vector2(speed, speed);
  //       break;
  //     case Direction.none:
  //       return;
  //   }

  //   Vector2 newPosition = _player.position + movementVector;
  //   newPosition.clamp(Vector2.zero(), worldSize - Vector2.all(_player.width));  // Assuming the player is a square for simplicity
  //   _player.position = newPosition;
  // }
}