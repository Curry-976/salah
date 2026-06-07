import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum TravelMode { driving, walking }

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMin;
  final TravelMode mode;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    required this.mode,
  });

  String get distanceLabel =>
      distanceKm < 1 ? '${(distanceKm * 1000).round()} m' : '${distanceKm.toStringAsFixed(1)} km';

  String get durationLabel {
    final min = durationMin.round();
    if (min < 60) return '${min} min';
    return '${min ~/ 60}h${(min % 60).toString().padLeft(2, '0')}';
  }
}

class RouteService {
  RouteService._();
  static final instance = RouteService._();

  static const _baseUrl = 'https://router.project-osrm.org/route/v1';

  Future<RouteResult?> getRoute({
    required LatLng from,
    required LatLng to,
    TravelMode mode = TravelMode.driving,
  }) async {
    // OSRM demo profiles: 'driving', 'cycling', 'foot' (not 'walking')
    final profile = switch (mode) {
      TravelMode.driving => 'driving',
      TravelMode.walking => 'foot',
    };
    final url =
        '$_baseUrl/$profile/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?geometries=geojson&overview=full';

    try {
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final coords = (route['geometry']['coordinates'] as List)
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      final leg = (route['legs'] as List)[0] as Map<String, dynamic>;
      return RouteResult(
        points: coords,
        distanceKm: (leg['distance'] as num).toDouble() / 1000,
        durationMin: (leg['duration'] as num).toDouble() / 60,
        mode: mode,
      );
    } catch (_) {
      return null;
    }
  }
}
