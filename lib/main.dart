import 'package:flutter/material.dart';
import 'package:paridhi_admin/screens/combo_events_screen.dart';
// import 'package:paridhi_admin/screens/screenLoadWait.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/events_provider.dart';
import 'providers/combo_events_provider.dart';
import 'providers/mrd_provider.dart';
import 'providers/rd_provider.dart';
import 'providers/gallery_provider.dart';
import 'providers/team_provider.dart';
import 'providers/crd_provider.dart';
import 'providers/domain_poster_provider.dart';
import 'providers/team_photo_provider.dart';
import 'providers/contact_query_provider.dart';
import 'providers/user_mrd.dart';
import 'services/contact_query_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_admin_screen.dart';
import 'screens/auth/register_user_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/events_screen.dart';
import 'screens/event_form_screen.dart';
import 'screens/event_management_screen.dart';
import 'screens/mrd_screen.dart';
import 'screens/rd_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/team_screen.dart';
import 'screens/crd_screen.dart';
import 'screens/DomainPoster_screen.dart';
import 'screens/team_poster_screen.dart';
import 'screens/posters_screen.dart';
import 'screens/contact_queries_screen.dart';
import 'screens/otp_verification_screen.dart';
// import 'screens/delete.dart';
import 'screens/loadingScreen/loadingAnimation.dart';
import 'screens/user_mrd_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Create AuthProvider first to initialize loading
  final authProvider = AuthProvider();

  // Run the app with pre-initialized AuthProvider
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authProvider),
      ChangeNotifierProxyProvider<AuthProvider, EventsProvider>(
        create: (_) => EventsProvider(null),
        update: (_, auth, __) => EventsProvider(auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, ComboEventsProvider>(
        create: (_) => ComboEventsProvider(null),
        update: (_, auth, __) => ComboEventsProvider(auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, MrdProvider>(
        create: (_) => MrdProvider(null),
        update: (_, auth, __) => MrdProvider(auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, RdProvider>(
        create: (_) => RdProvider(null),
        update: (_, auth, __) => RdProvider(auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, GalleryProvider>(
        create: (_) => GalleryProvider(null),
        update: (_, auth, __) => GalleryProvider(auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, TeamProvider>(
        create: (_) => TeamProvider(null),
        update: (_, auth, __) => TeamProvider(auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, CrdProvider>(
        create: (_) => CrdProvider(null),
        update: (_, auth, __) => CrdProvider(auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, DomainPosterProvider>(
        create: (_) => DomainPosterProvider(null),
        update: (_, auth, __) => DomainPosterProvider(auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, TeamPhotoProvider>(
        create: (_) => TeamPhotoProvider(dio: null),
        update: (_, auth, __) => TeamPhotoProvider(dio: auth.dio),
      ),
      ChangeNotifierProxyProvider<AuthProvider, ContactQueryProvider>(
        create: (_) => ContactQueryProvider(ContactQueryService(null)),
        update: (_, auth, __) =>
            ContactQueryProvider(ContactQueryService(auth.dio)),
      ),
      ChangeNotifierProxyProvider<AuthProvider, UserMrd>(
        create: (_) => UserMrd(authProvider),
        update: (_, auth, __) => UserMrd(auth),
      ),
    ],
    child: const AuthWrapper(),
  ));
}


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
        return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Loadinganimation(),
      );
      
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paridhi Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: authProvider.token != null && authProvider.user != null
          ? const DashboardScreen()
          : const LoginScreen(),
      // home: const DashboardScreen(),
      routes: {
        // '/': (context) => const dA(),
        '/login': (context) => const LoginScreen(),
        '/register-admin': (context) => const RegisterAdminScreen(),
        '/register-user': (context) => const RegisterUserScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/event-management': (context) => const EventManagementScreen(),
        '/events': (context) => const EventsScreen(),
        '/event-form': (context) => const EventFormScreen(),
        '/mrd': (context) => const MrdScreen(),
        '/rd': (context) => const RdScreen(),
        '/gallery': (context) => const GalleryScreen(),
        '/team': (context) => const TeamScreen(),
        '/crd': (context) => const CrdScreen(),
        '/posters': (context) => const PostersScreen(),
        '/domain-posters': (context) => const DomainPostersScreen(),
        '/team-poster': (context) => const TeamPosterScreen(),
        '/contact-queries': (context) => const ContactQueriesScreen(),
        '/user-mrd': (context) => const UserMRD(),
        '/combo-events':(context)=>const ComboEventsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle dynamic route generation
        if (settings.name == '/otp-verification') {
          // Extract arguments
          final args = settings.arguments as Map<String, String>?;
          final email = args?['email'] ?? '';
          return MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: email),
          );
        }
        return null;
      },
    );
  }
}
