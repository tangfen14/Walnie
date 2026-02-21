enum VoiceNormalizationScope { ruleOnly, llmOnly, both }

class VoiceNormalizationRule {
  const VoiceNormalizationRule({
    required this.id,
    required this.from,
    required this.to,
    required this.scope,
    required this.priority,
    required this.contextKeywords,
    required this.blockPhrases,
    required this.windowChars,
  });

  final String id;
  final String from;
  final String to;
  final VoiceNormalizationScope scope;
  final int priority;
  final List<String> contextKeywords;
  final List<String> blockPhrases;
  final int windowChars;

  bool get appliesToRuleParsing =>
      scope == VoiceNormalizationScope.ruleOnly ||
      scope == VoiceNormalizationScope.both;

  factory VoiceNormalizationRule.fromJson(Map<String, dynamic> json) {
    return VoiceNormalizationRule(
      id: (json['id'] ?? '').toString(),
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      scope: _scopeFromString(json['scope']?.toString()),
      priority: _parseInt(json['priority'], fallback: 0),
      contextKeywords: _parseStringList(
        json['contextKeywords'] ?? json['context_keywords'],
      ),
      blockPhrases: _parseStringList(
        json['blockPhrases'] ?? json['block_phrases'],
      ),
      windowChars: _parseInt(
        json['windowChars'] ?? json['window_chars'],
        fallback: 3,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'from': from,
      'to': to,
      'scope': _scopeToString(scope),
      'priority': priority,
      'contextKeywords': contextKeywords,
      'blockPhrases': blockPhrases,
      'windowChars': windowChars,
    };
  }

  static int _parseInt(Object? value, {required int fallback}) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static List<String> _parseStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static VoiceNormalizationScope _scopeFromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'llm':
      case 'llm_only':
      case 'llmonly':
        return VoiceNormalizationScope.llmOnly;
      case 'both':
        return VoiceNormalizationScope.both;
      case 'rule':
      case 'rule_only':
      case 'ruleonly':
      default:
        return VoiceNormalizationScope.ruleOnly;
    }
  }

  static String _scopeToString(VoiceNormalizationScope scope) {
    switch (scope) {
      case VoiceNormalizationScope.ruleOnly:
        return 'rule_only';
      case VoiceNormalizationScope.llmOnly:
        return 'llm_only';
      case VoiceNormalizationScope.both:
        return 'both';
    }
  }
}

class VoiceNormalizationConfig {
  const VoiceNormalizationConfig({
    required this.version,
    required this.ttlSeconds,
    required this.updatedAt,
    required this.rules,
    this.etag,
    this.fetchedAt,
  });

  final String version;
  final int ttlSeconds;
  final DateTime updatedAt;
  final List<VoiceNormalizationRule> rules;
  final String? etag;
  final DateTime? fetchedAt;

  Iterable<VoiceNormalizationRule> get rulesForRuleParsing sync* {
    for (final rule in rules) {
      if (rule.appliesToRuleParsing) {
        yield rule;
      }
    }
  }

  bool isStaleAt(DateTime now) {
    final baseline = fetchedAt ?? updatedAt;
    final effectiveTtl = ttlSeconds <= 0 ? 3600 : ttlSeconds;
    return now.difference(baseline).inSeconds >= effectiveTtl;
  }

  VoiceNormalizationConfig copyWith({
    String? version,
    int? ttlSeconds,
    DateTime? updatedAt,
    List<VoiceNormalizationRule>? rules,
    String? etag,
    DateTime? fetchedAt,
  }) {
    return VoiceNormalizationConfig(
      version: version ?? this.version,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
      rules: rules ?? this.rules,
      etag: etag ?? this.etag,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  factory VoiceNormalizationConfig.fromJson(
    Map<String, dynamic> json, {
    String? etag,
    DateTime? fetchedAt,
  }) {
    final updatedAtRaw = json['updatedAt'] ?? json['updated_at'];
    final parsedUpdatedAt = _parseDateTime(updatedAtRaw);
    final parsedFetchedAt = _parseDateTime(json['fetchedAt']);

    return VoiceNormalizationConfig(
      version: (json['version'] ?? 'unknown').toString(),
      ttlSeconds: VoiceNormalizationRule._parseInt(
        json['ttlSeconds'] ?? json['ttl_seconds'],
        fallback: 3600,
      ),
      updatedAt: parsedUpdatedAt ?? DateTime.now(),
      rules: _parseRules(json['rules']),
      etag: etag ?? json['etag']?.toString(),
      fetchedAt: fetchedAt ?? parsedFetchedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'ttlSeconds': ttlSeconds,
      'updatedAt': updatedAt.toIso8601String(),
      'rules': rules.map((item) => item.toJson()).toList(growable: false),
      'etag': etag,
      'fetchedAt': fetchedAt?.toIso8601String(),
    };
  }

  static VoiceNormalizationConfig fallback({DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    return VoiceNormalizationConfig(
      version: 'builtin-v1',
      ttlSeconds: 3600,
      updatedAt: timestamp,
      fetchedAt: timestamp,
      rules: const <VoiceNormalizationRule>[
        VoiceNormalizationRule(
          id: 'builtin-qingwei-qinwei',
          from: '轻微',
          to: '亲喂',
          scope: VoiceNormalizationScope.ruleOnly,
          priority: 200,
          contextKeywords: <String>['奶', '喂', 'ml', '毫升', '母乳', '瓶喂', '亲喂'],
          blockPhrases: <String>[],
          windowChars: 4,
        ),
        VoiceNormalizationRule(
          id: 'builtin-wei-wei',
          from: '为',
          to: '喂',
          scope: VoiceNormalizationScope.ruleOnly,
          priority: 120,
          contextKeywords: <String>[
            '奶',
            '喂',
            'ml',
            '毫升',
            '母乳',
            '配方奶',
            '奶瓶',
            '炫',
          ],
          blockPhrases: <String>['因为', '认为', '为何', '作为', '为了'],
          windowChars: 3,
        ),
      ],
    );
  }

  static List<VoiceNormalizationRule> _parseRules(Object? value) {
    if (value is! List) {
      return const <VoiceNormalizationRule>[];
    }
    return value
        .whereType<Map<String, dynamic>>()
        .map(VoiceNormalizationRule.fromJson)
        .toList(growable: false);
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw.toString());
  }
}
