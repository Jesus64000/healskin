import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { patient, doctor, none }

class HealSkinAuthState {
  final UserRole role;
  final bool isLoading;
  final Session? session;
  final bool isInitialized; // Nuevo: para saber si ya revisamos Supabase al abrir

  HealSkinAuthState({
    this.role = UserRole.none,
    this.isLoading = false,
    this.session,
    this.isInitialized = false,
  });

  HealSkinAuthState copyWith({UserRole? role, bool? isLoading, Session? session, bool? isInitialized}) {
    return HealSkinAuthState(
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      session: session ?? this.session,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<HealSkinAuthState> {
  final _supabase = Supabase.instance.client;

  AuthNotifier() : super(HealSkinAuthState()) {
    _init();
  }

  // REVISAR SESIÓN AL ABRIR
  void _init() {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      final role = session.user.email!.contains('doctor') ? UserRole.doctor : UserRole.patient;
      state = HealSkinAuthState(role: role, session: session, isInitialized: true);
    } else {
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<String?> signUp(String email, String password, String fullName, String role) async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'full_name': fullName, 'role': role},
      );
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
      final role = email.contains('doctor') ? UserRole.doctor : UserRole.patient;
      state = HealSkinAuthState(role: role, session: response.session, isLoading: false, isInitialized: true);
      return null;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false);
      return "Credenciales incorrectas";
    }
  }

  void logout() async {
    await _supabase.auth.signOut();
    state = HealSkinAuthState(isInitialized: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, HealSkinAuthState>((ref) => AuthNotifier());