import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const Color primaryBlue = Color(0xFF0B2C6B);
  static const Color primaryGreen = Color(0xFF16A34A);
  static const LatLng _defaultLocation = LatLng(30.0444, 31.2357);

  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _locations = [];
  bool _loadingLocation = false;
  LatLng? _myLocation;
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
        parent: _animationController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
    _loadLocationsFromFirestore();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationsFromFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('campaign_locations')
          .get();

      final List<Map<String, dynamic>> locations = [];
      final Set<Marker> markers = {};

      // إضافة الـ markers من Firestore
      for (final doc in snap.docs) {
        final d = doc.data();
        final lat = (d['lat'] as num?)?.toDouble();
        final lng = (d['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final type = d['type'] as String? ?? 'campaign';
        final color = _getMarkerColor(type);

        locations.add({
          'id': doc.id,
          'title': d['title'] ?? 'Location',
          'subtitle': d['subtitle'] ?? '',
          'type': type,
          'lat': lat,
          'lng': lng,
          'visits': d['visits'] ?? 0,
        });

        markers.add(Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: d['title'] ?? 'Location',
            snippet: d['subtitle'] ?? '',
          ),
          icon: await BitmapDescriptor.defaultMarkerWithHue(color),
          onTap: () => _onMarkerTap(d),
        ));
      }

      // لو مفيش بيانات في Firestore، حط بيانات افتراضية
      if (locations.isEmpty) {
        _addDefaultLocations(locations, markers);
      }

      if (mounted) {
        setState(() {
          _locations = locations;
          _markers = markers;
        });
      }
    } catch (e) {
      // في حالة error، استخدم البيانات الافتراضية
      final List<Map<String, dynamic>> locations = [];
      final Set<Marker> markers = {};
      _addDefaultLocations(locations, markers);
      if (mounted) {
        setState(() {
          _locations = locations;
          _markers = markers;
        });
      }
    }
  }

  void _addDefaultLocations(
      List<Map<String, dynamic>> locations, Set<Marker> markers) {
    final defaults = [
      {
        'id': 'default_1',
        'title': 'Awareness Campaign',
        'subtitle': 'Main volunteer meeting point',
        'type': 'campaign',
        'lat': 30.0444,
        'lng': 31.2357,
        'visits': 18,
      },
      {
        'id': 'default_2',
        'title': 'School Visit',
        'subtitle': 'Drug awareness session',
        'type': 'school',
        'lat': 30.0550,
        'lng': 31.2400,
        'visits': 7,
      },
      {
        'id': 'default_3',
        'title': 'Community Event',
        'subtitle': 'Volunteer hotspot area',
        'type': 'event',
        'lat': 30.0350,
        'lng': 31.2200,
        'visits': 12,
      },
    ];
    for (final d in defaults) {
      locations.add(d);
      markers.add(Marker(
        markerId: MarkerId(d['id'] as String),
        position: LatLng(d['lat'] as double, d['lng'] as double),
        infoWindow: InfoWindow(
          title: d['title'] as String,
          snippet: d['subtitle'] as String,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColor(d['type'] as String)),
      ));
    }
  }

  double _getMarkerColor(String type) {
    switch (type) {
      case 'school':
        return BitmapDescriptor.hueGreen;
      case 'event':
        return BitmapDescriptor.hueCyan;
      case 'hotspot':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'school':
        return Icons.school_rounded;
      case 'event':
        return Icons.groups_rounded;
      case 'hotspot':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'school':
        return primaryGreen;
      case 'event':
        return Colors.cyan.shade700;
      case 'hotspot':
        return Colors.redAccent;
      default:
        return primaryBlue;
    }
  }

  void _onMarkerTap(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationDetailSheet(data: data),
    );
  }

  Future<void> _goToMyLocation() async {
    setState(() => _loadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final myLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _myLocation = myLatLng);

      // حفظ الموقع في Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'lastLocation': {
            'lat': pos.latitude,
            'lng': pos.longitude,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        });
      }

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: myLatLng, zoom: 15, tilt: 35),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _animateToLocation(LatLng target, double zoom) async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom, tilt: 35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──
          GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 12.5,
            ),
            markers: _markers,
            myLocationEnabled: _myLocation != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: _mapType,
          ),

          // ── gradient overlay top ──
          Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // ── Top Bar ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        children: [
                          _glassButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.black : Colors.white)
                                    .withOpacity(0.92),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 16,
                                      offset: Offset(0, 6))
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Campaign Map',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : primaryBlue,
                                          ),
                                        ),
                                        Text(
                                          '${_locations.length} active zones',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Map type toggle
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _mapType = _mapType == MapType.normal
                                          ? MapType.satellite
                                          : MapType.normal;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            primaryBlue.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _mapType == MapType.normal
                                                ? Icons.satellite_alt_rounded
                                                : Icons.map_rounded,
                                            color: primaryBlue,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _mapType == MapType.normal
                                                ? 'Satellite'
                                                : 'Map',
                                            style: TextStyle(
                                                color: primaryBlue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── Bottom Card ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x26000000),
                                blurRadius: 24,
                                offset: Offset(0, 10))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      primaryBlue.withOpacity(0.1),
                                  child: const Icon(
                                      Icons.location_on_rounded,
                                      color: primaryBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Volunteer Activity Zones',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : primaryBlue,
                                    ),
                                  ),
                                ),
                                // Stats badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_locations.fold(0, (sum, l) => sum + (l['visits'] as int? ?? 0))} visits',
                                    style: TextStyle(
                                        color: primaryGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Location list
                            ..._locations.map((loc) => _locationTile(
                                  color: _getTypeColor(loc['type'] ?? ''),
                                  title: loc['title'] ?? '',
                                  subtitle: loc['subtitle'] ?? '',
                                  icon: _getTypeIcon(loc['type'] ?? ''),
                                  visits: loc['visits'] as int? ?? 0,
                                  isDark: isDark,
                                  onTap: () => _animateToLocation(
                                    LatLng(loc['lat'] as double,
                                        loc['lng'] as double),
                                    15,
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating Buttons (right) ──
          Positioned(
            right: 16,
            bottom: 300,
            child: Column(
              children: [
                _floatingMapButton(
                  icon: _loadingLocation
                      ? Icons.hourglass_bottom_rounded
                      : Icons.my_location_rounded,
                  onTap: _goToMyLocation,
                  color: primaryGreen,
                ),
                const SizedBox(height: 12),
                _floatingMapButton(
                  icon: Icons.add_rounded,
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 12),
                _floatingMapButton(
                  icon: Icons.remove_rounded,
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassButton(
      {required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 6))
            ],
          ),
          child: Icon(icon, color: primaryBlue),
        ),
      ),
    );
  }

  Widget _floatingMapButton(
      {required IconData icon,
      required VoidCallback onTap,
      Color color = primaryBlue}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 16,
                  offset: Offset(0, 6))
            ],
          ),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }

  Widget _locationTile({
    required Color color,
    required String title,
    required String subtitle,
    required IconData icon,
    required int visits,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF101828))),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black54)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$visits visits',
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Location Detail Bottom Sheet ──
class _LocationDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LocationDetailSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF0B2C6B);
    const primaryGreen = Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(data['title'] ?? '',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : primaryBlue)),
          const SizedBox(height: 6),
          Text(data['subtitle'] ?? '',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoChip(
                  Icons.place_rounded,
                  '${(data['lat'] as double?)?.toStringAsFixed(4)}, ${(data['lng'] as double?)?.toStringAsFixed(4)}',
                  primaryBlue,
                  isDark),
              const SizedBox(width: 10),
              _infoChip(
                  Icons.people_rounded,
                  '${data['visits'] ?? 0} visits',
                  primaryGreen,
                  isDark),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Get Directions',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color, bool isDark) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}