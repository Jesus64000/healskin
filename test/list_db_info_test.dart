import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('list db info', () async {
    final envFile = File('.env');
    final lines = envFile.readAsLinesSync();
    String? url;
    String? anonKey;
    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        url = line.split('=')[1].trim();
      }
      if (line.startsWith('SUPABASE_ANON_KEY=')) {
        anonKey = line.split('=')[1].trim();
      }
    }
    
    expect(url, isNotNull);
    expect(anonKey, isNotNull);
    
    final client = SupabaseClient(url!, anonKey!);
    
    try {
      print('--- Profiles ---');
      final profiles = await client.from('profiles').select('id, full_name, email, role');
      print('Total profiles: ${profiles.length}');
      for (var p in profiles) {
        print('Profile: ${p['id']} | ${p['full_name']} | ${p['email']} | ${p['role']}');
      }
    } catch (e) {
      print('Error profiles: $e');
    }

    try {
      print('\n--- AI Scans ---');
      final scans = await client.from('ai_scans').select('id, patient_id, risk_level, created_at');
      print('Total scans found: ${scans.length}');
    } catch (e) {
      print('Error scans basic: $e');
    }

    try {
      print('--- Querying ai_scans with profiles(full_name) ---');
      final res1 = await client.from('ai_scans').select('*, profiles(full_name)').limit(1);
      print('Query 1 success: ${res1.length} records');
    } catch (e) {
      print('Query 1 failed: $e');
    }

    try {
      print('--- Querying ai_scans with profiles:patient_id(full_name) ---');
      final res2 = await client.from('ai_scans').select('*, profiles:patient_id(full_name)').limit(1);
      print('Query 2 success: ${res2.length} records');
    } catch (e) {
      print('Query 2 failed: $e');
    }
  });
}
