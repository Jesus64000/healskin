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
    print('\n--- Querying profiles ---');
    final profiles = await supabase.from('profiles').select('id, full_name, role');
    for (var p in profiles) {
      print('Profile: ID=${p['id']}, Name=${p['full_name']}, Role=${p['role']}');
    }
    
    print('\n--- Querying appointments ---');
    final appts = await supabase.from('appointments').select('*');
    for (var a in appts) {
      print('Appointment: ID=${a['id']}, Doctor=${a['doctor_id']}, Patient=${a['patient_id']}, Status=${a['status']}, Date=${a['appointment_date']}, Reason=${a['reason']}');
    }
  } catch (e) {
    print("Error querying database: $e");
  }
}
