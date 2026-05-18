import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sun_moon_calculator/sun_moon_calculator.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SkyMonitorApp());
}

class SkyMonitorApp extends StatelessWidget {
  const SkyMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sky Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const SkyMonitorHomePage(),
    );
  }
}

class SkyMonitorHomePage extends StatefulWidget {
  const SkyMonitorHomePage({super.key});

  @override
  State<SkyMonitorHomePage> createState() => _SkyMonitorHomePageState();
}

class _SkyMonitorHomePageState extends State<SkyMonitorHomePage> {
  String _locationMessage = 'Fetching location...';
  String _sunriseTime = 'N/A';
  String _sunsetTime = 'N/A';
  String _moonriseTime = 'N/A';
  String _moonsetTime = 'N/A';
  String _moonPhase = 'N/A';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getSkyData();
  }

  Future<void> _getSkyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _locationMessage = 'Fetching location...';
      _sunriseTime = 'N/A';
      _sunsetTime = 'N/A';
      _moonriseTime = 'N/A';
      _moonsetTime = 'N/A';
      _moonPhase = 'N/A';
    });

    try {
      Position position = await _determinePosition();
      setState(() {
        _locationMessage = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      });

      DateTime now = DateTime.now();
      SunMoonCalculator calculator = SunMoonCalculator(
        date: now,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      DateTime? sunrise = calculator.getSunrise();
      DateTime? sunset = calculator.getSunset();
      DateTime? moonrise = calculator.getMoonrise();
      DateTime? moonset = calculator.getMoonset();
      MoonPhase moonPhase = calculator.getMoonPhase();

      setState(() {
        _sunriseTime = sunrise != null ? DateFormat.jm().format(sunrise) : 'N/A';
        _sunsetTime = sunset != null ? DateFormat.jm().format(sunset) : 'N/A';
        _moonriseTime = moonrise != null ? DateFormat.jm().format(moonrise) : 'N/A';
        _moonsetTime = moonset != null ? DateFormat.jm().format(moonset) : 'N/A';
        _moonPhase = _getMoonPhaseName(moonPhase);
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _locationMessage = 'Could not get location.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getMoonPhaseName(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon: return 'New Moon';
      case MoonPhase.waxingCrescent: return 'Waxing Crescent';
      case MoonPhase.firstQuarter: return 'First Quarter';
      case MoonPhase.waxingGibbous: return 'Waxing Gibbous';
      case MoonPhase.fullMoon: return 'Full Moon';
      case MoonPhase.waningGibbous: return 'Waning Gibbous';
      case MoonPhase.lastQuarter: return 'Last Quarter';
      case MoonPhase.waningCrescent: return 'Waning Crescent';
      default: return 'Unknown';
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled. Please enable them.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied. Please grant them.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied. Please enable them from app settings.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sky Monitor'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.location_on, size: 60, color: Colors.blueAccent),
              const SizedBox(height: 15),
              Text(
                _locationMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 15),
                    Text('Calculating sky data...', style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                  ],
                )
              else if (_errorMessage.isNotEmpty)
                Column(
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                    const SizedBox(height: 15),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildSkyInfoCard('Sunrise', _sunriseTime, Icons.wb_sunny, Colors.orange),
                    _buildSkyInfoCard('Sunset', _sunsetTime, Icons.nights_stay, Colors.deepPurple),
                    _buildSkyInfoCard('Moonrise', _moonriseTime, Icons.brightness_2, Colors.blueGrey),
                    _buildSkyInfoCard('Moonset', _moonsetTime, Icons.brightness_3, Colors.indigo),
                    _buildSkyInfoCard('Moon Phase', _moonPhase, Icons.flare, Colors.teal),
                  ],
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _getSkyData,
                child: const Text('Refresh Sky Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkyInfoCard(String label, String value, IconData icon, Color iconColor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}