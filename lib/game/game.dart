// dart imports
import 'dart:async' as async;
import 'dart:math';

// flutter imports
import 'package:flutter/material.dart';

// flame imports
import 'package:flame/game.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart' as flame_image;
// import 'package:flame_forge2d/flame_forge2d.dart';

// self imports
import 'package:flame_realtime_shooting/game/bullet.dart';
import 'package:flame_realtime_shooting/game/player.dart';
import 'package:flame_realtime_shooting/components/joypad.dart';

class MyGame extends FlameGame with HasCollisionDetection {
  static final Vector2 worldSize = Vector2(2000, 920);
  late World _world;
  late Player _player, _opponent;
  late CameraComponent _camera;
  late SpriteComponent _map;
  static const _initialHealthPoints = 100;
  int _playerHealthPoint = _initialHealthPoints;
  bool isGameOver = true;
  Direction _currentJoypadDirection = Direction.none; // setState move

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

    _world = World();
    await add(_world);
    // print(size.x);
    // print(size.y);

    _playerBulletImage = await images.load('player-bullet.png');
    _opponentBulletImage = await images.load('opponent-bullet.png');

    _map = SpriteComponent.fromImage(await images.load('background.jpg'), size: worldSize, priority: -1);
    _player = await createPlayer('player.png', true);
    _opponent = await createPlayer('opponent.png', false);

    // print('height = ' + _map.height.toString());
    // print('width = ' + _map.width.toString());

    // final world = World(children:[_map, _player, _opponent]);
    _world.add(_map);
    _world.add(_player);
    _world.add(_opponent);


    _camera = CameraComponent(
      world: _world,
      viewport: FixedResolutionViewport(resolution: worldSize),
    );
    await add(_camera);
    _camera.follow(_player);
    _camera.viewfinder.zoom = 3.0;

    _player.debugMode = true;
    _opponent.debugMode = true;
    _camera.debugMode = true;
  }

  Future<Player> createPlayer(String imagePath, bool isMe) async {
    final flame_image.Image playerImage = await images.load(imagePath);
    final spriteSize = Vector2.all(Player.radius * 2);
    return Player(isMe: isMe)..add(SpriteComponent(sprite: Sprite(playerImage), size: spriteSize));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) {
      return;
    }

    handleMovementBasedOnJoystickDirection(dt);

    for (final child in children) {
      if (child is Bullet && child.hasBeenHit && !child.isMine) {
        _playerHealthPoint -= child.damage;
        onGameStateUpdate(_player.position, _playerHealthPoint);  // 사용 위치 변경
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
  }

  void fireBullets(int setsCount) {
    List<Vector2> velocities = [
      Vector2(0, -100),
      Vector2(60, -80),
      Vector2(-60, -80),
    ];
    int currentSet = 0;

    // Set up the periodic timer
    async.Timer.periodic(Duration(milliseconds: 500), (timer) {
      // Check if the required number of sets has been reached
      if (currentSet >= setsCount) {
        timer.cancel();  // Stop the timer
        return;
      }

      // Calculate the initial position for the bullets
      Vector2 initialPosition = Vector2.copy(_player.position)..y -= Player.radius;

      // Fire bullets with different velocities
      for (Vector2 velocity in velocities) {
        Bullet bullet = Bullet(
          isMine: true,
          velocity: velocity,
          image: _playerBulletImage,
          initialPosition: initialPosition,
        );
        bullet.priority = 1;  // Render priority
        bullet.debugMode = true;  // Optional: for visual debugging
        _world.add(bullet);
      }

      currentSet++;
    });
  }

  void updateOpponent({required Vector2 position, required int health}) {
    _opponent.position = position; // Direct assignment of new position
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
    newPosition.clamp(Vector2.zero(), worldSize - Vector2.all(_player.width));  // Ensure within bounds
    _player.position = newPosition;

    // update position and potentially other game state variables
    onGameStateUpdate(_player.position, _playerHealthPoint);
  }

  void handleMovementBasedOnJoystickDirection(double dt) {
    final double speed = 2 * dt;
    Vector2 movementVector = Vector2.zero();

    switch (_currentJoypadDirection) {
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
      default:
        movementVector = Vector2.zero(); // Just a fallback, ideally never reached
    }

    // Vector2 newPosition = _player.position + movementVector;
    // newPosition.clamp(Vector2.zero(), worldSize - Vector2.all(_player.width));  // Assuming the player is a square for simplicity
    // _player.position = newPosition;

    Vector2 proposedNewPosition = _player.position + movementVector;
    proposedNewPosition.clamp(Vector2.zero(), worldSize - Vector2.all(_player.width));  // Ensure within bounds
    _player.position = proposedNewPosition;

    // if (!isCollide(proposedNewPosition, _opponent)) {
    //     _player.position = proposedNewPosition;
    // }

    // Directly update using the actual position
    onGameStateUpdate(_player.position, _playerHealthPoint);
  }

  // Simple collision detection method
  bool isCollide(Vector2 newPosition, Player opponent) {
    // Calculate a hypothetical collision rectangle for the new position
    final playerRect = newPosition.toRect().inflate(Player.radius); // Assuming radius is half of player size
    final opponentRect = opponent.position.toRect().inflate(Player.radius);

    return playerRect.overlaps(opponentRect);
  }
}