import 'package:flutter_tts/flutter_tts.dart';

abstract interface class Speaker {
  Future<void> speak(String text);
}

class TtsSpeaker implements Speaker {
  TtsSpeaker() {
    _tts.setSpeechRate(0.4);
    _tts.setPitch(1.1);
  }

  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }
}
