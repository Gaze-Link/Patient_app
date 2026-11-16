import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/services/arabic_speech.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/dwell_back_button.dart';
import '../../../shared/widgets/patient_status_chip.dart';
import '../../../shared/widgets/figma_icon.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final ArabicSpeech _speech = ArabicSpeech();
  String? _selectedPhrase;

  static const _phrases = [
    ('محتاج مساعدة حالًا', Icons.support_agent_rounded),
    ('أنا بتألم', Icons.favorite_outline_rounded),
    ('نادِ المرافق', Icons.notifications_active_outlined),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(
      _speech.initialize().then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  void _select(String phrase) {
    setState(() => _selectedPhrase = phrase);
    // Navigate to PhraseConfirmationScreen — it handles TTS on entry
    try {
      context.pushNamed(
        'confirmation',
        queryParameters: {'phrase': phrase, 'category': 'emergency'},
      );
    } catch (_) {
      // Fallback: speak inline if navigation context unavailable (e.g. tests)
      unawaited(_speech.speak(phrase));
    }
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('مساعدة عاجلة'),
      leading: const DwellBackButton(),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 760 &&
                constraints.maxWidth > constraints.maxHeight;
            final compact = constraints.maxWidth < 520;
            final heading = Row(
              children: [
                const FigmaIcon(AppAssets.urgentTitle),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ماذا تحتاج الآن؟',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.pageTitle,
                      ),
                      Text(
                        'ثبّت نظرك على الرسالة لتأكيدها ونطقها.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
            );
            final status = PatientStatusChip(
              compact: compact,
              title: 'الصوت ${_speech.ready ? 'جاهز' : 'اختياري'}',
              subtitle: _speech.ready ? 'العربية متاحة' : 'حسب إعدادات الجهاز',
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  heading,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: status,
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(child: heading),
                      status,
                    ],
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.greenSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.greenBorder),
                  ),
                  child: Text(
                    _selectedPhrase == null
                        ? 'اختر عبارة لنطقها'
                        : 'تم اختيار: $_selectedPhrase',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mint,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GridView.builder(
                    itemCount: _phrases.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: wide ? 3 : 1,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: wide ? 170 : 100,
                    ),
                    itemBuilder: (context, index) {
                      final phrase = _phrases[index].$1;
                      return DwellActionCard(
                        label: phrase,
                        borderColor: AppColors.urgentBorder,
                        fillColor: AppColors.surface,
                        semanticSelected: _selectedPhrase == phrase,
                        onActivate: () => _select(phrase),
                        child: Center(
                          child: Text(
                            phrase,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.urgent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedPhrase != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DwellActionCard(
                          label: 'إعادة نطق العبارة',
                          enabled: _speech.ready,
                          contentPadding: EdgeInsets.zero,
                          onActivate: () =>
                              unawaited(_speech.speak(_selectedPhrase!)),
                          child: const Center(child: Text('إعادة نطق العبارة')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DwellActionCard(
                          label: 'إلغاء اختيار العبارة',
                          contentPadding: EdgeInsets.zero,
                          onActivate: () =>
                              setState(() => _selectedPhrase = null),
                          child: const Center(child: Text('إلغاء')),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'هذه الشاشة تنطق العبارة على الجهاز فقط. لا ترسل تنبيهاً أو تتصل بالمرافق تلقائياً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textQuiet, fontSize: 14),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
