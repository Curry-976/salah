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
          colors: [Color(0xFF0C2318), Color(0xFF081A12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.green.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.18),
            blurRadius: 48,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glow halo top-right corner
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Column(
              children: [
                // Label
                Text(
                  prayer.isTomorrow ? 'FAJR · DEMAIN' : 'PROCHAINE PRIÈRE',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                const SizedBox(height: 14),

                // Arabic + French names
                Text(
                  prayer.name.arabicName,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                  textDirection: TextDirection.rtl,
                ).animate().fadeIn(duration: 500.ms, delay: 150.ms).scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      delay: 150.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 4),

                Text(
                  prayer.name.displayName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    letterSpacing: 0.4,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                const SizedBox(height: 20),

                // Time — large monospace
                Text(
                  PrayerFormatter.formatTime(prayer.time),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    height: 1,
                    fontFamily: 'monospace',
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 250.ms)
                    .slideY(begin: 0.15, end: 0, duration: 600.ms, delay: 250.ms),

                const SizedBox(height: 22),

                // Countdown chip
                _CountdownChip(timeToNext: timeToNext)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 350.ms),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }
}

class _CountdownChip extends StatelessWidget {
  final Duration timeToNext;
  const _CountdownChip({required this.timeToNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          _PulsingDot(),
          const SizedBox(width: 12),
          Text(
            PrayerFormatter.formatCountdown(timeToNext),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.greenLight.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(
              begin: 0.6,
              end: 1.4,
              duration: 1400.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .scaleXY(
              begin: 1.4,
              end: 0.6,
              duration: 1400.ms,
            ),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.greenLight,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
