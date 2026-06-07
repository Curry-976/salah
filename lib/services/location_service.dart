import 'package:flutter/foundation.dart';

class LocationService extends ChangeNotifier {
  // Coordonnées fixes : Mamoudzou, Mayotte
  static const double _lat = -12.7806;
  static const double _lng = 45.2278;

  double get latitude => _lat;
  double get longitude => _lng;
  String get cityName => 'Mayotte';
  String get error => '';
  bool get isLoading => false;
  bool get hasLocation => true;

  Future<void> fetchLocation() async {
    notifyListeners();
  }
}
