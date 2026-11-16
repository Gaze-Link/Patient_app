import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dwell/dwell_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/patient_bottom_nav.dart';

class SentenceBuilderScreen extends StatefulWidget {
  const SentenceBuilderScreen({super.key});

  @override
  State<SentenceBuilderScreen> createState() => _SentenceBuilderScreenState();
}

class _SentenceBuilderScreenState extends State<SentenceBuilderScreen> {
  final StringBuffer _buffer = StringBuffer();
  String get _text => _buffer.toString();

  /// Figma frame 37:4802 — 4-row Arabic keyboard layout.
  static const _rows = [
    ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ'],
    ['ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن', 'م'],
    ['ئ', 'ء', 'ؤ', 'ر', 'ى', 'ة', 'و', 'ز', 'ظ'],
    ['د', 'ذ', 'ج', 'ح', 'ط', 'ك'],
  ];

  bool get _isEmpty => _text.isEmpty;
  bool get _isResting => AppPreferences.isResting.value;

  @override
  void initState() {
    super.initState();
    AppPreferences.isResting.addListener(_onRestChanged);
  }

  void _onRestChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppPreferences.isResting.removeListener(_onRestChanged);
    super.dispose();
  }

  void _appendLetter(String letter) {
    if (_isResting) return;
    setState(() => _buffer.write(letter));
  }

  void _appendSpace() {
    if (_isResting || _isEmpty || _text.endsWith(' ')) return;
    setState(() => _buffer.write(' '));
  }

  void _backspace() {
    if (_isResting || _isEmpty) return;
    setState(() {
      final s = _text;
      _buffer.clear();
      // Remove last code-unit cluster safely; Arabic letters are BMP,
      // so substring(0, length-1) is correct for all single-character keys.
      if (s.isNotEmpty) _buffer.write(s.substring(0, s.length - 1));
    });
  }

  void _clearAll() {
    if (_isEmpty) return;
    setState(() => _buffer.clear());
  }

  void _speak() {
    final phrase = _text.trim();
    if (phrase.isEmpty) return;
    try {
      context.pushNamed(
        'confirmation',
        queryParameters: {'phrase': phrase, 'category': 'composer'},
      );
    } catch (_) {
      // No GoRouter context in tests — ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const PatientBottomNav(selected: 'composer'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final compact = constraints.maxHeight < 560;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 16,
                compact ? 10 : 20,
                wide ? 24 : 16,
                compact ? 8 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(wide: wide),
                  SizedBox(height: compact ? 10 : 18),
                  _ComposerBar(text: _text, onSpeak: _speak, compact: compact),
                  SizedBox(height: compact ? 8 : 14),
                  Expanded(
                    child: _ArabicKeyboard(
                      rows: _rows,
                      onLetter: _appendLetter,
                      onSpace: _appendSpace,
                      onBackspace: _backspace,
                      onClear: _clearAll,
                      onSpeak: _speak,
                      canSpeak: !_isEmpty,
                      canBackspace: !_isEmpty,
                      compact: compact,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.wide});
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: wide ? 96 : 74,
          height: 46,
          child: DwellActionCard(
            label: 'رجوع',
            borderRadius: 12,
            contentPadding: EdgeInsets.zero,
            borderColor: Colors.transparent,
            fillColor: Colors.transparent,
            onActivate: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed('dashboard');
              }
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back_rounded, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'رجوع',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اكتب رسالتك',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.text,
                  fontSize: wide ? 26 : 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (wide)
                Text(
                  'استخدم الحروف أو ارجع دون فقدان النص',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
            ],
          ),
        ),
        // Only show the status badge on screens wider than 420px
        if (wide) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.greenSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.greenBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'التتبّع يعمل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.mint,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'جاهز للاختيار',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Composer sentence bar
// ---------------------------------------------------------------------------

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.text,
    required this.onSpeak,
    required this.compact,
  });
  final String text;
  final VoidCallback onSpeak;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasText = text.isNotEmpty;
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 68 : 96),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.teal, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'جملتك الحالية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text.isEmpty ? 'ابدأ باختيار كلمة أو عبارة' : text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.text,
                    fontSize: compact ? 18 : 24,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: compact ? 100 : 170,
            height: compact ? 52 : 68,
            child: DwellActionCard(
              label: 'انطق الجملة',
              enabled: hasText,
              contentPadding: EdgeInsets.zero,
              fillColor: hasText ? AppColors.teal : null,
              onActivate: onSpeak,
              child: Opacity(
                opacity: hasText ? 1.0 : 0.45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      color: hasText
                          ? AppColors.onPrimary
                          : AppColors.textMuted,
                      size: compact ? 18 : 22,
                    ),
                    SizedBox(width: compact ? 4 : 8),
                    Flexible(
                      child: Text(
                        'انطق الجملة',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: hasText
                              ? AppColors.onPrimary
                              : AppColors.textMuted,
                          fontSize: compact ? 13 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arabic Virtual Keyboard (Figma 37:4802)
// ---------------------------------------------------------------------------

class _ArabicKeyboard extends StatelessWidget {
  const _ArabicKeyboard({
    required this.rows,
    required this.onLetter,
    required this.onSpace,
    required this.onBackspace,
    required this.onClear,
    required this.onSpeak,
    required this.canSpeak,
    required this.canBackspace,
    required this.compact,
  });

  final List<List<String>> rows;
  final ValueChanged<String> onLetter;
  final VoidCallback onSpace;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSpeak;
  final bool canSpeak;
  final bool canBackspace;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spacing = compact ? 5.0 : 9.0;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final row in rows)
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < row.length; i++) ...[
                      if (i > 0) SizedBox(width: spacing),
                      Flexible(
                        child: _LetterKey(
                          letter: row[i],
                          compact: compact,
                          onActivate: () => onLetter(row[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Action row: حذف / مسافة / اتكلم
          Flexible(
            child: Row(
              children: [
                _ActionKey(
                  label: 'حذف',
                  icon: Icons.backspace_outlined,
                  enabled: canBackspace,
                  compact: compact,
                  onActivate: onBackspace,
                ),
                SizedBox(width: spacing),
                Expanded(
                  flex: 5,
                  child: _ActionKey(
                    label: 'مسافة',
                    icon: Icons.space_bar_rounded,
                    enabled: true,
                    compact: compact,
                    onActivate: onSpace,
                  ),
                ),
                SizedBox(width: spacing),
                _ActionKey(
                  label: 'اتكلم',
                  icon: Icons.record_voice_over_rounded,
                  enabled: canSpeak,
                  compact: compact,
                  fillColor: canSpeak ? AppColors.teal : null,
                  textColor: canSpeak ? AppColors.onPrimary : null,
                  onActivate: onSpeak,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual letter key with per-key DwellController
// ---------------------------------------------------------------------------

class _LetterKey extends StatefulWidget {
  const _LetterKey({
    required this.letter,
    required this.compact,
    required this.onActivate,
  });
  final String letter;
  final bool compact;
  final VoidCallback onActivate;

  @override
  State<_LetterKey> createState() => _LetterKeyState();
}

class _LetterKeyState extends State<_LetterKey> {
  late final DwellController _ctrl = DwellController(
    targetId: 'kb_letter_${widget.letter}',
  );

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_rebuild);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!AppPreferences.isResting.value) {
          _ctrl.startDwell(onActivate: widget.onActivate);
        }
      },
      onExit: (_) => _ctrl.cancelDwell(),
      child: GestureDetector(
        onTap: widget.onActivate,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.compact ? 48 : 60,
            maxWidth: widget.compact ? 64 : 80,
            minHeight: widget.compact ? 50 : 64,
            maxHeight: widget.compact ? 60 : 76,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.border,
                      offset: const Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.letter,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.text,
                    fontSize: widget.compact ? 18 : 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_ctrl.progress > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    child: LinearProgressIndicator(
                      value: _ctrl.progress,
                      minHeight: 4,
                      color: AppColors.teal,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action key (حذف / مسافة / اتكلم)
// ---------------------------------------------------------------------------

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.compact,
    required this.onActivate,
    this.fillColor,
    this.textColor,
  });
  final String label;
  final IconData icon;
  final bool enabled;
  final bool compact;
  final VoidCallback onActivate;
  final Color? fillColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? AppColors.text;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: compact ? 50 : 64,
        maxHeight: compact ? 60 : 76,
      ),
      child: DwellActionCard(
        label: label,
        enabled: enabled,
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        fillColor: fillColor,
        onActivate: onActivate,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 16 : 20, color: fg),
              SizedBox(width: compact ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: fg,
                  fontSize: compact ? 13 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
