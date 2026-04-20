import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';

// Android emülatördeki sahte SSL (HTTPS) sertifikasını aşmak için (Chrome'da etkisizdir, telefonda hayat kurtarır)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Hafızadaki VIP bilekliği (Token) okuyan fonksiyon
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indiego',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      // home parametresine eskisi gibi direkt LoginScreen() vermek yerine,
      // FutureBuilder ile önce hafızayı kontrol ediyoruz.
      home: FutureBuilder<String?>(
        future: _getToken(),
        builder: (context, snapshot) {
          // 1. Hafıza okunurken (çok kısa bir an) ekranda dönen bir yüklenme işareti göster
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0A0A16),
              body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFA088E4))),
            );
          }

          // 2. Eğer hafızada token Varsa (Kullanıcı daha önce giriş yapmışsa) -> Ana Sayfaya git
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }

          // 3. Eğer token Yoksa (İlk kez açıyorsa veya çıkış yapmışsa) -> Giriş Ekranına git
          return const LoginScreen();
        },
      ),
    );
  }
}
