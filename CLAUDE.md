# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Generate Drift database code (required after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Linting and testing
flutter analyze
flutter test

# Run a single test
flutter test test/path/to/test_file.dart
```

## Architecture

This is a Flutter iOS app for baby tracking (新生儿吃喝拉撒记录) following Clean Architecture with clear layer separation:

### Layer Structure

- **`lib/domain/`**: Core business logic - entities, repository interfaces, service interfaces
- **`lib/application/`**: Use cases that orchestrate domain operations
- **`lib/infrastructure/`**: Concrete implementations - database (Drift/SQLite), notifications, voice services
- **`lib/presentation/`**: UI layer - pages, controllers (state), widgets, utilities
- **`lib/app/`**: App initialization and Riverpod providers

### Key Architectural Patterns

1. **Clean Architecture**: Dependencies flow inward → infrastructure depends on domain interfaces, presentation depends on use cases

2. **Riverpod for DI**: All dependencies are wired through `lib/app/providers.dart`. Infrastructure services are overridden at `main.dart` initialization

3. **Domain-Driven Design**:
   - Entities define core business rules (e.g., `BabyEvent.validateForSave()`)
   - Repository interfaces (`EventRepository`) abstract persistence
   - Service interfaces (`ReminderService`, `VoiceCommandService`) define cross-cutting concerns

### Voice Command Flow

Voice processing follows a two-stage pipeline:
1. **Rule-based parsing** (`RuleBasedIntentParser`) - handles common Chinese patterns with high confidence
2. **LLM fallback** (`LlmFallbackParser`) - optional fallback for unrecognized inputs

Both parsers return `VoiceIntent` with `intentType`, `confidence`, and `payload`. The UI shows confirmation dialogs when `needsConfirmation` is true.

### Database Schema

Drift ORM generates `app_database.g.dart` from `EventRecords` table. Run `dart run build_runner build` after schema changes.

Event types: `feed`, `poop`, `pee`. Feed method options include breast sides, bottle types, and mixed feeding.

### Reminder System

Reminders are scheduled using `flutter_local_notifications`. The `ReminderService` calculates next reminder time as `latestFeedTime + intervalHours` (default 3 hours, configurable 1-6 hours). Configuration stored in `SharedPreferences`.

### LLM Configuration

LLM fallback parser has hardcoded defaults in `lib/infrastructure/voice/llm_fallback_parser.dart`. These can be overridden via `--dart-define`:
- `LLM_PARSER_ENDPOINT`
- `LLM_PARSER_API_KEY`
- `LLM_MAX_INPUT_WORDS` (default 40)
- `LLM_MAX_TRANSCRIPT_CHARS` (default 180)
- `LLM_HTTP_TIMEOUT_MS` (default 3500)

## iOS Permissions

Required permissions are configured in `ios/Runner/Info.plist`:
- `NSMicrophoneUsageDescription` - for voice recording
- `NSSpeechRecognitionUsageDescription` - for speech-to-text

## Future Cloud API

`docs/openapi.yaml` contains a draft specification for future cloud sync endpoints. The current implementation is local-first with no network persistence.
