import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'presentation layer should not use hardcoded hex colors outside theme folder',
    () {
      final presentationDir = Directory('lib/presentation');
      final disallowedHexColor = RegExp(r'Color\s*\(\s*0x[0-9A-Fa-f]{8}\s*\)');
      final allowlistPrefixes = <String>[
        'lib/presentation/theme/',
        '/lib/presentation/theme/',
      ];

      final violations = <String>[];

      for (final entity in presentationDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final normalizedPath = entity.path.replaceAll('\\', '/');
        if (allowlistPrefixes.any(normalizedPath.startsWith)) {
          continue;
        }

        final content = entity.readAsStringSync();
        final matches = disallowedHexColor.allMatches(content);
        for (final match in matches) {
          final line =
              '\n'.allMatches(content.substring(0, match.start)).length + 1;
          violations.add('$normalizedPath:$line => ${match.group(0)}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Found hardcoded hex colors outside theme:\n'
            '${violations.join('\n')}',
      );
    },
  );
}
