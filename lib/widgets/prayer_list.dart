import 'package:flutter/material.dart';
import '../models/prayer_model.dart';
import '../utils/theme.dart';
import '../utils/prayer_formatter.dart';

class PrayerList extends StatelessWidget {
  final List<PrayerTime> prayers;

  const PrayerList({super.key, required this.prayers});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => PrayerTile(prayer: prayers[index]),
        childCount: prayers.length,
      ),
    );
  }
}

class PrayerTile extends StatelessWidget {
  final PrayerTime prayer;

  const PrayerTile({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    Color timeColor;

    if (prayer.isNext) {
      backgroundColor = AppColors.gold.withOpacity(0.15);
      textColor = AppColors.gold;
      timeColor = AppColors.gold;
    } else if (prayer.isPast) {
      backgroundColor = Colors.transparent;
      textColor = AppColors.prayerPast;
      timeColor = AppColors.prayerPast;
    } else {
      backgroundColor = Colors.transparent;
      textColor = isDark ? Colors.white : Colors.black87;
      timeColor = isDark ? Colors.white70 : Colors.black54;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: prayer.isNext
            ? Border.all(color: AppColors.gold.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _PrayerIcon(name: prayer.name, isPast: prayer.isPast, isNext: prayer.isNext),
        title: Text(
          prayer.name.displayName,
          style: TextStyle(
            color: textColor,
            fontWeight: prayer.isNext ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          prayer.name.arabicName,
          style: TextStyle(
            color: prayer.isNext ? AppColors.gold.withOpacity(0.8) : AppColors.prayerPast,
            fontSize: 13,
          ),
        ),
        trailing: Text(
          PrayerFormatter.formatTime(prayer.time),
          style: TextStyle(
            color: timeColor,
            fontSize: 20,
            fontWeight: prayer.isNext ? FontWeight.bold : FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _PrayerIcon extends StatelessWidget {
  final PrayerName name;
  final bool isPast;
  final bool isNext;

  const _PrayerIcon({required this.name, required this.isPast, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(name);
    final color = isNext
        ? AppColors.gold
        : isPast
            ? AppColors.prayerPast
            : AppColors.green;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  IconData _iconFor(PrayerName name) {
    switch (name) {
      case PrayerName.fajr:
        return Icons.wb_twilight;
      case PrayerName.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerName.dhuhr:
        return Icons.light_mode;
      case PrayerName.asr:
        return Icons.wb_cloudy_outlined;
      case PrayerName.maghrib:
        return Icons.nights_stay_outlined;
      case PrayerName.isha:
        return Icons.dark_mode_outlined;
    }
  }
}
