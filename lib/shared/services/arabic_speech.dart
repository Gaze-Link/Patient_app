import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/utils/app_preferences.dart';

class ArabicSpeech {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _checked = false;
  bool _disposed = false;
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);

  bool get ready => _ready;
  bool get checked => _checked;
  bool get isSpeaking => isSpeakingNotifier.value;

  void _setSpeaking(bool value) {
    if (!_disposed) isSpeakingNotifier.value = value;
  }

  Future<void> initialize() async {
    if (_disposed) return;
    try {
      _tts.setStartHandler(() {
        _setSpeaking(true);
      });
      _tts.setCompletionHandler(() {
        _setSpeaking(false);
      });
      _tts.setCancelHandler(() {
        _setSpeaking(false);
      });
      _tts.setErrorHandler((_) {
        _setSpeaking(false);
      });

      final languages = (await _tts.getLanguages as List<dynamic>).map(
        (language) => language.toString(),
      );
      String? locale;
      for (final language in languages) {
        final normalized = language.replaceAll('_', '-').toLowerCase();
        if (normalized == 'ar-eg') {
          locale = language;
          break;
        }
        if (locale == null && normalized.startsWith('ar')) locale = language;
      }
      if (locale != null) {
        await _tts.setLanguage(locale);
        if (_disposed) return;
        await _tts.setPitch(1);
        await _tts.setVolume(1);
        _ready = true;
      }
    } catch (error) {
      _ready = false;
      debugPrint('Arabic speech initialization failed: $error');
    } finally {
      if (!_disposed) _checked = true;
    }
  }

  Future<void> speak(String text) async {
    if (_disposed || !_ready || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      if (_disposed) return;
      await _tts.setSpeechRate(AppPreferences.speechRate.value);
      await _tts.speak(text);
    } catch (error) {
      _setSpeaking(false);
      debugPrint('Arabic speech failed: $error');
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(_stopSafely());
    isSpeakingNotifier.dispose();
  }

  Future<void> _stopSafely() async {
    try {
      await _tts.stop();
    } catch (error) {
      debugPrint('Could not stop Arabic speech: $error');
    }
  }
}
