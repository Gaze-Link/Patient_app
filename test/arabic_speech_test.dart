import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaze_app/shared/services/arabic_speech.dart';

void main() {
  const channel = MethodChannel('flutter_tts');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('initializes an available Arabic voice and speaks text', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getLanguages') return ['en-US', 'ar-EG'];
      return 1;
    });
    final speech = ArabicSpeech();
    addTearDown(speech.dispose);

    await speech.initialize();
    await speech.speak('أحتاج مساعدة');

    expect(speech.ready, isTrue);
    expect(calls.map((call) => call.method), containsAll(['setLanguage', 'speak']));
    expect(
      calls.where((call) => call.method == 'speak').single.arguments,
      'أحتاج مساعدة',
    );
  });

  test('reports an initialization failure safely', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getLanguages') {
        throw PlatformException(code: 'unavailable', message: 'engine missing');
      }
      return 1;
    });
    final speech = ArabicSpeech();
    addTearDown(speech.dispose);

    await speech.initialize();

    expect(speech.checked, isTrue);
    expect(speech.ready, isFalse);
    expect(speech.lastError, contains('engine missing'));
  });

  test('handles speech and stop errors without throwing', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getLanguages') return ['ar-EG'];
      if (call.method == 'speak' || call.method == 'stop') {
        throw PlatformException(code: 'failed', message: 'tts unavailable');
      }
      return 1;
    });
    final speech = ArabicSpeech();
    addTearDown(speech.dispose);

    await speech.initialize();
    await speech.speak('نعم');
    await speech.stop();

    expect(speech.lastError, contains('tts unavailable'));
    expect(speech.isSpeaking, isFalse);
  });
}
