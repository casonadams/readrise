import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'speaker_native.dart'
    if (dart.library.js_interop) 'speaker_web.dart'
    as platform;

/// Text-to-speech for this platform: the Web Speech API in browsers, the
/// system voice in the mobile apps.
Speaker createSpeaker() => platform.createSpeaker();
