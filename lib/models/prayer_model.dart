import 'package:adhan/adhan.dart';

enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerNameExtension on PrayerName {
  String get displayName {
    switch (this) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.sunrise:
        return 'Lever du soleil';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isha:
        return 'Isha';
    }
  }

  String get arabicName {
    switch (this) {
      case PrayerName.fajr:
        return 'الفجر';
      case PrayerName.sunrise:
        return 'الشروق';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  bool get isObligatory => this != PrayerName.sunrise;
}

class PrayerTime {
  final PrayerName name;
  final DateTime time;
  final bool isNext;
  final bool isPast;

  const PrayerTime({
    required this.name,
    required this.time,
    this.isNext = false,
    this.isPast = false,
  });
}

class PrayerSettings {
  final CalculationMethod method;
  final Madhab madhab;
  final bool notificationsEnabled;

  const PrayerSettings({
    this.method = CalculationMethod.muslim_world_league,
    this.madhab = Madhab.shafi,
    this.notificationsEnabled = true,
  });

  PrayerSettings copyWith({
    CalculationMethod? method,
    Madhab? madhab,
    bool? notificationsEnabled,
  }) {
    return PrayerSettings(
      method: method ?? this.method,
      madhab: madhab ?? this.madhab,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
