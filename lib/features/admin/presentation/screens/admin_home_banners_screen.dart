import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/home_banners_config_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/home_banners_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminHomeBannersScreen extends ConsumerStatefulWidget {
  const AdminHomeBannersScreen({super.key});

  @override
  ConsumerState<AdminHomeBannersScreen> createState() => _AdminHomeBannersScreenState();
}

class _AdminHomeBannersScreenState extends ConsumerState<AdminHomeBannersScreen> {
  bool _isLoading = false;
  
  final _reminderTitleCtrl = TextEditingController();
  final _reminderBodyCtrl = TextEditingController();
  final _battleTitleCtrl = TextEditingController();

  HomeBannersConfigModel? _initialConfig;

  @override
  void dispose() {
    _reminderTitleCtrl.dispose();
    _reminderBodyCtrl.dispose();
    _battleTitleCtrl.dispose();
    super.dispose();
  }

  void _initControllers(HomeBannersConfigModel config) {
    if (_initialConfig == null) {
      _initialConfig = config;
      _reminderTitleCtrl.text = config.reminderTitle ?? '';
      _reminderBodyCtrl.text = config.reminderBody ?? '';
      _battleTitleCtrl.text = config.battleBannerTitle ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configAsync = ref.watch(homeBannersConfigProvider);

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(title: l10n.adminHomeBannersTitle),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            l10n.adminLoadFailed,
            style: AppTextStyles.bodyMedium(context),
          ),
        ),
        data: (config) {
          _initControllers(config);
          
          return ListView(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 100.h),
            children: [
              AdminScreenHeader(
                subtitle: l10n.adminSectionTitle.toUpperCase(),
                title: l10n.adminHomeBannersTitle,
              ),
              SizedBox(height: 18.h),
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text(
                        l10n.adminShowReminderCard,
                        style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      activeColor: AppColors.gold,
                      value: config.showReminderCard,
                      onChanged: _isLoading
                          ? null
                          : (val) => _updateToggle(context, {'showReminderCard': val}),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Column(
                        children: [
                          TextField(
                            controller: _reminderTitleCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Custom Reminder Title (leave blank for default)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          TextField(
                            controller: _reminderBodyCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Custom Reminder Body (leave blank for default)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(
                        l10n.adminShowBattleBanner,
                        style: AppTextStyles.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                      ),
                      activeColor: AppColors.gold,
                      value: config.showBattleBanner,
                      onChanged: _isLoading
                          ? null
                          : (val) => _updateToggle(context, {'showBattleBanner': val}),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: TextField(
                        controller: _battleTitleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Custom Battle Banner Title (leave blank for default)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          minimumSize: Size(double.infinity, 48.h),
                        ),
                        onPressed: _isLoading ? null : () => _saveContent(context),
                        child: _isLoading 
                            ? const CircularProgressIndicator(color: AppColors.emeraldDeep)
                            : Text(
                                'Save Custom Content',
                                style: AppTextStyles.button(context).copyWith(color: AppColors.emeraldDeep),
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateToggle(BuildContext context, Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      await ref.read(firestoreServiceProvider).updateHomeBannersConfig(data);
      if (!context.mounted) return;
      showAdminSnackBar(context, message: 'Toggle saved.');
    } catch (_) {
      if (!context.mounted) return;
      showAdminSnackBar(context, message: l10n.adminSaveFailed, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveContent(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final data = {
        'reminderTitle': _reminderTitleCtrl.text.trim().isEmpty ? null : _reminderTitleCtrl.text.trim(),
        'reminderBody': _reminderBodyCtrl.text.trim().isEmpty ? null : _reminderBodyCtrl.text.trim(),
        'battleBannerTitle': _battleTitleCtrl.text.trim().isEmpty ? null : _battleTitleCtrl.text.trim(),
      };
      await ref.read(firestoreServiceProvider).updateHomeBannersConfig(data);
      if (!context.mounted) return;
      showAdminSnackBar(context, message: 'Content saved successfully.');
    } catch (_) {
      if (!context.mounted) return;
      showAdminSnackBar(context, message: l10n.adminSaveFailed, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
