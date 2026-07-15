import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('inspect ai_scans database', () async {
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
    
    print('\n--- Querying ai_scans count ---');
    final countRes = await client.from('ai_scans').select().limit(5);
    print('Total scans returned (limit 5): ${countRes.length}');
    if (countRes.isNotEmpty) {
      print('First scan data: ${countRes.first}');
    }

    print('\n--- Querying ai_scans joined with profiles ---');
    try {
      final joinRes = await client.from('ai_scans').select('*, profiles:patient_id(full_name)').limit(2);
      print('Join success with patient_id mapping: ${joinRes.length} records');
      if (joinRes.isNotEmpty) {
        print('First join record: ${joinRes.first}');
      }
    } catch (e) {
      print('Error joining: $e');
    }
  });
}
