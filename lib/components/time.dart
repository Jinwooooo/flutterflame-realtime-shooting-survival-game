// dart imports
import 'dart:async' as async;

class GameTimer {
  final Function(int) onTick;
  late final async.Timer _timer;
  int _elapsedSeconds = 0;

  String get formattedTime => '${(_elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}';

  GameTimer({required this.onTick});

  void start() {
    _timer = async.Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      onTick(_elapsedSeconds);
    });
  }

  void stop() {
    _timer.cancel();
  }

  int get elapsedSeconds => _elapsedSeconds;
}
