import 'dart:async';
import 'dart:math' as math;

import 'package:baby_tracker/presentation/theme/walnie_theme_extensions.dart';
import 'package:baby_tracker/presentation/theme/walnie_tokens.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voice recording action when user releases button
enum VoiceRecordingAction {
  /// Normal release - proceed with voice recognition
  proceed,

  /// Swipe left - cancel recording
  cancel,

  /// Swipe right - convert to text input
  toText,
}

/// A voice recording bottom sheet with gesture + explicit actions
class VoiceRecordingSheet extends StatefulWidget {
  const VoiceRecordingSheet({super.key});

  @override
  State<VoiceRecordingSheet> createState() => _VoiceRecordingSheetState();
}

class _VoiceRecordingSheetState extends State<VoiceRecordingSheet> {
  static const String _voiceExamplePrompt = '您可以说：「17点10分炫了60ml」、「8点20换了纸尿裤」';
  static const double _swipeUpThreshold = 80.0;
  static const int _waveBarCount = 20;
  static const double _minWaveHeight = 6.0;
  static const double _maxWaveHeight = 56.0;
  static const Duration _waveTick = Duration(milliseconds: 50);
  static const Duration _waveSilenceFallback = Duration(milliseconds: 700);
  static const double _waveSmoothing = 0.35;

  double _dragDistanceY = 0;
  double _baseY = 0;
  String _transcript = '';
  bool _isRecording = false;
  final SpeechToText _speechToText = SpeechToText();
  Timer? _timeoutTimer;
  Timer? _waveTimer;
  final List<double> _volumeLevels = List<double>.filled(
    _waveBarCount,
    _minWaveHeight,
    growable: true,
  );
  double _targetWaveHeight = _minWaveHeight;
  double _currentWaveHeight = _minWaveHeight;
  double _minSoundLevel = double.infinity;
  double _maxSoundLevel = double.negativeInfinity;
  double _smoothedSoundLevel = 0;
  int _soundLevelEventCount = 0;
  double _wavePhase = 0;
  DateTime _lastSoundLevelAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    await _initSpeech();
  }

  Future<void> _initSpeech() async {
    final initialized = await _speechToText.initialize();
    if (!initialized) {
      if (!mounted) return;
      setState(() {
        _transcript = '语音识别不可用，请检查系统权限';
      });
      return;
    }
    if (!mounted) return;
    await _startRecording();
  }

  Future<void> _startRecording() async {
    if (!mounted) return;
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _transcript = '';
    });
    _resetWaveState();

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        Navigator.of(context).pop(
          VoiceRecordingResult(
            action: VoiceRecordingAction.cancel,
            transcript: _transcript,
          ),
        );
      }
    });

    await _speechToText.listen(
      localeId: 'zh_CN',
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 10),
      listenOptions: SpeechListenOptions(partialResults: true),
      onSoundLevelChange: _onSoundLevelChange,
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _transcript = result.recognizedWords.trim();
        });
      },
    );

    if (!mounted || !_isRecording) return;
    _startWaveTicker();
  }

  void _resetWaveState() {
    _minSoundLevel = double.infinity;
    _maxSoundLevel = double.negativeInfinity;
    _smoothedSoundLevel = 0;
    _soundLevelEventCount = 0;
    _wavePhase = 0;
    _targetWaveHeight = _minWaveHeight;
    _currentWaveHeight = _minWaveHeight;
    _lastSoundLevelAt = DateTime.now();
    for (var i = 0; i < _volumeLevels.length; i++) {
      _volumeLevels[i] = _minWaveHeight;
    }
  }

  void _onSoundLevelChange(double level) {
    if (!_isRecording) return;

    _lastSoundLevelAt = DateTime.now();
    _soundLevelEventCount += 1;

    final safeLevel = level.isFinite ? level : 0.0;
    if (_soundLevelEventCount == 1) {
      _smoothedSoundLevel = safeLevel;
      _minSoundLevel = safeLevel;
      _maxSoundLevel = safeLevel + 1;
    } else {
      _smoothedSoundLevel = (_smoothedSoundLevel * 0.72) + (safeLevel * 0.28);
      _minSoundLevel = math
          .min(
            _smoothedSoundLevel,
            (_minSoundLevel * 0.98) + (_smoothedSoundLevel * 0.02),
          )
          .toDouble();
      _maxSoundLevel = math
          .max(
            _smoothedSoundLevel,
            (_maxSoundLevel * 0.98) + (_smoothedSoundLevel * 0.02),
          )
          .toDouble();
    }

    final range = _maxSoundLevel - _minSoundLevel;
    var normalized = range <= 0
        ? 0.0
        : ((_smoothedSoundLevel - _minSoundLevel) / range).clamp(0.0, 1.0);
    normalized = math.pow(normalized, 0.7).toDouble();
    final boosted = math.max(normalized, 0.12);

    _targetWaveHeight =
        _minWaveHeight + ((_maxWaveHeight - _minWaveHeight) * boosted);
  }

  void _startWaveTicker() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(_waveTick, (timer) {
      if (!_isRecording || !mounted) {
        timer.cancel();
        return;
      }

      _wavePhase += 0.35;
      final silenceDuration = DateTime.now().difference(_lastSoundLevelAt);
      final hasRecentSoundLevel = silenceDuration < _waveSilenceFallback;
      if (!hasRecentSoundLevel) {
        final idleNormalized = 0.12 + (0.06 * (math.sin(_wavePhase) + 1) / 2);
        _targetWaveHeight =
            _minWaveHeight +
            ((_maxWaveHeight - _minWaveHeight) * idleNormalized);
      }

      _currentWaveHeight +=
          (_targetWaveHeight - _currentWaveHeight) * _waveSmoothing;
      final modulation = hasRecentSoundLevel
          ? (1 + (0.16 * math.sin(_wavePhase * 1.8)))
          : 1.0;
      final barHeight = (_currentWaveHeight * modulation).clamp(
        _minWaveHeight,
        _maxWaveHeight,
      );

      setState(() {
        _volumeLevels.removeAt(0);
        _volumeLevels.add(barHeight);
      });
    });
  }

  Future<void> _stopRecording({bool updateState = true}) async {
    _waveTimer?.cancel();
    _waveTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    if (updateState && mounted) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_stopRecording(updateState: false));
    super.dispose();
  }

  bool get _isSwipedUp => _dragDistanceY < -_swipeUpThreshold;

  String _getStatusText() {
    if (_isSwipedUp) return '松开发送';
    return _voiceExamplePrompt;
  }

  void _finish(VoiceRecordingAction action) {
    unawaited(_stopRecording());
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(VoiceRecordingResult(action: action, transcript: _transcript));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motion = theme.motionTokens;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final statusColor = _isSwipedUp ? scheme.primary : scheme.onSurface;
    final mediaSize = MediaQuery.sizeOf(context);
    final orbSize = (mediaSize.width * 0.66).clamp(220.0, 340.0).toDouble();
    final leftBackground =
        Color.lerp(scheme.primaryContainer, scheme.surface, 0.42) ??
        scheme.primaryContainer;
    final rightBackground =
        Color.lerp(scheme.secondaryContainer, scheme.surface, 0.3) ??
        scheme.secondaryContainer;
    final orbTop =
        Color.lerp(scheme.primary, scheme.surface, 0.56) ?? scheme.primary;
    final orbBottom =
        Color.lerp(scheme.tertiary, scheme.surface, 0.62) ?? scheme.tertiary;
    final bubbleColor = scheme.surface.withValues(alpha: 0.42);
    final audioLevel =
        ((_currentWaveHeight - _minWaveHeight) /
                (_maxWaveHeight - _minWaveHeight))
            .clamp(0.0, 1.0)
            .toDouble();
    final breathA = ((math.sin(_wavePhase * 1.6) + 1) / 2).toDouble();
    final breathB = ((math.sin((_wavePhase * 1.6) + (math.pi / 2)) + 1) / 2)
        .toDouble();
    final ringInnerScale = 1.08 + (audioLevel * 0.18) + (breathA * 0.04);
    final ringOuterScale = 1.18 + (audioLevel * 0.28) + (breathB * 0.08);
    final ringInnerOpacity = (0.12 + (audioLevel * 0.15) + (breathA * 0.04))
        .clamp(0.08, 0.34)
        .toDouble();
    final ringOuterOpacity = (0.06 + (audioLevel * 0.12) + (breathB * 0.03))
        .clamp(0.05, 0.24)
        .toDouble();

    return GestureDetector(
      onVerticalDragStart: (details) {
        _baseY = details.globalPosition.dy;
      },
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragDistanceY = details.globalPosition.dy - _baseY;
        });
      },
      onVerticalDragEnd: (_) {
        final action = _isSwipedUp
            ? VoiceRecordingAction.proceed
            : VoiceRecordingAction.cancel;
        setState(() {
          _dragDistanceY = 0;
        });
        _finish(action);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [leftBackground, rightBackground],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: mediaSize.height * 0.2,
              left: 0,
              right: 0,
              child: Center(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: disableAnimations ? Duration.zero : motion.normal,
                    width: orbSize + 38,
                    height: orbSize + 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: 0.07),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    WalnieTokens.spacingLg,
                    WalnieTokens.spacingSm,
                    WalnieTokens.spacingLg,
                    0,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.more_horiz, color: scheme.onSurface),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WalnieTokens.spacingMd,
                          vertical: WalnieTokens.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(
                            WalnieTokens.radiusXl,
                          ),
                        ),
                        child: Text(
                          '语音记录模式',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.text_fields_rounded, color: scheme.onSurface),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: AnimatedContainer(
                duration: disableAnimations ? Duration.zero : motion.fast,
                curve: motion.enterCurve,
                transform: Matrix4.translationValues(
                  0,
                  _dragDistanceY.clamp(-120.0, 0.0),
                  0,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    WalnieTokens.spacingXl,
                    70,
                    WalnieTokens.spacingXl,
                    WalnieTokens.spacingXl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: WalnieTokens.spacingLg),
                      SizedBox(
                        width: orbSize * 1.72,
                        height: orbSize * 1.72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              key: const Key('voicePulseRingOuter'),
                              duration: disableAnimations
                                  ? Duration.zero
                                  : motion.fast,
                              width: orbSize * ringOuterScale,
                              height: orbSize * ringOuterScale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.primary.withValues(
                                    alpha: ringOuterOpacity,
                                  ),
                                  width: 1.2,
                                ),
                                gradient: RadialGradient(
                                  colors: [
                                    scheme.primary.withValues(
                                      alpha: ringOuterOpacity * 0.45,
                                    ),
                                    scheme.primary.withValues(alpha: 0),
                                  ],
                                  stops: const [0.62, 1],
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              key: const Key('voicePulseRingInner'),
                              duration: disableAnimations
                                  ? Duration.zero
                                  : motion.fast,
                              width: orbSize * ringInnerScale,
                              height: orbSize * ringInnerScale,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.primary.withValues(
                                    alpha: ringInnerOpacity,
                                  ),
                                  width: 1.6,
                                ),
                                gradient: RadialGradient(
                                  colors: [
                                    scheme.primary.withValues(
                                      alpha: ringInnerOpacity * 0.48,
                                    ),
                                    scheme.primary.withValues(alpha: 0),
                                  ],
                                  stops: const [0.64, 1],
                                ),
                              ),
                            ),
                            Container(
                              width: orbSize,
                              height: orbSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [orbTop, orbBottom],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.primary.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 38,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: WalnieTokens.spacingXl,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: List.generate(_waveBarCount, (
                                      index,
                                    ) {
                                      final volume = _volumeLevels[index];
                                      return AnimatedContainer(
                                        duration: disableAnimations
                                            ? Duration.zero
                                            : motion.fast,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1.6,
                                        ),
                                        width: 4.8,
                                        height: volume.clamp(8.0, 66.0),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.94,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            2.4,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: WalnieTokens.spacingLg),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text(
                          _getStatusText(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.72),
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: WalnieTokens.spacingMd),
                      SizedBox(
                        key: const Key('voiceTranscriptSlot'),
                        height: 96,
                        child: Center(
                          child: AnimatedOpacity(
                            duration: disableAnimations
                                ? Duration.zero
                                : motion.fast,
                            opacity: _transcript.isEmpty ? 0 : 1,
                            child: Semantics(
                              liveRegion: _transcript.isNotEmpty,
                              label: _transcript.isNotEmpty
                                  ? '实时转写内容 $_transcript'
                                  : '',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: WalnieTokens.spacingLg,
                                  vertical: WalnieTokens.spacingMd,
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                decoration: BoxDecoration(
                                  color: bubbleColor,
                                  borderRadius: BorderRadius.circular(
                                    WalnieTokens.radiusMd,
                                  ),
                                ),
                                child: Text(
                                  _transcript.isEmpty ? ' ' : _transcript,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurface,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: WalnieTokens.spacing2xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionBubble(
                            context: context,
                            icon: Icons.keyboard_alt_outlined,
                            label: '转文字',
                            color: bubbleColor,
                            foreground: scheme.onSurface,
                            onTap: () => _finish(VoiceRecordingAction.toText),
                            semanticsLabel: '切换文字输入',
                          ),
                          _buildActionBubble(
                            context: context,
                            icon: Icons.north_rounded,
                            label: '发送',
                            color: scheme.primary.withValues(
                              alpha: _transcript.trim().isEmpty ? 0.3 : 0.9,
                            ),
                            foreground: scheme.onPrimary,
                            onTap: _transcript.trim().isEmpty
                                ? null
                                : () => _finish(VoiceRecordingAction.proceed),
                            semanticsLabel: '发送语音结果',
                          ),
                          _buildActionBubble(
                            context: context,
                            icon: Icons.close_rounded,
                            label: '取消',
                            color: bubbleColor,
                            foreground: Colors.redAccent,
                            onTap: () => _finish(VoiceRecordingAction.cancel),
                            semanticsLabel: '取消语音录制',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBubble({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color foreground,
    String? semanticsLabel,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(38),
            child: Ink(
              width: 76,
              height: 76,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: Icon(icon, color: foreground, size: 34),
            ),
          ),
          const SizedBox(height: WalnieTokens.spacingSm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceRecordingResult {
  const VoiceRecordingResult({required this.action, required this.transcript});

  final VoiceRecordingAction action;
  final String transcript;
}

/// Show voice recording sheet and return user's action and transcript
Future<VoiceRecordingResult?> showVoiceRecordingSheet(BuildContext context) {
  return showModalBottomSheet<VoiceRecordingResult>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    builder: (context) => const VoiceRecordingSheet(),
  );
}
