// dart imports
import 'dart:async';

// flutter imports
import 'package:flutter/material.dart';

class FireBulletButton extends StatefulWidget {
  final VoidCallback? onFirePressed;

  const FireBulletButton({Key? key, this.onFirePressed}) : super(key: key);

  @override
  _FireButtonState createState() => _FireButtonState();
}

class _FireButtonState extends State<FireBulletButton> {
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
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Center(
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
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isButtonEnabled = true;
        });
      }
    });
  }
}
