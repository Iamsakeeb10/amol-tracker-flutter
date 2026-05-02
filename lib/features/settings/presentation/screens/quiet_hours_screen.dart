import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/card_container.dart';

class QuietHoursScreen extends StatefulWidget {
  const QuietHoursScreen({super.key});

  @override
  State<QuietHoursScreen> createState() => _QuietHoursScreenState();
}

class _QuietHoursScreenState extends State<QuietHoursScreen> {
  TimeOfDay _from = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 6, minute: 0);

  String _format(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _bumpHour(TimeOfDay t, int delta, bool start) {
    final newHour = (t.hour + delta) % 24;
    final v = TimeOfDay(hour: newHour < 0 ? newHour + 24 : newHour, minute: t.minute);
    setState(() {
      if (start) {
        _from = v;
      } else {
        _to = v;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: Text('Quiet hours', style: AppTextStyles.headlineMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Notifications stay silent during these hours. Reminders still run.',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TimeCard(
                  label: 'FROM',
                  time: _from,
                  formatted: _format(_from),
                  onUp: () => _bumpHour(_from, 1, true),
                  onDown: () => _bumpHour(_from, -1, true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeCard(
                  label: 'TO',
                  time: _to,
                  formatted: _format(_to),
                  onUp: () => _bumpHour(_to, 1, false),
                  onDown: () => _bumpHour(_to, -1, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          CardContainer(
            child: Row(
              children: [
                const Icon(
                  Icons.nightlight_round,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Silent from ${_format(_from)} to ${_format(_to)}',
                    style: AppTextStyles.bodyLarge.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.emeraldDeep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.emeraldDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final String formatted;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const _TimeCard({
    required this.label,
    required this.time,
    required this.formatted,
    required this.onUp,
    required this.onDown,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          Text(
            formatted,
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.goldLight,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onDown,
                icon: const Icon(Icons.remove),
                color: AppColors.gold,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onUp,
                icon: const Icon(Icons.add),
                color: AppColors.gold,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
