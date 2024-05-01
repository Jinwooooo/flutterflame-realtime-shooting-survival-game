// dart imports
import 'dart:ui' as ui;

// flutter imports
import 'package:flutter/material.dart';

// flame imports
import 'package:flame/components.dart';

// self imports
import 'package:flame_realtime_shooting/game/game.dart';


class Pattern1 extends PositionComponent {
  final List<PatternData1> patternsData;
  ui.Image? warningIconImage;
  double elapsedMilliseconds = 0;

  Pattern1({
    required this.patternsData,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    warningIconImage = await _getWarningIconImage();
  }

  Future<ui.Image> _getWarningIconImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const iconData = Icons.warning_amber;

    final painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 48.0,
        fontFamily: iconData.fontFamily,
        color: Colors.black,
      ),
    );
    painter.layout();
    painter.paint(canvas, Offset.zero);

    final picture = recorder.endRecording();
    return await picture.toImage(painter.width.toInt(), painter.height.toInt());
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsedMilliseconds += dt * 1000;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (var pattern in patternsData) {
      if (elapsedMilliseconds >= pattern.startTime && elapsedMilliseconds <= pattern.endTime) {
        _renderWarning(canvas, pattern);
      }
    }
  }

  void _renderWarning(Canvas canvas, PatternData1 pattern) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final rectWidth = worldSize.x / 4;
    final rectHeight = worldSize.y;
    final startX = worldSize.x * (pattern.quadrant - 1) / 4;
    final startY = 0.0;

    if (pattern.quadrant == 5) {
      canvas.drawRect(Rect.fromLTWH(worldSize.x / 4, 0.0, worldSize.x, worldSize.y), paint);

      if (warningIconImage != null) {
        final iconX = ((worldSize.x * 5) / 8) - (warningIconImage!.width) / 2;
        final iconY = (worldSize.y - warningIconImage!.height) / 2;
        paintImage(
          canvas: canvas,
          image: warningIconImage!,
          rect: Rect.fromLTWH(iconX, iconY, warningIconImage!.width.toDouble(), warningIconImage!.height.toDouble()),
          fit: BoxFit.scaleDown,
        );
      }
    } else {
      canvas.drawRect(Rect.fromLTWH(startX, startY, rectWidth, rectHeight), paint);

      if (warningIconImage != null) {
        final iconX = startX + (rectWidth - warningIconImage!.width) / 2;
        final iconY = startY + (rectHeight - warningIconImage!.height) / 2;
        paintImage(
          canvas: canvas,
          image: warningIconImage!,
          rect: Rect.fromLTWH(iconX, iconY, warningIconImage!.width.toDouble(), warningIconImage!.height.toDouble()),
          fit: BoxFit.scaleDown,
        );
      }
    }
  }
}

class PatternData1 {
  final double startTime;
  final double endTime;
  final int quadrant;

  PatternData1(this.startTime, this.endTime, this.quadrant);
}