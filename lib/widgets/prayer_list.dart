import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        (context, i) => PrayerTile(prayer: prayers[i])
            .animate(delay: (i * 55).ms)
            .fadeIn(duration: 380.ms, curve: Curves.easeOut)
            .slideX(begin: -0.06, end: 0, duration: 380.ms, curve: Curves.easeOut),
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
    final Color accent;
    final Color bg;
    final Color borderColor;

    if (prayer.isNext) {
      accent = AppColors.gold;
      bg = AppColors.gold.withOpacity(0.07);
      borderColor = AppColors.gold.withOpacity(0.25);
    } else if (prayer.isPast) {
      accent = AppColors.textMuted;
      bg = Colors.transparent;
      borderColor = Colors.transparent;
    } else {
      accent = AppColors.greenLight;
      bg = AppColors.surface;
      borderColor = AppColors.border.withOpacity(0.6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 3,
            height: 56,
            margin: const EdgeInsets.only(left: 1),
            decoration: BoxDecoration(
              color: prayer.isPast ? Colors.transparent : accent,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
                right: Radius.circular(2),
              ),
            ),
          ),
          // Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _PrayerIcon(
              name: prayer.name,
              isPast: prayer.isPast,
              isNext: prayer.isNext,
            ),
          ),
          // Names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer.name.displayName,
                  style: TextStyle(
                    color: prayer.isPast
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontWeight:
                        prayer.isNext ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prayer.name.arabicName,
                  style: TextStyle(
                    color: prayer.isNext
                        ? AppColors.gold.withOpacity(0.7)
                        : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Time
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  PrayerFormatter.formatTime(prayer.time),
                  style: TextStyle(
                    color: prayer.isNext
                        ? AppColors.gold
                        : prayer.isPast
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                    fontSize: 19,
                    fontWeight:
                        prayer.isNext ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'monospace',
                    letterSpacing: -0.5,
                  ),
                ),
                if (prayer.isNext)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SUIVANT',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
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

class _PrayerIcon extends StatelessWidget {
  final PrayerName name;
  final bool isPast;
  final bool isNext;

  const _PrayerIcon({
    required this.name,
    required this.isPast,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isNext
        ? AppColors.gold
        : isPast
            ? AppColors.textMuted.withOpacity(0.5)
            : AppColors.greenLight;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(isPast ? 0.06 : 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_iconFor(name), color: color, size: 20),
    );
  }

  IconData _iconFor(PrayerName n) {
    switch (n) {
      case PrayerName.fajr:    return Icons.wb_twilight;
      case PrayerName.sunrise: return Icons.wb_sunny_outlined;
      case PrayerName.dhuhr:   return Icons.light_mode;
      case PrayerName.asr:     return Icons.wb_cloudy_outlined;
      case PrayerName.maghrib: return Icons.nights_stay_outlined;
      case PrayerName.isha:    return Icons.dark_mode_outlined;
    }
  }
}
