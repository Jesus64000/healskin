import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:healskin/main.dart' as app;
import 'package:healskin/features/auth/register_screen.dart';

void main() {
  // Inicializa el binding de la prueba de integración
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Prueba de Integración Extremo a Extremo - Registro', () {
    testWidgets('Debe validar las reglas de negocio en el registro del paciente', (WidgetTester tester) async {
      // 1. Iniciar la aplicación HealSkin
      app.main();
      
      // Esperar a que pase el splash screen e inicializaciones
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Si estamos en el OnboardingScreen, hacer clic en "Saltar" para ir al Login
      final saltarFinder = find.text('Saltar');
      if (saltarFinder.evaluate().isNotEmpty) {
        await tester.tap(saltarFinder);
        await tester.pumpAndSettle();
      }

      // 3. En la pantalla de Login, hacer clic en "Regístrate aquí" para ir al RegisterScreen
      final registrateAquiFinder = find.text('Regístrate aquí');
      if (registrateAquiFinder.evaluate().isNotEmpty) {
        await tester.tap(registrateAquiFinder);
        await tester.pumpAndSettle();
      }

      // Confirmar que estamos en la pantalla de Registro
      expect(find.byType(RegisterScreen), findsOneWidget);

      // 4. PRUEBA: Validación de Nombre Completo Inválido
      // Buscamos los campos de texto
      final nameField = find.widgetWithText(TextFormField, 'Nombres y Apellidos Completos');
      final dniField = find.widgetWithText(TextFormField, 'Cédula / Documento de Identidad');
      final emailField = find.widgetWithText(TextFormField, 'Email');
      final passField = find.widgetWithText(TextFormField, 'Contraseña');
      final confirmPassField = find.widgetWithText(TextFormField, 'Confirmar Contraseña');
      final submitButton = find.text('Crear cuenta');

      // Intentamos escribir un nombre con números e incompleto
      await tester.enterText(nameField, 'Pedro123');
      await tester.pumpAndSettle();

      // Pulsamos el botón de submit para disparar las validaciones del formulario
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verificamos que se muestre el error de nombre inválido
      expect(find.text('El nombre no debe contener números'), findsOneWidget);

      // 5. PRUEBA: Validación de Cédula Inválida
      // Escribimos un nombre válido, pero una cédula muy corta (menos de 5 dígitos)
      await tester.enterText(nameField, 'Pedro Pérez');
      await tester.enterText(dniField, '123');
      await tester.pumpAndSettle();

      // Disparamos validación
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verificamos error de cédula
      expect(find.text('La cédula debe tener entre 5 y 8 dígitos'), findsOneWidget);

      // 6. PRUEBA: Validación de Contraseña Débil
      // Escribimos cédula válida, pero contraseña sin mayúsculas ni caracteres especiales
      await tester.enterText(dniField, '24890312');
      await tester.enterText(passField, '123456');
      await tester.pumpAndSettle();

      // Disparamos validación
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verificamos que al fallar notifica los requisitos faltantes específicos
      expect(find.text('Requisitos faltantes: letra mayúscula, letra minúscula, carácter especial'), findsOneWidget);

      // 7. PRUEBA: Éxito en validaciones locales con datos correctos
      await tester.enterText(passField, 'Clave123!');
      await tester.enterText(confirmPassField, 'Clave123!');
      await tester.enterText(emailField, 'paciente.prueba@healskin.com');
      await tester.pumpAndSettle();

      // Al presionar el botón con los datos correctos, las validaciones locales deben pasar
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Las advertencias de validación locales deben desaparecer de la pantalla
      expect(find.text('El nombre no debe contener números'), findsNothing);
      expect(find.text('La cédula debe tener entre 5 y 8 dígitos'), findsNothing);
      expect(find.text('Requisitos faltantes: letra mayúscula, letra minúscula, carácter especial'), findsNothing);
    });
  });
}
