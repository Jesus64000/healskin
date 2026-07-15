import 'package:flutter_test/flutter_test.dart';
import 'package:healskin/core/utils/validators.dart';

void main() {
  group('Pruebas Unitarias del Validador de Nombre Completo', () {
    test('Debe retornar un error si el nombre es nulo o vacío', () {
      expect(Validators.validateFullName(null), "Ingresa tu nombre completo");
      expect(Validators.validateFullName(""), "Ingresa tu nombre completo");
      expect(Validators.validateFullName("   "), "Ingresa tu nombre completo");
    });

    test('Debe retornar un error si el nombre tiene menos de 3 caracteres', () {
      expect(Validators.validateFullName("Ab"), "El nombre debe tener al menos 3 caracteres");
    });

    test('Debe retornar un error si el nombre contiene números', () {
      expect(Validators.validateFullName("Juan 34 Pérez"), "El nombre no debe contener números");
    });

    test('Debe retornar un error si falta el apellido (no tiene espacios)', () {
      expect(Validators.validateFullName("Mariana"), "Por favor, ingresa tus nombres y apellidos completos");
    });

    test('Debe retornar nulo (éxito) si el nombre y apellido son válidos', () {
      expect(Validators.validateFullName("Mariana Sandrea"), null);
      expect(Validators.validateFullName("Juan Carlos Pérez Gómez"), null);
    });
  });

  group('Pruebas Unitarias del Validador de Cédula (DNI)', () {
    test('Debe retornar un error si la cédula es nula o vacía', () {
      expect(Validators.validateDni(null), "Ingresa tu cédula o documento");
      expect(Validators.validateDni(""), "Ingresa tu cédula o documento");
    });

    test('Debe retornar un error si tiene menos de 5 dígitos o más de 8 dígitos', () {
      expect(Validators.validateDni("1234"), "La cédula debe tener entre 5 y 8 dígitos");
      expect(Validators.validateDni("123456789"), "La cédula debe tener entre 5 y 8 dígitos");
    });

    test('Debe retornar nulo (éxito) si la cédula tiene entre 5 y 8 dígitos', () {
      expect(Validators.validateDni("12345"), null);
      expect(Validators.validateDni("12345678"), null);
    });
  });

  group('Pruebas Unitarias del Validador de Contraseña Compleja', () {
    test('Debe retornar un error si la contraseña es nula o vacía', () {
      expect(Validators.validatePassword(null), "Ingresa tu contraseña");
      expect(Validators.validatePassword(""), "Ingresa tu contraseña");
    });

    test('Debe reportar todos los requisitos faltantes si la contraseña es muy débil', () {
      final result = Validators.validatePassword("123");
      expect(result, contains("mínimo 6 caracteres"));
      expect(result, contains("letra mayúscula"));
      expect(result, contains("letra minúscula"));
      expect(result, contains("carácter especial"));
    });

    test('Debe reportar requisitos específicos si solo faltan algunos', () {
      // Tiene minúsculas y números, pero no mayúsculas ni caracteres especiales ni tamaño mínimo
      final result1 = Validators.validatePassword("abc1");
      expect(result1, contains("mínimo 6 caracteres"));
      expect(result1, contains("letra mayúscula"));
      expect(result1, contains("carácter especial"));

      // Cumple tamaño, pero falta mayúscula y carácter especial
      final result2 = Validators.validatePassword("abcdef");
      expect(result2, contains("letra mayúscula"));
      expect(result2, contains("carácter especial"));
    });

    test('Debe retornar nulo (éxito) si la contraseña cumple con todos los requisitos complejos', () {
      expect(Validators.validatePassword("Clave123!"), null);
      expect(Validators.validatePassword("HealSkin#2026"), null);
    });
  });
}
