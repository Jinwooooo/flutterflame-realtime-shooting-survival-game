import 'dart:async';

import 'package:flutter/material.dart';

class ItemButton extends StatefulWidget {
  final VoidCallback? onItemPressed;

  const ItemButton({Key? key, this.onItemPressed}) : super(key: key);

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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue, // Changed to blue to differentiate from the fire button
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(Icons.card_giftcard, size: 50, color: Colors.white), // Icon changed to represent items
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
    Timer(Duration(seconds: 5), () { // Cooldown timer to prevent spamming
      if (mounted) {
        setState(() {
          _isButtonEnabled = true;
        });
      }
    });
  }
}
