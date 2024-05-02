// dart imports
import 'dart:async' as async;

// flutter imports
import 'package:flutter/material.dart';

class CannonButton extends StatefulWidget {
  final VoidCallback? onItemPressed;

  const CannonButton({Key? key, this.onItemPressed}) : super(key: key);

  @override
  _ItemButtonState createState() => _ItemButtonState();
}

class _ItemButtonState extends State<CannonButton> {
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
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.rocket, size: 50, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _handlePress() {
    if (widget.onItemPressed != null) {
      widget.onItemPressed!();
      _startCooldown();
    }
  }

  void _startCooldown() {
    setState(() {
      _isButtonEnabled = false;
    });
    async.Timer(const Duration(seconds: 5), () { // Cooldown timer to prevent spamming
      if (mounted) {
        setState(() {
          _isButtonEnabled = true;
        });
      }
    });
  }
}