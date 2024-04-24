import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum Direction { up, down, left, right, none }

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
    return SizedBox(
      height: 120,
      width: 120,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          child: Transform.translate(
            offset: delta,
            child: CircleAvatar(
              backgroundColor: Colors.blue[300],
              radius: 30,
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
    final newDirection = getDirectionFromOffset(newDelta);
    if (widget.onDirectionChanged != null) {
      widget.onDirectionChanged!(newDirection);
    }
  }

  Direction getDirectionFromOffset(Offset offset) {
    if (offset.dx.abs() > offset.dy.abs()) {
      return offset.dx > 0 ? Direction.right : Direction.left;
    } else if (offset.dy != 0) {
      return offset.dy > 0 ? Direction.down : Direction.up;
    }
    return Direction.none;
  }

  void _startMovementTimer() {
    movementTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (isPressed && widget.onDirectionChanged != null) {
        widget.onDirectionChanged!(direction);
      }
    });
  }

  void _stopMovementTimer() {
    movementTimer?.cancel();
  }
}
