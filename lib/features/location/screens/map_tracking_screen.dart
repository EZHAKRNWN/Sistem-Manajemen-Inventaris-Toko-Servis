import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class SupplierLocation {
  final String id;
  final String name;
  final String category;
  final String address;
  final String city;
  final LatLng coordinate;
  final String phone;
  final String stockStatus;

  const SupplierLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.coordinate,
    required this.phone,
    required this.stockStatus,
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

  // Jakarta Pusat SmartFix central service hub
  LatLng _currentPosition = const LatLng(-6.175392, 106.827153);
  LatLng? _selectedDestination = const LatLng(-6.166250, 106.797820);
  String _destinationName = 'Roxy Square Spare Parts Mega Center';
  String _destinationAddress = 'Jl. Kyai Tapa No. 1, Tomang, Jakarta Barat';
  String _destinationCategory = 'Screens, OLEDs & Flex Cables';

  bool _isLoadingGps = false;
  bool _showSearchResults = false;
  String _statusText = 'GPS Ready. Tap pinpoint to detect current location.';
  double? _distanceKm;
  int? _etaMinutes;

  // Pre-loaded verified spare parts suppliers & regional workshop hubs
  final List<SupplierLocation> _verifiedSuppliers = const [
    SupplierLocation(
      id: 'SUP-01',
      name: 'Roxy Square Spare Parts Mega Center',
      category: 'Screens, OLEDs & Flex Cables',
      address: 'Jl. Kyai Tapa No. 1, Tomang, Jakarta Barat',
      city: 'Jakarta Barat',
      coordinate: LatLng(-6.166250, 106.797820),
      phone: '+62 21 5695-8888',
      stockStatus: 'In Stock (Direct Factory Stock)',
    ),
    SupplierLocation(
      id: 'SUP-02',
      name: 'Mangga Dua Smartphone Components Hub',
      category: 'Motherboards, Power ICs & SMD Stencils',
      address: 'Jl. Mangga Dua Raya, Mall Mangga Dua Lt. 4, Jakarta Utara',
      city: 'Jakarta Utara',
      coordinate: LatLng(-6.136820, 106.829410),
      phone: '+62 21 612-9900',
      stockStatus: 'In Stock (OEM ICs & Soldering Tools)',
    ),
    SupplierLocation(
      id: 'SUP-03',
      name: 'SmartFix Central Workshop & Tech Lab',
      category: 'Master Repair Lab & Dispatch Depot',
      address: 'Jl. Medan Merdeka Barat No. 21, Gambir, Jakarta Pusat',
      city: 'Jakarta Pusat',
      coordinate: LatLng(-6.175392, 106.827153),
      phone: '+62 21 345-0011',
      stockStatus: 'Operational (24/7 Dispatch)',
    ),
    SupplierLocation(
      id: 'SUP-04',
      name: 'ITC Cempaka Mas Spareparts Depo',
      category: 'Batteries, Housings & Camera Modules',
      address: 'Jl. Letjen Suprapto, Cempaka Putih, Jakarta Pusat',
      city: 'Jakarta Pusat',
      coordinate: LatLng(-6.164310, 106.878190),
      phone: '+62 21 4288-1122',
      stockStatus: 'In Stock (High Capacity Batteries)',
    ),
    SupplierLocation(
      id: 'SUP-05',
      name: 'Bandung Electronic Center (BEC) Hub',
      category: 'Connectors, Microphones & Charge Ports',
      address: 'Jl. Purnawarman No. 13-15, Babakan Ciamis, Bandung',
      city: 'Bandung',
      coordinate: LatLng(-6.903420, 107.608750),
      phone: '+62 22 420-5555',
      stockStatus: 'In Stock (Same-day Cargo)',
    ),
    SupplierLocation(
      id: 'SUP-06',
      name: 'Surabaya Hi-Tech Mall Logistics Depot',
      category: 'Heavy Diagnostic Benches & Microscope Units',
      address: 'Jl. Kusuma Bangsa No. 116, Tambaksari, Surabaya',
      city: 'Surabaya',
      coordinate: LatLng(-7.257500, 112.752100),
      phone: '+62 31 531-8899',
      stockStatus: 'In Stock (Regional Distribution)',
    ),
  ];

  List<SupplierLocation> _filteredSuppliers = [];

  @override
  void initState() {
    super.initState();
    _filteredSuppliers = List.from(_verifiedSuppliers);
    _calculateRouteDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _calculateRouteDetails() {
    if (_selectedDestination == null) return;

    final distanceMeters = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      _selectedDestination!.latitude,
      _selectedDestination!.longitude,
    );

    setState(() {
      _distanceKm = distanceMeters / 1000.0;
      // Urban motorcycle courier estimated speed: ~28 km/h + 5 min dispatch handling
      _etaMinutes = ((_distanceKm! / 28.0) * 60).round() + 5;
    });
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingGps = true;
      _statusText = 'Acquiring GPS fix via device sensors...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingGps = false;
          _statusText = 'Location services disabled. Please enable device GPS.';
        });
        _showSnackBar('Please enable device location services.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingGps = false;
            _statusText = 'Location permission denied by user.';
          });
          _showSnackBar('Location permission was denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingGps = false;
          _statusText = 'Location permissions permanently denied in app settings.';
        });
        _showSnackBar('Location permission permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final newCoord = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = newCoord;
        _isLoadingGps = false;
        _statusText =
            'Technician GPS: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });

      _calculateRouteDetails();
      _mapController.move(newCoord, 15.5);
      _showSnackBar('Current technician GPS coordinates acquired.');
    } catch (e) {
      setState(() {
        _isLoadingGps = false;
        _statusText = 'GPS Error: $e';
      });
      _showSnackBar('Failed to acquire GPS: $e');
    }
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();

    // Check if query is a direct coordinate string: "lat, lng"
    final coordRegex = RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$');
    if (coordRegex.hasMatch(trimmed)) {
      final parts = trimmed.split(',');
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        final customCoord = LatLng(lat, lng);
        _selectCoordinate(
          customCoord,
          'Custom GPS Coordinates',
          'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
          'Custom Manual Waypoint',
        );
        return;
      }
    }

    setState(() {
      _showSearchResults = trimmed.isNotEmpty;
      _filteredSuppliers = _verifiedSuppliers.where((supplier) {
        final lower = trimmed.toLowerCase();
        return supplier.name.toLowerCase().contains(lower) ||
            supplier.address.toLowerCase().contains(lower) ||
            supplier.category.toLowerCase().contains(lower) ||
            supplier.city.toLowerCase().contains(lower);
      }).toList();
    });
  }

  void _selectCoordinate(
    LatLng target,
    String name,
    String address,
    String category,
  ) {
    setState(() {
      _selectedDestination = target;
      _destinationName = name;
      _destinationAddress = address;
      _destinationCategory = category;
      _showSearchResults = false;
      _searchController.clear();
      _statusText = 'Target Supplier: $name';
    });

    _calculateRouteDetails();
    _mapController.move(target, 15.5);
    FocusScope.of(context).unfocus();
  }

  void _centerRoute() {
    if (_selectedDestination == null) {
      _mapController.move(_currentPosition, 15.0);
      return;
    }

    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [_currentPosition, _selectedDestination!],
        padding: const EdgeInsets.only(
          top: 100,
          bottom: 240,
          left: 50,
          right: 50,
        ),
      ),
    );
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
        title: const Text('Parts Delivery & GPS Tracking'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Fit Route in View',
            icon: const Icon(Icons.route_rounded),
            onPressed: _centerRoute,
          ),
          IconButton(
            tooltip: 'Locate Technician GPS',
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
          // ─── 1. Interactive Map ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 14.5,
              onTap: (_, point) {
                // Allow tapping anywhere to pick custom destination
                _selectCoordinate(
                  point,
                  'Selected Map Location',
                  'Lat: ${point.latitude.toStringAsFixed(5)}, Lng: ${point.longitude.toStringAsFixed(5)}',
                  'Custom Dropped Pin',
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartfix.mobile',
              ),

              // Polyline Route from Technician to Supplier
              if (_selectedDestination != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_currentPosition, _selectedDestination!],
                      strokeWidth: 4.5,
                      color: const Color(0xFF0F766E),
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Markers Layer
              MarkerLayer(
                markers: [
                  // Technician Marker
                  Marker(
                    point: _currentPosition,
                    width: 54,
                    height: 54,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bike_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Destination Supplier Marker
                  if (_selectedDestination != null)
                    Marker(
                      point: _selectedDestination!,
                      width: 54,
                      height: 54,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.shade700,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ─── 2. Top Search & Auto-Suggest Bar ────────────────────────────
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
                      hintText: 'Search supplier, workshop or paste coordinates...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0F766E)),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ),

                // Search Results Dropdown List
                if (_showSearchResults)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: _filteredSuppliers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Text(
                              'No matching supplier found. You can enter "lat, lng" coordinates directly.',
                              style: TextStyle(fontSize: 12),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _filteredSuppliers.length,
                            separatorBuilder: (ctx, idx) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _filteredSuppliers[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0x1F0F766E),
                                  child: Icon(Icons.store, color: Color(0xFF0F766E), size: 18),
                                ),
                                title: Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${item.city} • ${item.category}',
                                  style: const TextStyle(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                                onTap: () => _selectCoordinate(
                                  item.coordinate,
                                  item.name,
                                  item.address,
                                  item.category,
                                ),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),

          // ─── 3. Floating Quick Action Controls ───────────────────────────
          Positioned(
            right: 14,
            bottom: 245,
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.gps_fixed_rounded),
                ),
              ],
            ),
          ),

          // ─── 4. Bottom Target & Delivery Details Card ────────────────────
          Positioned(
            bottom: 16,
            left: 14,
            right: 14,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TARGET DISPATCH ROUTE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_distanceKm != null)
                          Text(
                            '${_distanceKm!.toStringAsFixed(1)} km  (~${_etaMinutes ?? 0} mins)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Destination Title & Category Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _destinationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _destinationCategory,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _destinationAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy GPS', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (_selectedDestination != null) {
                                final text =
                                    '${_selectedDestination!.latitude.toStringAsFixed(6)}, ${_selectedDestination!.longitude.toStringAsFixed(6)}';
                                Clipboard.setData(ClipboardData(text: text));
                                _showSnackBar('Coordinates copied: $text');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.navigation_rounded, size: 16),
                            label: const Text('Dispatch Courier', style: TextStyle(fontSize: 13)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              _showSnackBar(
                                'Courier delivery route confirmed to $_destinationName.',
                              );
                            },
                          ),
                        ),
                      ],
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
