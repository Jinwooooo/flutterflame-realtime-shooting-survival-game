import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FireButton extends StatelessWidget {
  final VoidCallback? onFirePressed;

  const FireButton({Key? key, this.onFirePressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFirePressed,
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
    );
  }
}