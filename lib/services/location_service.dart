import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  String _cityName = '';
  String _error = '';
  bool _isLoading = false;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get cityName => _cityName;
  String get error => _error;
  bool get isLoading => _isLoading;
  bool get hasLocation => _latitude != null && _longitude != null;

  Future<void> fetchLocation() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Permission de localisation refusée';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Veuillez activer la localisation dans les réglages';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      await _fetchCityName();
    } catch (e) {
      _error = 'Impossible d\'obtenir la position';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCityName() async {
    if (_latitude == null || _longitude == null) return;
    try {
      final placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _cityName = place.locality ?? place.administrativeArea ?? place.country ?? '';
      }
    } catch (_) {
      _cityName = '';
    }
  }

  void setManualLocation(double lat, double lng, String city) {
    _latitude = lat;
    _longitude = lng;
    _cityName = city;
    _error = '';
    notifyListeners();
  }
}
