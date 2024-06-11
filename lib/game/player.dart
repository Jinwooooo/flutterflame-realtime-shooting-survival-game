// dart imports
import 'dart:async';

// flutter imports
import 'package:flutter/material.dart';

// flame imports
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

// self imports
import 'package:flame_realtime_shooting/game/game.dart';
import 'package:flame_realtime_shooting/game/bullet.dart';
import 'package:flame_realtime_shooting/game/cannon.dart';
import 'package:flame_realtime_shooting/components/joypad.dart';
import 'package:flame_realtime_shooting/components/raid_1.dart';


class Player extends PositionComponent with HasGameRef<MyGame>, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  late final Vector2 initialPosition;
  Timer? moveTimer;
  Player({required bool isMe}) : _isMyPlayer = isMe;
  final bool _isMyPlayer;
  static const radius = 40.0;
  Direction currentDirection = Direction.up;
  Map<Direction, Sprite> directionSprites = {};
  late SpriteComponent tankSprite;
  double hitCooldown = 0;

  @override
  Future<void>? onLoad() async {
    anchor = Anchor.center;
    width = radius * 2;
    height = radius * 2;

    final initialX = gameRef.size.x / 2;
    final initialY = gameRef.size.y / 2;

    initialPosition = _isMyPlayer
        ? Vector2(initialX, initialY + radius)
        : Vector2(initialX, initialY - radius);
    position = initialPosition;

    directionSprites = {
      Direction.up: Sprite(await gameRef.images.load('tank-1-0.png')),
      Direction.upRight: Sprite(await gameRef.images.load('tank-1-1.png')),
      Direction.right: Sprite(await gameRef.images.load('tank-1-2.png')),
      Direction.downRight: Sprite(await gameRef.images.load('tank-1-3.png')),
      Direction.down: Sprite(await gameRef.images.load('tank-1-4.png')),
      Direction.downLeft: Sprite(await gameRef.images.load('tank-1-5.png')),
      Direction.left: Sprite(await gameRef.images.load('tank-1-6.png')),
      Direction.upLeft: Sprite(await gameRef.images.load('tank-1-7.png')),
    };
    currentDirection = Direction.up;
    tankSprite = SpriteComponent(
      sprite: directionSprites[currentDirection],
      size: Vector2.all(radius * 2),
    );

    add(tankSprite);
    add(CircleHitbox());
    add(_Gauge());
    await super.onLoad();
  }

  void move(Vector2 delta) {
    Vector2 newPosition = position + delta;
    newPosition.clamp(Vector2(radius, radius), gameRef.size - Vector2(radius, radius));
    position = newPosition;
  }

  void updateDirection(Direction newDirection) {
    currentDirection = newDirection;
    tankSprite.sprite = directionSprites[currentDirection];
  }

  void updateHealth(double healthLeft) {
    for (final child in children) {
      if (child is _Gauge) {
        child._healthLeft = healthLeft;
      }
    }
  }

  void disableMovement() {
    currentDirection = Direction.none;
    tankSprite.sprite = directionSprites[currentDirection];
    gameRef.disableJoypadTemporarily();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hitCooldown > 0) {
      hitCooldown -= dt;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // bullet
    if (other is Bullet && _isMyPlayer != other.isMine) {
      other.hasBeenHit = true;
      other.removeFromParent();
    }

    // cannon
    if (other is Cannon && _isMyPlayer != other.isMine) {
      other.hasBeenHit = true;
      other.removeFromParent();
    }

    // raid
    if (other is RaidRectangle && hitCooldown <= 0) {
      hitCooldown = 2.0;
      gameRef.updatePlayerHealth(this, 25);

      if (_isMyPlayer) {
        gameRef.enableJoypad(false);

        Future.delayed(const Duration(seconds: 2), () {
          gameRef.enableJoypad(true);
        });
      }
    }
  }
}

class _Gauge extends PositionComponent {
  double _healthLeft = 1.0;

  @override
  FutureOr<void> onLoad() {
    final playerParent = parent;
    if (playerParent is Player) {
      width = playerParent.width;
      height = 10;
      anchor = Anchor.centerLeft;
      position = Vector2(0, 0);
    }
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
        Rect.fromPoints(
          const Offset(0, 0),
          Offset(width, height),
        ),
        Paint()..color = Colors.white);
    canvas.drawRect(
        Rect.fromPoints(
          const Offset(0, 0),
          Offset(width * _healthLeft, height),
        ),
        Paint()
          ..color = _healthLeft > 0.5
              ? Colors.green
              : _healthLeft > 0.25
                  ? Colors.orange
                  : Colors.red);
  }
}