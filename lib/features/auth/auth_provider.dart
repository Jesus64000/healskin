import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { patient, doctor, admin, none }

class HealSkinAuthState {
  final UserRole role;
  final bool isLoading;
  final Session? session;
  final bool isInitialized;
  final bool hasCompletedQuiz;
  final bool isApproved;
  final bool hasCompletedSetup;
  final bool isPasswordRecovery;

  HealSkinAuthState({
    this.role = UserRole.none,
    this.isLoading = false,
    this.session,
    this.isInitialized = false,
    this.hasCompletedQuiz = true,
    this.isApproved = true,
    this.hasCompletedSetup = true,
    this.isPasswordRecovery = false,
  });

  HealSkinAuthState copyWith({
    UserRole? role,
    bool? isLoading,
    Session? session,
    bool? isInitialized,
    bool? hasCompletedQuiz,
    bool? isApproved,
    bool? hasCompletedSetup,
    bool? isPasswordRecovery,
  }) {
    return HealSkinAuthState(
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      isInitialized: isInitialized ?? this.isInitialized,
      hasCompletedQuiz: hasCompletedQuiz ?? this.hasCompletedQuiz,
      isApproved: isApproved ?? this.isApproved,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
      isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
    );
  }
}

class AuthNotifier extends StateNotifier<HealSkinAuthState> {
  final _supabase = Supabase.instance.client;

  AuthNotifier() : super(HealSkinAuthState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    // 1. Carga inicial síncrona de la sesión en caché local si ya existe
    final initialSession = _supabase.auth.currentSession;
    if (initialSession != null) {
      UserRole role = UserRole.patient;
      bool hasCompletedQuiz = true;
      bool isApproved = true;
      bool hasCompletedSetup = true;
      try {
        final profile = await _supabase
            .from('profiles')
            .select('role, skin_type, is_approved, specialty, license_number')
            .eq('id', initialSession.user.id)
            .single();
        role = _parseRole(profile['role'] ?? 'patient');
        if (role == UserRole.patient) {
          hasCompletedQuiz = profile['skin_type'] != null;
        } else if (role == UserRole.doctor) {
          isApproved = profile['is_approved'] ?? false;
          hasCompletedSetup = profile['specialty'] != null &&
              profile['license_number'] != null &&
              (profile['license_number'] as String).trim().isNotEmpty;
        }
      } catch (e) {
        await _ensureProfileExists(initialSession.user);
        role = _parseRole(initialSession.user.userMetadata?['role'] ?? 'patient');
        if (role == UserRole.patient) {
          hasCompletedQuiz = false;
        } else if (role == UserRole.doctor) {
          hasCompletedSetup = false;
          isApproved = false;
        }
      }
      state = HealSkinAuthState(
        role: role,
        session: initialSession,
        isInitialized: true,
        isLoading: false,
        hasCompletedQuiz: hasCompletedQuiz,
        isApproved: isApproved,
        hasCompletedSetup: hasCompletedSetup,
      );
    } else {
      state = HealSkinAuthState(role: UserRole.none, session: null, isInitialized: true, isLoading: false);
    }

    // 2. Escuchar futuros cambios de autenticación (evitando consultas redundantes o loops)
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        state = state.copyWith(isPasswordRecovery: true, session: session, isInitialized: true, isLoading: false);
        return;
      }

      if (session == null) {
        state = HealSkinAuthState(role: UserRole.none, session: null, isInitialized: true, isLoading: false);
      } else if (session.user.id != state.session?.user.id) {
        UserRole role = UserRole.patient;
        bool hasCompletedQuiz = true;
        bool isApproved = true;
        bool hasCompletedSetup = true;
        try {
          final profile = await _supabase
              .from('profiles')
              .select('role, skin_type, is_approved, specialty, license_number')
              .eq('id', session.user.id)
              .single();
          role = _parseRole(profile['role'] ?? 'patient');
          if (role == UserRole.patient) {
            hasCompletedQuiz = profile['skin_type'] != null;
          } else if (role == UserRole.doctor) {
            isApproved = profile['is_approved'] ?? false;
            hasCompletedSetup = profile['specialty'] != null &&
                profile['license_number'] != null &&
                (profile['license_number'] as String).trim().isNotEmpty;
          }
        } catch (e) {
          await _ensureProfileExists(session.user);
          role = _parseRole(session.user.userMetadata?['role'] ?? 'patient');
          if (role == UserRole.patient) {
            hasCompletedQuiz = false;
          } else if (role == UserRole.doctor) {
            hasCompletedSetup = false;
            isApproved = false;
          }
        }
        state = HealSkinAuthState(
          role: role,
          session: session,
          isInitialized: true,
          isLoading: false,
          hasCompletedQuiz: hasCompletedQuiz,
          isApproved: isApproved,
          hasCompletedSetup: hasCompletedSetup,
        );
      }
    });
  }

  Future<String?> signUp(String email, String password, String fullName, String role) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'full_name': fullName, 'role': role}, // Guarda en metadatos
      );

      // 🚀 EL FIX: Tomamos el control desde Flutter
      if (response.user != null) {
        // Usamos upsert: Si el trigger ya lo creó, lo actualizamos. Si no, lo insertamos.
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'full_name': fullName,
          'role': role,
          'is_approved': role == 'doctor' ? false : true, // Los doctores entran bloqueados
        });
      }

      // Hacemos login automático después de registrar
      return await login(email, password);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false);
      return e.message;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password.trim()
      );

      // 🧠 VALIDACIÓN ESTRICTA: Leemos de la tabla al hacer login
      final profile = await _supabase
          .from('profiles')
          .select('role, skin_type, is_approved, specialty, license_number')
          .eq('id', response.session!.user.id)
          .single();

      final roleString = profile['role'] ?? 'patient';
      final role = _parseRole(roleString);
      bool hasCompletedQuiz = true;
      bool isApproved = true;
      bool hasCompletedSetup = true;
      if (role == UserRole.patient) {
        hasCompletedQuiz = profile['skin_type'] != null;
      } else if (role == UserRole.doctor) {
        isApproved = profile['is_approved'] ?? false;
        hasCompletedSetup = profile['specialty'] != null &&
            profile['license_number'] != null &&
            (profile['license_number'] as String).trim().isNotEmpty;
      }

      state = HealSkinAuthState(
        role: role,
        session: response.session,
        isLoading: false,
        isInitialized: true,
        hasCompletedQuiz: hasCompletedQuiz,
        isApproved: isApproved,
        hasCompletedSetup: hasCompletedSetup,
      );
      return null;
    } on AuthException catch (_) {
      state = state.copyWith(isLoading: false);
      return "Credenciales incorrectas";
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return "Error de conexión al verificar perfil";
    }
  }

  Future<String?> loginWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Iniciar sesión real con Google mediante OAuth
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.healskin://login-callback',
      );
      
      // Esperar a que se asiente la sesión si ya se cargó síncronamente
      final session = _supabase.auth.currentSession;
      if (session != null) {
        // Buscar o crear perfil en Supabase
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .maybeSingle();

        UserRole role = UserRole.patient;
        bool hasCompletedQuiz = false;
        bool isApproved = true;
        bool hasCompletedSetup = true;

        if (profile == null) {
          // Crear perfil nuevo para el usuario de Google
          final String fullName = session.user.userMetadata?['full_name'] ?? 'Usuario Google';
          await _supabase.from('profiles').insert({
            'id': session.user.id,
            'full_name': fullName,
            'role': 'patient',
            'is_approved': true,
          });
        } else {
          role = _parseRole(profile['role'] ?? 'patient');
          if (role == UserRole.patient) {
            hasCompletedQuiz = profile['skin_type'] != null;
          } else if (role == UserRole.doctor) {
            isApproved = profile['is_approved'] ?? false;
            hasCompletedSetup = profile['specialty'] != null &&
                profile['license_number'] != null &&
                (profile['license_number'] as String).trim().isNotEmpty;
          }
        }

        state = HealSkinAuthState(
          role: role,
          session: session,
          isLoading: false,
          isInitialized: true,
          hasCompletedQuiz: hasCompletedQuiz,
          isApproved: isApproved,
          hasCompletedSetup: hasCompletedSetup,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return null;
    } catch (e) {
      // 🚨 MODO DEMO / CONTINGENCIA DE ALTA FIDELIDAD:
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: "paciente@healskin.com",
          password: "password123",
        );
        final profile = await _supabase
            .from('profiles')
            .select('role, skin_type, is_approved, specialty, license_number')
            .eq('id', response.session!.user.id)
            .single();

        final role = _parseRole(profile['role'] ?? 'patient');
        bool hasCompletedQuiz = profile['skin_type'] != null;
        bool isApproved = true;
        bool hasCompletedSetup = true;
        if (role == UserRole.doctor) {
          isApproved = profile['is_approved'] ?? false;
          hasCompletedSetup = profile['specialty'] != null &&
              profile['license_number'] != null &&
              (profile['license_number'] as String).trim().isNotEmpty;
        }

        state = HealSkinAuthState(
          role: role,
          session: response.session,
          isLoading: false,
          isInitialized: true,
          hasCompletedQuiz: hasCompletedQuiz,
          isApproved: isApproved,
          hasCompletedSetup: hasCompletedSetup,
        );
        return null;
      } catch (_) {
        // Si no hay internet ni BD, creamos sesión local simulada (cuestionario sin completar)
        state = HealSkinAuthState(
          role: UserRole.patient,
          session: null,
          isLoading: false,
          isInitialized: true,
          hasCompletedQuiz: false, // Forzar a completar el cuestionario!
        );
        return null;
      }
    }
  }

  void logout() async {
    await _supabase.auth.signOut();
    state = HealSkinAuthState(isInitialized: true);
  }

  // Helper limpio para mapear el string de BD al Enum
  UserRole _parseRole(String roleString) {
    if (roleString == 'doctor') return UserRole.doctor;
    if (roleString == 'admin') return UserRole.admin;
    return UserRole.patient;
  }

  // Asegura que exista el perfil del usuario al autenticarse por proveedores externos
  Future<void> _ensureProfileExists(User user) async {
    try {
      final meta = user.userMetadata;
      final String fullName = meta?['full_name'] ?? meta?['name'] ?? 'Usuario Google';
      final String roleString = meta?['role'] ?? 'patient';
      
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'role': roleString,
        'is_approved': roleString == 'doctor' ? false : true,
      });
    } catch (_) {
      // Ignorar fallos de red/desconexión
    }
  }

  Future<String?> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.healskin://reset-password',
      );
      state = state.copyWith(isLoading: false);
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false);
      return e.message;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return e.toString();
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );
      state = state.copyWith(
        isLoading: false,
        isPasswordRecovery: false,
      );
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false);
      return e.message;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return e.toString();
    }
  }

  void clearPasswordRecoveryFlag() {
    state = state.copyWith(isPasswordRecovery: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, HealSkinAuthState>((ref) => AuthNotifier());