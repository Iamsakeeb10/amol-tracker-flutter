class TopicModel {
  final String id;
  final String name;
  final String? description;
  final String iconName;
  final bool isActive;
  final int questionCount;

  TopicModel({
    required this.id,
    required this.name,
    this.description,
    required this.iconName,
    required this.isActive,
    required this.questionCount,
  });

  String displayName(String languageCode) {
    return name;
  }

  String? displayDescription(String languageCode) {
    return description;
  }

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    print('TopicModel.fromJson received: $json');
    return TopicModel(
      id: json['id'] as String? ?? '',
      name: (json['name'] ?? json['nameBn'] ?? json['nameEn'] ?? '') as String,
      description: (json['description'] ?? json['descriptionBn'] ?? json['descriptionEn']) as String?,
      iconName: json['iconName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      questionCount: json['questionCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'isActive': isActive,
      'questionCount': questionCount,
    };
  }
}
