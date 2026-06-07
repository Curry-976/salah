import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adhan/adhan.dart';
import '../services/prayer_service.dart';
import '../services/location_service.dart';
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
        children: [
          const _LocationRow(),
          const SizedBox(height: 24),

          const _SectionLabel('CALCUL DES HORAIRES'),
          const _Line(),
          _Row(
            title: 'Méthode de calcul',
            subtitle: _methodName(settings.method),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 18,
            ),
            onTap: () => _showMethodPicker(context, prayers),
          ),
          const _Line(),
          _SwitchRow(
            title: "École juridique (Asr)",
            subtitle: settings.madhab == Madhab.hanafi
                ? 'Hanafi'
                : "Shafi'i / Maliki / Hanbali",
            value: settings.madhab == Madhab.hanafi,
            onChanged: (val) {
              prayers.updateSettings(settings.copyWith(
                madhab: val ? Madhab.hanafi : Madhab.shafi,
              ));
            },
          ),
          const _Line(),
          const SizedBox(height: 28),

          const _SectionLabel('NOTIFICATIONS'),
          const _Line(),
          _SwitchRow(
            title: 'Notifications Adhan',
            subtitle: 'Recevoir une notification à chaque prière',
            value: settings.notificationsEnabled,
            onChanged: (val) {
              prayers.updateSettings(
                  settings.copyWith(notificationsEnabled: val));
            },
          ),
          const _Line(),
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

// ── Location status band ──────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  const _LocationRow();

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.green.withOpacity(0.06),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🇾🇹', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
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
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      isGps
                          ? Icons.gps_fixed
                          : Icons.location_off_outlined,
                      size: 13,
                      color: isGps
                          ? AppColors.greenLight
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGps ? 'GPS' : 'Défaut',
                      style: TextStyle(
                        color: isGps
                            ? AppColors.greenLight
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
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
    );
  }
}

// ── Primitives ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      value: value,
      activeColor: AppColors.green,
      onChanged: onChanged,
    );
  }
}

// ── Method picker sheet ───────────────────────────────────────────────────────

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
            child: Text(
              'Méthode de calcul',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: CalculationMethod.values
                  .where((m) => m != CalculationMethod.other)
                  .map(
                    (m) => ListTile(
                      title: Text(SettingsScreen._methodName(m)),
                      trailing: prayers.settings.method == m
                          ? const Icon(Icons.check, color: AppColors.green)
                          : null,
                      onTap: () {
                        prayers.updateSettings(
                            prayers.settings.copyWith(method: m));
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
