/// Data models for bundled dua JSON assets.
class DuaCategory {
  const DuaCategory({
    required this.name,
    required this.url,
    required this.icon,
    required this.meta,
  });

  final String name;
  final String url;
  final String icon;
  final String meta;

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      meta: json['meta'] as String? ?? '',
    );
  }
}

class DuaSubCategory {
  const DuaSubCategory({
    required this.id,
    required this.title,
    required this.category,
    required this.duaIds,
  });

  final int id;
  final String title;
  final String category;
  final List<int> duaIds;

  factory DuaSubCategory.fromJson(Map<String, dynamic> json) {
    final rawIds = json['dua-ids'];
    return DuaSubCategory(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      duaIds: rawIds is List
          ? rawIds.map((e) => e as int).toList(growable: false)
          : const [],
    );
  }
}

class DuaModel {
  const DuaModel({
    required this.duaId,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.reference,
    required this.audio,
    required this.introduction,
  });

  final int duaId;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String reference;
  final String audio;
  final String introduction;

  bool get hasArabic => arabic.trim().isNotEmpty;
  bool get hasTransliteration => transliteration.trim().isNotEmpty;
  bool get hasTranslation => translation.trim().isNotEmpty;
  bool get hasIntroduction => introduction.trim().isNotEmpty;
  bool get hasAudio => audio.trim().isNotEmpty;

  factory DuaModel.fromJson(Map<String, dynamic> json) {
    return DuaModel(
      duaId: json['dua_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      arabic: json['arabic'] as String? ?? '',
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      audio: json['audio'] as String? ?? '',
      introduction: json['introduction'] as String? ?? '',
    );
  }

  String shareText() {
    final buffer = StringBuffer();
    if (title.isNotEmpty) {
      buffer.writeln(title);
      buffer.writeln();
    }
    if (arabic.isNotEmpty) {
      buffer.writeln(arabic);
      buffer.writeln();
    }
    if (transliteration.isNotEmpty) {
      buffer.writeln(transliteration);
      buffer.writeln();
    }
    if (translation.isNotEmpty) {
      buffer.writeln(translation);
      buffer.writeln();
    }
    if (reference.isNotEmpty) {
      buffer.writeln(reference);
    }
    return buffer.toString().trim();
  }
}
