import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Inicializar zonas horarias (Cabimas, Venezuela es America/Caracas)
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/Caracas'));
    } catch (e) {
      debugPrint("⚠️ Error al inicializar timezone, usando UTC: $e");
    }

    // 2. Configurar ajustes de inicialización para Android e iOS
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("🔔 Notificación clickeada con payload: ${response.payload}");
      },
    );
  }

  // Solicitar permisos en dispositivos Android 13+ y iOS
  Future<void> requestPermissions() async {
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint("⚠️ Error al solicitar permisos de notificación: $e");
    }
  }

  // Programar recordatorio recurrente diario para rutinas
  Future<void> scheduleDailyRoutineReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_reminders_channel',
          'Recordatorios de Rutinas',
          channelDescription: 'Canal para alertas de rutinas de mañana y noche',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Se repite diariamente
    );
    debugPrint("📅 Recordatorio de rutina programado a las $hour:$minute con ID: $id");
  }

  // Programar alarma de medicación (se repite diariamente a la hora indicada)
  Future<void> scheduleMedicationAlarm({
    required String alarmId,
    required String title,
    required String note,
    required String timeStr,
  }) async {
    final int id = alarmId.hashCode;

    // Parsear hora en formato "hh:mm a" (ej: "12:00 PM")
    DateTime parsedTime;
    try {
      parsedTime = DateFormat("hh:mm a").parse(timeStr);
    } catch (_) {
      try {
        parsedTime = DateFormat("HH:mm").parse(timeStr);
      } catch (_) {
        debugPrint("⚠️ No se pudo parsear la hora: $timeStr, usando hora actual + 5 min");
        parsedTime = DateTime.now().add(const Duration(minutes: 5));
      }
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      parsedTime.hour,
      parsedTime.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      note.isEmpty ? 'Es hora de tu cuidado facial programado' : note,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_alarms_channel',
          'Alarmas de Medicación',
          channelDescription: 'Canal para alarmas de medicamentos y recordatorios personalizados',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Se repite diariamente
    );
    debugPrint("⏰ Alarma de medicación programada a las $timeStr con ID: $id ($title)");
  }

  // Cancelar una notificación específica
  Future<void> cancelNotification(String alarmId) async {
    final int id = alarmId.hashCode;
    await _notificationsPlugin.cancel(id);
    debugPrint("❌ Alarma/Recordatorio cancelado con ID: $id");
  }

  // Cancelar todas las notificaciones de rutina
  Future<void> cancelAllRoutineReminders() async {
    await _notificationsPlugin.cancel(1001); // ID rutina mañana
    await _notificationsPlugin.cancel(1002); // ID rutina noche
    debugPrint("❌ Recordatorios de rutinas cancelados");
  }
}
