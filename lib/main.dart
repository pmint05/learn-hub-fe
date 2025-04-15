import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:learn_hub/configs/theme.dart';
import 'package:learn_hub/firebase_options.dart';
import 'package:learn_hub/providers/appbar_provider.dart';
import 'package:learn_hub/providers/app_auth_provider.dart';
import 'package:learn_hub/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:learn_hub/screens/app.dart';
import 'package:learn_hub/screens/login.dart';
import 'package:learn_hub/widgets/auth_wrapper.dart';
import 'package:provider/provider.dart';

void main() async {

  await dotenv.load(fileName: ".env");

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppBarProvider()),
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
          debugShowCheckedModeBanner: false,
          title: 'Learn Hub',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: AuthWrapper(),
        );
      },
    );
  }
}
