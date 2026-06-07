import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
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

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? morningJson = prefs.getString('healskin_morning_routine');
      final String? nightJson = prefs.getString('healskin_night_routine');
      final String? customJson = prefs.getString('healskin_custom_reminders');

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
        final String? lastDate = prefs.getString('healskin_routine_last_date');
        
        if (lastDate != todayStr) {
          for (var item in _morningRoutine) {
            item['done'] = false;
          }
          for (var item in _nightRoutine) {
            item['done'] = false;
          }
          prefs.setString('healskin_morning_routine', json.encode(_morningRoutine));
          prefs.setString('healskin_night_routine', json.encode(_nightRoutine));
          prefs.setString('healskin_routine_last_date', todayStr);
        }

        _isLoadingPrefs = false;
      });

      // 🔔 Sincronizar alarmas y recordatorios en segundo plano
      await _syncAllNotifications();
    } catch (e) {
      debugPrint("Error loading SharedPreferences: $e");
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
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('healskin_morning_routine', json.encode(_morningRoutine));
      await prefs.setString('healskin_night_routine', json.encode(_nightRoutine));
      await prefs.setString('healskin_custom_reminders', json.encode(_customReminders));
    } catch (e) {
      debugPrint("Error saving SharedPreferences: $e");
    }
  }

  Future<void> _syncAllNotifications() async {
    final notificationService = NotificationService();
    
    // ☀️ Programar recordatorio de rutina de mañana a las 8:00 AM
    await notificationService.scheduleDailyRoutineReminder(
      id: 1001,
      title: "☀️ Rutina de la Mañana",
      body: "Es hora de iniciar tu día cuidando tu piel. ¡Completa tu rutina de mañana!",
      hour: 8,
      minute: 0,
    );

    // 🌙 Programar recordatorio de rutina de noche a las 8:00 PM
    await notificationService.scheduleDailyRoutineReminder(
      id: 1002,
      title: "🌙 Rutina de la Noche",
      body: "Termina el día consintiendo tu piel. ¡Completa tu rutina nocturna!",
      hour: 20,
      minute: 0,
    );

    // ⏰ Programar alarmas personalizadas activas
    for (final alarm in _customReminders) {
      if (alarm['active'] == true) {
        await notificationService.scheduleMedicationAlarm(
          alarmId: alarm['id'] as String,
          title: alarm['title'] as String,
          note: (alarm['note'] ?? 'Recordatorio programado') as String,
          timeStr: alarm['time'] as String,
        );
      } else {
        await notificationService.cancelNotification(alarm['id'] as String);
      }
    }
  }

  double get _overallProgress {
    final int morningDone = _morningRoutine.where((e) => e['done'] == true).length;
    final int nightDone = _nightRoutine.where((e) => e['done'] == true).length;
    final int totalTasks = _morningRoutine.length + _nightRoutine.length;
    return (morningDone + nightDone) / totalTasks;
  }

  void _showAddReminderModal() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 16, minute: 0);

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
                    const Text("Agregar Alerta Personalizada", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 15),

                    // Título
                    const Text("¿Qué deseas recordar? *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "Ej. Aplicar gel hidratante, Tomar cápsula...",
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
                        hintText: "Ej. Receta del doctor Juan...",
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Selector de hora
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Hora de la alarma:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        TextButton.icon(
                          icon: const Icon(Icons.access_time, color: AppColors.primary),
                          label: Text(selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
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
                        child: const Text("Guardar Alerta", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Por favor escribe qué deseas recordar"), backgroundColor: AppColors.warning),
                            );
                            return;
                          }

                          final Map<String, dynamic> newAlarm = {
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'title': titleController.text.trim(),
                            'time': selectedTime.format(context),
                            'note': noteController.text.trim().isEmpty ? 'Recordatorio programado' : noteController.text.trim(),
                            'active': true,
                          };

                          setState(() {
                            _customReminders.add(newAlarm);
                          });
                          _savePreferences(); // 🚀 Guarda en SharedPreferences

                          NotificationService().scheduleMedicationAlarm(
                            alarmId: newAlarm['id'] as String,
                            title: newAlarm['title'] as String,
                            note: newAlarm['note'] as String,
                            timeStr: newAlarm['time'] as String,
                          );

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("⏰ Alarma programada con éxito"), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
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
                final scheduled = apts.where((a) => a['status'] == 'scheduled').toList();
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
              ..._morningRoutine.map((task) => _buildRoutineTile(task, true)),
            const SizedBox(height: 25),

            // 🌙 4. RUTINA DE LA NOCHE
            _buildRoutineHeader("🌙 Rutina de la Noche", Colors.indigo[900]!, false),
            const SizedBox(height: 10),
            if (_nightRoutine.isEmpty)
              _buildEmptyRoutinePlaceholder(isMorning: false)
            else
              ..._nightRoutine.map((task) => _buildRoutineTile(task, false)),
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

  Widget _buildRoutineTile(Map<String, dynamic> task, bool isMorning) {
    final bool done = task['done'];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: done ? AppColors.primary.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? AppColors.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          activeColor: AppColors.primary,
          value: done,
          onChanged: (val) {
            setState(() {
              task['done'] = val;
            });
            _savePreferences(); // 🚀 Persiste el progreso de cuidado facial
          },
        ),
        title: Text(
          task['task'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: done ? AppColors.textSecondary : AppColors.textPrimary,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(task['desc'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                alarm['time'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Switch.adaptive(
                activeColor: AppColors.primary,
                value: active,
                onChanged: (val) async {
                  setState(() {
                    alarm['active'] = val;
                  });
                  _savePreferences(); // 🚀 Persiste el cambio de estado
                  if (val) {
                    await NotificationService().scheduleMedicationAlarm(
                      alarmId: alarm['id'] as String,
                      title: alarm['title'] as String,
                      note: (alarm['note'] ?? 'Recordatorio programado') as String,
                      timeStr: alarm['time'] as String,
                    );
                  } else {
                    await NotificationService().cancelNotification(alarm['id'] as String);
                  }
                },
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

