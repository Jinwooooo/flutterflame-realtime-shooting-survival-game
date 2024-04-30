import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flame_realtime_shooting/game/player.dart';
import 'dart:async' as async;
class BombZone extends PositionComponent with HasGameRef, CollisionCallbacks {
  static const double damage = 10.0;
  static const double radius = 50.0;
  bool _isActivated = false;
  bool hasBeenHit = false;

  BombZone() {
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _activateBombZone();
    Future.delayed(const Duration(seconds: 5)).then((_) => removeFromParent());
  }

  void _activateBombZone() {
    _isActivated = true;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (_isActivated && other is Player && !hasBeenHit) {
      other.updateHealth(-damage);
      hasBeenHit = true;  // 폭탄이 처리되었다고 표시
      removeFromParent();  // 폭탄을 게임에서 제거
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = Colors.red.withOpacity(0.5);
    canvas.drawRect(size.toRect(), paint);
  }
}
