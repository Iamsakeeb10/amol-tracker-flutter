import 'package:cloud_firestore/cloud_firestore.dart';

class HomeBannersConfigModel {
  final bool showReminderCard;
  final bool showBattleBanner;
  final String? reminderTitle;
  final String? reminderBody;
  final String? battleBannerTitle;

  const HomeBannersConfigModel({
    this.showReminderCard = true,
    this.showBattleBanner = false,
    this.reminderTitle,
    this.reminderBody,
    this.battleBannerTitle,
  });

  factory HomeBannersConfigModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists) {
      return const HomeBannersConfigModel();
    }
    final data = doc.data() ?? <String, dynamic>{};
    return HomeBannersConfigModel(
      showReminderCard: (data['showReminderCard'] as bool?) ?? true,
      showBattleBanner: (data['showBattleBanner'] as bool?) ?? false,
      reminderTitle: data['reminderTitle'] as String?,
      reminderBody: data['reminderBody'] as String?,
      battleBannerTitle: data['battleBannerTitle'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'showReminderCard': showReminderCard,
        'showBattleBanner': showBattleBanner,
        'reminderTitle': reminderTitle,
        'reminderBody': reminderBody,
        'battleBannerTitle': battleBannerTitle,
      };
}
