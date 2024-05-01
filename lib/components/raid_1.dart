// flutter imports
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

// flame imports
import 'package:flame/flame.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

// self imports
import 'package:flame_realtime_shooting/game/game.dart';


class Raid1 extends PositionComponent {
  final List<RaidData1> raidsData;
  late SpriteAnimationTicker explosionAnimation;
  late SpriteAnimation test;
  double elapsedMilliseconds = 0;
  Map<int, RectangleComponent> activeExplosions = {};

  Raid1({required this.raidsData});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await _loadExplosionAnimation();
  }

  Future<void> _loadExplosionAnimation() async {
    final explosionImage = await Flame.images.load('explosion-sprite.png');
    final spriteSheet = SpriteSheet(image: explosionImage, srcSize: Vector2(128, 128));

    List<Sprite> sprites = [];
    for (int row = 0; row < 13; row++) {
      for (int column = 0; column < 2; column++) {
        sprites.add(spriteSheet.getSprite(row, column));
      }
    }

    final explosionAni = SpriteAnimation.spriteList(sprites, stepTime: (0.6/22), loop: true);
    explosionAnimation = SpriteAnimationTicker(explosionAni);
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsedMilliseconds += dt * 1000;
    explosionAnimation.update(dt);
    manageExplosions();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (var pattern in raidsData) {
      if (elapsedMilliseconds >= pattern.startTime && elapsedMilliseconds <= pattern.endTime) {
        _renderExplosions(canvas, pattern);
      }
    }
  }

  void _renderExplosions(Canvas canvas, RaidData1 pattern) {
    if (pattern.quadrant == 5) {
      final rectWidth = (worldSize.x * 3) / 4;
      final rectHeight = worldSize.y;
      final startX = worldSize.x / 4;
      final startY = 0.0;

      final rectPaint = Paint()..color = Colors.red.withOpacity(0.7);
      canvas.drawRect(Rect.fromLTWH(startX, startY, rectWidth, rectHeight), rectPaint);

      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          explosionAnimation.getSprite().render(canvas,
              position: Vector2(startX + worldSize.x * j / 4, startY + worldSize.y * i / 3),
              size: Vector2(worldSize.x / 4, worldSize.y / 3));
        }
      }
    } else {
      final rectWidth = worldSize.x / 4;
      final rectHeight = worldSize.y;
      final startX = worldSize.x * (pattern.quadrant - 1) / 4;
      final startY = 0.0;

      final rectPaint = Paint()..color = Colors.red.withOpacity(0.7);
      canvas.drawRect(Rect.fromLTWH(startX, startY, rectWidth, rectHeight), rectPaint);

      for (int i = 0; i < 3; i++) {
        explosionAnimation.getSprite().render(canvas,
            position: Vector2(startX, startY + worldSize.y * i / 3),
            size: Vector2(worldSize.x / 4, worldSize.y / 3));
      }
    }
  }

  void manageExplosions() {
    raidsData.forEach((pattern) {
      if (elapsedMilliseconds >= pattern.startTime && elapsedMilliseconds <= pattern.endTime) {
        if (!activeExplosions.containsKey(pattern.quadrant)) {
          final explosionArea = createExplosionArea(pattern);
          add(explosionArea);
          activeExplosions[pattern.quadrant] = explosionArea;
        }
      } else {
        if (activeExplosions.containsKey(pattern.quadrant)) {
          remove(activeExplosions[pattern.quadrant]!);
          activeExplosions.remove(pattern.quadrant);
        }
      }
    });
  }

  RectangleComponent createExplosionArea(RaidData1 pattern) {
    if (pattern.quadrant == 5) {
      double startX = worldSize.x / 4;
      double width = worldSize.x * 3 / 4;
      double height = worldSize.y;

      final explosionArea = RectangleComponent()
        ..position = Vector2(startX, 0)
        ..size = Vector2(width, height)
        ..anchor = Anchor.topLeft;

      explosionArea.opacity = 0;
      explosionArea.add(RectangleHitbox());

      return explosionArea;
    } else {
      double startX = worldSize.x * (pattern.quadrant - 1) / 4;
      double width = worldSize.x / 4;
      double height = worldSize.y;

      final explosionArea = RectangleComponent()
        ..position = Vector2(startX, 0)
        ..size = Vector2(width, height)
        ..anchor = Anchor.topLeft;

      explosionArea.opacity = 0;
      explosionArea.add(RectangleHitbox());

      return explosionArea;
    }
  }
}

class RaidData1 {
  final double startTime;
  final double endTime;
  final int quadrant;

  RaidData1(this.startTime, this.endTime, this.quadrant);
}