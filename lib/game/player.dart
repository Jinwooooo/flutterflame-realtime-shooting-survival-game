// dart imports
import 'dart:async';

// flutter imports
import 'package:flutter/material.dart';

// flame imports
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

// self imports
import 'package:flame_realtime_shooting/game/bullet.dart';
import 'package:flame_realtime_shooting/components/joypad.dart';

import '../components/pattern.dart';


class Player extends PositionComponent with HasGameRef, CollisionCallbacks {
  Vector2 velocity = Vector2.zero();
  late final Vector2 initialPosition;
  Timer? moveTimer;
  Player({required bool isMe}) : _isMyPlayer = isMe;
  final bool _isMyPlayer;
  static const radius = 20.0;
  late final String id;  // 플레이어 ID


  @override
  Future<void>? onLoad() async {
    anchor = Anchor.center;
    width = radius * 2;
    height = radius * 2;

    final initialX = gameRef.size.x / 2;
    initialPosition = _isMyPlayer
        ? Vector2(initialX, gameRef.size.y * 0.8)
        : Vector2(initialX, gameRef.size.y * 0.2);
    position = initialPosition;

    add(CircleHitbox());
    add(_Gauge());
    await super.onLoad();
  }
  void move(Vector2 delta) {
    Vector2 newPosition = position + delta;
    newPosition.clamp(Vector2(radius, radius), gameRef.size - Vector2(radius, radius));
    position = newPosition;
  }

  void updateHealth(double healthLeft) {
    for (final child in children) {
      if (child is _Gauge) {
        child._healthLeft = healthLeft;
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Bullet && _isMyPlayer != other.isMine) {
      other.hasBeenHit = true;
      other.removeFromParent();
    }
    if (other is BombZone && !other.hasBeenHit) {
      other.hasBeenHit = true;
      other.removeFromParent();
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

    // 체력 값을 화면에 표시 (디버깅용)
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Health: ${_healthLeft.toStringAsFixed(2)}',
        style: TextStyle(color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: width,
    );

    textPainter.paint(canvas, Offset(0, -20)); // 체력바 위에 체력 값을 그립니다.
  }
}