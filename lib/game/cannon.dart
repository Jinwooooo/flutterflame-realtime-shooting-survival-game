// dart imports
import 'dart:async';

// flame imports
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/image_composition.dart' as flame_image;

class Cannon extends PositionComponent with CollisionCallbacks, HasGameRef {
  final Vector2 velocity;
  final flame_image.Image image;
  static const radius = 5.0;
  bool hasBeenCannon = false;
  final bool isCannon;
  int damage = 2;

  Cannon({
    required this.isCannon,
    required this.velocity,
    required this.image,
    required Vector2 initialPosition,
  }) : super(position: initialPosition);

  @override
  Future<void>? onLoad() async {
    anchor = Anchor.center;

    width = radius * 2;
    height = radius * 2;

    add(CircleHitbox()
      ..collisionType = CollisionType.passive
      ..anchor = Anchor.center);

    final sprite =
    SpriteComponent.fromImage(image, size: Vector2.all(radius * 2));

    add(sprite);
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    if (position.y < 0 || position.y > gameRef.size.y) {
      removeFromParent();
    }
  }
}