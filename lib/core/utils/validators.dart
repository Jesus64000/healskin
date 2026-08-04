class Validators {
  /// Valida que el nombre completo no sea nulo/vacío, tenga al menos 3 caracteres,
  /// no contenga números, e incluya al menos un espacio (nombres y apellidos).
  static String? validateFullName(String? val) {
    if (val == null || val.trim().isEmpty) {
      return "Por favor, ingresa tu nombre completo";
    }
    final cleanVal = val.trim();
    if (cleanVal.length < 3) {
      return "El nombre debe tener al menos 3 caracteres";
    }
    if (RegExp(r'[0-9]').hasMatch(cleanVal)) {
      return "El nombre no debe contener números";
    }
    if (!cleanVal.contains(' ')) {
      return "Ingresa tus nombres y apellidos completos (Ej: Juan Pérez)";
    }
    return null;
  }

  /// Valida que la cédula (sin el prefijo) tenga entre 5 y 10 dígitos.
  static String? validateDni(String? val) {
    if (val == null || val.trim().isEmpty) {
      return "Ingresa tu cédula o documento de identidad";
    }
    final cleanVal = val.trim();
    if (cleanVal.length < 5 || cleanVal.length > 10) {
      return "El documento debe tener entre 5 y 10 dígitos";
    }
    return null;
  }

  /// Valida que la contraseña cumpla los requisitos complejos solicitados:
  /// mínimo 6 caracteres, letra mayúscula, letra minúscula y un carácter especial.
  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return "Ingresa tu contraseña";
    }
    final List<String> missing = [];
    if (val.length < 6) {
      missing.add("mínimo 6 caracteres");
    }
    if (!RegExp(r'[A-Z]').hasMatch(val)) {
      missing.add("letra mayúscula");
    }
    if (!RegExp(r'[a-z]').hasMatch(val)) {
      missing.add("letra minúscula");
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(val)) {
      missing.add("carácter especial");
    }
    if (missing.isNotEmpty) {
      return "Requisitos faltantes: ${missing.join(', ')}";
    }
    return null;
  }
}
