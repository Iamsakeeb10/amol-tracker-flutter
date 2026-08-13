class TopicModel {
  final String id;
  final String nameEn;
  final String nameBn;
  final String? descriptionEn;
  final String? descriptionBn;
  final String iconName;
  final bool isActive;
  final int questionCount;

  TopicModel({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    this.descriptionEn,
    this.descriptionBn,
    required this.iconName,
    required this.isActive,
    required this.questionCount,
  });

  String displayName(String languageCode) {
    if (languageCode == 'bn' && nameBn.isNotEmpty) return nameBn;
    return nameEn;
  }

  String? displayDescription(String languageCode) {
    if (languageCode == 'bn' && descriptionBn != null && descriptionBn!.isNotEmpty) return descriptionBn;
    return descriptionEn;
  }

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameBn: json['nameBn'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String?,
      descriptionBn: json['descriptionBn'] as String?,
      iconName: json['iconName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      questionCount: json['questionCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameBn': nameBn,
      'descriptionEn': descriptionEn,
      'descriptionBn': descriptionBn,
      'iconName': iconName,
      'isActive': isActive,
      'questionCount': questionCount,
    };
  }
}
