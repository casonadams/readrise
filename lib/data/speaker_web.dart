import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:web/web.dart' as web;

import 'speech_sequencer.dart';

Speaker createSpeaker() => SpeechSequencer(WebSpeechEngine());

/// Browser speech through the Web Speech API. Speech is blocked until the
/// first tap, so the first tap speaks a silent line to unlock it (iOS Safari
/// needs this); until then lines finish silently.
class WebSpeechEngine implements SpeechEngine {
  WebSpeechEngine() {
    if (!_supported) return;
    for (final type in _unlockEvents) {
      web.window.addEventListener(type, _unlockJs, true.toJS);
    }
  }

  static const _unlockEvents = ['click', 'touchend', 'pointerup', 'keydown'];

  static bool get _supported => globalContext.has('speechSynthesis');

  bool _unlocked = false;

  late final JSExportedDartFunction _unlockJs = _unlock.toJS;

  void _unlock(web.Event _) {
    if (_unlocked) return;
    _unlocked = true;
    for (final type in _unlockEvents) {
      web.window.removeEventListener(type, _unlockJs, true.toJS);
    }
    final silent = web.SpeechSynthesisUtterance(' ')..volume = 0;
    web.window.speechSynthesis.speak(silent);
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
    utterance.onend = ((web.Event _) => onDone()).toJS;
    utterance.onerror = ((web.Event _) => onError()).toJS;
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
