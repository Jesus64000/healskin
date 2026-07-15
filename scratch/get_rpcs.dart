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
    
    final paths = data['paths'] as Map<String, dynamic>;
    final rpcPaths = paths.keys.where((k) => k.startsWith('/rpc/')).toList();
    print('RPC paths: $rpcPaths');
  } catch (e) {
    print('Error: $e');
  } finally {
    client.close();
  }
}
