import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

@immutable
class WalnieTimelineColors extends ThemeExtension<WalnieTimelineColors> {
  const WalnieTimelineColors({
    required this.feed,
    required this.poop,
    required this.pee,
    required this.diaper,
    required this.pump,
    required this.trackLine,
    required this.groupDot,
    required this.relativeChipBackground,
    required this.relativeChipForeground,
  });

  final Color feed;
  final Color poop;
  final Color pee;
  final Color diaper;
  final Color pump;
  final Color trackLine;
  final Color groupDot;
  final Color relativeChipBackground;
  final Color relativeChipForeground;

  @override
  WalnieTimelineColors copyWith({
    Color? feed,
    Color? poop,
    Color? pee,
    Color? diaper,
    Color? pump,
    Color? trackLine,
    Color? groupDot,
    Color? relativeChipBackground,
    Color? relativeChipForeground,
  }) {
    return WalnieTimelineColors(
      feed: feed ?? this.feed,
      poop: poop ?? this.poop,
      pee: pee ?? this.pee,
      diaper: diaper ?? this.diaper,
      pump: pump ?? this.pump,
      trackLine: trackLine ?? this.trackLine,
      groupDot: groupDot ?? this.groupDot,
      relativeChipBackground:
          relativeChipBackground ?? this.relativeChipBackground,
      relativeChipForeground:
          relativeChipForeground ?? this.relativeChipForeground,
    );
  }

  @override
  WalnieTimelineColors lerp(
    covariant ThemeExtension<WalnieTimelineColors>? other,
    double t,
  ) {
    if (other is! WalnieTimelineColors) {
      return this;
    }
    return WalnieTimelineColors(
      feed: Color.lerp(feed, other.feed, t) ?? feed,
      poop: Color.lerp(poop, other.poop, t) ?? poop,
      pee: Color.lerp(pee, other.pee, t) ?? pee,
      diaper: Color.lerp(diaper, other.diaper, t) ?? diaper,
      pump: Color.lerp(pump, other.pump, t) ?? pump,
      trackLine: Color.lerp(trackLine, other.trackLine, t) ?? trackLine,
      groupDot: Color.lerp(groupDot, other.groupDot, t) ?? groupDot,
      relativeChipBackground:
          Color.lerp(relativeChipBackground, other.relativeChipBackground, t) ??
          relativeChipBackground,
      relativeChipForeground:
          Color.lerp(relativeChipForeground, other.relativeChipForeground, t) ??
          relativeChipForeground,
    );
  }
}

@immutable
class WalnieVoiceOverlayColors
    extends ThemeExtension<WalnieVoiceOverlayColors> {
  const WalnieVoiceOverlayColors({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.accentSoft,
    required this.transcriptSurface,
    required this.cancelSurface,
  });

  final Color background;
  final Color foreground;
  final Color accent;
  final Color accentSoft;
  final Color transcriptSurface;
  final Color cancelSurface;

  @override
  WalnieVoiceOverlayColors copyWith({
    Color? background,
    Color? foreground,
    Color? accent,
    Color? accentSoft,
    Color? transcriptSurface,
    Color? cancelSurface,
  }) {
    return WalnieVoiceOverlayColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      transcriptSurface: transcriptSurface ?? this.transcriptSurface,
      cancelSurface: cancelSurface ?? this.cancelSurface,
    );
  }

  @override
  WalnieVoiceOverlayColors lerp(
    covariant ThemeExtension<WalnieVoiceOverlayColors>? other,
    double t,
  ) {
    if (other is! WalnieVoiceOverlayColors) {
      return this;
    }
    return WalnieVoiceOverlayColors(
      background: Color.lerp(background, other.background, t) ?? background,
      foreground: Color.lerp(foreground, other.foreground, t) ?? foreground,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t) ?? accentSoft,
      transcriptSurface:
          Color.lerp(transcriptSurface, other.transcriptSurface, t) ??
          transcriptSurface,
      cancelSurface:
          Color.lerp(cancelSurface, other.cancelSurface, t) ?? cancelSurface,
    );
  }
}

@immutable
class WalnieMotionTokens extends ThemeExtension<WalnieMotionTokens> {
  const WalnieMotionTokens({
    required this.fast,
    required this.normal,
    required this.emphasized,
    required this.enterCurve,
    required this.emphasizedCurve,
  });

  final Duration fast;
  final Duration normal;
  final Duration emphasized;
  final Curve enterCurve;
  final Curve emphasizedCurve;

  @override
  WalnieMotionTokens copyWith({
    Duration? fast,
    Duration? normal,
    Duration? emphasized,
    Curve? enterCurve,
    Curve? emphasizedCurve,
  }) {
    return WalnieMotionTokens(
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      emphasized: emphasized ?? this.emphasized,
      enterCurve: enterCurve ?? this.enterCurve,
      emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
    );
  }

  @override
  WalnieMotionTokens lerp(
    covariant ThemeExtension<WalnieMotionTokens>? other,
    double t,
  ) {
    if (other is! WalnieMotionTokens) {
      return this;
    }
    return WalnieMotionTokens(
      fast: Duration(
        milliseconds: lerpDouble(
          fast.inMilliseconds.toDouble(),
          other.fast.inMilliseconds.toDouble(),
          t,
        )!.round(),
      ),
      normal: Duration(
        milliseconds: lerpDouble(
          normal.inMilliseconds.toDouble(),
          other.normal.inMilliseconds.toDouble(),
          t,
        )!.round(),
      ),
      emphasized: Duration(
        milliseconds: lerpDouble(
          emphasized.inMilliseconds.toDouble(),
          other.emphasized.inMilliseconds.toDouble(),
          t,
        )!.round(),
      ),
      enterCurve: t < 0.5 ? enterCurve : other.enterCurve,
      emphasizedCurve: t < 0.5 ? emphasizedCurve : other.emphasizedCurve,
    );
  }
}

extension WalnieThemeX on ThemeData {
  WalnieTimelineColors get timelineColors => extension<WalnieTimelineColors>()!;

  WalnieVoiceOverlayColors get voiceOverlayColors =>
      extension<WalnieVoiceOverlayColors>()!;

  WalnieMotionTokens get motionTokens => extension<WalnieMotionTokens>()!;
}
