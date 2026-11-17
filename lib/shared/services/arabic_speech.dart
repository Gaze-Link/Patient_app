import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/utils/app_preferences.dart';

class ArabicSpeech {
  ArabicSpeech({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;
  bool _checked = false;
  bool _disposed = false;
  String? _lastError;
  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);

  bool get ready => _ready;
  bool get checked => _checked;
  bool get isSpeaking => isSpeakingNotifier.value;
  String? get lastError => _lastError;

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
      _tts.setErrorHandler((error) {
        _lastError = error.toString();
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
        _lastError = null;
      } else {
        _ready = false;
        _lastError = 'لا يتوفر صوت عربي على هذا الجهاز.';
      }
    } catch (error) {
      _ready = false;
      _lastError = error.toString();
      debugPrint('Arabic speech initialization failed: $error');
    } finally {
      if (!_disposed) _checked = true;
    }
  }

  Future<void> speak(String text) async {
    if (_disposed || !_ready || text.trim().isEmpty) return;
    try {
      await stop();
      if (_disposed) return;
      await _tts.setSpeechRate(AppPreferences.speechRate.value);
      await _tts.speak(text);
    } catch (error) {
      _lastError = error.toString();
      _setSpeaking(false);
      debugPrint('Arabic speech failed: $error');
    }
  }

  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _tts.stop();
      _setSpeaking(false);
    } catch (error) {
      _lastError = error.toString();
      _setSpeaking(false);
      debugPrint('Could not stop Arabic speech: $error');
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
