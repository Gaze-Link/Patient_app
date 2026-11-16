import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/speaking_waveform.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/arabic_speech.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/dwell_back_button.dart';

class PhraseConfirmationScreen extends StatefulWidget {
  const PhraseConfirmationScreen({
    required this.phrase,
    this.category,
    super.key,
  });

  final String phrase;
  final String? category;

  @override
  State<PhraseConfirmationScreen> createState() =>
      _PhraseConfirmationScreenState();
}

class _PhraseConfirmationScreenState extends State<PhraseConfirmationScreen> {
  final ArabicSpeech _speech = ArabicSpeech();

  /// Whether the phrase parameter is non-empty and meaningful.
  bool get _hasPhrase => widget.phrase.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    unawaited(() async {
      await _speech.initialize();
      if (mounted) {
        setState(() {});
        // Only auto-speak when there is a valid phrase
        if (_hasPhrase) await _speech.speak(widget.phrase);
      }
    }());
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  void _replay() {
    if (!_hasPhrase) return;
    unawaited(_speech.speak(widget.phrase));
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('dashboard');
    }
  }

  String get _categoryTitle => switch (widget.category) {
    'needs' => 'احتياجاتي',
    'health' => 'صحتي وألمي',
    'feelings' => 'مشاعري',
    'emergency' => 'مساعدة عاجلة',
    'composer' => 'تكوين جملة',
    _ => 'تأكيد العبارة',
  };

  @override
  Widget build(BuildContext context) {
    final contentWidth = (MediaQuery.sizeOf(context).width - 48)
        .clamp(0.0, 720.0)
        .toDouble();
    final statusWidth = contentWidth.clamp(0.0, 420.0).toDouble();
    final actionWidth = contentWidth.clamp(0.0, 300.0).toDouble();
    final compact = contentWidth < 360;

    // Guard: if phrase is empty, show an error state instead of blank card
    if (!_hasPhrase) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_categoryTitle),
          leading: DwellBackButton(onPressed: _cancel),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.textMuted,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد عبارة للتأكيد.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.textMuted,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 140,
                height: 48,
                child: DwellActionCard(
                  label: 'رجوع',
                  borderRadius: 12,
                  fillColor: AppColors.teal,
                  onActivate: _cancel,
                  child: Center(
                    child: Text(
                      'رجوع',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryTitle),
        leading: DwellBackButton(onPressed: _cancel),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- "تأكيد العبارة" label — 18px Bold Cairo teal
                  Text(
                    'تأكيد العبارة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.teal,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // --- "العبارة المختارة" subtitle — 28px Regular Cairo muted
                  Text(
                    'العبارة المختارة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textMuted,
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- Phrase card — 48px Bold Cairo (Figma: 36:2164 / 40:3134)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 180),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.teal, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.phrase,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.text,
                        // Figma: 48px Bold (both light 36:2165 and dark 40:3135)
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- Status badge "العبارة جاهزة" — Figma: 44×44 circle icon
                  Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    width: statusWidth,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 22,
                      vertical: compact ? 10 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.greenBorder),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: compact ? 36 : 44,
                            height: compact ? 36 : 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: compact ? 20 : 24,
                              color: AppColors.mint,
                            ),
                          ),
                          SizedBox(width: compact ? 8 : 12),
                          Text(
                            'العبارة جاهزة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.mint,
                              fontSize: compact ? 16 : 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Action buttons: Replay and Cancel
                  // Figma: 300px wide, 76px tall, 21px SemiBold Cairo
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 14,
                    children: [
                      SizedBox(
                        width: actionWidth,
                        height: 76,
                        child: DwellActionCard(
                          label: 'إعادة نطق العبارة',
                          onActivate: _replay,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _speech.isSpeakingNotifier,
                            builder: (context, isSpeaking, _) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSpeaking) ...[
                                      SpeakingWaveform(
                                        isSpeaking: isSpeaking,
                                        color: AppColors.teal,
                                      ),
                                      const SizedBox(width: 8),
                                    ] else ...[
                                      Icon(
                                        Icons.volume_up_rounded,
                                        color: AppColors.teal,
                                        size: 26,
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      'إعادة نطق العبارة',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: AppColors.teal,
                                        fontSize: compact ? 18 : 21,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: actionWidth,
                        height: 76,
                        child: DwellActionCard(
                          label: 'إلغاء',
                          onActivate: _cancel,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textMuted,
                                  size: 26,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AppColors.text,
                                    fontSize: compact ? 18 : 21,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // --- Instruction — 16px Regular Cairo quiet (Figma 36:2188)
                  Text(
                    'ثبّت نظرك حتى يكتمل المؤشر. إعادة النطق والإلغاء هدفان منفصلان ولا يعملان من نظرة سريعة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textQuiet,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
