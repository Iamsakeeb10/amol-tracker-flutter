import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/mock/mock_data.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<MockNotification> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(kNotifications);
  }

  void _markAllRead() {
    setState(() {
      _items = _items
          .map(
            (n) => MockNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              time: n.time,
              icon: n.icon,
              unread: false,
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => n.unread).length;
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 22.r),
          onPressed: () => context.canPop() ? context.pop() : context.go('/more'),
        ),
        title: Row(
          children: [
            Text('Alerts', style: AppTextStyles.headlineMedium(context)),
            if (unread > 0) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 7.w,
                  vertical: 2.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(99.r),
                ),
                child: Text(
                  '$unread',
                  style: AppTextStyles.pill(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Mark all read',
              style: AppTextStyles.button(context).copyWith(color: AppColors.gold),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(0, 4.h, 0, 24.h),
        itemCount: _items.length,
        separatorBuilder: (_, _) => SizedBox(height: 8.h),
        itemBuilder: (_, i) => _NotificationRow(item: _items[i]),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final MockNotification item;
  const _NotificationRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      color: item.unread ? AppColors.goldCard : AppColors.cardDark,
      borderColor: item.unread ? AppColors.goldBorder : AppColors.cardBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              item.icon,
              color: item.unread ? AppColors.gold : AppColors.textSecondary,
              size: 18.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.bodyLarge(context).copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.unread)
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  item.body,
                  style: AppTextStyles.bodySmall(context).copyWith(fontSize: 11.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.time,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    fontSize: 10.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
