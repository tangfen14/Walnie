import 'package:baby_tracker/domain/entities/voice_normalization_config.dart';

abstract class VoiceNormalizationConfigRepository {
  Future<VoiceNormalizationConfig> getActiveConfig();

  Future<void> refreshIfStale();
}
