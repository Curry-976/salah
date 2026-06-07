# Salah — Application de prière Flutter

Application mobile Flutter de prière islamique inspirée de RunSalah.

## Fonctionnalités
- Horaires de prière (Fajr, Dhuhr, Asr, Maghrib, Isha) calculés par GPS
- Direction Qibla avec boussole interactive
- Notifications Adhan locales à chaque heure de prière
- Calendrier hégirien avec événements islamiques

## Stack technique
- Flutter + Dart
- `adhan` — calcul des horaires selon méthodes islamiques
- `flutter_qiblah` + `flutter_compass` — direction Qibla
- `flutter_local_notifications` — notifications Adhan
- `hijri` — conversions calendrier hégirien
- `geolocator` — position GPS
- `provider` — gestion d'état

## Structure
```
lib/
  main.dart
  models/         — prayer_model.dart
  services/       — prayer_service, location_service, notification_service
  screens/        — home, qibla, calendar, settings
  widgets/        — next_prayer_banner, prayer_list, hijri_date_card
  utils/          — theme, prayer_formatter
```

## Démarrage
```bash
flutter pub get
flutter run
```

## Permissions requises
- iOS: NSLocationWhenInUseUsageDescription (Info.plist)
- Android: ACCESS_FINE_LOCATION, SCHEDULE_EXACT_ALARM (AndroidManifest.xml)
