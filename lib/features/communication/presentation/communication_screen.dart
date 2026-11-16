import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dwell/dwell_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../shared/widgets/patient_bottom_nav.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/dwell_back_button.dart';
import '../../../shared/widgets/urgent_assistance_card.dart';
import '../data/communication_catalog.dart';
import '../domain/models/communication_option.dart';
import 'widgets/communication_phrase_tile.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({this.category, super.key});
  final String? category;

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final FlutterTts _tts = FlutterTts();
  late final DwellController _dwellController = DwellController(
    targetId: 'communication_option',
  );
  int? _focusedIndex;
  int? _selectedIndex;
  int? _dwellIndex;
  bool _speechReady = false;
  bool _speechChecked = false;
  int _speechRequestId = 0;

  bool get _hasUrgentAssistance =>
      const {'needs', 'health', 'feelings'}.contains(widget.category);
  bool get _isResting => AppPreferences.isResting.value;

  List<CommunicationOption> get _options =>
      CommunicationCatalog.optionsByCategory[widget.category] ??
      CommunicationCatalog.defaultOptions;

  @override
  void didUpdateWidget(covariant CommunicationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category == widget.category) return;
    _dwellController.cancelDwell();
    _dwellIndex = null;
    _focusedIndex = null;
    _selectedIndex = null;
    _speechRequestId++;
    unawaited(_tts.stop());
  }

  String get _title => switch (widget.category) {
    'needs' => 'احتياجاتي',
    'health' => 'صحتي وألمي',
    'feelings' => 'مشاعري',
    'communication' => 'التواصل',
    _ => 'التواصل',
  };

  String get _prompt => switch (widget.category) {
    'needs' => 'ماذا تحتاج الآن؟',
    'health' => 'كيف تشعر؟',
    'feelings' => 'عبّر عن شعورك',
    _ => 'اختار اللي عايز تقوله',
  };

  @override
  void initState() {
    super.initState();
    _dwellController.addListener(_handleDwellUpdate);
    AppPreferences.isResting.addListener(_handleRestModeChanged);
    unawaited(_configureSpeech());
  }

  void _handleDwellUpdate() {
    if (mounted) setState(() {});
  }

  void _handleRestModeChanged() {
    if (_isResting) _cancelDwell();
    if (mounted) setState(() {});
  }

  Future<void> _configureSpeech() async {
    try {
      final languages = (await _tts.getLanguages as List<dynamic>).map(
        (e) => e.toString(),
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
        await _tts.setPitch(1);
        await _tts.setVolume(1);
        _speechReady = true;
      }
    } catch (_) {
      _speechReady = false;
    } finally {
      if (mounted) setState(() => _speechChecked = true);
    }
  }

  Future<void> _speakOption(int index) async {
    if (!_speechReady) return;
    final id = ++_speechRequestId;
    try {
      await _tts.stop();
      if (!mounted || id != _speechRequestId) return;
      await _tts.setSpeechRate(AppPreferences.speechRate.value);
      await _tts.speak(_options[index].label);
    } catch (_) {
      // This screen remains usable if the local speech engine fails.
    }
  }

  void _selectOption(int index) {
    if (_isResting) return;
    _cancelDwell();
    setState(() {
      _selectedIndex = index;
      _focusedIndex = index;
    });
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      unawaited(_speakOption(index));
      return;
    }
    router.pushNamed(
      'confirmation',
      queryParameters: {
        'phrase': _options[index].label,
        if (widget.category != null) 'category': widget.category!,
      },
    );
  }

  void _startDwell(int index) {
    if (_isResting) return;
    if (_dwellIndex == index) return;
    _cancelDwell();
    setState(() {
      _focusedIndex = index;
      _dwellIndex = index;
    });
    _dwellController.startDwell(onActivate: () => _selectOption(index));
  }

  void _cancelDwell() {
    _dwellController.cancelDwell();
    _dwellIndex = null;
  }

  @override
  void dispose() {
    _dwellController.removeListener(_handleDwellUpdate);
    _dwellController.dispose();
    AppPreferences.isResting.removeListener(_handleRestModeChanged);
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _selectedIndex == null
        ? null
        : _options[_selectedIndex!];
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: const DwellBackButton(),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 14),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width < 400 ? 64 : 170,
              height: 56,
              child: DwellActionCard(
                label: _isResting ? 'متابعة التواصل' : 'راحة',
                allowDuringRestMode: true,
                contentPadding: EdgeInsets.zero,
                onActivate: () {
                  AppPreferences.isResting.value = !_isResting;
                  _selectedIndex = null;
                  _focusedIndex = null;
                },
                child: MediaQuery.sizeOf(context).width < 400
                    ? Icon(
                        _isResting
                            ? Icons.play_arrow_rounded
                            : Icons.self_improvement_rounded,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isResting
                                ? Icons.play_arrow_rounded
                                : Icons.self_improvement_rounded,
                          ),
                          const SizedBox(width: 8),
                          Text(_isResting ? 'متابعة التواصل' : 'راحة'),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PatientBottomNav(selected: 'categories'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final short = constraints.maxHeight < 450;
            final inlineUrgent =
                _hasUrgentAssistance &&
                wide &&
                (constraints.maxHeight >= 500 || constraints.maxWidth >= 800);
            final columns = wide ? 3 : 2;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 16,
                10,
                wide ? 24 : 16,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _prompt,
                              maxLines: short ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.pageTitle.copyWith(
                                fontSize: short
                                    ? 21
                                    : wide
                                    ? 26
                                    : 24,
                              ),
                            ),
                            if (!short)
                              Text(
                                'ثبّت المؤشر أو المس العبارة لاختيارها.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body,
                              ),
                          ],
                        ),
                      ),
                      if (inlineUrgent) ...[
                        const SizedBox(width: 12),
                        SizedBox(
                          width: short ? 210 : 250,
                          height: short ? 64 : 96,
                          child: UrgentAssistanceCard(
                            compact: short,
                            onActivate: () => context.pushNamed('emergency'),
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      Container(
                        width: constraints.maxWidth < 500 ? 108 : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.greenSurface,
                          border: Border.all(color: AppColors.greenBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'جاهز للاختيار',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.mint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (const {
                    'needs',
                    'health',
                    'feelings',
                  }.contains(widget.category)) ...[
                    _categoryTabs(context),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: GridView.builder(
                      itemCount: _options.length,
                      physics: const ClampingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: wide ? 2.0 : 1.45,
                      ),
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        final isSelected = _selectedIndex == index;
                        final isHighlighted = _selectedIndex == index;
                        return MouseRegion(
                          onEnter: (_) => _startDwell(index),
                          onExit: (_) {
                            if (_dwellIndex == index) {
                              _cancelDwell();
                            }
                            setState(() {
                              if (_focusedIndex == index) _focusedIndex = null;
                            });
                          },
                          child: CommunicationPhraseTile(
                            option: option,
                            isHighlighted: isHighlighted,
                            isSelected: isSelected,
                            dwellProgress: _dwellIndex == index
                                ? _dwellController.progress
                                : 0,
                            onTap: () {
                              _dwellController.triggerImmediate(
                                onActivate: () => _selectOption(index),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(minHeight: 62),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.greenBorder),
                    ),
                    child: selectedOption == null
                        ? Text(
                            _isResting
                                ? 'وضع الراحة شغال. اختار أي جملة عشان ترجع للتواصل.'
                                : !_speechChecked
                                ? 'جاري تجهيز الصوت العربي...'
                                : !_speechReady
                                ? 'الصوت العربي مش متاح على الجهاز'
                                : 'الاختيار هيظهر هنا',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'الاختيار المحاكى: ${selectedOption.label}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: DwellActionCard(
                                  label: 'اسمع الاختيار تاني',
                                  enabled: _speechReady,
                                  contentPadding: EdgeInsets.zero,
                                  onActivate: () =>
                                      unawaited(_speakOption(_selectedIndex!)),
                                  child: Icon(
                                    Icons.volume_up_rounded,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (_hasUrgentAssistance && !inlineUrgent) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 76,
                      child: UrgentAssistanceCard(
                        compact: true,
                        onActivate: () => context.pushNamed('emergency'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _categoryTabs(BuildContext context) {
    const categories = [
      (id: 'needs', label: 'احتياجاتي'),
      (id: 'health', label: 'صحتي وألمي'),
      (id: 'feelings', label: 'مشاعري'),
    ];

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          for (final category in categories) ...[
            if (category != categories.first) const SizedBox(width: 8),
            Expanded(
              child: DwellActionCard(
                label: category.label,
                targetId: 'communication-category-${category.id}',
                semanticSelected: widget.category == category.id,
                fillColor: widget.category == category.id
                    ? AppColors.greenSurface
                    : AppColors.surface,
                borderColor: widget.category == category.id
                    ? AppColors.greenBorder
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                onActivate: () => context.goNamed(
                  'communication',
                  queryParameters: {'category': category.id},
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      category.label,
                      style: TextStyle(
                        color: widget.category == category.id
                            ? AppColors.teal
                            : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
