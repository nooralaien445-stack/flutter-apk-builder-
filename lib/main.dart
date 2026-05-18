import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Star Gazer',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StarGazerHomePage(),
    );
  }
}

class StarGazerHomePage extends StatefulWidget {
  const StarGazerHomePage({super.key});

  @override
  State<StarGazerHomePage> createState() => _StarGazerHomePageState();
}

class _StarGazerHomePageState extends State<StarGazerHomePage> {
  Position? _currentPosition;
  bool _isLoading = true;
  bool _permissionGranted = false;
  List<CelestialObject> _celestialObjects = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _determinePosition();
    if (_permissionGranted) {
      _loadCelestialObjects();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _permissionGranted = false;
        });
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionGranted = false;
      });
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    setState(() {
      _permissionGranted = true;
    });
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      _currentPosition = null;
      print("Error getting location: $e");
    }
  }

  void _loadCelestialObjects() {
    final now = DateTime.now();
    final random = Random(now.millisecondsSinceEpoch);

    _celestialObjects = [
      CelestialObject(
        name: 'Moon',
        type: 'Planet',
        altitude: (random.nextDouble() * 90).toStringAsFixed(2),
        azimuth: (random.nextDouble() * 360).toStringAsFixed(2),
        magnitude: '-12.7',
      ),
      CelestialObject(
        name: 'Jupiter',
        type: 'Planet',
        altitude: (random.nextDouble() * 90).toStringAsFixed(2),
        azimuth: (random.nextDouble() * 360).toStringAsFixed(2),
        magnitude: '-2.5',
      ),
      CelestialObject(
        name: 'Saturn',
        type: 'Planet',
        altitude: (random.nextDouble() * 90).toStringAsFixed(2),
        azimuth: (random.nextDouble() * 360).toStringAsFixed(2),
        magnitude: '0.7',
      ),
      CelestialObject(
        name: 'Mars',
        type: 'Planet',
        altitude: (random.nextDouble() * 90).toStringAsFixed(2),
        azimuth: (random.nextDouble() * 360).toStringAsFixed(2),
        magnitude: '-1.0',
      ),
      CelestialObject(
        name: 'Venus',
        type: 'Planet',
        altitude: (random.nextDouble() * 90).toStringAsFixed(2),
        azimuth: (random.nextDouble() * 360).toStringAsFixed(2),
        magnitude: '-4.5',
      ),
      CelestialObject(
        name: 'Sirius',
        type: 'Star',
        altitude: (random.nextDouble() * 90).toStringAsFixed(2),
        azimuth: (random.nextDouble() * 360).toStringAsFixed(2),
        magnitude: '-1.46',
      ),
      CelestialObject(
        name: 'Alpha Centauri',
        type: 'Star',
        altitude: (random.nextDouble() * 90).toStringAsFixed(2),
        azimuth: (random.nextDouble() * 360).toStringAsFixed(2),
        magnitude: '-0.27',
      ),
      CelestialObject(
        name: 'Betelgeuse',
        type: 'Star',
        altitude: (random.nextDouble() * 90).toStringAsFixed(2),
        azimuth: (random.nextDouble() * 360).toStringAsFixed(2),
        magnitude: '0.5',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Star Gazer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              openAppSettings();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_permissionGranted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off, size: 80),
                        const SizedBox(height: 20),
                        const Text(
                          'Location permission is required to monitor celestial objects.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await openAppSettings();
                            _refreshData();
                          },
                          child: const Text('Open App Settings'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Location:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _currentPosition == null
                                  ? const Text('Location not available.')
                                  : Text(
                                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                                      'Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}\n'
                                      'Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _celestialObjects.length,
                        itemBuilder: (context, index) {
                          return CelestialObjectCard(
                              object: _celestialObjects[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class CelestialObject {
  final String name;
  final String type;
  final String altitude;
  final String azimuth;
  final String magnitude;

  CelestialObject({
    required this.name,
    required this.type,
    required this.altitude,
    required this.azimuth,
    required this.magnitude,
  });
}

class CelestialObjectCard extends StatelessWidget {
  final CelestialObject object;

  const CelestialObjectCard({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              object.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${object.type}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Altitude: ${object.altitude}°',
                        style: const TextStyle(fontSize: 15)),
                    Text('Azimuth: ${object.azimuth}°',
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Magnitude: ${object.magnitude}',
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}