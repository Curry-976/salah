import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../data/mosques_data.dart';
import '../models/mosque_model.dart';
import '../services/mosque_service.dart';
import '../services/location_service.dart';
import '../utils/theme.dart';

class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen> {
  final MapController _mapController = MapController();
  Mosque? _selectedMosque;
  String? _filterSector;

  List<Mosque> _mosques = mosqueesMayotte;
  MosqueSource _source = MosqueSource.fallback;
  bool _isLoading = false;

  static const _mayotteCenter = LatLng(-12.8275, 45.1662);

  @override
  void initState() {
    super.initState();
    _loadMosques();
  }

  Future<void> _loadMosques({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final result = await MosqueService.instance.getMosques(forceRefresh: forceRefresh);
    if (mounted) {
      setState(() {
        _mosques = result.mosques;
        _source = result.source;
        _isLoading = false;
        if (forceRefresh) _filterSector = null;
      });
    }
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
          if (_isLoading)
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
              onTap: (_, __) => setState(() => _selectedMosque = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mayotte.salah',
              ),
              MarkerLayer(markers: [
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
                ..._filtered.map((mosque) => Marker(
                      point: LatLng(mosque.lat, mosque.lng),
                      width: 38,
                      height: 38,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedMosque = mosque),
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
          // Bandeau source + compteur
          Positioned(
            top: 8,
            left: 8,
            right: 60,
            child: _SourceBanner(
                count: _filtered.length, source: _source),
          ),
          // Fiche mosquée sélectionnée
          if (_selectedMosque != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: _MosqueInfoCard(
                mosque: _selectedMosque!,
                userLat: location.latitude,
                userLng: location.longitude,
                onClose: () =>
                    setState(() => _selectedMosque = null),
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

class _SourceBanner extends StatelessWidget {
  final int count;
  final MosqueSource source;
  const _SourceBanner({required this.count, required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      MosqueSource.api     => ('OpenStreetMap', Colors.green.shade700),
      MosqueSource.cache   => ('Cache OSM', Colors.orange.shade700),
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

class _MosqueInfoCard extends StatelessWidget {
  final Mosque mosque;
  final double? userLat;
  final double? userLng;
  final VoidCallback onClose;

  const _MosqueInfoCard(
      {required this.mosque,
      this.userLat,
      this.userLng,
      required this.onClose});

  String _distance() {
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
    final dist = _distance();
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            const Text('🕌', style: TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mosque.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(mosque.sector,
                        style: const TextStyle(
                            color: AppColors.gold, fontSize: 13)),
                    if (dist.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.directions_walk,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(dist,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ]),
                ],
              ),
            ),
            IconButton(
                icon: const Icon(Icons.close), onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
