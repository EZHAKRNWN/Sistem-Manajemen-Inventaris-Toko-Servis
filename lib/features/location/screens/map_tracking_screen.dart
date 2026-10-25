// ============================================================================
// FITUR: LBS PELACAKAN LOKASI GUDANG & NAVIGASI RUTE (MAP TRACKING SCREEN)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Location-Based Service (LBS): Mendeteksi titik koordinat GPS real-time teknisi menggunakan 'geolocator'.
// 2. Integrasi Peta Digital: Menampilkan peta interaktif OpenStreetMap (OSM) via 'flutter_map' tanpa biaya API berbayar.
// 3. Jaringan Titik Distribusi DIY: 6 titik gudang suku cadang tersebar di Sleman, Kota Yogya, Bantul, dan Gunungkidul.
// 4. Kalkulasi Rute Jalan Raya (OSRM Engine): Menghitung jarak jalan (km), estimasi waktu tempuh (ETA),
//    serta menggambar Polyline rute navigasi jalan raya yang akurat.
// 5. Eksternal Navigasi: Integrasi peluncuran rute langsung ke aplikasi Google Maps bawaan HP (url_launcher).
// ============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// MODEL DATA: Merepresentasikan entitas titik lokasi fisik gudang/depo suku cadang
class WarehouseLocation {
  final String id;
  final String name;
  final String category;
  final String address;
  final String district;
  final LatLng coordinate;
  final String phone;
  final String hours;
  final String stockInfo;
  final IconData icon;

  const WarehouseLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.district,
    required this.coordinate,
    required this.phone,
    required this.hours,
    required this.stockInfo,
    this.icon = Icons.warehouse_rounded,
  });
}

class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentPosition = const LatLng(-7.7956, 110.3695);
  WarehouseLocation? _selectedWarehouse;

  bool _isLoadingGps = false;
  bool _showSearchResults = false;
  String _statusText = 'Pilih gudang untuk melihat detail & rute';
  double? _distanceKm;
  int? _etaMinutes;

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  static const List<WarehouseLocation> _warehouses = [
    WarehouseLocation(
      id: 'GDG-01',
      name: 'Gudang Pusat Sparepart SmartFix',
      category: 'Layar OLED, LCD & Baterai',
      address: 'Jl. Magelang KM 5, Sinduadi, Mlati, Sleman',
      district: 'Sleman',
      coordinate: LatLng(-7.7512, 110.3603),
      phone: '+62 274 555-0101',
      hours: 'Senin–Sabtu, 08.00–17.00',
      stockInfo: 'Stok Lengkap (500+ SKU)',
      icon: Icons.warehouse_rounded,
    ),
    WarehouseLocation(
      id: 'GDG-02',
      name: 'Depo Komponen Elekronik Malioboro',
      category: 'IC Chip, Motherboard & Alat Servis',
      address: 'Jl. Malioboro No. 47, Gedongtengen, Yogyakarta',
      district: 'Kota Yogyakarta',
      coordinate: LatLng(-7.7920, 110.3658),
      phone: '+62 274 512-3456',
      hours: 'Setiap Hari, 09.00–20.00',
      stockInfo: 'Tersedia (IC OEM & Solder)',
      icon: Icons.store_rounded,
    ),
    WarehouseLocation(
      id: 'GDG-03',
      name: 'Hub Sparepart HP Amplaz Ambarrukmo',
      category: 'Kasing, Kamera & Port Charger',
      address: 'Jl. Laksda Adisucipto KM 6, Ambarrukmo, Sleman',
      district: 'Sleman',
      coordinate: LatLng(-7.7833, 110.3981),
      phone: '+62 274 488-7700',
      hours: 'Senin–Minggu, 10.00–21.00',
      stockInfo: 'Tersedia (Aksesoris & Casing)',
      icon: Icons.shopping_bag_rounded,
    ),
    WarehouseLocation(
      id: 'GDG-04',
      name: 'Depo Suku Cadang Bantul Elektronik',
      category: 'Baterai, Fleksibel & Mikrofon',
      address: 'Jl. Parangtritis KM 3, Sewon, Bantul',
      district: 'Bantul',
      coordinate: LatLng(-7.8407, 110.3648),
      phone: '+62 274 367-8899',
      hours: 'Senin–Sabtu, 08.30–16.30',
      stockInfo: 'Tersedia (Stok Reguler)',
      icon: Icons.electrical_services_rounded,
    ),
    WarehouseLocation(
      id: 'GDG-05',
      name: 'Pusat Distribusi Godean Tech',
      category: 'Alat Diagnostik & Mikroskop Servis',
      address: 'Jl. Godean KM 4, Sidoarum, Sleman',
      district: 'Sleman',
      coordinate: LatLng(-7.7812, 110.3233),
      phone: '+62 274 620-1122',
      hours: 'Senin–Jumat, 08.00–16.00',
      stockInfo: 'Tersedia (Peralatan Profesional)',
      icon: Icons.build_circle_rounded,
    ),
    WarehouseLocation(
      id: 'GDG-06',
      name: 'Gudang Sparepart Wonosari Gunungkidul',
      category: 'Panel LCD, Touch Screen & Speaker',
      address: 'Jl. Wonosari KM 15, Piyungan, Bantul',
      district: 'Gunungkidul',
      coordinate: LatLng(-7.8512, 110.4598),
      phone: '+62 274 391-5544',
      hours: 'Senin–Sabtu, 08.00–15.00',
      stockInfo: 'Tersedia (Pengiriman 1-2 Hari)',
      icon: Icons.inventory_2_rounded,
    ),
  ];

  List<WarehouseLocation> _filteredWarehouses = [];

  @override
  void initState() {
    super.initState();
    _filteredWarehouses = List.from(_warehouses);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determinePosition();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _calculateRouteDetails(WarehouseLocation warehouse) {
    final distanceMeters = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      warehouse.coordinate.latitude,
      warehouse.coordinate.longitude,
    );

    setState(() {
      _distanceKm = distanceMeters / 1000.0;

      _etaMinutes = ((_distanceKm! / 28.0) * 60).round() + 5;
    });
  }

  /// FITUR: Deteksi Lokasi Pengguna via Sensor GPS (Geolocator)
  /// Memeriksa service status, meminta runtime permission, dan mengambil koordinat GPS terkini
  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingGps = true;
      _statusText = 'Mendeteksi koordinat GPS Anda...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingGps = false;
          _statusText = 'GPS nonaktif — menampilkan pusat kota Yogyakarta';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingGps = false;
            _statusText = 'Izin lokasi ditolak';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingGps = false;
          _statusText = 'Izin lokasi ditolak permanen';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingGps = false;
        _statusText =
            'Lokasi Anda: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });

      if (_selectedWarehouse != null) {
        _calculateRouteDetails(_selectedWarehouse!);
        _fetchRoadRoute(_selectedWarehouse!);
      }
      _mapController.move(_currentPosition, 14.0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGps = false;
        _statusText = 'GPS error — menggunakan lokasi default Yogyakarta';
      });
    }
  }

  /// FITUR: Routing Rute Jalan Raya Nyata menggunakan OSRM (Open Source Routing Machine)
  /// Mengambil geometri GeoJSON koordinat jalur jalan, jarak tempuh (meter), dan durasi (detik)
  Future<void> _fetchRoadRoute(WarehouseLocation warehouse) async {
    setState(() {
      _isLoadingRoute = true;
      _routePoints = [_currentPosition, warehouse.coordinate];
      _statusText = 'Menghitung rute jalan ke ${warehouse.name}...';
    });

    final origin = _currentPosition;
    final dest = warehouse.coordinate;
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};${dest.longitude},${dest.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coords = geometry['coordinates'] as List<dynamic>;

          final List<LatLng> points = coords.map((c) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          final double distMeters =
              (route['distance'] as num?)?.toDouble() ?? 0;
          final double durSeconds =
              (route['duration'] as num?)?.toDouble() ?? 0;

          if (mounted && _selectedWarehouse?.id == warehouse.id) {
            setState(() {
              _routePoints = points;
              if (distMeters > 0) {
                _distanceKm = distMeters / 1000.0;
                _etaMinutes = (durSeconds / 60.0).round().clamp(1, 999);
              }
              _statusText =
                  'Rute jalan aktif (${_distanceKm?.toStringAsFixed(1)} km, ~$_etaMinutes mnt)';
              _isLoadingRoute = false;
            });

            _mapController.fitCamera(
              CameraFit.coordinates(
                coordinates: points.isNotEmpty
                    ? points
                    : [_currentPosition, warehouse.coordinate],
                padding: const EdgeInsets.only(
                  top: 90,
                  bottom: 270,
                  left: 40,
                  right: 40,
                ),
              ),
            );
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted && _selectedWarehouse?.id == warehouse.id) {
      setState(() {
        _isLoadingRoute = false;
        _routePoints = [_currentPosition, warehouse.coordinate];
        _statusText = 'Gudang dipilih: ${warehouse.name}';
      });

      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [_currentPosition, warehouse.coordinate],
          padding: const EdgeInsets.only(
            top: 90,
            bottom: 270,
            left: 40,
            right: 40,
          ),
        ),
      );
    }
  }

  void _selectWarehouse(WarehouseLocation warehouse) {
    setState(() {
      _selectedWarehouse = warehouse;
      _showSearchResults = false;
      _searchController.clear();
      _statusText = 'Gudang dipilih: ${warehouse.name}';
    });
    _calculateRouteDetails(warehouse);
    _fetchRoadRoute(warehouse);
    FocusScope.of(context).unfocus();
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    setState(() {
      _showSearchResults = trimmed.isNotEmpty;
      _filteredWarehouses = _warehouses.where((w) {
        final lower = trimmed.toLowerCase();
        return w.name.toLowerCase().contains(lower) ||
            w.address.toLowerCase().contains(lower) ||
            w.category.toLowerCase().contains(lower) ||
            w.district.toLowerCase().contains(lower);
      }).toList();
    });
  }

  Future<void> _openInGoogleMaps(WarehouseLocation warehouse) async {
    final lat = warehouse.coordinate.latitude;
    final lng = warehouse.coordinate.longitude;
    final origin = '${_currentPosition.latitude},${_currentPosition.longitude}';
    final destination = '$lat,$lng';
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$origin'
      '&destination=$destination'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final fallback = Uri.parse(
        'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(warehouse.name)})',
      );
      if (await canLaunchUrl(fallback)) {
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
          );
        }
      }
    }
  }

  void _centerMap() {
    if (_selectedWarehouse != null) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [_currentPosition, _selectedWarehouse!.coordinate],
          padding: const EdgeInsets.only(
            top: 80,
            bottom: 260,
            left: 40,
            right: 40,
          ),
        ),
      );
    } else {
      _mapController.move(_currentPosition, 13.0);
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Gudang Sparepart'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Pusatkan Peta',
            icon: const Icon(Icons.fit_screen_rounded),
            onPressed: _centerMap,
          ),
          IconButton(
            tooltip: 'Deteksi Lokasi Saya',
            icon: _isLoadingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            onPressed: _isLoadingGps ? null : _determinePosition,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-7.7956, 110.3695),
              initialZoom: 12.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartfix.mobile',
              ),

              if (_selectedWarehouse != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints.isNotEmpty
                          ? _routePoints
                          : [_currentPosition, _selectedWarehouse!.coordinate],
                      strokeWidth: 5.0,
                      color: const Color(0xFF0F766E),
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                      pattern: _routePoints.isEmpty
                          ? StrokePattern.dashed(segments: const [12, 8])
                          : const StrokePattern.solid(),
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 56,
                    height: 56,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  ..._warehouses.map(
                    (w) => Marker(
                      point: w.coordinate,
                      width: 52,
                      height: 52,
                      child: GestureDetector(
                        onTap: () => _selectWarehouse(w),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _selectedWarehouse?.id == w.id
                                    ? Colors.redAccent.shade700
                                    : const Color(0xFF1E40AF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: _selectedWarehouse?.id == w.id
                                      ? 2.5
                                      : 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                w.icon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Material(
                  elevation: 6,
                  shadowColor: Colors.black38,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari gudang sparepart di Yogyakarta...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF0F766E),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _showSearchResults = false);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                if (_showSearchResults)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _filteredWarehouses.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Text(
                              'Gudang tidak ditemukan. Coba nama kecamatan atau kategori suku cadang.',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _filteredWarehouses.length,
                            separatorBuilder: (ctx, idx) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _filteredWarehouses[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF1E40AF)
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    item.icon,
                                    color: const Color(0xFF1E40AF),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.district} • ${item.category}',
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                ),
                                onTap: () => _selectWarehouse(item),
                              );
                            },
                          ),
                  ),

                if (!_showSearchResults && _statusText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoadingRoute) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          const Icon(
                            Icons.alt_route_rounded,
                            size: 14,
                            color: Color(0xFF0F766E),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            _statusText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            right: 14,
            bottom: _selectedWarehouse != null ? 265 : 24,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'fab_zoom_in',
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom + 1);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_zoom_out',
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom - 1);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_gps',
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  onPressed: _isLoadingGps ? null : _determinePosition,
                  child: _isLoadingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.gps_fixed_rounded),
                ),
              ],
            ),
          ),

          if (_selectedWarehouse != null)
            Positioned(
              bottom: 16,
              left: 14,
              right: 14,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E40AF)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'GUDANG SUKU CADANG',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_distanceKm != null)
                            Text(
                              '${_distanceKm!.toStringAsFixed(1)} km  (~${_etaMinutes ?? 0} menit)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _selectedWarehouse!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _selectedWarehouse!.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedWarehouse!.address,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedWarehouse!.hours,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy_rounded, size: 15),
                              label: const Text(
                                'Salin Lokasi',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                final text =
                                    '${_selectedWarehouse!.name}\n${_selectedWarehouse!.address}\n'
                                    '${_selectedWarehouse!.coordinate.latitude.toStringAsFixed(6)}, '
                                    '${_selectedWarehouse!.coordinate.longitude.toStringAsFixed(6)}';
                                Clipboard.setData(ClipboardData(text: text));
                                _showSnackBar(
                                  'Info gudang disalin ke clipboard',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Buka Google Maps',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () =>
                                  _openInGoogleMaps(_selectedWarehouse!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_selectedWarehouse == null)
            Positioned(
              bottom: 24,
              left: 14,
              right: 14,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.touch_app_rounded,
                        color: Color(0xFF1E40AF),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Ketuk marker 🔵 pada peta atau cari nama gudang\nuntuk melihat detail & rute ke Google Maps',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
