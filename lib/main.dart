import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:astronomy_engine/astronomy_engine.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sky Watcher',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          bodySmall: TextStyle(color: Colors.white54),
        ),
      ),
      home: const SkyWatcherApp(),
    );
  }
}

class SkyWatcherApp extends StatefulWidget {
  const SkyWatcherApp({super.key});

  @override
  State<SkyWatcherApp> createState() => _SkyWatcherAppState();
}

class _SkyWatcherAppState extends State<SkyWatcherApp> {
  Position? _currentPosition;
  bool _permissionGranted = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<CelestialObjectInfo> _visibleObjects = [];
  Timer? _updateTimer;
  DateTime _lastUpdatedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeLocationAndSkyData();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocationAndSkyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _checkAndRequestLocationPermission();
      if (_permissionGranted) {
        await _getCurrentLocation();
        if (_currentPosition != null) {
          _updateCelestialObjects();
          _startPeriodicUpdates();
        } else {
          _errorMessage = 'Could not retrieve current location.';
        }
      } else {
        _errorMessage = 'Location permission denied. Please enable it in settings.';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      print('Initialization error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAndRequestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionGranted = false;
        });
        return;
      }
    }
    setState(() {
      _permissionGranted = (permission == LocationPermission.whileInUse || permission == LocationPermission.always);
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!_permissionGranted) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _currentPosition = position;
      });
    } on TimeoutException {
      _errorMessage = 'Location request timed out. Please check your GPS.';
    } catch (e) {
      _errorMessage = 'Failed to get location: ${e.toString()}';
    }
  }

  void _startPeriodicUpdates() {
    _updateTimer?.cancel(); // Cancel any existing timer
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentPosition != null) {
        _updateCelestialObjects();
      }
    });
  }

  void _updateCelestialObjects() {
    if (_currentPosition == null) return;

    final observer = Observer(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      // Altitude is optional, assuming sea level for simplicity
    );

    final now = DateTime.now().toUtc();
    List<CelestialObjectInfo> objects = [];

    // Planets and Sun/Moon
    final celestialBodies = <String, Body>{
      'Sun': Body.Sun,
      'Moon': Body.Moon,
      'Mercury': Body.Mercury,
      'Venus': Body.Venus,
      'Mars': Body.Mars,
      'Jupiter': Body.Jupiter,
      'Saturn': Body.Saturn,
      'Uranus': Body.Uranus,
      'Neptune': Body.Neptune,
    };

    celestialBodies.forEach((name, body) {
      final coords = HorizonCoordinates.fromEquatorial(
        observer,
        EquatorialCoordinates.fromBody(body, now),
        now,
      );
      if (coords.altitude.toDegrees() > 0) { // Only show objects above the horizon
        objects.add(CelestialObjectInfo(
          name: name,
          altitude: coords.altitude.toDegrees(),
          azimuth: coords.azimuth.toDegrees(),
        ));
      }
    });

    // Add some bright stars
    final brightStars = <String, Star>{
      'Sirius': Star.sirius,
      'Canopus': Star.canopus,
      'Arcturus': Star.arcturus,
      'Vega': Star.vega,
      'Capella': Star.capella,
      'Rigel': Star.rigel,
      'Procyon': Star.procyon,
      'Achernar': Star.achernar,
      'Betelgeuse': Star.betelgeuse,
      'Hadar': Star.hadar,
      'Altair': Star.altair,
      'Aldebaran': Star.aldebaran,
      'Spica': Star.spica,
      'Antares': Star.antares,
      'Pollux': Star.pollux,
      'Fomalhaut': Star.fomalhaut,
      'Deneb': Star.deneb,
      'Regulus': Star.regulus,
      'Adhara': Star.adhara,
      'Castor': Star.castor,
      'Gacrux': Star.gacrux,
      'Shaula': Star.shaula,
      'Bellatrix': Star.bellatrix,
      'Elnath': Star.elnath,
      'Miaplacidus': Star.miaplacidus,
      'Alnilam': Star.alnilam,
      'Alnair': Star.alnair,
      'Alioth': Star.alioth,
      'Mirfak': Star.mirfak,
      'Dubhe': Star.dubhe,
    };

    brightStars.forEach((name, star) {
      final coords = HorizonCoordinates.fromEquatorial(
        observer,
        EquatorialCoordinates.fromStar(star, now),
        now,
      );
      if (coords.altitude.toDegrees() > 0) {
        objects.add(CelestialObjectInfo(
          name: name,
          altitude: coords.altitude.toDegrees(),
          azimuth: coords.azimuth.toDegrees(),
        ));
      }
    });

    // Sort by altitude (highest first)
    objects.sort((a, b) => b.altitude.compareTo(a.altitude));

    setState(() {
      _visibleObjects = objects;
      _lastUpdatedTime = DateTime.now();
    });
  }

  String _formatAngle(double degrees) {
    return '${degrees.toStringAsFixed(2)}°';
  }

  String _getAzimuthDirection(double azimuthDegrees) {
    if (azimuthDegrees >= 337.5 || azimuthDegrees < 22.5) return 'N';
    if (azimuthDegrees >= 22.5 && azimuthDegrees < 67.5) return 'NE';
    if (azimuthDegrees >= 67.5 && azimuthDegrees < 112.5) return 'E';
    if (azimuthDegrees >= 112.5 && azimuthDegrees < 157.5) return 'SE';
    if (azimuthDegrees >= 157.5 && azimuthDegrees < 202.5) return 'S';
    if (azimuthDegrees >= 202.5 && azimuthDegrees < 247.5) return 'SW';
    if (azimuthDegrees >= 247.5 && azimuthDegrees < 292.5) return 'W';
    if (azimuthDegrees >= 292.5 && azimuthDegrees < 337.5) return 'NW';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky Watcher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _initializeLocationAndSkyData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                        ),
                        if (!_permissionGranted && _errorMessage!.contains('permission denied'))
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                await openAppSettings();
                                _initializeLocationAndSkyData(); // Re-check after user might have changed settings
                              },
                              child: const Text('Open App Settings'),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Location:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentPosition != null
                                    ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                    : 'Location not available',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Last Updated: ${DateFormat('HH:mm:ss').format(_lastUpdatedTime)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _visibleObjects.isEmpty
                          ? const Center(
                              child: Text(
                                'No celestial objects visible above the horizon right now.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _visibleObjects.length,
                              itemBuilder: (context, index) {
                                final obj = _visibleObjects[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: ListTile(
                                    title: Text(
                                      obj.name,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    subtitle: Text(
                                      'Altitude: ${_formatAngle(obj.altitude)} | Azimuth: ${_formatAngle(obj.azimuth)} (${_getAzimuthDirection(obj.azimuth)})',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    trailing: const Icon(Icons.star, color: Colors.amber),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class CelestialObjectInfo {
  final String name;
  final double altitude;
  final double azimuth;

  CelestialObjectInfo({
    required this.name,
    required this.altitude,
    required this.azimuth,
  });
}