import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'PendingApprovalScreen.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


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
import 'NotificationSettingsScreen.dart';
import 'SuccessScreen.dart';
import 'RejectedAccountScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupFirebaseMessaging();

  runApp(const MyApp());
}

Future<void> setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,

      useInheritedMediaQuery: true,
      locale: const Locale('ar'),

      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DevicePreview.appBuilder(
            context,
            child,
          ),
        );
      },

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
        '/NotificationSettings': (context) => const NotificationSettingsScreen(),
        '/news': (context) => const NewsScreen(),
        '/news-details': (context) => const NewsDetailsScreen(),
        '/add-news': (context) => const AddNewsScreen(),
        '/add-member': (context) => const AddMemberScreen(),
        '/add-category': (context) => const AddCategoryScreen(),
        '/members-management': (context) => const MembersManagementScreen(),
        '/contact-us': (context) => const ContactUsScreen(),
        '/rate-app': (context) => const RateAppScreen(),
        '/terms': (context) => const TermsScreen(),
        '/privacy-policy': (context) => const PrivacyPolicyScreen(),
        '/SuccessScreen': (context) => const SuccessScreen(),
        '/pending-approval': (_) => const PendingApprovalScreen(),
        '/rejected-account': (_) => const RejectedAccountScreen(),
      },
    );
  }
}