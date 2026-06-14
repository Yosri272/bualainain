import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'admin_screen.dart';
import 'welcome_screen.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'otp_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'news_screen.dart';
import 'news_details_screen.dart';
import 'add_news_screen.dart';
import 'add_member_screen.dart';
import 'add_category_screen.dart';
import 'members_management_screen.dart';
import 'contact_us_screen.dart';
import 'rate_app_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,

      theme: ThemeData(
        textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(),
        fontFamily: GoogleFonts.ibmPlexSansArabic().fontFamily,
      ),

      initialRoute: '/welcome',

      routes: {
        '/admin': (context) => const AdminScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/otp': (context) => const OtpScreen(),
        '/': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/news': (context) => const NewsScreen(),
        '/news-details': (context) => const NewsDetailsScreen(),
        '/add-news': (context) => const AddNewsScreen(),
        '/add-member': (context) => const AddMemberScreen(),
        '/add-category': (context) => const AddCategoryScreen(),
        '/members-management': (context) =>
        const MembersManagementScreen(),
        '/contact-us': (context) => const ContactUsScreen(),
        '/rate-app': (context) => const RateAppScreen(),
        '/terms': (context) => const TermsScreen(),
        '/privacy-policy': (context) =>
        const PrivacyPolicyScreen(),
      },
    );
  }
}