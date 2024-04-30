// dart imports
import 'dart:async';

// flutter imports
import 'package:flutter/material.dart';

class ItemButton extends StatefulWidget {
  final VoidCallback? onFirePressed;

  const ItemButton({Key? key, this.onFirePressed}) : super(key: key);

  @override
  _ItemButtonState createState() => _ItemButtonState();
}

class _ItemButtonState extends State<ItemButton> {
  bool _isButtonEnabled = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isButtonEnabled ? _handlePress : null,
      child: Opacity(
        opacity: _isButtonEnabled ? 1.0 : 0.5,
        child: Container(
          width: 120,
          height: 120,
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