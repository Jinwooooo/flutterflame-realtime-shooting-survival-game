// flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// realtime sync imports
import 'package:supabase_flutter/supabase_flutter.dart';

// self imports
import 'game/game_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
  await setPreferredOrientations();
  runApp(const MyApp());
}

Future<void> initializeSupabase() async {
  // HW
  // await Supabase.initialize(
  //   url: 'https://djeovzmiajfslovjeafy.supabase.co',
  //   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqZW92em1pYWpmc2xvdmplYWZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM3NzMxOTcsImV4cCI6MjAyOTM0OTE5N30.qUak0tbzXZIep0rfSbIp3Tznxowg0uiiMgeSGiD3znY',
  //   realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 40),
  // );

  // JW
  await Supabase.initialize(
    url: 'https://pqyrqglvljqrdvogvfdk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxeXJxZ2x2bGpxcmR2b2d2ZmRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM2Mjc2NjIsImV4cCI6MjAyOTIwMzY2Mn0.bo5bfyE9CB0dHUhqKkk7THhD7xE_RBiSfs52SY-ifxI',
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
      title: 'UFO Shooting Game',
      debugShowCheckedModeBanner: false,
      home: GamePage(),
    );
  }
}