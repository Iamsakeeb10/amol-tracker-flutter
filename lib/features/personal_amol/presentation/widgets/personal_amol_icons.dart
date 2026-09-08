import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';

/// Persisted-token prefix for Material icons (e.g. `m:auto_awesome`). Emoji
/// and empty icons do not carry this prefix.
const String kPersonalAmolMaterialIconPrefix = 'm:';

/// Curated Material icons offered for personal amol, keyed by a stable name
/// that is persisted in Firestore (see [encodePersonalAmolIcon]). The full
/// screen picker ("see all") shows every icon; the compact row shows a preset
/// slice.
///
/// Intentionally Islamic/halal-friendly: [Icons.mosque] is kept; other-religion
/// buildings (church, temples, synagogue), face/reaction glyphs, and temple-like
/// façades (e.g. account_balance) are excluded so neither the row nor the full
/// picker can show them. Flutter's built-in Material icons are used so no extra
/// package is required, and every value is a const [IconData] so icon
/// tree-shaking keeps the glyphs.
const Map<String, IconData> kPersonalAmolIcons = <String, IconData>{
  // Spiritual / habits
  'auto_awesome': Icons.auto_awesome,
  'star': Icons.star,
  'star_border': Icons.star_border,
  'star_rounded': Icons.star_rounded,
  'favorite': Icons.favorite,
  'favorite_border': Icons.favorite_border,
  'mosque': Icons.mosque,
  'volunteer_activism': Icons.volunteer_activism,
  'handshake': Icons.handshake,
  'menu_book': Icons.menu_book,
  'auto_stories': Icons.auto_stories,
  'import_contacts': Icons.import_contacts,
  'book': Icons.book,
  'school': Icons.school,
  'emoji_objects': Icons.emoji_objects,
  'self_improvement': Icons.self_improvement,
  'wb_sunny': Icons.wb_sunny,
  'nightlight': Icons.nightlight,
  'bedtime': Icons.bedtime,
  'dark_mode': Icons.dark_mode,
  'light_mode': Icons.light_mode,
  // Completion / tracking
  'check_circle': Icons.check_circle,
  'check_circle_outline': Icons.check_circle_outline,
  'task_alt': Icons.task_alt,
  'verified': Icons.verified,
  'done': Icons.done,
  'done_all': Icons.done_all,
  'rule': Icons.rule,
  'event_available': Icons.event_available,
  'event': Icons.event,
  'calendar_month': Icons.calendar_month,
  'today': Icons.today,
  'alarm': Icons.alarm,
  'alarm_on': Icons.alarm_on,
  'schedule': Icons.schedule,
  'timer': Icons.timer,
  'hourglass_empty': Icons.hourglass_empty,
  'hourglass_bottom': Icons.hourglass_bottom,
  'refresh': Icons.refresh,
  'replay': Icons.replay,
  'restart_alt': Icons.restart_alt,
  'loop': Icons.loop,
  'autorenew': Icons.autorenew,
  'published_with_changes': Icons.published_with_changes,
  'update': Icons.update,
  'cloud_done': Icons.cloud_done,
  // Health / body
  'directions_run': Icons.directions_run,
  'fitness_center': Icons.fitness_center,
  'water_drop': Icons.water_drop,
  'local_drink': Icons.local_drink,
  'restaurant': Icons.restaurant,
  'ramen_dining': Icons.ramen_dining,
  'lunch_dining': Icons.lunch_dining,
  'dinner_dining': Icons.dinner_dining,
  'flatware': Icons.flatware,
  'egg': Icons.egg,
  'egg_alt': Icons.egg_alt,
  'icecream': Icons.icecream,
  'local_cafe': Icons.local_cafe,
  'coffee': Icons.coffee,
  'sports_gymnastics': Icons.sports_gymnastics,
  'directions_walk': Icons.directions_walk,
  'directions_bike': Icons.directions_bike,
  'pool': Icons.pool,
  'hiking': Icons.hiking,
  'bed': Icons.bed,
  'sick': Icons.sick,
  'health_and_safety': Icons.health_and_safety,
  'bloodtype': Icons.bloodtype,
  'monitor_heart': Icons.monitor_heart,
  // Study / productivity
  'edit_note': Icons.edit_note,
  'note_add': Icons.note_add,
  'assignment': Icons.assignment,
  'checklist': Icons.checklist,
  'checklist_rtl': Icons.checklist_rtl,
  'fact_check': Icons.fact_check,
  'history_edu': Icons.history_edu,
  'psychology': Icons.psychology,
  'lightbulb': Icons.lightbulb,
  'tips_and_updates': Icons.tips_and_updates,
  'border_color': Icons.border_color,
  'draw': Icons.draw,
  'brush': Icons.brush,
  'palette': Icons.palette,
  'music_note': Icons.music_note,
  'mic': Icons.mic,
  'headphones': Icons.headphones,
  'podcasts': Icons.podcasts,
  'radio': Icons.radio,
  'equalizer': Icons.equalizer,
  // Heart / charity / social
  'redeem': Icons.redeem,
  'card_giftcard': Icons.card_giftcard,
  'savings': Icons.savings,
  'paid': Icons.paid,
  'payments': Icons.payments,
  'storefront': Icons.storefront,
  'receipt_long': Icons.receipt_long,
  'groups': Icons.groups,
  'group': Icons.group,
  'person': Icons.person,
  'people': Icons.people,
  'thumb_up': Icons.thumb_up,
  'celebration': Icons.celebration,
  // Daily / home
  'home': Icons.home,
  'home_outlined': Icons.home_outlined,
  'work': Icons.work,
  'work_outline': Icons.work_outline,
  'shopping_cart': Icons.shopping_cart,
  'shopping_bag': Icons.shopping_bag,
  'cleaning_services': Icons.cleaning_services,
  'soap': Icons.soap,
  'yard': Icons.yard,
  'grass': Icons.grass,
  'local_laundry_service': Icons.local_laundry_service,
  'park': Icons.park,
  'landscape': Icons.landscape,
  'beach_access': Icons.beach_access,
  'pets': Icons.pets,
  'eco': Icons.eco,
  'forest': Icons.forest,
  'flight': Icons.flight,
  'directions_car': Icons.directions_car,
  'directions_bus': Icons.directions_bus,
  'tram': Icons.tram,
  'directions_subway': Icons.directions_subway,
  // Tech / contact
  'phone': Icons.phone,
  'smartphone': Icons.smartphone,
  'laptop': Icons.laptop,
  'computer': Icons.computer,
  'email': Icons.email,
  'mark_email_read': Icons.mark_email_read,
  'send': Icons.send,
  'chat': Icons.chat,
  'forum': Icons.forum,
  'call': Icons.call,
  // Misc
  'star_rate': Icons.star_rate,
  'rocket_launch': Icons.rocket_launch,
  'bolt': Icons.bolt,
  'flag': Icons.flag,
  'flag_outlined': Icons.flag_outlined,
  'emoji_flags': Icons.emoji_flags,
  'pin_drop': Icons.pin_drop,
  'explore': Icons.explore,
  'terrain': Icons.terrain,
};

/// All curated icons, in display order.
List<IconData> get kPersonalAmolMaterialIcons =>
    kPersonalAmolIcons.values.toList();

/// True when [icon] is a persisted Material-icon token.
bool isPersonalAmolMaterialIcon(String icon) =>
    icon.startsWith(kPersonalAmolMaterialIconPrefix);

/// Encodes a Material icon from the curated set into its persisted token.
String encodePersonalAmolIcon(IconData icon) {
  for (final entry in kPersonalAmolIcons.entries) {
    if (entry.value.codePoint == icon.codePoint) {
      return '$kPersonalAmolMaterialIconPrefix${entry.key}';
    }
  }
  return '';
}

/// Decodes a persisted personal-amol icon token into its const [IconData], or
/// null when the string is an emoji/empty/unknown.
IconData? decodePersonalAmolIcon(String icon) {
  if (!isPersonalAmolMaterialIcon(icon)) return null;
  return kPersonalAmolIcons[icon.substring(kPersonalAmolMaterialIconPrefix.length)];
}

/// Renders a personal-amol icon: a Material icon when the persisted string is
/// a material token, otherwise the emoji/fallback text.
class AmolIconView extends StatelessWidget {
  const AmolIconView({
    super.key,
    required this.icon,
    this.onFilled = false,
    this.iconSize,
    this.emojiSize = 18,
    this.fallbackText,
  });

  final String icon;

  /// True when rendered on a gold background, so Material icons turn emerald.
  final bool onFilled;
  final double? iconSize;
  final double emojiSize;
  final String? fallbackText;

  @override
  Widget build(BuildContext context) {
    final material = decodePersonalAmolIcon(icon);
    if (material != null) {
      return Icon(
        material,
        size: iconSize ?? emojiSize,
        color: onFilled ? AppColors.emeraldDeep : AppColors.gold,
      );
    }
    final text = icon.isNotEmpty
        ? icon
        : (fallbackText != null && fallbackText!.isNotEmpty
              ? fallbackText!.characters.first
              : '');
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(text, style: TextStyle(fontSize: emojiSize, height: 1));
  }
}