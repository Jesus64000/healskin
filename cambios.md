# 📋 Registro de Cambios - HealSkin

Este documento registra todas las correcciones solicitadas por el cliente, ajustadas según el marco teórico y los evaluadores, además de mejoras técnicas adicionales.

---

## 🔐 Fase 1: Autenticación, Registro y Perfil
- [x] **Validación de Nombre Completo:** Bloqueo de entrada numérica e indicación para solicitar nombres y apellidos completos. ([`register_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/auth/register_screen.dart))
- [x] **Selector y Delimitación de Cédula:** Selector de nacionalidad/tipo (`V`, `E`, `J`, `P`) y límite máximo de 8 dígitos (V/E/J) y 10 (P). ([`register_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/auth/register_screen.dart))
- [x] **Checklist Interactivo de Requisitos de Contraseña:** Muestra los 4 requisitos (min 6 caracteres, mayúscula, minúscula, carácter especial) con actualización dinámico visual (rojo/verde). ([`register_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/auth/register_screen.dart))
- [x] **Diálogo de Verificación por Correo:** Aviso de confirmación de e-mail post-registro. ([`register_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/auth/register_screen.dart))
- [x] **Aviso de Datos Demográficos:** Banner prominente en la pantalla de inicio del paciente para recordarle llenar edad y género. ([`patient_home_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/patient/views/patient_home_view.dart))

---

## 🏥 Fase 2: Historial Médico Digital, Recetas y PDF
- [x] **Tarjeta Interactiva de Indicaciones Médicas (`img1`):** Hacer tappable la tarjeta de procedimiento/indicación en *Mis Citas* para abrir un `BottomSheet` detallado con Diagnóstico formal del médico, Receta completa, Frecuencia y Notas. ([`patient_appointments_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/patient/views/patient_appointments_view.dart))
- [x] **Línea de Tiempo con Hitos Médicos (`img2`):** Integrar los diagnósticos y actualizaciones del médico especialista en la línea de tiempo del paciente junto a los escaneos de IA. ([`patient_timeline_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/patient/views/patient_timeline_view.dart))
- [x] **Renombrar Sección en Vista Médico (`img3`):** Cambiar *"Tratamientos y Procedimientos"* a solo *"Procedimientos"*. ([`patient_clinical_detail_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/doctor/patient_clinical_detail_screen.dart))
- [x] **Estructuración de Receta Médica (`img3`):** Dividir la Receta Médica en 2 categorías claras: **Tópico** (cremas/geles) y **Vía Oral / Tomado** (pastillas/cápsulas). ([`patient_clinical_detail_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/doctor/patient_clinical_detail_screen.dart))
- [x] **Filtro de IA en Reporte PDF (`img5`):** Excluir escaneos crudos de IA del informe impreso/PDF para dejar únicamente diagnósticos médicos oficiales e indicaciones. ([`patient_clinical_detail_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/doctor/patient_clinical_detail_screen.dart))
- [x] **Selección Múltiple de Patologías para PDF (`img5`):** Permitir al médico seleccionar mediante checkboxes qué patología(s) incluir en el reporte PDF antes de exportarlo. ([`patient_clinical_detail_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/doctor/patient_clinical_detail_screen.dart))

---

## 🛡️ Fase 3: Módulo Admin, Usuarios, Escaneos y Cuestionarios
- [x] **Borrado Real de Usuarios (`img6`):** Corregir el botón "Eliminar" para que desactive/elimine los registros en Supabase e invalide los providers de la UI. ([`admin_users_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/admin/admin_users_view.dart))
- [x] **Visualización de Escaneos de IA en Admin (`img12`):** Corregir consulta de Supabase (`allScansProvider`) para mostrar fotos y análisis de IA a los administradores. ([`admin_scans_history_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/admin/admin_scans_history_screen.dart))
- [x] **Ajuste de UI Creador de Cuestionarios (`img13`):** Resolver superposición del teclado y ajuste de scroll en el panel del admin. ([`quizzes_admin_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/admin/quizzes_admin_screen.dart))
- [x] **Cuestionarios Dinámicos en Paciente (`img13`):** Mostrar en la app del paciente los cuestionarios creados por el admin. ([`dynamic_quiz_screen.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/patient/views/dynamic_quiz_screen.dart))

---

## 💬 Fase 4: Agenda, Chat, Notificaciones y Ubicación
- [x] **Remover Accesos Duplicados a Chat (`img7` & `img8`):** Eliminar botón redundante pequeño (verde) en home de paciente y médicos, dejando solo el botón destacado (morado). ([`patient_home_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/patient/views/patient_home_view.dart))
- [x] **Restricción por Bloqueo de Horarios (`img8`):** Impedir que los pacientes agenden citas en bloques de horario/días bloqueados por el médico. ([`doctor_agenda_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/doctor/doctor_agenda_view.dart))
- [x] **Notificación y Reagendamiento (`img8`):** Enviar aviso de disculpa y botón para reagendar si el médico bloquea una fecha con citas previas. ([`doctor_agenda_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/doctor/doctor_agenda_view.dart))
- [x] **Notificaciones en Tiempo Real para Chat (`img8`):** Enviar notificaciones cuando haya nuevos mensajes entre médico y paciente. ([`chat_notification_listener.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/chat/chat_notification_listener.dart))
- [x] **Datos Dinámicos de Clínica (`img9`):** Cargar nombre y dirección exacta de la clínica desde el perfil real del médico / geolocalización. ([`patient_clinic_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/patient/views/patient_clinic_view.dart))

---

## ⏰ Fase 5: Formato de Horas, Alarmas y Pulido Final
- [x] **Estandarización 12h AM/PM:** Unificar la configuración y visualización de horas en toda la aplicación (`alwaysUse24HourFormat: false`).
- [x] **Corrección TimePicker por Teclado (`img10`):** Resolver el error de *"Hora no válida"* al escribir números manualmente en el selector de hora.
- [x] **Ajuste de UI de Medicamentos (`img11`):** Compactar distancia entre nombre de producto e indicaciones. ([`patient_reminders_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/patient/views/patient_reminders_view.dart))
- [x] **Sistema de Alarmas Local (`img11`):** Reparar las 3 modalidades de alarmas (Hora fija, Predeterminada y Escala) con `flutter_local_notifications`. ([`patient_reminders_view.dart`](file:///home/Jesus64/Documentos/healskin/lib/features/patient/views/patient_reminders_view.dart))

---

## 🌟 Mejoras Adicionales Recomendadas
- [x] **Persistencia Local Offline de Alarmas:** Guardar recordatorios en `shared_preferences` para asegurar su funcionamiento tras reinicios.
- [x] **Máscaras de Entrada (`InputFormatters`):** Filtrar entradas en campos telefónicos y de cédula.
- [x] **Skeletons de Carga:** Mejorar estados de carga en listas e imágenes.
- [x] **Políticas RLS en Supabase Storage:** Asegurar lectura de buckets de escaneos para el rol admin.
- [x] **Feedback Háptico:** Respuesta vibratoria sutil al interactuar con TimePickers o menús.
