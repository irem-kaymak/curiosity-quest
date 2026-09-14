import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import 'audio_player.dart';

const _curioApiBaseUrl = String.fromEnvironment(
  'CURIO_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

/// Device speech only; does not send the child's recordings to a server.
/// Instantiated on the first user tap, never during initial screen rendering.
class Narration {
  static FlutterTts? _engine;
  static Future<bool> speak(String text) async {
    if (await _speakWithCurioVoice(text)) return true;
    return _speakWithDeviceVoice(text);
  }

  static Future<bool> _speakWithCurioVoice(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_curioApiBaseUrl/agent/tts'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 18));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return false;
      final audioBase64 = data['audio_base64'];
      if (audioBase64 is! String || audioBase64.isEmpty) return false;
      return playMp3Base64(audioBase64);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _speakWithDeviceVoice(String text) async {
    try {
      final engine = _engine ??= FlutterTts();
      await engine.stop();
      final available = await engine.isLanguageAvailable('en-US');
      if (available != true && available != 1) return false;
      await engine.setLanguage('en-US');
      await engine.setSpeechRate(0.39);
      await engine.setPitch(1.18);
      final result = await engine.speak(text);
      return result == 1;
    } catch (_) {
      return false;
    }
  }

  static Future<void> stop() async {
    try {
      await _engine?.stop();
    } catch (_) {
      /* No speech engine on this device. */
    }
  }
}
