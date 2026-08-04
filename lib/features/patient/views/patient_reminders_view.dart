import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import 'patient_appointments_provider.dart';
import '../../../core/services/notification_service.dart';

class PatientRemindersView extends ConsumerStatefulWidget {
  const PatientRemindersView({super.key});

  @override
  ConsumerState<PatientRemindersView> createState() => _PatientRemindersViewState();
}

class _PatientRemindersViewState extends ConsumerState<PatientRemindersView> {
  List<Map<String, dynamic>> _morningRoutine = [];
  List<Map<String, dynamic>> _nightRoutine = [];
  List<Map<String, dynamic>> _customReminders = [];

  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  String _getPrefKey(String baseKey) {
    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'guest';
    return '${baseKey}_$userId';
  }

  Future<void> _loadPreferences() async {
    bool loadFailed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? morningJson = prefs.getString(_getPrefKey('healskin_morning_routine'));
      final String? nightJson = prefs.getString(_getPrefKey('healskin_night_routine'));
      final String? customJson = prefs.getString(_getPrefKey('healskin_custom_reminders'));

      setState(() {
        if (morningJson != null) {
          _morningRoutine = List<Map<String, dynamic>>.from(
            (json.decode(morningJson) as List).map((item) => Map<String, dynamic>.from(item))
          );
        } else {
          _morningRoutine = [
            {'id': 'm1', 'task': 'Limpiador facial suave', 'done': false, 'desc': 'Elimina el exceso de grasa y sudor nocturno'},
            {'id': 'm2', 'task': 'Crema hidratante ligera', 'done': false, 'desc': 'Restaura la barrera de hidratación'},
            {'id': 'm3', 'task': 'Protector Solar FPS 50+', 'done': false, 'desc': 'Vital para prevenir manchas y envejecimiento'},
          ];
        }

        if (nightJson != null) {
          _nightRoutine = List<Map<String, dynamic>>.from(
            (json.decode(nightJson) as List).map((item) => Map<String, dynamic>.from(item))
          );
        } else {
          _nightRoutine = [
            {'id': 'n1', 'task': 'Limpieza facial profunda', 'done': false, 'desc': 'Remueve impurezas y polución del día'},
            {'id': 'n2', 'task': 'Suero activo / Retinol', 'done': false, 'desc': 'Estimula la regeneración celular'},
            {'id': 'n3', 'task': 'Crema nutritiva restauradora', 'done': false, 'desc': 'Repara la piel mientras duermes'},
          ];
        }

        if (customJson != null) {
          _customReminders = List<Map<String, dynamic>>.from(
            (json.decode(customJson) as List).map((item) => Map<String, dynamic>.from(item))
          );
        } else {
          _customReminders = [
            {'id': 'c1', 'title': 'Tomar abundante agua (2L)', 'time': '02:00 PM', 'note': 'Mantener hidratación celular', 'active': true},
            {'id': 'c2', 'title': 'Re-aplicar Protector Solar', 'time': '12:00 PM', 'note': 'Retocar cada 4 horas', 'active': true},
          ];
        }

        // --- 📅 REINICIO DIARIO DE RUTINAS ---
        final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final String? lastDate = prefs.getString(_getPrefKey('healskin_routine_last_date'));
        
        if (lastDate != todayStr) {
          for (var item in _morningRoutine) {
            item['done'] = false;
          }
          for (var item in _nightRoutine) {
            item['done'] = false;
          }
          prefs.setString(_getPrefKey('healskin_morning_routine'), json.encode(_morningRoutine));
          prefs.setString(_getPrefKey('healskin_night_routine'), json.encode(_nightRoutine));
          prefs.setString(_getPrefKey('healskin_routine_last_date'), todayStr);
        }

        _isLoadingPrefs = false;
      });
    } catch (e) {
      debugPrint("Error loading SharedPreferences: $e");
      loadFailed = true;
      setState(() {
        _morningRoutine = [
          {'id': 'm1', 'task': 'Limpiador facial suave', 'done': false, 'desc': 'Elimina el exceso de grasa y sudor nocturno'},
          {'id': 'm2', 'task': 'Crema hidratante ligera', 'done': false, 'desc': 'Restaura la barrera de hidratación'},
          {'id': 'm3', 'task': 'Protector Solar FPS 50+', 'done': false, 'desc': 'Vital para prevenir manchas y envejecimiento'},
        ];
        _nightRoutine = [
          {'id': 'n1', 'task': 'Limpieza facial profunda', 'done': false, 'desc': 'Remueve impurezas y polución del día'},
          {'id': 'n2', 'task': 'Suero activo / Retinol', 'done': false, 'desc': 'Estimula la regeneración celular'},
          {'id': 'n3', 'task': 'Crema nutritiva restauradora', 'done': false, 'desc': 'Repara la piel mientras duermes'},
        ];
        _customReminders = [
          {'id': 'c1', 'title': 'Tomar abundante agua (2L)', 'time': '02:00 PM', 'note': 'Mantener hidratación celular', 'active': true},
          {'id': 'c2', 'title': 'Re-aplicar Protector Solar', 'time': '12:00 PM', 'note': 'Retocar cada 4 horas', 'active': true},
        ];
        _isLoadingPrefs = false;
      });
    }

    if (!loadFailed) {
      try {
        await _syncAllNotifications();
      } catch (e) {
        debugPrint("Error running _syncAllNotifications: $e");
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getPrefKey('healskin_morning_routine'), json.encode(_morningRoutine));
      await prefs.setString(_getPrefKey('healskin_night_routine'), json.encode(_nightRoutine));
      await prefs.setString(_getPrefKey('healskin_custom_reminders'), json.encode(_customReminders));
    } catch (e) {
      debugPrint("Error saving SharedPreferences: $e");
    }
  }

  Future<void> _syncAllNotifications() async {
    final notificationService = NotificationService();
    
    // ☀️ Programar recordatorio de rutina de mañana a las 8:00 AM
    try {
      await notificationService.scheduleDailyRoutineReminder(
        id: 1001,
        title: "☀️ Rutina de la Mañana",
        body: "Es hora de iniciar tu día cuidando tu piel. ¡Completa tu rutina de mañana!",
        hour: 8,
        minute: 0,
      );
    } catch (e) {
      debugPrint("Error scheduling morning routine: $e");
    }

    // 🌙 Programar recordatorio de rutina de noche a las 8:00 PM
    try {
      await notificationService.scheduleDailyRoutineReminder(
        id: 1002,
        title: "🌙 Rutina de la Noche",
        body: "Termina el día consintiendo tu piel. ¡Completa tu rutina nocturna!",
        hour: 20,
        minute: 0,
      );
    } catch (e) {
      debugPrint("Error scheduling night routine: $e");
    }

    // ⏰ Programar alarmas personalizadas activas
    for (final alarm in _customReminders) {
      try {
        if (alarm['active'] == true) {
          final type = alarm['type'] as String? ?? 'specific_time';
          final value = alarm['value'] as String? ?? (alarm['time'] as String? ?? '12:00 PM');

          await notificationService.scheduleCustomReminder(
            alarmId: alarm['id'] as String,
            title: alarm['title'] as String,
            note: (alarm['note'] ?? 'Recordatorio programado') as String,
            type: type,
            value: value,
          );
        } else {
          await notificationService.cancelCustomReminder(alarm['id'] as String);
        }
      } catch (e) {
        debugPrint("Error syncing alarm ${alarm['id']}: $e");
      }
    }
  }

  double get _overallProgress {
    final int morningDone = _morningRoutine.where((e) => e['done'] == true).length;
    final int nightDone = _nightRoutine.where((e) => e['done'] == true).length;
    final int totalTasks = _morningRoutine.length + _nightRoutine.length;
    return (morningDone + nightDone) / totalTasks;
  }

  void _showAddReminderModal({Map<String, dynamic>? reminderToEdit}) {
    final TextEditingController titleController = TextEditingController(text: reminderToEdit?['title'] ?? '');
    final TextEditingController noteController = TextEditingController(text: reminderToEdit?['note'] ?? '');
    
    TimeOfDay selectedTime = const TimeOfDay(hour: 16, minute: 0);
    String selectedType = reminderToEdit?['type'] ?? 'specific_time';
    String selectedPresetValue = 'morning';
    String selectedIntervalValue = '4';

    if (reminderToEdit != null) {
      final String val = reminderToEdit['value'] ?? (reminderToEdit['time'] ?? '');
      if (selectedType == 'specific_time' && val.contains(':')) {
        try {
          final parts = val.split(':');
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          selectedTime = TimeOfDay(hour: h, minute: m);
        } catch (_) {}
      } else if (selectedType == 'preset') {
        selectedPresetValue = val.isNotEmpty ? val : 'morning';
      } else if (selectedType == 'interval') {
        selectedIntervalValue = val.isNotEmpty ? val : '4';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 24, right: 24, top: 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminderToEdit == null ? "Agregar Alerta de Cuidado" : "Editar Alerta de Cuidado",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 15),

                    // Título
                    const Text("¿Qué deseas recordar? *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Ej. Protector Solar, Tomar agua, Crema...",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Nota
                    const Text("Nota / Descripción corta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: "Ej. Re-aplicar cada 4 horas en el rostro...",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Selector de tipo de frecuencia
                    const Text("Frecuencia del Recordatorio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Hora fija", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            selected: selectedType == 'specific_time',
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: selectedType == 'specific_time' ? AppColors.primary : AppColors.textSecondary),
                            onSelected: (val) {
                              if (val) setModalState(() => selectedType = 'specific_time');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Preajuste", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            selected: selectedType == 'preset',
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: selectedType == 'preset' ? AppColors.primary : AppColors.textSecondary),
                            onSelected: (val) {
                              if (val) setModalState(() => selectedType = 'preset');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text("Intervalo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            selected: selectedType == 'interval',
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            labelStyle: TextStyle(color: selectedType == 'interval' ? AppColors.primary : AppColors.textSecondary),
                            onSelected: (val) {
                              if (val) setModalState(() => selectedType = 'interval');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Configuración específica de la frecuencia
                    if (selectedType == 'specific_time') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Seleccionar hora exacta:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          TextButton.icon(
                            icon: const Icon(Icons.access_time, color: AppColors.primary),
                            label: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            onPressed: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedTime = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ] else if (selectedType == 'preset') ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedPresetValue,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'morning', child: Text("Mañana (08:00 AM)")),
                          DropdownMenuItem(value: 'afternoon', child: Text("Tarde (02:00 PM)")),
                          DropdownMenuItem(value: 'evening', child: Text("Noche (08:00 PM)")),
                          DropdownMenuItem(value: 'morning_afternoon', child: Text("Mañana y Tarde")),
                          DropdownMenuItem(value: 'morning_afternoon_evening', child: Text("Mañana, Tarde y Noche")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedPresetValue = val;
                            });
                          }
                        },
                      ),
                    ] else if (selectedType == 'interval') ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedIntervalValue,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: '2', child: Text("Cada 2 horas (Horario activo)")),
                          DropdownMenuItem(value: '4', child: Text("Cada 4 horas (Horario activo)")),
                          DropdownMenuItem(value: '6', child: Text("Cada 6 horas (Horario activo)")),
                          DropdownMenuItem(value: '8', child: Text("Cada 8 horas (Horario activo)")),
                          DropdownMenuItem(value: '12', child: Text("Cada 12 horas (Horario activo)")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedIntervalValue = val;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 25),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(reminderToEdit == null ? "Guardar Alerta" : "Actualizar Alerta", style: const TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Por favor escribe qué deseas recordar"), backgroundColor: AppColors.warning),
                            );
                            return;
                          }

                          final String alarmValue = selectedType == 'specific_time'
                              ? "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}"
                              : (selectedType == 'preset' ? selectedPresetValue : selectedIntervalValue);

                          if (reminderToEdit != null) {
                            setState(() {
                              reminderToEdit['title'] = titleController.text.trim();
                              reminderToEdit['type'] = selectedType;
                              reminderToEdit['value'] = alarmValue;
                              reminderToEdit['note'] = noteController.text.trim().isEmpty ? 'Recordatorio programado' : noteController.text.trim();
                            });
                            _savePreferences();

                            try {
                              if (reminderToEdit['active'] == true) {
                                NotificationService().scheduleCustomReminder(
                                  alarmId: reminderToEdit['id'] as String,
                                  title: reminderToEdit['title'] as String,
                                  note: reminderToEdit['note'] as String,
                                  type: reminderToEdit['type'] as String,
                                  value: reminderToEdit['value'] as String,
                                );
                              }
                            } catch (e) {
                              debugPrint("Error updating custom alarm: $e");
                            }
                          } else {
                            final Map<String, dynamic> newAlarm = {
                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                              'title': titleController.text.trim(),
                              'type': selectedType,
                              'value': alarmValue,
                              'note': noteController.text.trim().isEmpty ? 'Recordatorio programado' : noteController.text.trim(),
                              'active': true,
                            };

                            setState(() {
                              _customReminders.add(newAlarm);
                            });
                            _savePreferences();

                            try {
                              NotificationService().scheduleCustomReminder(
                                alarmId: newAlarm['id'] as String,
                                title: newAlarm['title'] as String,
                                note: newAlarm['note'] as String,
                                type: newAlarm['type'] as String,
                                value: newAlarm['value'] as String,
                              );
                            } catch (e) {
                              debugPrint("Error scheduling custom alarm: $e");
                            }
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(reminderToEdit == null ? "⏰ Alarma programada con éxito" : "✏️ Alarma actualizada con éxito"),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Escuchar citas en tiempo real para calcular cuentas regresivas
    final appointmentsAsync = ref.watch(myAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary), // Habilita la flecha de regreso premium
        title: const Text("Recordatorios y Hábitos", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderModal,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_alarm, color: Colors.white, size: 26),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📊 1. ANILLO DE PROGRESO DE RUTINAS DIARIAS (DISEÑO WOW)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  // Anillo visual
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 75,
                        height: 75,
                        child: CircularProgressIndicator(
                          value: _overallProgress,
                          strokeWidth: 8,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "${(_overallProgress * 100).toInt()}%",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Progreso de Cuidado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text(
                          "Completar tus rutinas diarias ayuda a que los diagnósticos de IA sean más exitosos.",
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 📅 2. CUENTA REGRESIVA DE CITAS MÉDICAS (SUPABASE REAL-TIME)
            appointmentsAsync.when(
              data: (apts) {
                final scheduled = apts.where((a) {
                  if (a['status'] != 'scheduled') return false;
                  final DateTime aptDate = DateTime.parse(a['appointment_date']).toLocal();
                  return aptDate.isAfter(DateTime.now());
                }).toList();
                if (scheduled.isEmpty) return const SizedBox.shrink();

                // Obtenemos la cita más cercana
                scheduled.sort((a, b) => DateTime.parse(a['appointment_date']).compareTo(DateTime.parse(b['appointment_date'])));
                final nextApt = scheduled.first;
                final DateTime aptDate = DateTime.parse(nextApt['appointment_date']).toLocal();
                final Duration timeLeft = aptDate.difference(DateTime.now());

                final int daysLeft = timeLeft.inDays;
                final int hoursLeft = timeLeft.inHours % 24;

                return Container(
                  margin: const EdgeInsets.only(bottom: 25),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, Color(0xFFFF9E95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: AppColors.secondary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.hourglass_empty, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("PRÓXIMA VIDEOCONSULTA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.1)),
                            const SizedBox(height: 4),
                            Text(
                              daysLeft > 0 
                                  ? "Faltan $daysLeft días y $hoursLeft horas"
                                  : "Faltan $hoursLeft horas para tu cita",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Fecha: ${DateFormat('dd/MM/yyyy - hh:mm a').format(aptDate)}",
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ☀️ 3. RUTINA DE LA MAÑANA
            _buildRoutineHeader("☀️ Rutina de la Mañana", Colors.amber[800]!, true),
            const SizedBox(height: 10),
            if (_morningRoutine.isEmpty)
              _buildEmptyRoutinePlaceholder(isMorning: true)
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _morningRoutine.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _morningRoutine.removeAt(oldIndex);
                    _morningRoutine.insert(newIndex, item);
                  });
                  _savePreferences();
                },
                itemBuilder: (context, index) {
                  final task = _morningRoutine[index];
                  return _buildRoutineTile(task, true, index);
                },
              ),
            const SizedBox(height: 25),

            // 🌙 4. RUTINA DE LA NOCHE
            _buildRoutineHeader("🌙 Rutina de la Noche", Colors.indigo[900]!, false),
            const SizedBox(height: 10),
            if (_nightRoutine.isEmpty)
              _buildEmptyRoutinePlaceholder(isMorning: false)
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _nightRoutine.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _nightRoutine.removeAt(oldIndex);
                    _nightRoutine.insert(newIndex, item);
                  });
                  _savePreferences();
                },
                itemBuilder: (context, index) {
                  final task = _nightRoutine[index];
                  return _buildRoutineTile(task, false, index);
                },
              ),
            const SizedBox(height: 25),

            // ⏰ 5. ALERTAS PERSONALIZADAS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "Alarmas de Medicación y Cuidado",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                TextButton(
                  onPressed: _showAddReminderModal,
                  child: const Text("Agregar", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_customReminders.isEmpty)
              _buildEmptyAlarms()
            else
              ..._customReminders.map((alarm) => _buildAlarmCard(alarm)),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildRoutineHeader(String title, Color iconColor, bool isMorning) {
    return Row(
      children: [
        Icon(Icons.spa_outlined, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _showAddEditRoutineStepModal(isMorning: isMorning),
          icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
          label: const Text("Añadir paso", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineTile(Map<String, dynamic> task, bool isMorning, int index) {
    final bool done = task['done'];
    return AnimatedContainer(
      key: ValueKey(task['id']),
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done ? AppColors.primary.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? AppColors.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_indicator,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            Checkbox(
              activeColor: AppColors.primary,
              value: done,
              onChanged: (val) {
                setState(() {
                  task['done'] = val;
                });
                _savePreferences(); // 🚀 Persiste el progreso de cuidado facial
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task['task'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: done ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task['desc'].toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task['desc'],
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
              onPressed: () => _showAddEditRoutineStepModal(isMorning: isMorning, stepToEdit: task),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              onPressed: () => _deleteRoutineStep(isMorning: isMorning, stepId: task['id']),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRoutinePlaceholder({required bool isMorning}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          Icon(Icons.spa_outlined, size: 30, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text(
            isMorning ? "No hay pasos en tu rutina de la mañana." : "No hay pasos en tu rutina de la noche.",
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddEditRoutineStepModal({required bool isMorning, Map<String, dynamic>? stepToEdit}) {
    final TextEditingController taskController = TextEditingController(text: stepToEdit != null ? stepToEdit['task'] : '');
    final TextEditingController descController = TextEditingController(text: stepToEdit != null ? stepToEdit['desc'] : '');
    final bool isEdit = stepToEdit != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 24, right: 24, top: 24
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? "Editar Paso de Rutina" : "Agregar Paso de Rutina",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 15),

                // Nombre del paso
                const Text("¿Qué producto o paso aplicarás? *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 5),
                TextField(
                  controller: taskController,
                  decoration: InputDecoration(
                    hintText: "Ej. Suero de Niacinamida, Gel Limpiador...",
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),

                // Descripción o notas
                const Text("Instrucciones o descripción *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 5),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    hintText: "Ej. Aplicar 3 gotas sobre rostro seco y limpio...",
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 25),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final taskName = taskController.text.trim();
                      final descName = descController.text.trim();

                      if (taskName.isEmpty || descName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Por favor, llena todos los campos marcados con *"),
                          backgroundColor: AppColors.danger,
                        ));
                        return;
                      }

                      setState(() {
                        if (isEdit) {
                          stepToEdit['task'] = taskName;
                          stepToEdit['desc'] = descName;
                        } else {
                          final newStep = {
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'task': taskName,
                            'desc': descName,
                            'done': false,
                          };
                          if (isMorning) {
                            _morningRoutine.add(newStep);
                          } else {
                            _nightRoutine.add(newStep);
                          }
                        }
                      });

                      _savePreferences();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      isEdit ? "Guardar Cambios" : "Agregar a Rutina",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteRoutineStep({required bool isMorning, required String stepId}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("¿Eliminar paso?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Esta acción quitará de forma permanente este paso de tu rutina diaria."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (isMorning) {
                    _morningRoutine.removeWhere((e) => e['id'] == stepId);
                  } else {
                    _nightRoutine.removeWhere((e) => e['id'] == stepId);
                  }
                });
                _savePreferences();
                Navigator.pop(context);
              },
              child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String _getAlarmReadableValue(Map<String, dynamic> alarm) {
    final type = alarm['type'] as String? ?? 'specific_time';
    final value = alarm['value'] as String? ?? (alarm['time'] as String? ?? '12:00 PM');

    if (type == 'specific_time') {
      try {
        final parts = value.split(':');
        if (parts.length == 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour % 12 == 0 ? 12 : hour % 12;
          final minStr = minute.toString().padLeft(2, '0');
          final hrStr = displayHour.toString().padLeft(2, '0');
          return "$hrStr:$minStr $period";
        }
      } catch (_) {}
      return value;
    } else if (type == 'preset') {
      switch (value) {
        case 'morning': return 'Mañana';
        case 'afternoon': return 'Tarde';
        case 'evening': return 'Noche';
        case 'morning_afternoon': return 'Mañana y Tarde';
        case 'morning_afternoon_evening': return 'Mañana, Tarde y Noche';
        default: return 'Preajuste';
      }
    } else if (type == 'interval') {
      return 'Cada $value h';
    }
    return value;
  }

  void _deleteAlarm(Map<String, dynamic> alarm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("¿Eliminar recordatorio?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Esta acción quitará de forma permanente este recordatorio de cuidado facial."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _customReminders.removeWhere((e) => e['id'] == alarm['id']);
                });
                _savePreferences();
                try {
                  await NotificationService().cancelCustomReminder(alarm['id'] as String);
                } catch (e) {
                  debugPrint("Error canceling alarm: $e");
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Recordatorio eliminado"), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                  );
                }
              },
              child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm) {
    final bool active = alarm['active'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.alarm, color: active ? AppColors.primary : AppColors.textSecondary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(alarm['note'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getAlarmReadableValue(alarm),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                    onPressed: () => _showAddReminderModal(reminderToEdit: alarm),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _deleteAlarm(alarm),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    activeColor: AppColors.primary,
                    value: active,
                    onChanged: (val) async {
                      setState(() {
                        alarm['active'] = val;
                      });
                      _savePreferences();
                      try {
                        if (val) {
                          final type = alarm['type'] as String? ?? 'specific_time';
                          final value = alarm['value'] as String? ?? (alarm['time'] as String? ?? '12:00 PM');
                          
                          await NotificationService().scheduleCustomReminder(
                            alarmId: alarm['id'] as String,
                            title: alarm['title'] as String,
                            note: (alarm['note'] ?? 'Recordatorio programado') as String,
                            type: type,
                            value: value,
                          );
                        } else {
                          await NotificationService().cancelCustomReminder(alarm['id'] as String);
                        }
                      } catch (e) {
                        debugPrint("Error toggling alarm: $e");
                      }
                    },
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyAlarms() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.alarm_off, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          const Text("No tienes alarmas configuradas", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

