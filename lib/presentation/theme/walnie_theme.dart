import 'package:baby_tracker/presentation/theme/walnie_theme_extensions.dart';
import 'package:baby_tracker/presentation/theme/walnie_tokens.dart';
import 'package:flutter/material.dart';

ThemeData buildWalnieLightTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: WalnieTokens.lightPrimary,
        brightness: Brightness.light,
      ).copyWith(
        primary: WalnieTokens.lightPrimary,
        onPrimary: WalnieTokens.lightTextPrimary,
        primaryContainer: WalnieTokens.lightSecondary.withValues(alpha: 0.45),
        onPrimaryContainer: WalnieTokens.lightTextPrimary,
        secondary: WalnieTokens.lightSecondary,
        onSecondary: WalnieTokens.lightTextPrimary,
        tertiary: WalnieTokens.lightSuccess,
        onTertiary: WalnieTokens.lightSurface,
        surface: WalnieTokens.lightSurface,
        onSurface: WalnieTokens.lightTextPrimary,
        error: WalnieTokens.error,
        onError: WalnieTokens.onError,
        errorContainer: WalnieTokens.errorContainer,
        onErrorContainer: WalnieTokens.onErrorContainer,
        outline: WalnieTokens.lightBorder,
        outlineVariant: WalnieTokens.lightBorder.withValues(alpha: 0.7),
      );

  return _buildTheme(
    scheme: scheme,
    scaffoldBackground: WalnieTokens.lightBackground,
    textPrimary: WalnieTokens.lightTextPrimary,
    textSecondary: WalnieTokens.lightTextSecondary,
    timelineColors: WalnieTimelineColors(
      feed: const Color(0xFFCC9A06),
      poop: const Color(0xFFD97706),
      pee: const Color(0xFF0E7490),
      diaper: const Color(0xFFFACC15),
      pump: const Color(0xFFB48A00),
      trackLine: WalnieTokens.lightBorder,
      groupDot: WalnieTokens.lightPrimary,
      relativeChipBackground: WalnieTokens.lightSecondary.withValues(
        alpha: 0.28,
      ),
      relativeChipForeground: WalnieTokens.lightTextPrimary,
    ),
    voiceOverlayColors: const WalnieVoiceOverlayColors(
      background: Color(0xE6151116),
      foreground: Color(0xFFFFFFFF),
      accent: Color(0xFFF6C947),
      accentSoft: Color(0x66F6C947),
      transcriptSurface: Color(0x26FFFFFF),
      cancelSurface: Color(0x30FFFFFF),
    ),
  );
}

ThemeData buildWalnieDarkTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: WalnieTokens.darkPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: WalnieTokens.darkPrimary,
        onPrimary: WalnieTokens.darkBackground,
        primaryContainer: WalnieTokens.darkSecondary.withValues(alpha: 0.35),
        onPrimaryContainer: WalnieTokens.darkTextPrimary,
        secondary: WalnieTokens.darkSecondary,
        onSecondary: WalnieTokens.darkTextPrimary,
        tertiary: WalnieTokens.darkSuccess,
        onTertiary: WalnieTokens.darkBackground,
        surface: WalnieTokens.darkSurface,
        onSurface: WalnieTokens.darkTextPrimary,
        error: const Color(0xFFFF9B8A),
        onError: const Color(0xFF4A100C),
        errorContainer: const Color(0xFF6E1A14),
        onErrorContainer: const Color(0xFFFFDAD5),
        outline: WalnieTokens.darkBorder,
        outlineVariant: WalnieTokens.darkBorder.withValues(alpha: 0.7),
      );

  return _buildTheme(
    scheme: scheme,
    scaffoldBackground: WalnieTokens.darkBackground,
    textPrimary: WalnieTokens.darkTextPrimary,
    textSecondary: WalnieTokens.darkTextSecondary,
    timelineColors: WalnieTimelineColors(
      feed: const Color(0xFFF6C547),
      poop: const Color(0xFFF59E0B),
      pee: const Color(0xFF22D3EE),
      diaper: const Color(0xFFFACC15),
      pump: const Color(0xFFE9B949),
      trackLine: WalnieTokens.darkBorder,
      groupDot: WalnieTokens.darkPrimary,
      relativeChipBackground: WalnieTokens.darkSecondary.withValues(alpha: 0.2),
      relativeChipForeground: WalnieTokens.darkTextPrimary,
    ),
    voiceOverlayColors: const WalnieVoiceOverlayColors(
      background: Color(0xE0171218),
      foreground: Color(0xFFFDF3CF),
      accent: Color(0xFFF6C947),
      accentSoft: Color(0x66F6C947),
      transcriptSurface: Color(0x26FFFFFF),
      cancelSurface: Color(0x2EFFFFFF),
    ),
  );
}

ThemeData _buildTheme({
  required ColorScheme scheme,
  required Color scaffoldBackground,
  required Color textPrimary,
  required Color textSecondary,
  required WalnieTimelineColors timelineColors,
  required WalnieVoiceOverlayColors voiceOverlayColors,
}) {
  final motionTokens = const WalnieMotionTokens(
    fast: Duration(milliseconds: 140),
    normal: Duration(milliseconds: 220),
    emphasized: Duration(milliseconds: 320),
    enterCurve: Curves.easeOutCubic,
    emphasizedCurve: Curves.easeInOutCubic,
  );

  final baseTextTheme = ThemeData(
    brightness: scheme.brightness,
    useMaterial3: true,
  ).textTheme;

  final bodyTextTheme = baseTextTheme.apply(
    fontFamily: 'NotoSansSC',
    bodyColor: textPrimary,
    displayColor: textPrimary,
  );

  final textTheme = bodyTextTheme.copyWith(
    headlineLarge: bodyTextTheme.headlineLarge?.copyWith(
      fontFamily: 'NotoSerifSC',
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    headlineMedium: bodyTextTheme.headlineMedium?.copyWith(
      fontFamily: 'NotoSerifSC',
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    headlineSmall: bodyTextTheme.headlineSmall?.copyWith(
      fontFamily: 'NotoSerifSC',
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    titleLarge: bodyTextTheme.titleLarge?.copyWith(
      fontFamily: 'NotoSerifSC',
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    titleMedium: bodyTextTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    titleSmall: bodyTextTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
    bodyLarge: bodyTextTheme.bodyLarge?.copyWith(
      color: textPrimary,
      height: 1.45,
    ),
    bodyMedium: bodyTextTheme.bodyMedium?.copyWith(
      color: textSecondary,
      height: 1.45,
    ),
    bodySmall: bodyTextTheme.bodySmall?.copyWith(
      color: textSecondary,
      height: 1.35,
    ),
    labelLarge: bodyTextTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: textPrimary,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBackground,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusLg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: scaffoldBackground,
      foregroundColor: textPrimary,
      titleTextStyle: textTheme.titleLarge,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: WalnieTokens.spacingLg,
          vertical: WalnieTokens.spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
        ),
        textStyle: textTheme.titleSmall,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
      ),
      side: BorderSide(color: scheme.outlineVariant),
      selectedColor: scheme.primaryContainer,
      labelStyle: textTheme.bodyMedium,
      secondaryLabelStyle: textTheme.bodyMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: WalnieTokens.spacingSm,
        vertical: WalnieTokens.spacingXs,
      ),
      backgroundColor: scheme.surface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
        borderSide: BorderSide(color: scheme.error, width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: WalnieTokens.spacingMd,
        vertical: WalnieTokens.spacingMd,
      ),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: textSecondary.withValues(alpha: 0.9),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusLg),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyLarge,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      modalBackgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(WalnieTokens.radiusXl),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WalnieTokens.radiusMd),
      ),
    ),
    extensions: [timelineColors, voiceOverlayColors, motionTokens],
  );
}
