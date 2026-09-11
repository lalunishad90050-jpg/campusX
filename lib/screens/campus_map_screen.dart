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

  // Approximate BIT GIDA campus center.
  // We will refine this later using the actual campus boundary.
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
              minZoom: 12,
              maxZoom: 20,
              onTap: selectLocation,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campusx.app',
              ),

              // BIT GIDA approximate center marker.
              MarkerLayer(
                markers: [
                  Marker(
                    point: campusCenter,
                    width: 70,
                    height: 70,
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 38,
                          color: theme.colorScheme.primary,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(blurRadius: 4, spreadRadius: 1),
                            ],
                          ),
                          child: const Text(
                            'BIT GIDA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (selectedLocation != null)
                    Marker(
                      point: selectedLocation!,
                      width: 55,
                      height: 65,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.touch_app_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Map par unsafe location select karne ke liye tap karo.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (selectedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Safety Location Selected',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
                      ),

                      Text(
                        'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
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
            ),
        ],
      ),
    );
  }
}
