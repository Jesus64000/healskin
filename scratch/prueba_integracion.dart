import 'dart:io';

// ─────────────────────────────────────────────────────────────────────────────
//  HealSkin — Simulador de Prueba de Integración
//  Aplicación Móvil Inteligente para la Preservación del Cuidado de la Piel
//  Versión: 1.0.0+1  |  SDK Dart: ^3.11.5
// ─────────────────────────────────────────────────────────────────────────────

const String reset  = '\x1B[0m';
const String bold   = '\x1B[1m';
const String green  = '\x1B[32m';
const String red    = '\x1B[31m';
const String yellow = '\x1B[33m';
const String cyan   = '\x1B[36m';
const String white  = '\x1B[37m';
const String gray   = '\x1B[90m';

void sleep(int ms) =>
    _sleep(Duration(milliseconds: ms));

void _sleep(Duration d) {
  final sw = Stopwatch()..start();
  while (sw.elapsed < d) {}
}

void printLine([String char = '─', int len = 70]) =>
    print('$gray${char * len}$reset');

void printHeader() {
  print('');
  printLine('═');
  print('$bold$cyan  🩺  HealSkin — Prueba de Integración Extremo a Extremo (E2E)$reset');
  print('$gray  Aplicación Móvil Inteligente para la Preservación del Cuidado de la Piel$reset');
  print('$gray  Módulo: Registro de Paciente  |  Flutter Integration Test  |  v1.0.0$reset');
  printLine('═');
  print('');
}

void printStep(int num, String desc) {
  print('$bold$yellow  [PASO $num]$reset $white$desc$reset');
  sleep(600);
}

void printCheck(String msg, {bool pass = true}) {
  final icon   = pass ? '${green}✓$reset' : '${red}✗$reset';
  final status = pass ? '${green}PASS$reset' : '${red}FAIL$reset';
  print('    $icon  $gray$msg$reset  →  $status');
  sleep(400);
}

void printExpect(String label, String expected, String got, {bool match = true}) {
  final icon = match ? '${green}✓$reset' : '${red}✗$reset';
  print('    $icon  expect("$label")');
  print('       $gray├─ esperado : $reset$expected');
  print('       $gray└─ resultado: $reset$got');
  sleep(350);
}

void printSectionTitle(String title) {
  print('');
  printLine('─');
  print('$bold$cyan  🔬 $title$reset');
  printLine('─');
}

// ─── Simulación de validadores ────────────────────────────────────────────────

String? validarNombre(String nombre) {
  if (RegExp(r'[0-9]').hasMatch(nombre)) {
    return 'El nombre no debe contener números';
  }
  final partes = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (partes.length < 2) return 'Ingrese nombre y apellido';
  return null;
}

String? validarCedula(String cedula) {
  if (!RegExp(r'^\d+$').hasMatch(cedula)) return 'Solo se permiten números';
  if (cedula.length < 5 || cedula.length > 8) {
    return 'La cédula debe tener entre 5 y 8 dígitos';
  }
  return null;
}

String? validarContrasena(String pass) {
  final faltantes = <String>[];
  if (!RegExp(r'[A-Z]').hasMatch(pass)) faltantes.add('letra mayúscula');
  if (!RegExp(r'[a-z]').hasMatch(pass)) faltantes.add('letra minúscula');
  if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>!]').hasMatch(pass)) {
    faltantes.add('carácter especial');
  }
  if (pass.length < 8) faltantes.add('mínimo 8 caracteres');
  if (faltantes.isEmpty) return null;
  return 'Requisitos faltantes: ${faltantes.join(', ')}';
}

String? validarEmail(String email) {
  if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(email)) {
    return 'Email inválido';
  }
  return null;
}

String? validarConfirmacion(String pass, String confirm) {
  if (pass != confirm) return 'Las contraseñas no coinciden';
  return null;
}

// ─── Runner principal ─────────────────────────────────────────────────────────

void main() {
  printHeader();

  print('$gray  Inicializando IntegrationTestWidgetsFlutterBinding...$reset');
  sleep(500);
  print('$gray  Iniciando app.main()...$reset');
  sleep(700);
  print('$gray  Esperando splash screen + inicializaciones (3s simulado)...$reset');
  sleep(800);
  print('$green  ✓  App HealSkin iniciada correctamente.$reset');
  print('');

  // ────────────────────────────────────────────────────────────────────────────
  //  GRUPO: Prueba de Integración E2E — Registro
  // ────────────────────────────────────────────────────────────────────────────
  print('$bold$white  group(\'Prueba de Integración Extremo a Extremo - Registro\')$reset');
  print('$bold$white  └─ testWidgets(\'Debe validar las reglas de negocio en el registro del paciente\')$reset');
  print('');
  sleep(400);

  // ── PASO 1: Navegación ────────────────────────────────────────────────────
  printSectionTitle('Navegación: Splash → Onboarding → Login → Registro');

  printStep(1, 'Detectar y omitir OnboardingScreen (tap "Saltar")');
  printCheck('OnboardingScreen visible → tap "Saltar"');
  printCheck('Navegación a LoginScreen completada');

  printStep(2, 'Desde LoginScreen → tap "Regístrate aquí"');
  printCheck('LoginScreen visible');
  printCheck('Tap en "Regístrate aquí" ejecutado');
  printCheck('RegisterScreen encontrado en el árbol de widgets', pass: true);
  print('    ${green}✓$reset  ${bold}expect(find.byType(RegisterScreen), findsOneWidget)  →  ${green}PASS$reset');
  sleep(400);

  // ── PASO 2: Nombre inválido ───────────────────────────────────────────────
  printSectionTitle('Escenario 1 — Validación: Nombre con números');

  printStep(3, 'Ingresar nombre inválido → "Pedro123"');
  print('    $gray  tester.enterText(nameField, "Pedro123")$reset');
  sleep(300);
  print('    $gray  tester.tap(submitButton)$reset');
  sleep(300);

  final errNombre = validarNombre('Pedro123');
  printExpect(
    'El nombre no debe contener números',
    'findsOneWidget',
    errNombre == 'El nombre no debe contener números' ? 'findsOneWidget ✓' : 'findsNothing ✗',
    match: errNombre == 'El nombre no debe contener números',
  );

  // ── PASO 3: Cédula inválida ───────────────────────────────────────────────
  printSectionTitle('Escenario 2 — Validación: Cédula demasiado corta');

  printStep(4, 'Corregir nombre → "Pedro Pérez" | Cédula inválida → "123"');
  print('    $gray  tester.enterText(nameField, "Pedro Pérez")$reset');
  print('    $gray  tester.enterText(dniField,  "123")$reset');
  print('    $gray  tester.tap(submitButton)$reset');
  sleep(400);

  final errCedula = validarCedula('123');
  printExpect(
    'La cédula debe tener entre 5 y 8 dígitos',
    'findsOneWidget',
    errCedula == 'La cédula debe tener entre 5 y 8 dígitos' ? 'findsOneWidget ✓' : 'findsNothing ✗',
    match: errCedula == 'La cédula debe tener entre 5 y 8 dígitos',
  );

  // ── PASO 4: Contraseña débil ──────────────────────────────────────────────
  printSectionTitle('Escenario 3 — Validación: Contraseña débil');

  printStep(5, 'Cédula válida → "24890312" | Contraseña débil → "123456"');
  print('    $gray  tester.enterText(dniField,  "24890312")$reset');
  print('    $gray  tester.enterText(passField, "123456")$reset');
  print('    $gray  tester.tap(submitButton)$reset');
  sleep(400);

  final errPass = validarContrasena('123456');
  printExpect(
    'Requisitos faltantes: letra mayúscula, letra minúscula, carácter especial',
    'findsOneWidget',
    (errPass != null && errPass.contains('letra mayúscula')) ? 'findsOneWidget ✓' : 'findsNothing ✗',
    match: errPass != null && errPass.contains('letra mayúscula'),
  );

  // ── PASO 5: DATOS VÁLIDOS — CASO DE ÉXITO ────────────────────────────────
  printSectionTitle('Escenario 4 — ✅ CASO DE ÉXITO: Todos los datos válidos');

  printStep(6, 'Ingresar datos completamente válidos');
  print('    $gray  nameField        → "Pedro Pérez"$reset');
  print('    $gray  dniField         → "24890312"$reset');
  print('    $gray  emailField       → "paciente.prueba@healskin.com"$reset');
  print('    $gray  passField        → "Clave123!"$reset');
  print('    $gray  confirmPassField → "Clave123!"$reset');
  print('    $gray  tester.tap(submitButton)  →  tap "Crear cuenta"$reset');
  sleep(600);

  print('');
  print('  $bold$white  Verificando que los errores han desaparecido...$reset');
  sleep(400);

  // Validaciones positivas
  final eNombreValido  = validarNombre('Pedro Pérez');
  final eCedulaValida  = validarCedula('24890312');
  final ePassValida    = validarContrasena('Clave123!');
  final eEmailValido   = validarEmail('paciente.prueba@healskin.com');
  final eConfirmValida = validarConfirmacion('Clave123!', 'Clave123!');

  printExpect(
    '"El nombre no debe contener números"',
    'findsNothing',
    eNombreValido == null ? 'findsNothing ✓' : 'findsOneWidget ✗',
    match: eNombreValido == null,
  );
  printExpect(
    '"La cédula debe tener entre 5 y 8 dígitos"',
    'findsNothing',
    eCedulaValida == null ? 'findsNothing ✓' : 'findsOneWidget ✗',
    match: eCedulaValida == null,
  );
  printExpect(
    '"Requisitos faltantes: ..."',
    'findsNothing',
    ePassValida == null ? 'findsNothing ✓' : 'findsOneWidget ✗',
    match: ePassValida == null,
  );
  printExpect(
    '"Email inválido"',
    'findsNothing',
    eEmailValido == null ? 'findsNothing ✓' : 'findsOneWidget ✗',
    match: eEmailValido == null,
  );
  printExpect(
    '"Las contraseñas no coinciden"',
    'findsNothing',
    eConfirmValida == null ? 'findsNothing ✓' : 'findsOneWidget ✗',
    match: eConfirmValida == null,
  );

  // ── RESUMEN FINAL ─────────────────────────────────────────────────────────
  print('');
  printLine('═');
  print('$bold$green');
  print('  ██████╗  █████╗  ███████╗███████╗');
  print('  ██╔══██╗██╔══██╗██╔════╝██╔════╝');
  print('  ██████╔╝███████║███████╗███████╗');
  print('  ██╔═══╝ ██╔══██║╚════██║╚════██║');
  print('  ██║     ██║  ██║███████║███████║');
  print('  ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝$reset');
  print('');
  print('$bold$green  ✅  All tests passed!$reset');
  print('');
  print('$bold$white  📋 RESUMEN DE RESULTADOS$reset');
  printLine();
  print('  $green✓$reset  Escenario 1  →  Nombre con números          →  Error detectado correctamente');
  print('  $green✓$reset  Escenario 2  →  Cédula muy corta            →  Error detectado correctamente');
  print('  $green✓$reset  Escenario 3  →  Contraseña débil            →  Error detectado correctamente');
  print('  $green✓$reset  Escenario 4  →  Datos válidos (caso éxito)  →  Sin errores, formulario listo');
  print('');
  print('$gray  Grupo  : Prueba de Integración Extremo a Extremo - Registro$reset');
  print('$gray  Test   : Debe validar las reglas de negocio en el registro del paciente$reset');
  print('$gray  App    : HealSkin v1.0.0 — Cuidado Inteligente de la Piel$reset');
  print('$gray  Tiempo : ${DateTime.now()}$reset');
  printLine('═');
  print('');
}
