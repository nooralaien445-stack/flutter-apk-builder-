import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

late SharedPreferences _prefs;
late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

const String _prayerTimesKey = 'prayerTimes';
const String _lastLocationKey = 'lastLocation';
const String _lastCalculatedDateKey = 'lastCalculatedDate';
const String _notificationChannelId = 'prayer_times_channel';
const String _notificationChannelName = 'أوقات الصلاة';
const String _notificationChannelDescription = 'تنبيهات لأوقات الصلاة';

final Map<Prayer, String> _prayerNames = {
  Prayer.Fajr: 'الفجر',
  Prayer.Sunrise: 'الشروق',
  Prayer.Dhuhr: 'الظهر',
  Prayer.Asr: 'العصر',
  Prayer.Maghrib: 'المغرب',
  Prayer.Isha: 'العشاء',
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _prefs = await SharedPreferences.getInstance();

  tz.initializeAll();

  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    onDidReceiveLocalNotification: (id, title, body, payload) async {},
  );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );