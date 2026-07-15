import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://uceithusnfqmcbxoptcu.supabase.co/rest/v1/');
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    request.headers.add('apikey', 'sb_publishable_mvlT5LVYzKjmbyavFFmYYw_tTD0KF4e');
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final data = jsonDecode(responseBody);
    
    final definitions = data['definitions'] as Map<String, dynamic>;
    print('All keys in definitions: ${definitions.keys.toList()}');
    
    for (var table in ['profiles', 'medical_centers', 'doctors']) {
      if (definitions.containsKey(table)) {
        print('\n=== Table: $table ===');
        final props = definitions[table]['properties'] as Map<String, dynamic>;
        for (var col in props.keys) {
          print('  $col: ${props[col]['type']}');
        }
      } else {
        print('\nTable $table not found in definitions. Close matches: ${definitions.keys.where((k) => k.contains(table)).toList()}');
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
