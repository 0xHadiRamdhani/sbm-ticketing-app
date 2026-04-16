import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/ticket_provider.dart';
import 'screens/dashboard_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isFirebaseInitialized = false;
  String errorMessage = "";

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
    errorMessage = e.toString();
  }

  runApp(
    isFirebaseInitialized
        ? MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => TicketProvider()),
            ],
            child: const TicketingApp(),
          )
        : FirebaseErrorApp(errorMessage: errorMessage),
  );
}

class FirebaseErrorApp extends StatelessWidget {
  final String errorMessage;

  const FirebaseErrorApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Setup Firebase Required',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'Konfigurasi Firebase Diperlukan',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[900]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Aplikasi tidak dapat berjalan karena Firebase belum dikonfigurasi.\n\nSilakan buka terminal di folder proyek ini dan jalankan:\n\nflutterfire configure\n\nKemudian jalankan ulang aplikasi.',
                  style: TextStyle(fontSize: 16, color: Colors.red[800], height: 1.5),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    errorMessage,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TicketingApp extends StatelessWidget {
  const TicketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SBM ITB Ticketing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade900,
          primary: Colors.blue.shade800,
          secondary: Colors.orange.shade600,
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: DashboardWrapper(),
    );
  }
}
