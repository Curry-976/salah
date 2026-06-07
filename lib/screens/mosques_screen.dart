import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mosques_data.dart';
import '../models/mosque_model.dart';
import '../services/mosque_service.dart';
import '../services/route_service.dart';
import '../services/location_service.dart';
import '../utils/theme.dart';

class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  final MapController _mapController = MapController();

  List<Mosque> _mosques = mosqueesMayotte;
  MosqueSource _source = MosqueSource.fallback;
  bool _isLoadingMosques = false;

  Mosque? _selectedMosque;
  String? _filterSector;

  RouteResult? _route;
  bool _isRoutingLoading = false;
  TravelMode _travelMode = TravelMode.driving;

  static const _mayotteCenter = LatLng(-12.8275, 45.1662);

  @override
  void initState() {
    super.initState();
    _loadMosques();
  }

  Future<void> _loadMosques({bool forceRefresh = false}) async {
    setState(() => _isLoadingMosques = true);
    final result = await MosqueService.instance.getMosques(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _mosques = result.mosques;
        _source = result.source;
        _isLoadingMosques = false;
        if (forceRefresh) _filterSector = null;
      });
    }
  }

  Future<void> _fetchRoute(LocationService location) async {
    if (!location.hasLocation || _selectedMosque == null) return;
    setState(() => _isRoutingLoading = true);

    final result = await RouteService.instance.getRoute(
      from: LatLng(location.latitude!, location.longitude!),
      to: LatLng(_selectedMosque!.lat, _selectedMosque!.lng),
      mode: _travelMode,
    );

    if (mounted) {
      setState(() {
        _route = result;
        _isRoutingLoading = false;
      });
      if (result != null) _fitRoute(result, location);
    }
  }

  void _fitRoute(RouteResult route, LocationService location) {
    if (route.points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(route.points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  void _clearRoute() => setState(() => _route = null);

  Future<void> _openNavigation(Mosque mosque) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${mosque.lat},${mosque.lng}&travelmode=${_travelMode == TravelMode.driving ? 'driving' : 'walking'}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<Mosque> get _filtered => _filterSector == null
      ? _mosques
      : _mosques.where((m) => m.sector == _filterSector).toList();

  List<String> get _sectors =>
      _mosques.map((m) => m.sector).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mosquées de Mayotte'),
        actions: [
          if (_isLoadingMosques)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser depuis OpenStreetMap',
              onPressed: () => _loadMosques(forceRefresh: true),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _SectorFilter(
            sectors: _sectors,
            selected: _filterSector,
            onSelected: (s) => setState(() {
              _filterSector = s == _filterSector ? null : s;
              _selectedMosque = null;
              _clearRoute();
            }),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mayotteCenter,
              initialZoom: 11.0,
              onTap: (_, __) {
                setState(() {
                  _selectedMosque = null;
                  _clearRoute();
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mayotte.salah',
              ),
              // Tracé de l'itinéraire
              if (_route != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.points,
                      color: Colors.blue.shade700,
                      strokeWidth: 5,
                    ),
                    // Bordure blanche pour lisibilité
                    Polyline(
                      points: _route!.points,
                      color: Colors.white.withOpacity(0.5),
                      strokeWidth: 8,
                    ),
                  ],
                ),
              MarkerLayer(markers: [
                // Position utilisateur
                if (location.hasLocation)
                  Marker(
                    point: LatLng(location.latitude!, location.longitude!),
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 10)
                        ],
                      ),
                    ),
                  ),
                // Marqueurs mosquées
                ..._filtered.map((mosque) => Marker(
                      point: LatLng(mosque.lat, mosque.lng),
                      width: 38,
                      height: 38,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMosque = mosque;
                            _clearRoute();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _selectedMosque == mosque
                                ? AppColors.gold
                                : AppColors.green,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: (_selectedMosque == mosque
                                        ? AppColors.gold
                                        : AppColors.green)
                                    .withOpacity(0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🕌',
                                style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ),
                    )),
              ]),
            ],
          ),
          // Bandeau source
          Positioned(
            top: 8,
            left: 8,
            right: 60,
            child: _SourceBanner(count: _filtered.length, source: _source),
          ),
          // Fiche mosquée + itinéraire
          if (_selectedMosque != null)
            Positioned(
              bottom: 80,
              left: 12,
              right: 12,
              child: _MosqueCard(
                mosque: _selectedMosque!,
                userLat: location.latitude,
                userLng: location.longitude,
                route: _route,
                isRoutingLoading: _isRoutingLoading,
                travelMode: _travelMode,
                onClose: () {
                  setState(() {
                    _selectedMosque = null;
                    _clearRoute();
                  });
                },
                onGetRoute: () => _fetchRoute(location),
                onNavigate: () => _openNavigation(_selectedMosque!),
                onModeChanged: (mode) {
                  setState(() {
                    _travelMode = mode;
                    _clearRoute();
                  });
                },
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'center_mayotte',
            onPressed: () => _mapController.move(_mayotteCenter, 11.0),
            backgroundColor: Colors.white,
            child: const Icon(Icons.map, color: AppColors.green),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: () {
              if (location.hasLocation) {
                _mapController.move(
                    LatLng(location.latitude!, location.longitude!), 14.0);
              }
            },
            backgroundColor: AppColors.green,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _MosqueCard extends StatelessWidget {
  final Mosque mosque;
  final double? userLat;
  final double? userLng;
  final RouteResult? route;
  final bool isRoutingLoading;
  final TravelMode travelMode;
  final VoidCallback onClose;
  final VoidCallback onGetRoute;
  final VoidCallback onNavigate;
  final void Function(TravelMode) onModeChanged;

  const _MosqueCard({
    required this.mosque,
    this.userLat,
    this.userLng,
    this.route,
    required this.isRoutingLoading,
    required this.travelMode,
    required this.onClose,
    required this.onGetRoute,
    required this.onNavigate,
    required this.onModeChanged,
  });

  String _straightDistance() {
    if (userLat == null || userLng == null) return '';
    const d = Distance();
    final km = d.as(LengthUnit.Kilometer, LatLng(userLat!, userLng!),
        LatLng(mosque.lat, mosque.lng));
    return km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Text('🕌', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mosque.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 13, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text(mosque.sector,
                            style: const TextStyle(
                                color: AppColors.gold, fontSize: 12)),
                        if (_straightDistance().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.straighten,
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(_straightDistance(),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ]),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onClose,
                    padding: EdgeInsets.zero),
              ],
            ),
            const SizedBox(height: 8),
            // Sélecteur de mode
            Row(
              children: [
                _ModeChip(
                  icon: Icons.directions_car,
                  label: 'Voiture',
                  selected: travelMode == TravelMode.driving,
                  onTap: () => onModeChanged(TravelMode.driving),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  icon: Icons.directions_walk,
                  label: 'À pied',
                  selected: travelMode == TravelMode.walking,
                  onTap: () => onModeChanged(TravelMode.walking),
                ),
              ],
            ),
            // Infos de route si disponible
            if (route != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _RouteInfo(
                        icon: Icons.route,
                        value: route!.distanceLabel,
                        label: 'Distance'),
                    _RouteInfo(
                        icon: Icons.access_time,
                        value: route!.durationLabel,
                        label: 'Durée estimée'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRoutingLoading ? null : onGetRoute,
                    icon: isRoutingLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.alt_route, size: 18),
                    label: Text(
                        route != null ? 'Recalculer' : 'Itinéraire'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Naviguer'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withOpacity(0.15)
              : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.green : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: selected ? AppColors.green : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color:
                        selected ? AppColors.green : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _RouteInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _RouteInfo(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontSize: 15)),
          ],
        ),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _SourceBanner extends StatelessWidget {
  final int count;
  final MosqueSource source;
  const _SourceBanner({required this.count, required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      MosqueSource.api => ('OpenStreetMap', Colors.green.shade700),
      MosqueSource.cache => ('Cache OSM', Colors.orange.shade700),
      MosqueSource.fallback => ('Liste de base', Colors.grey.shade600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            '$count mosquée${count > 1 ? "s" : ""} · $label',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}

class _SectorFilter extends StatelessWidget {
  final List<String> sectors;
  final String? selected;
  final void Function(String) onSelected;

  const _SectorFilter(
      {required this.sectors,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: sectors
            .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    selected: selected == s,
                    onSelected: (_) => onSelected(s),
                    selectedColor: AppColors.green.withOpacity(0.2),
                    checkmarkColor: AppColors.green,
                    side: BorderSide(
                        color: selected == s
                            ? AppColors.green
                            : Colors.grey.withOpacity(0.4)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
