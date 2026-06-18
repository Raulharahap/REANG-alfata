import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/app/theme/app_theme.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/providers/theme_provider.dart';
import 'package:reang_app/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:reang_app/providers/cart_provider.dart';
import 'package:reang_app/services/api_service.dart';

Future<void> main() async {
  // Pastikan Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi format tanggal
  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (ctx) => CartProvider(ApiService(), ctx.read<AuthProvider>()),
          update: (ctx, auth, previousCart) {
            // Ini memastikan CartProvider selalu dapat AuthProvider terbaru
            return CartProvider(ApiService(), auth);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Reang App',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
