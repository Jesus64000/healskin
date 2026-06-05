import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final supabase = Supabase.instance.client;
  try {
    final response = await supabase.from('articles').select().limit(1);
    if (response.isNotEmpty) {
      print("ARTICLE KEYS: ${response.first.keys}");
      print("ARTICLE DATA: ${response.first}");
    } else {
      print("No articles found in table, but connection succeeded.");
    }
  } catch (e) {
    print("Error querying database: $e");
  }
}
