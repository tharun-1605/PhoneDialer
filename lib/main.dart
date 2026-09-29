import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const PhoneDialerApp());
}

class PhoneDialerApp extends StatefulWidget {
  const PhoneDialerApp({Key? key}) : super(key: key);

  @override
  State<PhoneDialerApp> createState() => _PhoneDialerAppState();
}

class _PhoneDialerAppState extends State<PhoneDialerApp> {
  static const platform = MethodChannel('com.example.phone_dialer/default_dialer');

  @override
  void initState() {
    super.initState();
    _requestDefaultDialer();
  }

  Future<void> _requestDefaultDialer() async {
    try {
      await Permission.notification.request();

      final bool isDefault = await platform.invokeMethod('isDefaultDialer') ?? false;
      if (!isDefault) {
        await platform.invokeMethod('requestDefaultDialer');
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to request default dialer: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nothing Dialer',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.redAccent,
          surface: Color(0xFF1C1C1C),
        ),
        fontFamily: 'Roboto', // We can update the font later to a Nothing-like font (e.g. NDot or similar)
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
