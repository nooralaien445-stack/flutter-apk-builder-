import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sun_moon_calendar_flutter/sun_moon_calendar_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
      home: const SkyMonitorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SkyMonitorScreen extends StatefulWidget {
  const SkyMonitorScreen({super.key});

  @override
  State<SkyMonitorScreen> createState() => _SkyMonitorScreenState();
}

class _SkyMonitorScreenState extends State<SkyMonitorScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;

  DateTime? _sunrise;
  DateTime? _sunset;
  DateTime? _moonrise;
  DateTime? _moonset;
  MoonPhase? _moonPhase;

  @override
  void initState() {
    super.initState();
    _getLocationAndSkyData();
  }

  Future<void> _getLocationAndSkyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'تم رفض أذونات الموقع';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'تم رفض أذونات الموقع بشكل دائم. يرجى تمكينها من إعدادات التطبيق.';
          _isLoading = false;
        });
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'خدمات الموقع معطلة. يرجى تمكينها.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      // Calculate sky data
      final DateTime now = DateTime.now();
      final SunMoonCalendar sunMoonCalendar = SunMoonCalendar(
        latitude: position.latitude,
        longitude: position.longitude,
        date: now,
      );

      final SunMoonTimes sunTimes = sunMoonCalendar.getSunTimes();
      final MoonTimes moonTimes = sunMoonCalendar.getMoonTimes();
      final MoonPhase moonPhase = sunMoonCalendar.getMoonPhase();

      setState(() {
        _sunrise = sunTimes.sunrise;
        _sunset = sunTimes.sunset;
        _moonrise = moonTimes.moonrise;
        _moonset = moonTimes.moonset;
        _moonPhase = moonPhase;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return 'غير متاح';
    }
    return DateFormat.jm('ar').format(time);
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'غير متاح';
    }
    return DateFormat.yMMMEd('ar').format(date);
  }

  String _getMoonPhaseName(MoonPhase? phase) {
    if (phase == null) return 'غير متاح';
    switch (phase) {
      case MoonPhase.newMoon:
        return 'محاق';
      case MoonPhase.waxingCrescent:
        return 'هلال متزايد';
      case MoonPhase.firstQuarter:
        return 'تربيع أول';
      case MoonPhase.waxingGibbous:
        return 'أحدب متزايد';
      case MoonPhase.fullMoon:
        return 'بدر';
      case MoonPhase.waningGibbous:
        return 'أحدب متناقص';
      case MoonPhase.lastQuarter:
        return 'تربيع أخير';
      case MoonPhase.waningCrescent:
        return 'هلال متناقص';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقب السماء'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitFadingCircle(
                      color: Colors.blueAccent,
                      size: 50.0,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'جاري تحميل بيانات السماء...',
                      style: TextStyle(fontSize: 18, color: Colors.blueGrey),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                          const SizedBox(height: 20),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, color: Colors.red),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: _getLocationAndSkyData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _getLocationAndSkyData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'موقعك الحالي',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  _currentPosition != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'خط العرض: ${_currentPosition!.latitude.toStringAsFixed(4)}',
                                              style: Theme.of(context).textTheme.bodyLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'خط الطول: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                                              style: Theme.of(context).textTheme.bodyLarge,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'تاريخ ووقت التحديث: ${_formatDate(_currentPosition!.timestamp)} - ${_formatTime(_currentPosition!.timestamp)}',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'لا توجد بيانات موقع متاحة.',
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'بيانات الشمس',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  _sunrise != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                                              title: Text(
                                                'شروق الشمس:',
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                              trailing: Text(
                                                _formatTime(_sunrise),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.nights_stay, color: Colors.deepOrange),
                                              title: Text(
                                                'غروب الشمس:',
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                              trailing: Text(
                                                _formatTime(_sunset),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'لا توجد بيانات شمس متاحة.',
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'بيانات القمر',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  _moonrise != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.brightness_2, color: Colors.blueGrey),
                                              title: Text(
                                                'شروق القمر:',
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                              trailing: Text(
                                                _formatTime(_moonrise),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.brightness_3, color: Colors.indigo),
                                              title: Text(
                                                'غروب القمر:',
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                              trailing: Text(
                                                _formatTime(_moonset),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.flare, color: Colors.amber),
                                              title: Text(
                                                'طور القمر:',
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                              trailing: Text(
                                                _getMoonPhaseName(_moonPhase),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'لا توجد بيانات قمر متاحة.',
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}