import 'package:flutter/material.dart';
import '../models/prayer_model.dart';
import '../utils/theme.dart';
import '../utils/prayer_formatter.dart';

class NextPrayerBanner extends StatelessWidget {
  final PrayerTime prayer;
  final Duration timeToNext;

  const NextPrayerBanner({
    super.key,
    required this.prayer,
    required this.timeToNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, Color(0xFF145C30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Prochaine prière',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                prayer.name.arabicName,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                prayer.name.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            PrayerFormatter.formatTime(prayer.time),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  PrayerFormatter.formatCountdown(timeToNext),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
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
