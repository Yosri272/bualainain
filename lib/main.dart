import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'PendingApprovalScreen.dart';
import 'family_tree_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';


import 'admin_screen.dart';
import 'news_search_screen.dart';
import 'welcome_screen.dart';
import 'register_screen.dart';
import 'login_screen.dart';
import 'admin_login_screen.dart';
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
import 'users_management_screen.dart';
import 'contact_us_screen.dart';
import 'rate_app_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import 'NotificationSettingsScreen.dart';
import 'SuccessScreen.dart';
import 'RejectedAccountScreen.dart';
import 'edit_profile_screen.dart';
import 'manage_news_screen.dart';
import 'manage_categories_screen.dart';
import 'splash_screen.dart';
import 'add_family_member_screen.dart';
import 'main_navigation_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');

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

// حركة انتقال يدوية: الصفحة الجديدة دايمًا تدخل من الشمال،
// والصفحة القديمة تنسحب شوي لليمين. مضمونة على كل الأجهزة
// بدون الاعتماد على انعكاس تلقائي قد ما يشتغل بكل الحالات.
class _RTLPageTransitionsBuilder extends PageTransitionsBuilder {
  const _RTLPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final incomingTween = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    final outgoingTween = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.25, 0.0),
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    return SlideTransition(
      position: animation.drive(incomingTween),
      child: SlideTransition(
        position: secondaryAnimation.drive(outgoingTween),
        child: child,
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // اللغة والاتجاه
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // نلف كل التطبيق (بما فيه الـ Navigator) باتجاه RTL
      // بدون DevicePreview عشان ما يتعارض مع الاتجاه ولا الحركات الطبيعية
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      theme: ThemeData(
        textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(),
        fontFamily: GoogleFonts.ibmPlexSansArabic().fontFamily,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _RTLPageTransitionsBuilder(),
            TargetPlatform.iOS: _RTLPageTransitionsBuilder(),
            TargetPlatform.macOS: _RTLPageTransitionsBuilder(),
            TargetPlatform.windows: _RTLPageTransitionsBuilder(),
            TargetPlatform.linux: _RTLPageTransitionsBuilder(),
          },
        ),
      ),

      initialRoute: '/splash',

      routes: {
        '/admin': (context) => const AdminScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/otp': (context) => const OtpScreen(),
        '/': (context) => const MainNavigationScreen(
          initialIndex: 0,
        ),
        '/home': (context) => const MainNavigationScreen(
          initialIndex: 0,
        ),

        '/news': (context) => const MainNavigationScreen(
          initialIndex: 1,
        ),

        '/notifications': (context) => const MainNavigationScreen(
          initialIndex: 2,
        ),

        '/profile': (context) => const MainNavigationScreen(
          initialIndex: 3,
        ),
        '/NotificationSettings': (context) => const NotificationSettingsScreen(),
        '/news-details': (context) => const NewsDetailsScreen(),
        '/add-news': (context) => const AddNewsScreen(),
        '/add-member': (context) => const AddMemberScreen(),
        '/add-category': (context) => const AddCategoryScreen(),
        '/members-management': (context) => const MembersManagementScreen(),
        '/users_management_screen': (context) => const UsersManagementScreen(),
        '/contact-us': (context) => const ContactUsScreen(),
        '/rate-app': (context) => const RateAppScreen(),
        '/terms': (context) => const TermsScreen(),
        '/privacy-policy': (context) => const PrivacyPolicyScreen(),
        '/SuccessScreen': (context) => const SuccessScreen(),
        '/pending-approval': (_) => const PendingApprovalScreen(),
        '/rejected-account': (_) => const RejectedAccountScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/manage-news': (context) => const ManageNewsScreen(),
        '/manage-categories': (context) => const ManageCategoriesScreen(),
        '/news-search': (context) => const NewsSearchScreen(),
        '/splash': (context) => const SplashScreen(),
        '/AddFamilyMemberScreen': (context) => const AddFamilyMemberScreen(),
        '/FamilyTreeScreen': (context) => const FamilyTreeScreen(),

      },
    );
  }
}