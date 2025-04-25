import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Color> colorList = [
    const Color(0xFF1A1C1E),
    const Color(0xFF2C3E50),
    const Color(0xFF1A1C1E),
    const Color(0xFF2C3E50).withOpacity(0.8),
  ];

  int index = 0;
  Color bottomColor = const Color(0xFF1A1C1E);
  Color topColor = const Color(0xFF2C3E50);
  Alignment begin = Alignment.bottomLeft;
  Alignment end = Alignment.topRight;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        bottomColor = colorList[index % colorList.length];
        topColor = colorList[(index + 1) % colorList.length];
        index = index + 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = MediaQuery.of(context).size.width * 0.1;
    final size = MediaQuery.of(context).size.width * 0.08;
    final textsize = MediaQuery.of(context).size.width * 0.045;

    return Scaffold(
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1C1E),
          ),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF1A1C1E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: radius,
                                backgroundColor: const Color(0xFF3498DB),
                                child: Text(
                                  context.read<AuthProvider>().user?.name[0] ??
                                      'U',
                                  style: TextStyle(
                                    fontSize: size,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.read<AuthProvider>().user?.name ??
                                  'User not Found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: textsize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // const SizedBox(height: 5),
              _buildDrawerItem(
                context,
                'Home Screen',
                Icons.home_rounded,
                Colors.white70,
                textsize,
                () => Navigator.pushNamed(context, '/dashboard'),
              ),
              _buildDrawerItem(
                context,
                'Resolve Queries',
                Icons.question_answer_rounded,
                Colors.white70,
                textsize,
                () => Navigator.pushNamed(context, '/contact-queries'),
              ),
              _buildDrawerItem(
                context,
                'Register User',
                Icons.person_add_rounded,
                Colors.white70,
                textsize,
                () => Navigator.pushNamed(context, '/register-user'),
              ),
              _buildDrawerItem(
                context,
                'User MRD',
                Icons.app_registration_rounded,
                Colors.white70,
                textsize,
                () => Navigator.pushNamed(context, '/user-mrd'),
              ),
              const Divider(color: Colors.white24),
              _buildDrawerItem(
                context,
                'Log Out',
                Icons.logout_rounded,
                Colors.white70,
                textsize,
                () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1A1C1E),
        title: Center(
          child: Text(
            // textAlign: TextAlign.center,
            // maxLines: 2,
            // overflow: TextOverflow.ellipsis,
            'DASHBOARD',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        onEnd: () {
          setState(() {
            begin = begin == Alignment.bottomLeft
                ? Alignment.bottomRight
                : Alignment.bottomLeft;
            end = end == Alignment.topRight
                ? Alignment.topLeft
                : Alignment.topRight;
          });
        },
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [bottomColor, topColor],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardTile(
                    context,
                    'Register\nAdmin',
                    Icons.admin_panel_settings_rounded,
                    const Color(0xFF3498DB),
                    () => Navigator.pushNamed(context, '/register-admin'),
                    'Add new administrators',
                  ),
                  _buildDashboardTile(
                    context,
                    'Event\nManagement',
                    Icons.event_rounded,
                    const Color(0xFFC0C0C0),
                    () => Navigator.pushNamed(context, '/event-management'),
                    'Manage tech fest events',
                  ),
                  _buildDashboardTile(
                    context,
                    'MRD\nSearch',
                    Icons.search_rounded,
                    const Color(0xFFE67E22),
                    () => Navigator.pushNamed(context, '/mrd'),
                    'MRD search',
                  ),
                  _buildDashboardTile(
                    context,
                    'RD\nSearch',
                    Icons.file_copy,
                    const Color(0xFFDC143C),
                    () => Navigator.pushNamed(context, '/rd'),
                    'RD search',
                  ),
                  _buildDashboardTile(
                    context,
                    'CRD\nSearch',
                    Icons.folder,
                    const Color(0xFF16A085),
                    () => Navigator.pushNamed(context, '/crd'),
                    'CRD search',
                  ),
                  _buildDashboardTile(
                    context,
                    'Media\nManagement',
                    Icons.image_rounded,
                    const Color(0xFFE74C3C),
                    () => Navigator.pushNamed(context, '/posters'),
                    'Manage posters & media',
                  ),
                  _buildDashboardTile(
                    context,
                    'Team\nManagement',
                    Icons.people_rounded,
                    const Color(0xFF2980B9),
                    () => Navigator.pushNamed(context, '/team'),
                    'Manage team members',
                  ),
                  _buildDashboardTile(
                    context,
                    'Gallery\nManagement',
                    Icons.photo_library_rounded,
                    const Color(0xFF8E44AD),
                    () => Navigator.pushNamed(context, '/gallery'),
                    'Manage event gallery',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    Color textColor,
    double textSize,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: textSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: Colors.white10,
    );
  }

  Widget _buildDashboardTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    String description,
  ) {
    return Card(
      elevation: 8,
      shadowColor: color.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: const Color(0xFF232528),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
