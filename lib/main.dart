import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sun_sync/sun_sync.dart';
import 'package:intl/intl.dart';
import 'package:moon_phases/moon_phases.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مراقب السماء',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
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
      home: const SkyMonitorApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SkyMonitorApp extends StatefulWidget {
  const SkyMonitorApp({super.key});

  @override
  State<SkyMonitorApp> createState() => _SkyMonitorAppState();
}

class _SkyMonitorAppState extends State<SkyMonitorApp> {
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;

  DateTime? _sunrise;
  DateTime? _sunset;
  DateTime? _civilDawn;
  DateTime? _civilDusk;
  DateTime? _nauticalDawn;
  DateTime? _nauticalDusk;
  DateTime? _astronomicalDawn;
  DateTime? _astronomicalDusk;

  MoonPhase? _moonPhase;
  double? _moonIllumination;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'خدمات الموقع معطلة. يرجى تمكينها.';
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'تم رفض أذونات الموقع.';
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'تم رفض أذونات الموقع بشكل دائم. لا يمكن الوصول إلى الموقع.';
        _isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      _calculateSkyData(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء الحصول على الموقع: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _calculateSkyData(double latitude, double longitude) {
    final now = DateTime.now();
    final sunCalc = SunCalc(date: now, latitude: latitude, longitude: longitude);

    setState(() {
      _sunrise = sunCalc.sunrise;
      _sunset = sunCalc.sunset;
      _civilDawn = sunCalc.dawn;
      _civilDusk = sunCalc.dusk;
      _nauticalDawn = sunCalc.nauticalDawn;
      _nauticalDusk = sunCalc.nauticalDusk;
      _astronomicalDawn = sunCalc.astronomicalDawn;
      _astronomicalDusk = sunCalc.astronomicalDusk;

      final moon = MoonPhases.forDate(now);
      _moonPhase = moon.phase;
      _moonIllumination = moon.illumination;

      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'غير متاح';
    return DateFormat('HH:mm:ss', 'ar').format(dateTime);
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'غير متاح';
    return DateFormat('yyyy-MM-dd', 'ar').format(dateTime);
  }

  String _getMoonPhaseName(MoonPhase? phase) {
    if (phase == null) return 'غير متاح';
    switch (phase) {
      case MoonPhase.newMoon: return 'قمر جديد';
      case MoonPhase.waxingCrescent: return 'هلال متزايد';
      case MoonPhase.firstQuarter: return 'الربع الأول';
      case MoonPhase.waxingGibbous: return 'أحدب متزايد';
      case MoonPhase.fullMoon: return 'بدر كامل';
      case MoonPhase.waningGibbous: return 'أحدب متناقص';
      case MoonPhase.lastQuarter: return 'الربع الأخير';
      case MoonPhase.waningCrescent: return 'هلال متناقص';
    }
  }

  Widget _buildInfoCard({required String title, required String value, IconData? icon}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.blueGrey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.blue[200], size: 28),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقب السماء'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
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
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _determinePosition,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _determinePosition,
                  color: Colors.blueAccent,
                  backgroundColor: Colors.blueGrey[900],
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'البيانات الحالية (${_formatDate(DateTime.now())})',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              title: 'الموقع الجغرافي',
                              value: _currentPosition != null
                                  ? 'خط العرض: ${_currentPosition!.latitude.toStringAsFixed(4)}\nخط الطول: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                  : 'غير متاح',
                              icon: Icons.location_on,
                            ),
                            _buildInfoCard(
                              title: 'الوقت الحالي',
                              value: DateFormat('HH:mm:ss', 'ar').format(DateTime.now()),
                              icon: Icons.access_time,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'أوقات الشمس',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              title: 'شروق الشمس',
                              value: _formatDateTime(_sunrise),
                              icon: Icons.wb_sunny,
                            ),
                            _buildInfoCard(
                              title: 'غروب الشمس',
                              value: _formatDateTime(_sunset),
                              icon: Icons.nights_stay,
                            ),
                            _buildInfoCard(
                              title: 'فجر مدني (بداية الشفق)',
                              value: _formatDateTime(_civilDawn),
                              icon: Icons.brightness_low,
                            ),
                            _buildInfoCard(
                              title: 'غسق مدني (نهاية الشفق)',
                              value: _formatDateTime(_civilDusk),
                              icon: Icons.brightness_high,
                            ),
                            _buildInfoCard(
                              title: 'فجر بحري',
                              value: _formatDateTime(_nauticalDawn),
                              icon: Icons.waves,
                            ),
                            _buildInfoCard(
                              title: 'غسق بحري',
                              value: _formatDateTime(_nauticalDusk),
                              icon: Icons.waves_outlined,
                            ),
                            _buildInfoCard(
                              title: 'فجر فلكي (بداية الظلام التام)',
                              value: _formatDateTime(_astronomicalDawn),
                              icon: Icons.star_border,
                            ),
                            _buildInfoCard(
                              title: 'غسق فلكي (نهاية الظلام التام)',
                              value: _formatDateTime(_astronomicalDusk),
                              icon: Icons.star,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'بيانات القمر',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              title: 'طور القمر',
                              value: _getMoonPhaseName(_moonPhase),
                              icon: Icons.brightness_2,
                            ),
                            _buildInfoCard(
                              title: 'إضاءة القمر',
                              value: _moonIllumination != null
                                  ? '${(_moonIllumination! * 100).toStringAsFixed(2)}%'
                                  : 'غير متاح',
                              icon: Icons.light_mode,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}