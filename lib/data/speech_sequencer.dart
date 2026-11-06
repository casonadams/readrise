import 'dart:async';

import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// Whatever actually makes sound.
abstract interface class SpeechEngine {
  /// Starts [text]. Eventually calls [onDone] or [onError] once, unless
  /// [cancel] is called first.
  void start(
    String text, {
    required void Function() onDone,
    required void Function() onError,
  });

  void cancel();
}

/// Turns a speech engine into a [Speaker] that never leaves a caller waiting:
/// a new line interrupts the old one, and every line finishes on its end, on
/// an error, or after [timeout]. A short [startDelay] after cancelling avoids
/// browsers dropping a line spoken right after a cancel.
class SpeechSequencer implements Speaker {
  SpeechSequencer(
    this._engine, {
    this.startDelay = const Duration(milliseconds: 60),
    this.timeout = const Duration(seconds: 10),
  });

  final SpeechEngine _engine;
  final Duration startDelay;
  final Duration timeout;

  int _id = 0;
  Completer<void>? _current;
  Timer? _startTimer;
  Timer? _watchdog;

  @override
  Future<void> speak(String text) {
    _release();
    final id = ++_id;
    final done = Completer<void>();
    _current = done;
    _engine.cancel();
    _startTimer = Timer(startDelay, () {
      _watchdog = Timer(timeout, () => _finish(id));
      _engine.start(
        text,
        onDone: () => _finish(id),
        onError: () => _finish(id),
      );
    });
    return done.future;
  }

  /// Ends the line [id] unless a newer one has replaced it.
  void _finish(int id) {
    if (id != _id) return;
    _release();
  }

  void _release() {
    _startTimer?.cancel();
    _watchdog?.cancel();
    final current = _current;
    _current = null;
    if (current != null && !current.isCompleted) current.complete();
  }
}
