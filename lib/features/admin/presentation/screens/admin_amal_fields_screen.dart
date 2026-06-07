import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/constants/amal_fields.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/amal_fields_service.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/amal_fields_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/admin_amal_field_tile.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminAmalFieldsScreen extends ConsumerWidget {
  const AdminAmalFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;

    if (!AdminConfig.isFullAdmin(user?.uid, role: user?.role)) {
      return AppScaffold(
        body: Center(
          child: Text(
            l10n.adminNotAuthorized,
            style: AppTextStyles.bodyMedium(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final fieldsAsync = ref.watch(allAmalFieldsProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(title: l10n.adminAmalFieldsTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminAmalFieldForm),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.emeraldDeep,
        icon: Icon(Icons.add, size: 20.r),
        label: Text(
          l10n.adminAmalFieldFormCreate,
          style: AppTextStyles.button(context).copyWith(
            color: AppColors.emeraldDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
        children: [
          AdminScreenHeader(
            subtitle: l10n.adminSectionTitle.toUpperCase(),
            title: l10n.adminAmalFieldsTitle,
          ),
          SizedBox(height: 18.h),
          fieldsAsync.when(
            loading: () => const AdminListShimmer(),
            error: (_, _) => CardContainer(
              child: Text(
                l10n.adminAmalFieldsLoadFailed,
                style: AppTextStyles.bodyMedium(context),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _AdminEmptyList(message: l10n.adminAmalFieldEmptyList);
              }
              return Column(
                children: items
                    .map((field) => _AdminAmalFieldRow(field: field))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminEmptyList extends StatelessWidget {
  const _AdminEmptyList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
      child: Column(
        children: [
          Icon(
            Icons.checklist_rtl_outlined,
            color: AppColors.gold,
            size: 36.r,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context),
          ),
        ],
      ),
    );
  }
}

class _AdminAmalFieldRow extends ConsumerWidget {
  const _AdminAmalFieldRow({required this.field});

  final AmalField field;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AdminAmalFieldTile(
      field: field,
      onTap: () => context.push(AppRoutes.adminAmalFieldForm, extra: field),
      onToggleActive: (value) async {
        try {
          await ref
              .read(amalFieldsServiceProvider)
              .setFieldActive(field.id, value);
        } catch (_) {
          if (!context.mounted) return;
          showAdminSnackBar(
            context,
            message: l10n.adminAmalFieldToggleFailed,
            isError: true,
          );
        }
      },
    );
  }
}
