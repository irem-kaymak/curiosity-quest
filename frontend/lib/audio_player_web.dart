import 'dart:html' as html;

html.AudioElement? _activeAudio;

Future<bool> playMp3Base64(String audioBase64) async {
  try {
    _activeAudio?.pause();
    final audio = html.AudioElement('data:audio/mpeg;base64,$audioBase64')
      ..preload = 'auto';
    _activeAudio = audio;
    await audio.play();
    return true;
  } catch (_) {
    return false;
  }
}
