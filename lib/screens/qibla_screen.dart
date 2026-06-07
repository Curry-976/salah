import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../utils/theme.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Direction Qibla')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_off, size: 64, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text(
                'La boussole Qibla nécessite\nun appareil mobile',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final location = context.watch<LocationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direction Qibla'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: !location.hasLocation
          ? const Center(
              child: Text('Localisation requise pour la direction Qibla'),
            )
          : _QiblaCompass(
              latitude: location.latitude!,
              longitude: location.longitude!,
            ),
    );
  }
}

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
          return const Center(child: CircularProgressIndicator());
        }

        final qiblah = snapshot.data!;
        final angle = (qiblah.qiblah * (math.pi / 180) * -1);

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
              style: Theme.of(context).textTheme.bodyMedium,
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
                    child: _CompassRose(),
                  ),
                  Transform.rotate(
                    angle: angle,
                    child: _QiblahNeedle(),
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

class _CompassRose extends StatelessWidget {
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
            AppColors.darkSurface.withOpacity(0.5),
            AppColors.darkBg.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final dir in ['N', 'E', 'S', 'O'])
            _CompassLabel(dir),
        ],
      ),
    );
  }
}

class _CompassLabel extends StatelessWidget {
  final String label;
  const _CompassLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final Map<String, Alignment> positions = {
      'N': Alignment(0, -0.85),
      'E': Alignment(0.85, 0),
      'S': Alignment(0, 0.85),
      'O': Alignment(-0.85, 0),
    };

    return Align(
      alignment: positions[label]!,
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

class _QiblahNeedle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🕋', style: TextStyle(fontSize: 28)),
        Container(
          width: 4,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.greenLight, Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _AccuracyIndicator extends StatelessWidget {
  final double accuracy;
  const _AccuracyIndicator({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final isAccurate = accuracy < 15;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isAccurate ? Icons.check_circle : Icons.warning_amber,
          color: isAccurate ? Colors.green : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          isAccurate ? 'Précision correcte' : 'Calibrez votre boussole',
          style: TextStyle(
            color: isAccurate ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}
