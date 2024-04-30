import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flame_realtime_shooting/game/player.dart';
import 'dart:async' as async;

class BombZone extends PositionComponent with HasGameRef, CollisionCallbacks {
  bool _isActivated = false;
  bool hasBeenHit = false;  // 충돌 처리 여부 표시
  static const double damage = 1.0;
  static const double radius = 50.0;
  Function? onActivate;

  BombZone(Vector2 velocity) {
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    add(RectangleHitbox());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _activateBombZone();
    Future.delayed(const Duration(seconds: 5)).then((_) {
      if (!_isActivated) return;
      _isActivated = false;
      if (onActivate != null) onActivate!();
      removeFromParent();
    });
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
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()..color = _isActivated ? Colors.red.withOpacity(0.5) : Colors.grey.withOpacity(0.5);
    canvas.drawRect(size.toRect(), paint);
  }
}
