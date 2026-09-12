import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final MapController mapController = MapController();

  // Approximate BIT GIDA campus reference point.
  // This will be refined later if exact GIS coordinates are available.
  static const LatLng campusCenter = LatLng(26.7439, 83.2212);

  LatLng? selectedLocation;

  void selectLocation(TapPosition tapPosition, LatLng point) {
    setState(() {
      selectedLocation = point;
    });
  }

  void resetLocation() {
    setState(() {
      selectedLocation = null;
    });

    mapController.move(campusCenter, 17);
  }

  void useSelectedLocation() {
    final location = selectedLocation;

    if (location == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pehle map par unsafe location select karo.'),
          ),
        );
      return;
    }

    Navigator.pop(context, location);
  }

  // ---------------------------------------------------------------------------
  // CAMPUS REFERENCE GEOMETRY
  //
  // These shapes are visual approximations based on the supplied BIT GIDA
  // satellite-map reference screenshots.
  // ---------------------------------------------------------------------------

  List<Polygon> buildCampusBuildings() {
    return [
      // Main BIT building - upper/central block.
      Polygon(
        points: const [
          LatLng(26.74465, 83.22055),
          LatLng(26.74465, 83.22145),
          LatLng(26.74415, 83.22145),
          LatLng(26.74415, 83.22055),
        ],
        color: const Color(0xFF263238).withValues(alpha: 0.88),
        borderColor: const Color(0xFF8FA3B8),
        borderStrokeWidth: 2.0,
        label: 'BIT',
      ),

      // Main BIT central building extension.
      Polygon(
        points: const [
          LatLng(26.74405, 83.22065),
          LatLng(26.74405, 83.22118),
          LatLng(26.74372, 83.22118),
          LatLng(26.74372, 83.22065),
        ],
        color: const Color(0xFF37474F).withValues(alpha: 0.9),
        borderColor: const Color(0xFF90A4AE),
        borderStrokeWidth: 1.8,
      ),

      // Pharmacy building - right side.
      Polygon(
        points: const [
          LatLng(26.74365, 83.22155),
          LatLng(26.74365, 83.22238),
          LatLng(26.74282, 83.22238),
          LatLng(26.74282, 83.22155),
        ],
        color: const Color(0xFF455A64).withValues(alpha: 0.9),
        borderColor: const Color(0xFF90A4AE),
        borderStrokeWidth: 2.0,
        label: 'Pharmacy',
      ),

      // Lower/right rectangular campus block.
      Polygon(
        points: const [
          LatLng(26.74272, 83.22160),
          LatLng(26.74272, 83.22235),
          LatLng(26.74230, 83.22235),
          LatLng(26.74230, 83.22160),
        ],
        color: const Color(0xFF37474F).withValues(alpha: 0.86),
        borderColor: const Color(0xFF78909C),
        borderStrokeWidth: 1.8,
      ),

      // Left-side campus block.
      Polygon(
        points: const [
          LatLng(26.74395, 83.21972),
          LatLng(26.74395, 83.22042),
          LatLng(26.74335, 83.22042),
          LatLng(26.74335, 83.21972),
        ],
        color: const Color(0xFF37474F).withValues(alpha: 0.84),
        borderColor: const Color(0xFF78909C),
        borderStrokeWidth: 1.8,
      ),
    ];
  }

  List<Polygon> buildGreenZones() {
    return [
      // Large green/open area.
      Polygon(
        points: const [
          LatLng(26.74345, 83.21895),
          LatLng(26.74345, 83.22005),
          LatLng(26.74215, 83.22005),
          LatLng(26.74215, 83.21895),
        ],
        color: const Color(0xFF14532D).withValues(alpha: 0.28),
        borderColor: const Color(0xFF22C55E).withValues(alpha: 0.45),
        borderStrokeWidth: 1.0,
      ),

      // Upper open area.
      Polygon(
        points: const [
          LatLng(26.74515, 83.22000),
          LatLng(26.74515, 83.22230),
          LatLng(26.74475, 83.22230),
          LatLng(26.74475, 83.22000),
        ],
        color: const Color(0xFF166534).withValues(alpha: 0.22),
        borderColor: const Color(0xFF22C55E).withValues(alpha: 0.35),
        borderStrokeWidth: 1.0,
      ),
    ];
  }

  List<Polyline> buildCampusRoads() {
    const roadColor = Color(0xFFB0BEC5);

    return [
      // Main horizontal road.
      Polyline(
        points: const [LatLng(26.74525, 83.21870), LatLng(26.74525, 83.22270)],
        color: roadColor,
        strokeWidth: 7,
      ),

      // Upper internal road.
      Polyline(
        points: const [
          LatLng(26.74485, 83.21915),
          LatLng(26.74485, 83.22225),
          LatLng(26.74445, 83.22255),
        ],
        color: roadColor,
        strokeWidth: 6,
      ),

      // Left loop road.
      Polyline(
        points: const [
          LatLng(26.74490, 83.21910),
          LatLng(26.74420, 83.21910),
          LatLng(26.74375, 83.21930),
          LatLng(26.74375, 83.22030),
        ],
        color: roadColor,
        strokeWidth: 6,
      ),

      // Central vertical road.
      Polyline(
        points: const [
          LatLng(26.74505, 83.22065),
          LatLng(26.74405, 83.22065),
          LatLng(26.74220, 83.22065),
        ],
        color: roadColor,
        strokeWidth: 6,
      ),

      // Pharmacy approach road.
      Polyline(
        points: const [
          LatLng(26.74405, 83.22115),
          LatLng(26.74355, 83.22155),
          LatLng(26.74300, 83.22155),
          LatLng(26.74225, 83.22155),
        ],
        color: roadColor,
        strokeWidth: 6,
      ),

      // Right-side loop.
      Polyline(
        points: const [
          LatLng(26.74445, 83.22225),
          LatLng(26.74335, 83.22225),
          LatLng(26.74275, 83.22225),
          LatLng(26.74225, 83.22185),
        ],
        color: roadColor,
        strokeWidth: 6,
      ),
    ];
  }

  List<Marker> buildCampusLabels(BuildContext context) {
    final theme = Theme.of(context);

    return [
      Marker(
        point: const LatLng(26.74445, 83.22095),
        width: 130,
        height: 48,
        child: _MapBuildingLabel(
          icon: Icons.school_rounded,
          title: 'Buddha Institute',
          subtitle: 'of Technology',
          color: theme.colorScheme.primary,
        ),
      ),
      Marker(
        point: const LatLng(26.74318, 83.22205),
        width: 130,
        height: 52,
        child: _MapBuildingLabel(
          icon: Icons.local_pharmacy_rounded,
          title: 'Buddha Institute',
          subtitle: 'of Pharmacy',
          color: Colors.cyanAccent,
        ),
      ),
    ];
  }

  List<Marker> buildSafetyMarkers(BuildContext context) {
    return [
      // Demo safety points.
      //
      // Later these can come directly from Firestore safety_reports.
      Marker(
        point: const LatLng(26.74372, 83.22015),
        width: 42,
        height: 42,
        child: _RiskMarker(
          color: Colors.redAccent,
          icon: Icons.warning_rounded,
        ),
      ),
      Marker(
        point: const LatLng(26.74292, 83.22105),
        width: 42,
        height: 42,
        child: _RiskMarker(
          color: Colors.orangeAccent,
          icon: Icons.warning_amber_rounded,
        ),
      ),
      Marker(
        point: const LatLng(26.74430, 83.22195),
        width: 42,
        height: 42,
        child: _RiskMarker(
          color: Colors.greenAccent,
          icon: Icons.check_circle_rounded,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Safety Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: resetLocation,
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: campusCenter,
              initialZoom: 17,
              minZoom: 15,
              maxZoom: 20,
              onTap: selectLocation,
            ),
            children: [
              // ----------------------------------------------------------------
              // REAL WORLD BASE MAP
              // ----------------------------------------------------------------
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusx.app',
                maxZoom: 19,
              ),

              // ----------------------------------------------------------------
              // CAMPUS GREEN / OPEN AREAS
              // ----------------------------------------------------------------
              PolygonLayer(polygons: buildGreenZones()),

              // ----------------------------------------------------------------
              // CAMPUS BUILDINGS
              // ----------------------------------------------------------------
              PolygonLayer(polygons: buildCampusBuildings()),

              // ----------------------------------------------------------------
              // INTERNAL CAMPUS ROADS
              // ----------------------------------------------------------------
              PolylineLayer(polylines: buildCampusRoads()),

              // ----------------------------------------------------------------
              // CAMPUS LABELS + SAFETY MARKERS
              // ----------------------------------------------------------------
              MarkerLayer(
                markers: [
                  ...buildCampusLabels(context),
                  ...buildSafetyMarkers(context),

                  // BIT center marker.
                  Marker(
                    point: campusCenter,
                    width: 70,
                    height: 70,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 27,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: const [
                              BoxShadow(blurRadius: 5, spreadRadius: 1),
                            ],
                          ),
                          child: const Text(
                            'BIT GIDA',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selected unsafe location.
                  if (selectedLocation != null)
                    Marker(
                      point: selectedLocation!,
                      width: 62,
                      height: 72,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 14,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              size: 27,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'Selected',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // --------------------------------------------------------------------
          // TOP INFORMATION CARD
          // --------------------------------------------------------------------
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 1,
                    color: Colors.black.withValues(alpha: 0.22),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BIT GIDA Campus',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Tap anywhere to report an unsafe location',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --------------------------------------------------------------------
          // MAP LEGEND
          // --------------------------------------------------------------------
          Positioned(
            right: 14,
            bottom: selectedLocation == null ? 20 : 190,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(blurRadius: 12)],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 7),
                  _LegendItem(color: Colors.redAccent, text: 'High Risk'),
                  SizedBox(height: 5),
                  _LegendItem(color: Colors.orangeAccent, text: 'Medium'),
                  SizedBox(height: 5),
                  _LegendItem(color: Colors.greenAccent, text: 'Low Risk'),
                ],
              ),
            ),
          ),

          // --------------------------------------------------------------------
          // SELECTED LOCATION PANEL
          // --------------------------------------------------------------------
          if (selectedLocation != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 22,
                      spreadRadius: 1,
                      color: Colors.black.withValues(alpha: 0.30),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Safety Location Selected',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedLocation = null;
                            });
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: useSelectedLocation,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Use This Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BUILDING LABEL
// -----------------------------------------------------------------------------

class _MapBuildingLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _MapBuildingLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SAFETY MARKER
// -----------------------------------------------------------------------------

class _RiskMarker extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _RiskMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: Colors.white),
    );
  }
}

// -----------------------------------------------------------------------------
// LEGEND
// -----------------------------------------------------------------------------

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
