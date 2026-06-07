import 'dart:math' as math;
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
      clipBehavior: Clip.none,
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
        clipBehavior: Clip.none,
        children: [
          // Concentric arc ornament — top-right corner
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcPainter(AppColors.green),
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
                        style: AppFonts.arabic(
                          color: AppColors.gold,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1,
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
                            style: AppFonts.mono(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 380.ms, delay: 300.ms),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── RIGHT: prayer time ───────────────────────────────────
                Text(
                  PrayerFormatter.formatTime(prayer.time),
                  style: AppFonts.mono(
                    color: AppColors.textPrimary,
                    fontSize: 68,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -3,
                    height: 1,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 560.ms, delay: 200.ms)
                    .slideY(begin: 0.10, end: 0, duration: 560.ms, delay: 200.ms, curve: Curves.easeOut),
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

// Four concentric quarter-circle arcs centered at the top-right corner.
// Start angle π/2 (right edge, depth r), sweep +π/2 clockwise to top edge (x = width-r).
class _ArcPainter extends CustomPainter {
  final Color baseColor;
  _ArcPainter(this.baseColor);

  static const _radii    = [58.0, 96.0, 134.0, 172.0];
  static const _opacities = [0.20, 0.14, 0.09, 0.05];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _radii.length; i++) {
      final paint = Paint()
        ..color = baseColor.withOpacity(_opacities[i])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width, 0), radius: _radii[i]),
        math.pi / 2,  // start: right edge at y = r
        math.pi / 2,  // sweep clockwise → top edge at x = width - r
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.baseColor != baseColor;
}
