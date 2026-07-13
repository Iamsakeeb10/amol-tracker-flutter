import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/admin_config.dart';
import '../../../../core/utils/admin_push_debug.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/admin_push_provider.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/streak_badge.dart';
import '../widgets/admin_push_type_selector.dart';
import '../widgets/admin_shared_widgets.dart';


class AdminPushNotificationScreen extends ConsumerStatefulWidget {
  const AdminPushNotificationScreen({super.key});

  @override
  ConsumerState<AdminPushNotificationScreen> createState() =>
      _AdminPushNotificationScreenState();
}

class _AdminPushNotificationScreenState
    extends ConsumerState<AdminPushNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  String _type = 'announcement';
  bool _isSending = false;
  bool _isTargetingUser = false;
  
  bool _isSearching = false;
  List<UserModel> _searchResults = [];
  UserModel? _selectedUser;
  
  Timer? _debounce;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _resetForm() {
    _titleCtrl.clear();
    _messageCtrl.clear();
    _searchCtrl.clear();
    setState(() {
      _type = 'announcement';
      _isTargetingUser = false;
      _selectedUser = null;
      _searchResults = [];
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().length < 2) {
        if (mounted) setState(() => _searchResults = []);
        return;
      }
      
      setState(() => _isSearching = true);
      final results = await ref
          .read(firestoreServiceProvider)
          .searchUsersByQuery(query);
          
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    
    if (_isTargetingUser && _selectedUser == null) {
      showAdminSnackBar(
        context, 
        message: l10n.adminPushSelectUser,
        isError: true,
      );
      return;
    }

    final uid = ref.read(authStateProvider).asData?.value?.uid;
    final user = ref.read(currentUserProvider).asData?.value;
    if (!AdminConfig.isFullAdmin(user?.email, role: user?.role)) return;

    final gateway = ref.read(adminPushGatewayServiceProvider);
    logAdminPushDebug(
      'send tapped: uid=$uid gateway=${gateway.gatewayUrl} '
      'configured=${gateway.isConfigured} hasKey=${gateway.hasGatewayKey} '
      'targetUid=${_selectedUser?.uid}',
    );
    if (!gateway.isConfigured) {
      showAdminSnackBar(context, message: l10n.adminPushGatewayNotConfigured);
      return;
    }

    setState(() => _isSending = true);
    final result = await gateway.sendAdminPush(
      adminUid: uid!,
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      type: _type,
      targetUid: _isTargetingUser ? _selectedUser?.uid : null,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (result.success) {
      showAdminSnackBar(context, message: l10n.adminPushSent);
      _resetForm();
      return;
    }

    final detail = result.body ?? result.error ?? '';
    showAdminSnackBar(
      context,
      message: detail.isEmpty ? l10n.adminPushFailed : detail,
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).asData?.value;
    final hasKey = ref.watch(adminPushGatewayServiceProvider).hasGatewayKey;

    if (!AdminConfig.isFullAdmin(user?.email, role: user?.role)) {
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

    return AppScaffold(
      padding: EdgeInsets.zero,
      appBar: AdminAppBar(title: l10n.adminPushScreenTitle),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
          children: [
            AdminScreenHeader(
              subtitle: l10n.adminSectionTitle.toUpperCase(),
              title: l10n.adminPushScreenTitle,
            ),
            
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminPushAudience.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildAudienceToggle(
                          l10n.adminPushBroadcast,
                          Icons.campaign_outlined,
                          !_isTargetingUser,
                          () => setState(() => _isTargetingUser = false),
                        ),
                        SizedBox(width: 8.w),
                        _buildAudienceToggle(
                          l10n.adminPushSingleUser,
                          Icons.person_outline,
                          _isTargetingUser,
                          () => setState(() => _isTargetingUser = true),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_isTargetingUser) ...[
                    SizedBox(height: 16.h),
                    if (_selectedUser != null)
                      _buildSelectedUserPill(l10n)
                    else
                      _buildUserSearch(l10n),
                  ],
                ],
              ),
            ),
            
            SizedBox(height: 18.h),
            SectionHeader(title: l10n.adminPushMessage.toUpperCase()),
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminFormField(
                    label: l10n.adminPushTitle,
                    controller: _titleCtrl,
                    icon: Icons.title_rounded,
                    required: true,
                    error: l10n.adminPushTitleRequired,
                  ),
                  AdminFormField(
                    label: l10n.adminPushMessage,
                    controller: _messageCtrl,
                    icon: Icons.message_outlined,
                    required: true,
                    error: l10n.adminPushMessageRequired,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SectionHeader(title: l10n.adminPushType.toUpperCase()),
            CardContainer(
              child: AdminPushTypePillSelector(
                selected: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
            ),
            if (!hasKey) ...[
              SizedBox(height: 12.h),
              const Pill(
                text: 'Gateway key optional',
                icon: Icons.info_outline,
                color: AppColors.warningLight,
                textColor: AppColors.warning,
              ),
            ],
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _send,
                icon: _isSending
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.emeraldDeep,
                        ),
                      )
                    : Icon(Icons.send_rounded, size: 18.r),
                label: Text(
                  _isTargetingUser && _selectedUser != null
                      ? l10n.adminPushSendToUser(_selectedUser!.name.isNotEmpty ? _selectedUser!.name : 'User')
                      : l10n.adminPushSend,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.emeraldDeep,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  textStyle: AppTextStyles.button(context).copyWith(
                    color: AppColors.emeraldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceToggle(
    String label, 
    IconData icon, 
    bool isSelected, 
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldCard : AppColors.cardDark,
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.r,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppTextStyles.pill(context).copyWith(
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUserPill(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.emeraldMid.withValues(alpha: 0.2),
            backgroundImage: _selectedUser!.photoUrl.isNotEmpty
                ? NetworkImage(_selectedUser!.photoUrl)
                : null,
            child: _selectedUser!.photoUrl.isEmpty
                ? Text(
                    _selectedUser!.name.isNotEmpty 
                        ? _selectedUser!.name[0].toUpperCase() 
                        : '?',
                    style: AppTextStyles.label(context).copyWith(
                      color: AppColors.emeraldMid,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedUser!.name.isNotEmpty 
                      ? _selectedUser!.name 
                      : 'Unnamed user',
                  style: AppTextStyles.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedUser!.email.isNotEmpty)
                  Text(
                    _selectedUser!.email,
                    style: AppTextStyles.bodySmall(context),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20.r, color: AppColors.textSecondary),
            onPressed: () => setState(() => _selectedUser = null),
          ),
        ],
      ),
    );
  }

  Widget _buildUserSearch(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          style: AppTextStyles.bodyMedium(context),
          decoration: InputDecoration(
            hintText: l10n.adminPushSearchUser,
            hintStyle: AppTextStyles.label(context),
            filled: true,
            fillColor: AppColors.cardDark,
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: _isSearching
                  ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  : Icon(Icons.search_rounded, size: 18.r, color: AppColors.gold),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 44.w, minHeight: 34.h),
            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_searchCtrl.text.trim().length >= 2) ...[
          SizedBox(height: 12.h),
          if (_searchResults.isEmpty && !_isSearching)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                l10n.adminPushNoUsersFound,
                style: AppTextStyles.label(context).copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Container(
              constraints: BoxConstraints(maxHeight: 200.h),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1, 
                  color: AppColors.cardBorder,
                ),
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    leading: CircleAvatar(
                      radius: 16.r,
                      backgroundColor: AppColors.goldCard,
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? NetworkImage(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? Text(
                              user.name.isNotEmpty 
                                  ? user.name[0].toUpperCase() 
                                  : '?',
                              style: AppTextStyles.label(context).copyWith(
                                color: AppColors.gold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      user.name.isNotEmpty ? user.name : 'Unnamed user',
                      style: AppTextStyles.bodyMedium(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: user.email.isNotEmpty
                        ? Text(
                            user.email,
                            style: AppTextStyles.label(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedUser = user;
                        _searchCtrl.clear();
                        _searchResults = [];
                      });
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

