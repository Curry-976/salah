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
                  subtitle:
                      Text(settings.madhab == Madhab.hanafi ? 'Hanafi' : 'Shafi\'i / Maliki / Hanbali'),
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
                prayers.updateSettings(settings.copyWith(notificationsEnabled: val));
              },
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader('Méthodes disponibles'),
          Card(
            child: Column(
              children: CalculationMethod.values
                  .where((m) => m != CalculationMethod.other)
                  .map((m) => ListTile(
                        dense: true,
                        title: Text(_methodName(m)),
                        leading: Radio<CalculationMethod>(
                          value: m,
                          groupValue: settings.method,
                          activeColor: AppColors.green,
                          onChanged: (val) {
                            if (val != null) {
                              prayers.updateSettings(settings.copyWith(method: val));
                            }
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _methodName(CalculationMethod method) {
    switch (method) {
      case CalculationMethod.muslim_world_league:
        return 'Ligue Mondiale Musulmane';
      case CalculationMethod.egyptian:
        return 'Autorité Générale Égyptienne';
      case CalculationMethod.karachi:
        return 'Université des Sciences Islamiques, Karachi';
      case CalculationMethod.umm_al_qura:
        return 'Umm Al-Qura, Mecque';
      case CalculationMethod.dubai:
        return 'Dubai';
      case CalculationMethod.moon_sighting_committee:
        return 'Comité de vision de la lune';
      case CalculationMethod.north_america:
        return 'Amérique du Nord (ISNA)';
      case CalculationMethod.kuwait:
        return 'Koweït';
      case CalculationMethod.qatar:
        return 'Qatar';
      case CalculationMethod.singapore:
        return 'Singapour';
      case CalculationMethod.turkey:
        return 'Turquie';
      case CalculationMethod.tehran:
        return 'Téhéran';
      case CalculationMethod.france:
        return 'France (UOIF)';
      default:
        return method.name;
    }
  }

  void _showMethodPicker(BuildContext context, PrayerService prayers) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _MethodPickerSheet(prayers: prayers),
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
                        title: Text(_name(m)),
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

  String _name(CalculationMethod m) {
    const names = {
      CalculationMethod.muslim_world_league: 'Ligue Mondiale Musulmane',
      CalculationMethod.egyptian: 'Égypte',
      CalculationMethod.karachi: 'Karachi',
      CalculationMethod.umm_al_qura: 'Umm Al-Qura',
      CalculationMethod.dubai: 'Dubai',
      CalculationMethod.north_america: 'Amérique du Nord',
      CalculationMethod.kuwait: 'Koweït',
      CalculationMethod.qatar: 'Qatar',
      CalculationMethod.singapore: 'Singapour',
      CalculationMethod.turkey: 'Turquie',
      CalculationMethod.tehran: 'Téhéran',
      CalculationMethod.france: 'France',
    };
    return names[m] ?? m.name;
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
