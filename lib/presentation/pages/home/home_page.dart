import 'package:couple_note/core/utils/utils.dart';
import 'package:couple_note/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// Models
class AlarmData {
  final String time;
  final String period;
  final String label;
  final String? owner;
  final bool isEnabled;
  final IconData? icon;

  AlarmData({
    required this.time,
    required this.period,
    required this.label,
    this.owner,
    this.isEnabled = true,
    this.icon,
  });
}

// Providers
final selectedTabProvider = StateProvider<int>(
  (ref) => 0,
); // 0 = Mine, 1 = Ours

final userAlarmsProvider = StateProvider<List<AlarmData>>(
  (ref) => [AlarmData(time: '07:30', period: 'AM', label: 'Gym time!')],
);

final partnerAlarmsProvider = StateProvider<List<AlarmData>>(
  (ref) => [AlarmData(time: '08:15', period: 'AM', label: 'Coffee break')],
);

final activeAlarmsProvider = StateProvider<List<AlarmData>>(
  (ref) => [
    AlarmData(
      time: '08:45',
      period: 'AM',
      label: '"Breakfast in bed?"',
      owner: 'NEW FROM ANN',
      icon: Icons.restaurant,
    ),
    AlarmData(
      time: '07:00',
      period: 'AM',
      label: 'Weekdays • Enabled',
      owner: 'DAILY WAKEUP',
      isEnabled: true,
      icon: Icons.wb_sunny_outlined,
    ),
  ],
);

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAlarms = ref.watch(userAlarmsProvider);
    final partnerAlarms = ref.watch(partnerAlarmsProvider);
    final activeAlarms = ref.watch(activeAlarmsProvider);
    final selectedTab = ref.watch(selectedTabProvider);
    final currentUser = ref.watch(currentUserStreamProvider).value?.data;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${getName(currentUser, maxLength: 15)}!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Everything is in sync',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.pink.shade300,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.pink.shade300,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.notifications_none,
                          color: Colors.pink.shade300,
                          size: 24,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Alarm Cards
                Row(
                  children: [
                    Expanded(
                      child: _AlarmCard(
                        title: 'Yours',
                        time: userAlarms[0].time,
                        period: userAlarms[0].period,
                        label: userAlarms[0].label,
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AlarmCard(
                        title: 'Ann\'s',
                        time: partnerAlarms[0].time,
                        period: partnerAlarms[0].period,
                        label: partnerAlarms[0].label,
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tab Bar
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(selectedTabProvider.notifier).state = 0,
                        child: _TabButton(
                          label: 'Mine',
                          isSelected: selectedTab == 0,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(selectedTabProvider.notifier).state = 1,
                        child: _TabButton(
                          label: 'Ours',
                          isSelected: selectedTab == 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Active Alarms Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE ALARMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${activeAlarms.length} Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.pink.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Alarms List
                ...activeAlarms.asMap().entries.map((entry) {
                  final index = entry.key;
                  final alarm = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _ActiveAlarmCard(
                      alarm: alarm,
                      isNewRequest: index == 0,
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final String title;
  final String time;
  final String period;
  final String label;
  final bool isPrimary;

  const _AlarmCard({
    required this.title,
    required this.time,
    required this.period,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary
            ? const Color.fromARGB(255, 248, 100, 152)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? const Color(0xFFFF5893).withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                size: 14,
                color: isPrimary ? Colors.white : Colors.pink.shade300,
              ),
              const SizedBox(width: 4),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : Colors.pink.shade300,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.white : const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isPrimary ? Colors.white : const Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isPrimary
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TabButton({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFFFF5893) : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 3,
          width: 40,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5893) : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _ActiveAlarmCard extends StatelessWidget {
  final AlarmData alarm;
  final bool isNewRequest;

  const _ActiveAlarmCard({required this.alarm, required this.isNewRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNewRequest ? Colors.pink.shade100 : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alarm.owner != null) ...[
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  size: 12,
                  color: Colors.pink.shade300,
                ),
                const SizedBox(width: 6),
                Text(
                  alarm.owner!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.pink.shade300,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    alarm.time,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      alarm.period,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ],
              ),
              if (alarm.icon != null)
                Icon(alarm.icon, color: Colors.pink.shade300, size: 20),
            ],
          ),
          Text(
            alarm.label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (isNewRequest) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5893),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'ACCEPT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'DECLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: Switch(
                value: alarm.isEnabled,
                onChanged: (value) {},
                activeColor: const Color(0xFFFF5893),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
    ),
  );
}
