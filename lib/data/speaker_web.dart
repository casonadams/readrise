import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:web/web.dart' as web;

import 'speech_sequencer.dart';

Speaker createSpeaker() => SpeechSequencer(WebSpeechEngine());

/// Browser speech through the Web Speech API.
///
/// iOS Safari refuses speech until a line has been started inside a tap, and
/// an empty line is enough. Every tap tries until a line is seen to start, so
/// an event that Safari does not count as a tap cannot lock speech out for
/// good. Until then lines finish silently.
class WebSpeechEngine implements SpeechEngine {
  WebSpeechEngine() {
    if (!_supported) return;
    for (final type in _unlockEvents) {
      web.window.addEventListener(type, _unlockJs, true.toJS);
    }
  }

  static const _unlockEvents = ['click', 'touchend', 'keydown'];

  static bool get _supported => globalContext.has('speechSynthesis');

  bool _confirmed = false;

  /// Held so the browser cannot garbage-collect a line before it ends, which
  /// silently drops its 'end' event.
  final List<web.SpeechSynthesisUtterance> _alive = [];

  late final JSExportedDartFunction _unlockJs = _unlock.toJS;

  void _unlock(web.Event _) {
    if (_confirmed) return;
    final empty = web.SpeechSynthesisUtterance('');
    empty.onstart = ((web.Event _) => _confirm()).toJS;
    _keep(empty);
    web.window.speechSynthesis.speak(empty);
  }

  void _confirm() {
    if (_confirmed) return;
    _confirmed = true;
    for (final type in _unlockEvents) {
      web.window.removeEventListener(type, _unlockJs, true.toJS);
    }
  }

  void _keep(web.SpeechSynthesisUtterance utterance) {
    _alive.add(utterance);
    if (_alive.length > 6) _alive.removeAt(0);
  }

  @override
  void start(
    String text, {
    required void Function() onDone,
    required void Function() onError,
  }) {
    if (!_supported) {
      onDone();
      return;
    }
    final synth = web.window.speechSynthesis;
    final utterance = web.SpeechSynthesisUtterance(text)
      ..lang = 'en-US'
      ..rate = 0.85
      ..pitch = 1.1;
    final voice = _englishVoice(synth);
    if (voice != null) utterance.voice = voice;
    utterance.onstart = ((web.Event _) => _confirm()).toJS;
    utterance.onend = ((web.Event _) => onDone()).toJS;
    utterance.onerror = ((web.Event _) => onError()).toJS;
    _keep(utterance);
    synth.resume();
    synth.speak(utterance);
  }

  @override
  void cancel() {
    if (_supported) web.window.speechSynthesis.cancel();
  }

  web.SpeechSynthesisVoice? _englishVoice(web.SpeechSynthesis synth) {
    web.SpeechSynthesisVoice? fallback;
    for (final v in synth.getVoices().toDart) {
      if (v.lang.replaceAll('_', '-') == 'en-US') return v;
      if (fallback == null && v.lang.toLowerCase().startsWith('en')) {
        fallback = v;
      }
    }
    return fallback;
  }
}
