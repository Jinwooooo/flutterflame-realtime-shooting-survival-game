// Dart imports
import 'dart:async';

// Flutter imports
import 'package:flutter/material.dart';

class FireButton extends StatefulWidget {
  final VoidCallback? onFirePressed;

  const FireButton({Key? key, this.onFirePressed}) : super(key: key);

  @override
  _FireButtonState createState() => _FireButtonState();
}

class _FireButtonState extends State<FireButton> {
  bool _isButtonEnabled = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isButtonEnabled ? _handlePress : null,
      child: Opacity(
        opacity: _isButtonEnabled ? 1.0 : 0.5,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(Icons.fireplace, size: 50, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _handlePress() {
    if (widget.onFirePressed != null) {
      widget.onFirePressed!();
      _startCooldown();
    }
  }

  void _startCooldown() {
    setState(() {
      _isButtonEnabled = false;
    });
    Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isButtonEnabled = true;
        });
      }
    });
  }
}