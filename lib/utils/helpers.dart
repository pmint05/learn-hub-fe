import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(Function callback) {
    _timer?.cancel();
    _timer = Timer(delay, () => callback());
  }

  void cancel() {
    _timer?.cancel();
  }
}