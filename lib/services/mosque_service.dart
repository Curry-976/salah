import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mosque_model.dart';
import '../data/mosques_data.dart';

class MosqueService {
  MosqueService._();
  static final instance = MosqueService._();

  static const _cacheKey = 'mosques_v1';
  static const _cacheTimestampKey = 'mosques_ts_v1';
  static const _cacheTtlMs = 7 * 24 * 60 * 60 * 1000; // 7 jours

  // Endpoints Overpass avec fallback
  static const _overpassUrls = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  // Bounding box Mayotte : S, W, N, E
  static const _query = r'''
[out:json][timeout:30];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](-13.1,44.9,-12.5,45.4);
  way["amenity"="place_of_worship"]["religion"="muslim"](-13.1,44.9,-12.5,45.4);
);
out center;
''';

  Future<MosqueResult> getMosques({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _loadCache();
      if (cached != null) return MosqueResult(cached, MosqueSource.cache);
    }
    try {
      final fresh = await _fetchOverpass();
      if (fresh.isNotEmpty) {
        await _saveCache(fresh);
        return MosqueResult(fresh, MosqueSource.api);
      }
    } catch (_) {}
    return MosqueResult(mosqueesMayotte, MosqueSource.fallback);
  }

  Future<List<Mosque>?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cacheTimestampKey) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - ts > _cacheTtlMs) return null;
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Mosque(
                name: e['name'] as String,
                sector: e['sector'] as String,
                lat: (e['lat'] as num).toDouble(),
                lng: (e['lng'] as num).toDouble(),
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(List<Mosque> mosques) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(mosques
          .map((m) => {
                'name': m.name,
                'sector': m.sector,
                'lat': m.lat,
                'lng': m.lng,
              })
          .toList()),
    );
    await prefs.setInt(
        _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Mosque>> _fetchOverpass() async {
    final body = 'data=${Uri.encodeComponent(_query)}';
    final headers = {'Content-Type': 'application/x-www-form-urlencoded'};

    for (final url in _overpassUrls) {
      try {
        final resp = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(const Duration(seconds: 35));
        if (resp.statusCode != 200) continue;
        return _parseOverpassResponse(resp.body);
      } catch (_) {
        continue;
      }
    }
    throw Exception('Tous les endpoints Overpass ont échoué');
  }

  List<Mosque> _parseOverpassResponse(String body) {
    final elements = jsonDecode(body)['elements'] as List;
    final result = <Mosque>[];

    for (final el in elements) {
      double? lat, lng;
      if (el['type'] == 'node') {
        lat = (el['lat'] as num?)?.toDouble();
        lng = (el['lon'] as num?)?.toDouble();
      } else {
        lat = (el['center']?['lat'] as num?)?.toDouble();
        lng = (el['center']?['lon'] as num?)?.toDouble();
      }
      if (lat == null || lng == null) continue;

      final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
      final name = (tags['name:fr'] ?? tags['name'] ?? 'Mosquée').toString();
      final sector = (tags['addr:city'] ??
              tags['addr:suburb'] ??
              _communeFromCoords(lat, lng))
          .toString();

      result.add(Mosque(name: name, sector: sector, lat: lat, lng: lng));
    }
    return result;
  }

  // 15 communes de Mayotte avec leurs centres géographiques approximatifs
  static const _communes = [
    ('Mamoudzou',       -12.782, 45.228),
    ('Koungou',         -12.731, 45.207),
    ('Bandraboua',      -12.734, 45.248),
    ('Tsingoni',        -12.767, 45.117),
    ("M'Tsangamouji",   -12.753, 45.117),
    ('Acoua',           -12.730, 45.064),
    ('Mtsamboro',       -12.688, 45.083),
    ('Ouangani',        -12.850, 45.200),
    ('Dembeni',         -12.833, 45.233),
    ('Sada',            -12.848, 45.107),
    ('Chirongui',       -12.921, 45.140),
    ('Kani-Kéli',       -12.898, 45.119),
    ('Bouéni',          -12.950, 45.000),
    ('Dzaoudzi',        -12.783, 45.267),
    ('Pamandzi',        -12.795, 45.285),
  ];

  static String _communeFromCoords(double lat, double lng) {
    var minDist = double.infinity;
    var closest = 'Mayotte';
    for (final (name, clat, clng) in _communes) {
      final d = (lat - clat) * (lat - clat) + (lng - clng) * (lng - clng);
      if (d < minDist) {
        minDist = d;
        closest = name;
      }
    }
    return closest;
  }
}
