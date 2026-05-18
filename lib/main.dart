import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter_celestial/flutter_celestial.dart';

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
        primarySwatch: Colors.blueGrey,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.blueGrey[800],
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const StargazerHomePage(),
    );
  }
}

class StargazerHomePage extends StatefulWidget {
  const StargazerHomePage({super.key});

  @override
  State<StargazerHomePage> createState() => _StargazerHomePageState();
}

class _StargazerHomePageState extends State<StargazerHomePage> {
  LocationData? _currentLocation;
  String _errorMessage = '';
  List<CelestialObjectInfo> _celestialObjects = [];
  bool _isLoading = false;

  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetchData();
  }

  Future<void> _checkLocationAndFetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _celestialObjects = [];
    });

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'خدمة الموقع غير مفعلة.';
          _isLoading = false;
        });
        return;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'لم يتم منح إذن الموقع.';
          _isLoading = false;
        });
        return;
      }
    }

    try {
      _currentLocation = await _location.getLocation();
      if (_currentLocation != null && _currentLocation!.latitude != null && _currentLocation!.longitude != null) {
        await _fetchCelestialData(_currentLocation!.latitude!, _currentLocation!.longitude!);
      } else {
        setState(() {
          _errorMessage = 'تعذر الحصول على الموقع الحالي.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ أثناء الحصول على الموقع: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false