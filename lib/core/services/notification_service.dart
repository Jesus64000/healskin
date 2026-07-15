import 'dart:async';
import 'dart:typed_data';
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

  static final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  Future<void> init() async {
    // 1. Inicializar zonas horarias (Cabimas, Venezuela es America/Caracas)
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('America/Caracas'));
      } catch (e) {
        debugPrint("⚠️ America/Caracas location not found, fallback to UTC: $e");
        tz.setLocalLocation(tz.UTC);
      }
    } catch (e) {
      debugPrint("⚠️ Error al inicializar timezone: $e");
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
        selectNotificationStream.add(response.payload);
      },
    );

    // Verificar si la app fue abierta desde una notificación
    try {
      final NotificationAppLaunchDetails? notificationAppLaunchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
        final payload = notificationAppLaunchDetails?.notificationResponse?.payload;
        if (payload != null) {
          Future.delayed(const Duration(milliseconds: 500), () {
            selectNotificationStream.add(payload);
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error al obtener detalles de lanzamiento por notificación: $e");
    }
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_reminders_channel_v2',
          'Recordatorios de Rutinas',
          channelDescription: 'Canal para alertas de rutinas de mañana y noche',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          channelShowBadge: true,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_alarms_channel_v2',
          'Alarmas de Medicación',
          channelDescription: 'Canal para alarmas de medicamentos y recordatorios personalizados',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          channelShowBadge: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

  // Lanzar notificación instantánea local (para alertas de evolución y chats en tiempo real)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'evolution_alerts_channel_v2',
          'Alertas de Evolución y Mensajes',
          channelDescription: 'Alertas de cambios en la piel y mensajes de chat',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          channelShowBadge: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
    debugPrint("🔔 Notificación instantánea emitida: $title");
  }

  // Programar recordatorio recurrente para procedimientos
  Future<void> scheduleProcedureReminder({
    required String procedureId,
    required String procedureName,
    required int frequencyDays,
  }) async {
    final int baseId = procedureId.hashCode;

    // Primero cancelamos ocurrencias previas para evitar duplicados
    await cancelProcedureReminder(procedureId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Programamos recordatorios cada 48 horas (2 días) para recordar que está PENDIENTE
    for (int i = 1; i <= 5; i++) {
      final scheduledDate = now.add(Duration(hours: 48 * i));
      final int notificationId = baseId + i;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Tratamiento Pendiente ⚠️',
        'Aún no has registrado tu tratamiento: "$procedureName". Por favor, ingresa a la app para reportarlo hoy.',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'procedure_reminders_channel_v2',
            'Recordatorios de Procedimientos',
            channelDescription: 'Recordatorios recurrentes para tus procedimientos dérmicos',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            channelShowBadge: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'filter_map:$procedureName',
      );
      debugPrint("📅 Recordatorio de pendiente $i para '$procedureName' programado para $scheduledDate con ID: $notificationId");
    }
  }
  // Cancelar recordatorios de un procedimiento
  Future<void> cancelProcedureReminder(String procedureId) async {
    final int baseId = procedureId.hashCode;
    for (int i = 1; i <= 5; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
    debugPrint("❌ Recordatorios del procedimiento '$procedureId' cancelados.");
  }

  // --- LÓGICA DE ALARMAS PERSONALIZADAS FLEXIBLES (HORA FIJA, PREAJUSTES, INTERVALOS) ---

  DateTime _parseTimeStr(String timeStr) {
    try {
      final cleaned = timeStr.toLowerCase().replaceAll('.', '').replaceAll(' ', '').trim();
      final bool isPm = cleaned.contains('pm') || cleaned.contains('p.m.');
      final bool isAm = cleaned.contains('am') || cleaned.contains('a.m.');
      
      var digitsOnly = cleaned.replaceAll('am', '').replaceAll('pm', '').replaceAll('a.m.', '').replaceAll('p.m.', '');
      final parts = digitsOnly.split(':');
      if (parts.length == 2) {
        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        
        if (isPm && hour < 12) {
          hour += 12;
        } else if (isAm && hour == 12) {
          hour = 0;
        }
        
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      debugPrint("⚠️ Error manual parsing time '$timeStr': $e");
    }

    try {
      return DateFormat("hh:mm a").parse(timeStr);
    } catch (_) {
      try {
        return DateFormat("HH:mm").parse(timeStr);
      } catch (_) {
        debugPrint("⚠️ No se pudo parsear la hora: $timeStr, usando hora actual + 5 min");
        return DateTime.now().add(const Duration(minutes: 5));
      }
    }
  }

  tz.TZDateTime _buildScheduledDateTime(tz.TZDateTime now, int hour, int minute) {
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
    return scheduledDate;
  }

  Future<void> scheduleCustomReminder({
    required String alarmId,
    required String title,
    required String note,
    required String type, // 'specific_time', 'preset', 'interval'
    required String value, // ej. "12:00 PM", "morning_afternoon", "4" (horas)
  }) async {
    final int baseId = alarmId.hashCode;

    // Primero cancelamos cualquier ocurrencia previa para evitar duplicados
    await cancelCustomReminder(alarmId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    List<tz.TZDateTime> scheduledTimes = [];

    if (type == 'specific_time') {
      final time = _parseTimeStr(value);
      scheduledTimes.add(_buildScheduledDateTime(now, time.hour, time.minute));
    } else if (type == 'preset') {
      if (value == 'morning') {
        scheduledTimes.add(_buildScheduledDateTime(now, 8, 0));
      } else if (value == 'afternoon') {
        scheduledTimes.add(_buildScheduledDateTime(now, 14, 0));
      } else if (value == 'evening') {
        scheduledTimes.add(_buildScheduledDateTime(now, 20, 0));
      } else if (value == 'morning_afternoon') {
        scheduledTimes.add(_buildScheduledDateTime(now, 8, 0));
        scheduledTimes.add(_buildScheduledDateTime(now, 14, 0));
      } else if (value == 'morning_afternoon_evening') {
        scheduledTimes.add(_buildScheduledDateTime(now, 8, 0));
        scheduledTimes.add(_buildScheduledDateTime(now, 14, 0));
        scheduledTimes.add(_buildScheduledDateTime(now, 20, 0));
      }
    } else if (type == 'interval') {
      // Cada X horas, empezando desde las 8:00 AM hasta las 10:00 PM (horas activas)
      final int hours = int.tryParse(value) ?? 4;
      int currentHour = 8;
      while (currentHour <= 22) {
        scheduledTimes.add(_buildScheduledDateTime(now, currentHour, 0));
        currentHour += hours;
      }
    }

    // Programar cada fecha calculada
    for (int i = 0; i < scheduledTimes.length; i++) {
      final scheduledDate = scheduledTimes[i];
      final int notificationId = baseId + i;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        title,
        note.isEmpty ? 'Recordatorio de cuidado facial' : note,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_alarms_channel_v2',
            'Alarmas de Medicación y Cuidado',
            channelDescription: 'Canal para alarmas de medicamentos y rutinas flexibles',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            channelShowBadge: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Se repite diariamente
        payload: 'chat_dummy', // payload ficticio para evitar nulos
      );
      debugPrint("⏰ Alarma programada con ID: $notificationId para las $scheduledDate (Tipo: $type, Valor: $value)");
    }
  }

  Future<void> cancelCustomReminder(String alarmId) async {
    final int baseId = alarmId.hashCode;
    // Cancelamos hasta 12 posibles sub-alarmas (por si era un intervalo de cada 2 horas)
    for (int i = 0; i < 12; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
    debugPrint("❌ Alarma personalizada cancelada con ID base: $baseId");
  }
}
