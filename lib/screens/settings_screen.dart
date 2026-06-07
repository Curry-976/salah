import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import '../services/prayer_service.dart';
import '../services/location_service.dart';
import '../models/prayer_model.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prayers = context.watch<PrayerService>();
    final settings = prayers.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LocationInfoCard(),
          const SizedBox(height: 16),
          _SectionHeader('Calcul des horaires'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Méthode de calcul'),
                  subtitle: Text(_methodName(settings.method)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showMethodPicker(context, prayers),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('École juridique (Asr)'),
                  subtitle: Text(
                      settings.madhab == Madhab.hanafi
                          ? 'Hanafi'
                          : "Shafi'i / Maliki / Hanbali"),
                  trailing: Switch(
                    value: settings.madhab == Madhab.hanafi,
                    activeColor: AppColors.green,
                    onChanged: (val) {
                      prayers.updateSettings(settings.copyWith(
                        madhab: val ? Madhab.hanafi : Madhab.shafi,
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('Notifications'),
          Card(
            child: SwitchListTile(
              title: const Text('Notifications Adhan'),
              subtitle: const Text('Recevoir une notification à chaque prière'),
              value: settings.notificationsEnabled,
              activeColor: AppColors.green,
              onChanged: (val) {
                prayers.updateSettings(
                    settings.copyWith(notificationsEnabled: val));
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _methodName(CalculationMethod method) {
    const names = {
      CalculationMethod.muslim_world_league: 'Ligue Mondiale Musulmane',
      CalculationMethod.egyptian: 'Autorité Générale Égyptienne',
      CalculationMethod.karachi: 'Université des Sciences Islamiques, Karachi',
      CalculationMethod.umm_al_qura: 'Umm Al-Qura, Mecque',
      CalculationMethod.dubai: 'Dubaï',
      CalculationMethod.moon_sighting_committee: 'Comité de vision de la lune',
      CalculationMethod.north_america: 'Amérique du Nord (ISNA)',
      CalculationMethod.kuwait: 'Koweït',
      CalculationMethod.qatar: 'Qatar',
      CalculationMethod.singapore: 'Singapour',
      CalculationMethod.turkey: 'Turquie',
      CalculationMethod.tehran: 'Téhéran',
    };
    return names[method] ?? method.name;
  }

  void _showMethodPicker(BuildContext context, PrayerService prayers) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _MethodPickerSheet(prayers: prayers),
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  const _LocationInfoCard();

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>();
    final isGps = !location.isUsingFallback && location.hasLocation;

    final title = isGps
        ? (location.cityName.isNotEmpty ? location.cityName : 'Position GPS')
        : 'Mayotte — Mamoudzou';

    final subtitle = location.hasLocation
        ? 'Lat. ${location.latitude!.toStringAsFixed(4)}° · '
          'Long. ${location.longitude!.toStringAsFixed(4)}° · UTC+3'
        : 'Lat. -12.7806° · Long. 45.2278° · UTC+3';

    return Card(
      color: AppColors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🇾🇹', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                      Icon(
                        isGps ? Icons.gps_fixed : Icons.location_off_outlined,
                        size: 14,
                        color: isGps ? AppColors.green : Colors.grey,
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppFonts.mono(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodPickerSheet extends StatelessWidget {
  final PrayerService prayers;
  const _MethodPickerSheet({required this.prayers});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Méthode de calcul',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: CalculationMethod.values
                  .where((m) => m != CalculationMethod.other)
                  .map((m) => ListTile(
                        title: Text(SettingsScreen._methodName(m)),
                        trailing: prayers.settings.method == m
                            ? const Icon(Icons.check, color: AppColors.green)
                            : null,
                        onTap: () {
                          prayers.updateSettings(
                              prayers.settings.copyWith(method: m));
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
