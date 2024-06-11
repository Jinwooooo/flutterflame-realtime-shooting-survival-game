// flutter imports
import 'package:flutter/material.dart';

// flame imports
import 'package:flame/flame.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

// self imports
import 'package:flame_realtime_shooting/game/game.dart';


class Raid1 extends PositionComponent with HasGameRef, CollisionCallbacks {
  final List<RaidData1> raidsData;
  late SpriteAnimationTicker explosionAnimation;
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
      _manageExplosions();
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
    final isQuadrantFive = pattern.quadrant == 5;
    final rectWidth = isQuadrantFive ? worldSize.x * 3 / 4 : worldSize.x / 4;
    final startX = isQuadrantFive ? 0.0 : worldSize.x * (pattern.quadrant - 1) / 4;
    final rectHeight = worldSize.y;
    final rectPaint = Paint()..color = Colors.red.withOpacity(0.7);

    canvas.drawRect(Rect.fromLTWH(startX, 0, rectWidth, rectHeight), rectPaint);

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < (isQuadrantFive ? 3 : 1); j++) {
        double posX = startX + worldSize.x * j / (isQuadrantFive ? 4 : 1);
        double posY = worldSize.y * i / 3;
        explosionAnimation.getSprite().render(canvas, 
                                              position: Vector2(posX, posY), 
                                              size: Vector2(rectWidth / (isQuadrantFive ? 3 : 1), worldSize.y / 3));
      }
    }
  }

  void _manageExplosions() {
    for (var pattern in raidsData) {
    if (elapsedMilliseconds >= pattern.startTime && elapsedMilliseconds <= pattern.endTime) {
        if (!activeExplosions.containsKey(pattern.quadrant)) {
          final explosionArea = _createExplosionArea(pattern);
          add(explosionArea);
          activeExplosions[pattern.quadrant] = explosionArea;
        }
      } else {
        if (activeExplosions.containsKey(pattern.quadrant)) {
          remove(activeExplosions[pattern.quadrant]!);
          activeExplosions.remove(pattern.quadrant);
        }
      }
    }
  }

  RaidRectangle _createExplosionArea(RaidData1 pattern) {
    double startX = (pattern.quadrant == 5) ? 0.0 : worldSize.x * (pattern.quadrant - 1) / 4;
    double width = (pattern.quadrant == 5) ? worldSize.x * 3 / 4 : worldSize.x / 4;
    double height = worldSize.y;

    return RaidRectangle(
      position: Vector2(startX, 0),
      size: Vector2(width, height),
    );
  }
}

class RaidData1 {
    final double startTime;
    final double endTime;
    final int quadrant;

    RaidData1(this.startTime, this.endTime, this.quadrant);
}

class RaidRectangle extends RectangleComponent {
  final bool isRaid = true;

  RaidRectangle({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size) {
    paint = Paint()..color = Colors.transparent;
    add(RectangleHitbox());
  }
}