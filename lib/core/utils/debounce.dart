class Debouncer {
  Debouncer(this.delay);
  final Duration delay;
  void Function()? _pending;

  void call(void Function() action) {
    _pending?.call = null;
    _pending = action;
    Future.delayed(delay, () {
      final action = _pending;
      _pending = null;
      if (action != null) action();
    });
  }
}
