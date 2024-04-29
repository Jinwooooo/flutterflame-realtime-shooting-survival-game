// dart imports
import 'dart:async';
import 'dart:math';

// flutter imports
import 'package:flutter/material.dart';

enum Direction { up, down, left, right, upLeft, upRight, downLeft, downRight, none }

class Joypad extends StatefulWidget {
  final ValueChanged<Direction>? onDirectionChanged;
  const Joypad({Key? key, this.onDirectionChanged}) : super(key: key);

  @override
  JoypadState createState() => JoypadState();
}

class JoypadState extends State<Joypad> {
  Direction direction = Direction.none;
  Offset delta = Offset.zero;
  bool isPressed = false;
  Timer? movementTimer;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Container(
        height: 120,
        width: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,  // This enforces a circular shape for the outer circle
          color: Colors.grey[800],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Center(  // Ensure the controlling stick is centered
            child: Transform.translate(
              offset: delta,
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                // The radius is set to half the size of the outer circle
                radius: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    isPressed = true;
    _updateMovement(details.localPosition);
    _startMovementTimer();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (isPressed) {
      _updateMovement(details.localPosition);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    isPressed = false;
    updateDelta(Offset.zero);
    _stopMovementTimer();
  }

  void _updateMovement(Offset localPosition) {
    final newDelta = localPosition - const Offset(60, 60);
    updateDelta(
      Offset.fromDirection(
        newDelta.direction,
        min(30, newDelta.distance),
      ),
    );
  }

  void updateDelta(Offset newDelta) {
    setState(() {
      delta = newDelta;
    });
    direction = getDirectionFromOffset(newDelta); // Update the direction here
    if (widget.onDirectionChanged != null) {
      widget.onDirectionChanged!(direction);
    }
  }

  Direction getDirectionFromOffset(Offset offset) {
    final double angle = offset.direction;
    if (offset.distance < 10) return Direction.none;

    // 8 방향 정의
    if (angle >= -pi / 8 && angle < pi / 8) {
      return Direction.right;
    } else if (angle >= pi / 8 && angle < 3 * pi / 8) {
      return Direction.downRight;
    } else if (angle >= 3 * pi / 8 && angle < 5 * pi / 8) {
      return Direction.down;
    } else if (angle >= 5 * pi / 8 && angle < 7 * pi / 8) {
      return Direction.downLeft;
    } else if (angle >= 7 * pi / 8 || angle < -7 * pi / 8) {
      return Direction.left;
    } else if (angle >= -7 * pi / 8 && angle < -5 * pi / 8) {
      return Direction.upLeft;
    } else if (angle >= -5 * pi / 8 && angle < -3 * pi / 8) {
      return Direction.up;
    } else {
      return Direction.upRight;
    }
  }

  void _startMovementTimer() {
    movementTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (isPressed && widget.onDirectionChanged != null) {
        widget.onDirectionChanged!(direction);
      }
    });
  }

  void _stopMovementTimer() {
    movementTimer?.cancel();
  }
}