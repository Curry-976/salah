import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService extends ChangeNotifier {
  // Fallback : centre de Mayotte (Mamoudzou)
  static const double _defaultLat = -12.7806;
  static const double _defaultLng = 45.2278;

  double? _latitude;
  double? _longitude;
  String _cityName = '';
  String _error = '';
  bool _isLoading = false;
  bool _isUsingFallback = false;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get cityName => _cityName;
  String get error => _error;
  bool get isLoading => _isLoading;
  bool get isUsingFallback => _isUsingFallback;
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
          _useFallback();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallback();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _isUsingFallback = false;

      if (!kIsWeb) {
        await _fetchCityName();
      }
    } catch (e) {
      _useFallback();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _useFallback() {
    _latitude = _defaultLat;
    _longitude = _defaultLng;
    _cityName = 'Mayotte';
    _error = '';
    _isLoading = false;
    _isUsingFallback = true;
  }

  Future<void> _fetchCityName() async {
    if (_latitude == null || _longitude == null) return;
    try {
      final placemarks = await placemarkFromCoordinates(_latitude!, _longitude!);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _cityName = place.locality ?? place.administrativeArea ?? 'Mayotte';
      }
    } catch (_) {
      _cityName = 'Mayotte';
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
