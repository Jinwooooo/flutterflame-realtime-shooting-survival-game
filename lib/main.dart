// flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// realtime sync imports
import 'package:supabase_flutter/supabase_flutter.dart';

// self imports
import 'package:flame_realtime_shooting/game/game_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  await setPreferredOrientations();
  runApp(const MyApp());
}

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'supbase_url',
    anonKey: 'subpase_anonKey',
    realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 40),
  );
}

Future<void> setPreferredOrientations() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'KJ4L5T4',
      debugShowCheckedModeBanner: false,
      home: GamePage(),
    );
  }
}