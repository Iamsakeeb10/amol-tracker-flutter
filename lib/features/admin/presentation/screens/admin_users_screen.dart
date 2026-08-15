import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/user_role.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/avatar_chip.dart';
import '../../providers/admin_users_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final email = _emailController.text.trim();
    ref.read(adminUserSearchProvider.notifier).searchUserByEmail(email);
  }

  void _onRoleChanged(String uid, UserRole newRole) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(adminUserSearchProvider.notifier).updateUserRole(uid, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userRoleUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchState = ref.watch(adminUserSearchProvider);

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.adminUsersTitle, style: AppTextStyles.headlineMedium(context)),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: l10n.searchUserEmail,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: _onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.emeraldDeep,
                  ),
                  child: const Text('Search'),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: searchState.when(
                data: (user) {
                  if (user == null) {
                    return Center(
                      child: Text(
                        'No user found.',
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }

                  return ListView(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldMid,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            AvatarChip(
                              initial: user.name.isNotEmpty
                                  ? user.name.substring(0, 1).toUpperCase()
                                  : 'U',
                              size: 48,
                              color: AppColors.gold,
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isNotEmpty ? user.name : 'No Name',
                                    style: AppTextStyles.titleMedium(context),
                                  ),
                                  Text(
                                    user.email,
                                    style: AppTextStyles.bodySmall(context).copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownButton<UserRole>(
                              value: user.role,
                              dropdownColor: AppColors.emeraldMid,
                              underline: const SizedBox(),
                              items: UserRole.values.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role.name.toUpperCase(),
                                    style: AppTextStyles.bodyMedium(context),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newRole) {
                                if (newRole != null && newRole != user.role) {
                                  _onRoleChanged(user.uid, newRole);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
