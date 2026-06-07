import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/hijri_converter.dart';
import '../utils/theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  HijriDate _toHijri(DateTime date) => HijriDate.fromGregorian(date);

  @override
  Widget build(BuildContext context) {
    final hijriToday = _toHijri(DateTime.now());
    final hijriSelected = _toHijri(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendrier Hégirien')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HijriHeader(hijri: hijriToday),
            _MonthNavigator(
              focusedDay: _focusedDay,
              onPrevious: () => setState(
                  () => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
              onNext: () => setState(
                  () => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
            ),
            _CalendarGrid(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              onDaySelected: (day) => setState(() => _selectedDay = day),
              toHijri: _toHijri,
            ),
            const Divider(),
            _SelectedDayInfo(gregorian: _selectedDay, hijri: hijriSelected),
            const SizedBox(height: 8),
            const _IslamicEventsCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HijriHeader extends StatelessWidget {
  final HijriDate hijri;
  const _HijriHeader({required this.hijri});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.green, Color(0xFF145C30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            hijri.format(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthNavigator({
    required this.focusedDay,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final hijri = HijriDate.fromGregorian(
        DateTime(focusedDay.year, focusedDay.month, 15));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy', 'fr_FR').format(focusedDay),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                hijri.formatMonthYear(),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime) onDaySelected;
  final HijriDate Function(DateTime) toHijri;

  const _CalendarGrid({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.toHijri,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
    final daysInMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sunday = 0

    final weekdays = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.75,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox();
              final day = DateTime(
                  focusedDay.year, focusedDay.month, index - startWeekday + 1);
              final hijri = toHijri(day);
              final isSelected = day.day == selectedDay.day &&
                  day.month == selectedDay.month &&
                  day.year == selectedDay.year;
              final isToday = day.day == DateTime.now().day &&
                  day.month == DateTime.now().month &&
                  day.year == DateTime.now().year;
              final hasEvent = _islamicEventDays.any(
                (e) => e.$1 == hijri.month && e.$2 == hijri.day,
              );

              return GestureDetector(
                onTap: () => onDaySelected(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.green
                        : isToday
                            ? AppColors.greenLight.withOpacity(0.15)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.greenLight, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                      Text(
                        '${hijri.day}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.textMuted,
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.greenLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // (month, day) pairs for Islamic event markers
  static const _islamicEventDays = [
    (1, 1), (1, 10), (3, 12), (7, 27),
    (8, 15), (9, 1), (9, 27), (10, 1),
    (12, 9), (12, 10),
  ];
}

class _SelectedDayInfo extends StatelessWidget {
  final DateTime gregorian;
  final HijriDate hijri;

  const _SelectedDayInfo({required this.gregorian, required this.hijri});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('Grégorien', style: TextStyle(fontSize: 12)),
              Text(
                DateFormat('d MMM yyyy', 'fr_FR').format(gregorian),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const VerticalDivider(),
          Column(
            children: [
              const Text('Hégirien', style: TextStyle(fontSize: 12)),
              Text(
                hijri.format(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IslamicEventsCard extends StatelessWidget {
  const _IslamicEventsCard();

  // (hijriMonth, hijriDay, name)
  static const _defs = [
    (1,  1,  'Nouvel an hégirien'),
    (1,  10, 'Achoura'),
    (3,  12, 'Mawlid an-Nabawi'),
    (7,  27, 'Laylat al-Miraj'),
    (8,  15, "Laylat al-Baraat"),
    (9,  1,  'Début du Ramadan'),
    (9,  27, 'Laylat al-Qadr (estimée)'),
    (10, 1,  'Aïd el-Fitr'),
    (12, 9,  "Jour d'Arafat"),
    (12, 10, 'Aïd el-Adha'),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijriYear = HijriDate.fromGregorian(now).year;
    final fmt = DateFormat('d MMM yyyy', 'fr_FR');

    // Compute Gregorian date for each event; if already past, use next hijri year
    final events = _defs.map((def) {
      final (hm, hd, name) = def;
      var greg = HijriDate(hijriYear, hm, hd).toGregorian();
      var hy = hijriYear;
      if (greg.isBefore(DateTime(now.year, now.month, now.day))) {
        hy = hijriYear + 1;
        greg = HijriDate(hy, hm, hd).toGregorian();
      }
      return (name: name, hijri: HijriDate(hy, hm, hd), greg: greg);
    }).toList()
      ..sort((a, b) => a.greg.compareTo(b.greg));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Événements islamiques',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            for (final e in events)
              ListTile(
                dense: true,
                leading: const Icon(Icons.star, color: AppColors.textSecondary, size: 18),
                title: Text(e.name),
                subtitle: Text(
                  e.hijri.format(),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                trailing: Text(
                  fmt.format(e.greg),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
