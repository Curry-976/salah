import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2016), Color(0xFF071510), Color(0xFF060F1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.5, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.green.withOpacity(0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.14),
            blurRadius: 40,
            spreadRadius: -8,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle right-side glow behind the time
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 120,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(28),
                ),
                gradient: RadialGradient(
                  center: Alignment.bottomRight,
                  radius: 1.0,
                  colors: [
                    AppColors.green.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 22, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── LEFT: prayer identity ─────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status label
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.greenLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            prayer.isTomorrow ? 'FAJR · DEMAIN' : 'PROCHAINE PRIÈRE',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 380.ms, delay: 80.ms),

                      const SizedBox(height: 18),

                      // Arabic name — large, left-anchored
                      Text(
                        prayer.name.arabicName,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1,
                          letterSpacing: 0.5,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 480.ms, delay: 130.ms)
                          .slideX(begin: -0.06, end: 0, duration: 480.ms, delay: 130.ms, curve: Curves.easeOut),

                      const SizedBox(height: 5),

                      // French name
                      Text(
                        prayer.name.displayName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w400,
                        ),
                      ).animate().fadeIn(duration: 380.ms, delay: 180.ms),

                      const SizedBox(height: 26),

                      // Countdown inline — no pill border, just dot + number
                      Row(
                        children: [
                          _PulsingDot(),
                          const SizedBox(width: 10),
                          Text(
                            PrayerFormatter.formatCountdown(timeToNext),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 380.ms, delay: 300.ms),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── RIGHT: time — dominant number, bottom-anchored ────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    PrayerFormatter.formatTime(prayer.time),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2.5,
                      height: 1,
                      fontFamily: 'monospace',
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 560.ms, delay: 200.ms)
                      .slideY(begin: 0.12, end: 0, duration: 560.ms, delay: 200.ms, curve: Curves.easeOut),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.07, end: 0, duration: 500.ms, curve: Curves.easeOut);
  }
}

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.greenLight.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 0.5, end: 1.5, duration: 1400.ms, curve: Curves.easeInOut)
            .then()
            .scaleXY(begin: 1.5, end: 0.5, duration: 1400.ms),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppColors.greenLight,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
