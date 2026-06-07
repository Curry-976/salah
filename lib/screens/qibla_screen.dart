import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../utils/theme.dart';

// ── Haversine helpers ─────────────────────────────────────────────────────────

const _meccaLat = 21.4225;
const _meccaLng = 39.8262;

double _distanceKm(double lat, double lng) {
  const R = 6371.0;
  final dLat = (_meccaLat - lat) * math.pi / 180;
  final dLng = (_meccaLng - lng) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat * math.pi / 180) *
          math.cos(_meccaLat * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _bearingDeg(double lat, double lng) {
  final dLng = (_meccaLng - lng) * math.pi / 180;
  final lat1 = lat * math.pi / 180;
  final lat2 = _meccaLat * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

String _fmtDist(double km) {
  final s = km.round().toString();
  return s.length > 3 ? '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}' : s;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>();

    final appBar = AppBar(
      title: const Text('Direction Qibla'),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );

    if (kIsWeb) {
      return Scaffold(
        appBar: appBar,
        body: location.isLoading
            ? const _Loading()
            : _QiblaFallback(
                latitude: location.latitude ?? -12.8275,
                longitude: location.longitude ?? 45.1662,
                isMayotteFallback: !location.hasLocation,
                isWeb: true,
              ),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: location.isLoading
          ? const _Loading()
          : !location.hasLocation
              ? _QiblaFallback(
                  latitude: -12.8275,
                  longitude: 45.1662,
                  isMayotteFallback: true,
                )
              : _QiblaCompass(
                  latitude: location.latitude!,
                  longitude: location.longitude!,
                ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2),
      );
}

// ── Static Qibla info (web or no-location) ────────────────────────────────────

class _QiblaFallback extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool isMayotteFallback;
  final bool isWeb;

  const _QiblaFallback({
    required this.latitude,
    required this.longitude,
    this.isMayotteFallback = false,
    this.isWeb = false,
  });

  String _notice() {
    if (isWeb && isMayotteFallback) {
      return 'Flèche orientée depuis le Nord · Position par défaut (Mayotte) · Activez la géolocalisation pour votre position exacte';
    }
    if (isWeb) {
      return 'Flèche orientée depuis le Nord · La boussole interactive nécessite un appareil mobile';
    }
    return 'Position par défaut (Mayotte) · Activez la localisation pour orienter la flèche depuis votre position exacte';
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distanceKm(latitude, longitude);
    final bearing = _bearingDeg(latitude, longitude);
    final bearingRad = bearing * math.pi / 180;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        children: [
          // Arabic + French header
          Text(
            'اتجاه القبلة',
            style: AppFonts.arabic(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          const Text(
            'Direction de la Qibla',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 60.ms),

          const SizedBox(height: 40),

          // Compass with static Qibla arrow
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    gradient: RadialGradient(colors: [
                      AppColors.surface.withValues(alpha: 0.5),
                      AppColors.bgDark.withValues(alpha: 0.8),
                    ]),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final d in ['N', 'E', 'S', 'O']) _CompassLabel(d),
                    ],
                  ),
                ),
                Transform.rotate(
                  angle: bearingRad,
                  child: const _QiblahNeedle(diameter: 240),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 100.ms)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 500.ms,
                delay: 100.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 36),

          // Distance + bearing chips
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: 'DISTANCE',
                  value: _fmtDist(dist),
                  unit: 'km de La Mecque',
                  icon: Icons.route_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChip(
                  label: 'DIRECTION',
                  value: '${bearing.toStringAsFixed(1)}°',
                  unit: 'depuis le Nord',
                  icon: Icons.navigation_outlined,
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.06, end: 0, duration: 400.ms, delay: 200.ms),

          const SizedBox(height: 16),

          // Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLo,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    isMayotteFallback && !isWeb
                        ? Icons.location_off_outlined
                        : Icons.info_outline,
                    color: AppColors.textMuted,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _notice(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 280.ms),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 13),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppFonts.mono(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live compass (mobile with sensor) ────────────────────────────────────────

class _QiblaCompass extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _QiblaCompass({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _Loading();
        }

        final qiblah = snapshot.data!;
        final angle = qiblah.qiblah * (math.pi / 180) * -1;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'La Mecque',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '${qiblah.direction.toStringAsFixed(1)}° depuis le Nord',
              style: AppFonts.mono(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: qiblah.direction * (math.pi / 180) * -1,
                    child: const _CompassRose(),
                  ),
                  Transform.rotate(
                    angle: angle,
                    child: const _QiblahNeedle(diameter: 280),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _AccuracyIndicator(accuracy: qiblah.qiblah.abs()),
          ],
        );
      },
    );
  }
}

// ── Shared compass sub-widgets ────────────────────────────────────────────────

class _CompassRose extends StatelessWidget {
  const _CompassRose();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
        gradient: RadialGradient(
          colors: [
            AppColors.darkSurface.withValues(alpha: 0.5),
            AppColors.darkBg.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final d in ['N', 'E', 'S', 'O']) _CompassLabel(d),
        ],
      ),
    );
  }
}

class _CompassLabel extends StatelessWidget {
  final String label;
  const _CompassLabel(this.label);

  static const _positions = {
    'N': Alignment(0, -0.85),
    'E': Alignment(0.85, 0),
    'S': Alignment(0, 0.85),
    'O': Alignment(-0.85, 0),
  };

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _positions[label]!,
      child: Text(
        label,
        style: TextStyle(
          color: label == 'N' ? Colors.red : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// Aiguille Qibla correctement dimensionnée.
// La widget a la même taille que la boussole (diameter × diameter) ;
// son centre = centre de la boussole = pivot de la rotation.
// Align(topCenter) place la Kaaba près du bord, l'aiguille traverse le centre.
class _QiblahNeedle extends StatelessWidget {
  final double diameter;
  const _QiblahNeedle({this.diameter = 240});

  @override
  Widget build(BuildContext context) {
    final r = diameter / 2;
    // Bar : de la base de l'emoji jusqu'à 20 px après le centre
    // top(10) + emoji(24) + bar = r + 20  →  bar = r - 14
    final barH = r - 14;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text('🕋', style: TextStyle(fontSize: 24)),
            Container(
              width: 3,
              height: barH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.greenLight,
                    AppColors.greenLight.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracyIndicator extends StatelessWidget {
  final double accuracy;
  const _AccuracyIndicator({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final ok = accuracy < 15;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.warning_amber,
          color: ok ? Colors.green : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          ok ? 'Précision correcte' : 'Calibrez votre boussole',
          style: TextStyle(color: ok ? Colors.green : Colors.orange),
        ),
      ],
    );
  }
}
