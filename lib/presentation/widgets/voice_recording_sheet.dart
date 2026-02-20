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
    await _startRecording();
  }

  Future<void> _startRecording() async {
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
    return '上滑发送，或使用下方按钮';
  }

  void _finish(VoiceRecordingAction action) {
    Navigator.of(
      context,
    ).pop(VoiceRecordingResult(action: action, transcript: _transcript));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceColors = theme.voiceOverlayColors;
    final motion = theme.motionTokens;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final statusColor = _isSwipedUp
        ? voiceColors.accent
        : voiceColors.foreground;

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
      child: ColoredBox(
        color: voiceColors.background,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: AnimatedOpacity(
                  duration: disableAnimations ? Duration.zero : motion.fast,
                  opacity: _isSwipedUp ? 1.0 : 0.35,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: WalnieTokens.spacingXl,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: statusColor,
                          size: 28,
                        ),
                        const SizedBox(height: WalnieTokens.spacingXs),
                        Text(
                          _isSwipedUp ? '松开发送' : '上滑确认',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: WalnieTokens.spacingXl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 86,
                        decoration: BoxDecoration(
                          color: voiceColors.accentSoft,
                          borderRadius: BorderRadius.circular(
                            WalnieTokens.radiusLg,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WalnieTokens.spacingSm,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(_waveBarCount, (index) {
                              final volume = _volumeLevels[index];
                              return AnimatedContainer(
                                duration: disableAnimations
                                    ? Duration.zero
                                    : motion.fast,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                width: 5,
                                height: volume.clamp(4.0, 60.0),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: WalnieTokens.spacingLg),
                      Text(
                        _getStatusText(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: voiceColors.foreground,
                        ),
                      ),
                      const SizedBox(height: WalnieTokens.spacingMd),
                      if (_transcript.isNotEmpty)
                        Semantics(
                          liveRegion: true,
                          label: '实时转写内容 $_transcript',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: WalnieTokens.spacingLg,
                              vertical: WalnieTokens.spacingMd,
                            ),
                            constraints: const BoxConstraints(maxWidth: 320),
                            decoration: BoxDecoration(
                              color: voiceColors.transcriptSurface,
                              borderRadius: BorderRadius.circular(
                                WalnieTokens.radiusMd,
                              ),
                            ),
                            child: Text(
                              _transcript,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: voiceColors.foreground,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const SizedBox(height: WalnieTokens.spacingLg),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: '取消语音录制',
                              child: OutlinedButton(
                                onPressed: () =>
                                    _finish(VoiceRecordingAction.cancel),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: voiceColors.foreground,
                                  side: BorderSide(
                                    color: voiceColors.foreground.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: WalnieTokens.spacingMd,
                                  ),
                                ),
                                child: const Text('取消'),
                              ),
                            ),
                          ),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: '切换文字输入',
                              child: OutlinedButton(
                                onPressed: () =>
                                    _finish(VoiceRecordingAction.toText),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: voiceColors.foreground,
                                  side: BorderSide(
                                    color: voiceColors.foreground.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: WalnieTokens.spacingMd,
                                  ),
                                ),
                                child: const Text('转文字'),
                              ),
                            ),
                          ),
                          const SizedBox(width: WalnieTokens.spacingSm),
                          Expanded(
                            child: Semantics(
                              button: true,
                              label: '发送语音结果',
                              child: FilledButton(
                                onPressed: _transcript.trim().isEmpty
                                    ? null
                                    : () =>
                                          _finish(VoiceRecordingAction.proceed),
                                style: FilledButton.styleFrom(
                                  backgroundColor: voiceColors.accent,
                                  foregroundColor: voiceColors.background,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: WalnieTokens.spacingMd,
                                  ),
                                ),
                                child: const Text('发送'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(WalnieTokens.spacingXl),
                  child: Semantics(
                    button: true,
                    label: '取消录音并返回',
                    child: GestureDetector(
                      onTap: () => _finish(VoiceRecordingAction.cancel),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: WalnieTokens.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          color: voiceColors.cancelSurface,
                          borderRadius: BorderRadius.circular(
                            WalnieTokens.radiusMd,
                          ),
                        ),
                        child: Text(
                          '取消并返回',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: voiceColors.foreground,
                          ),
                        ),
                      ),
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
