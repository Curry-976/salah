class Mosque {
  final String name;
  final String sector;
  final double lat;
  final double lng;

  const Mosque({
    required this.name,
    required this.sector,
    required this.lat,
    required this.lng,
  });
}

enum MosqueSource { api, cache, fallback }

class MosqueResult {
  final List<Mosque> mosques;
  final MosqueSource source;
  const MosqueResult(this.mosques, this.source);
}
