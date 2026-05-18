import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:celestial_bodies/celestial_bodies.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مراقب النجوم والكواكب',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
  String _locationStatus = 'جارٍ الحصول على الموقع...';
  Position? _currentPosition;
  List<Map<String, String>> _celestialData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndCelestialData();
  }

  Future<void> _fetchLocationAndCelestialData() async {
    setState(() {
      _isLoading = true;
      _locationStatus = 'جارٍ الحصول على الموقع...';
      _celestialData = [];
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'تم رفض إذن الموقع.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'تم رفض إذن الموقع بشكل دائم. يرجى تمكينه من الإعدادات.';
          _isLoading = false;
        });
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _locationStatus = 'الموقع الحالي: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
      });

      _calculateCelestialPositions();
    } catch (e) {
      setState(() {
        _locationStatus = 'خطأ في الحصول على الموقع: $e';
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateCelestialPositions() {
    if (_currentPosition == null) {
      setState(() {
        _celestialData = [{'name': 'خطأ', 'info': 'لا يمكن حساب المواقع بدون موقع جغرافي.'}];
      });
      return;
    }

    final DateTime now = DateTime.now().toUtc();
    final double latitude = _currentPosition!.latitude;
    final double longitude = _currentPosition!.longitude;

    final List<CelestialBody> bodies = [
      Sun(),
      Moon(),
      Mercury(),
      Venus(),
      Mars(),
      Jupiter(),
      Saturn(),
    ];

    List<Map<String, String>> data = [];
    for (var body in bodies) {
      final position = body.getApparentPosition(now, latitude, longitude);
      if (position != null) {
        data.add({
          'name': _getBodyName(body),
          'info': 'الارتفاع: ${position.altitude.toDegrees().toStringAsFixed(2)}°، السمت: ${position.azimuth.toDegrees().toStringAsFixed(2)}°',
        });
      } else {
        data.add({
          'name': _getBodyName(body),
          'info': 'غير متاح حاليًا',
        });
      }
    }

    setState(() {
      _celestialData = data;
    });
  }

  String _getBodyName(CelestialBody body) {
    if (body is Sun) return 'الشمس';
    if (body is Moon) return 'القمر';
    if (body is Mercury) return 'عطارد';
    if (body is Venus) return 'الزهرة';
    if (body is Mars) return 'المريخ';
    if (body is Jupiter) return 'المشتري';
    if (body is Saturn) return 'زحل';
    return 'جسم سماوي';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقب النجوم والكواكب'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _locationStatus,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: _celestialData.isEmpty && _currentPosition != null
                        ? const Center(child: Text('لا توجد بيانات سماوية متاحة.'))
                        : ListView.builder(
                            itemCount: _celestialData.length,
                            itemBuilder: (context, index) {
                              final item = _celestialData[index];
                              return Card(
                                color: Colors.blueGrey[900],
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']!,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['info']!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchLocationAndCelestialData,
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث البيانات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}