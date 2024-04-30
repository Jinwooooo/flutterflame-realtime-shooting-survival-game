
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
          shape: BoxShape.circle,
          color: Colors.grey[800],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Center(
            child: Transform.translate(
              offset: delta,
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
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
    direction = getDirectionFromOffset(newDelta);
    if (widget.onDirectionChanged != null) {
      widget.onDirectionChanged!(direction);
    }
  }

  Direction getDirectionFromOffset(Offset offset) {
    final double dx = offset.dx;
    final double dy = offset.dy;
    if (dx.abs() > 10 && dy.abs() > 10) {
      if (dx > 0 && dy < 0) {
        return Direction.upRight;
      } else if (dx < 0 && dy < 0) {
        return Direction.upLeft;
      } else if (dx < 0 && dy > 0) {
        return Direction.downLeft;
      } else if (dx > 0 && dy > 0) {
        return Direction.downRight;
      }
    } else if (dx.abs() > dy.abs()) {
      return dx > 0 ? Direction.right : Direction.left;
    } else if (dy.abs() > dx.abs()) {
      return dy > 0 ? Direction.down : Direction.up;
    }
    return Direction.none;
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
