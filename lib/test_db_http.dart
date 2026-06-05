import 'dart:convert';
import 'dart:io';

void main() async {
  // Read .env file
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print("No .env file found");
    return;
  }

  final lines = await envFile.readAsLines();
  String? url;
  String? anonKey;
  for (var line in lines) {
    if (line.trim().startsWith('#') || !line.contains('=')) continue;
    final parts = line.split('=');
    final key = parts[0].trim();
    final value = parts.sublist(1).join('=').trim().replaceAll('"', '').replaceAll("'", "");
    if (key == 'SUPABASE_URL') url = value;
    if (key == 'SUPABASE_ANON_KEY') anonKey = value;
  }

  if (url == null || anonKey == null) {
    print("Failed to parse SUPABASE_URL or SUPABASE_ANON_KEY from .env");
    return;
  }

  final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  final requestUrl = Uri.parse('$cleanUrl/rest/v1/articles?limit=1');

  final client = HttpClient();
  try {
    final request = await client.getUrl(requestUrl);
    request.headers.add('apikey', anonKey);
    request.headers.add('Authorization', 'Bearer $anonKey');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final List data = jsonDecode(responseBody);
      if (data.isNotEmpty) {
        print("COLUMNS: ${data.first.keys.toList()}");
        print("SAMPLE: ${data.first}");
      } else {
        print("Success! Connection OK, but no articles found.");
      }
    } else {
      print("Error from Supabase: ${response.statusCode} - $responseBody");
    }
  } catch (e) {
    print("Exception: $e");
  } finally {
    client.close();
  }
}
