import 'package:automl/main.dart';
import 'package:automl/utils/snackbar_helper.dart';
import 'package:automl/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:automl/core/firebase_setup.dart';
import 'package:automl/screens/job/job_creation/job_creation_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _handleLogout() async {
    await signOut();
    if(mounted){
      showCustomSnackbar(context, 'Signed out successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = auth.currentUser?.email ?? 'Anonymous';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final myAppState = MyApp.of(context);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF0D1B2A), const Color(0xFF3A0665)]
              : [const Color(0xFFFFF1F4), const Color(0xFFFFF9F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        appBar: CommonAppBar(
          actions: [
            // Rebuild the actions list here
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  width: 2.0,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: myAppState.toggleTheme,
                  tooltip: 'Toggle Theme',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black,
                child: Text(
                  userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'A',
                  style: const TextStyle(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to AutoML Studio,',
                  style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 20),
                Text(
                  textAlign: TextAlign.center,
                  'Train machine learning models without writing code. Upload your data, select models, and get result in minutes.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, JobCreationScreen.routeName);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2645E5), Color(0xFF7D0BDB)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      width: 210,
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            'Start new Job',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: GridView.count(
                      crossAxisCount: isDesktop? 4: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isDesktop? 1.6 : 1.3,
                      children: [
                        StatCard(
                          isDarkMode: isDarkMode,
                          title: 'Total Jobs',
                          value: '127',
                          trend: '+12%',
                          icon: Icons.show_chart,
                          iconColor: Colors.blue,
                        ),
                        StatCard(
                          isDarkMode: isDarkMode,
                          title: 'Models Trained',
                          value: '342',
                          trend: '+23%',
                          icon: Icons.hub_outlined,
                          iconColor: Colors.purple,
                        ),
                        StatCard(
                          isDarkMode: isDarkMode,
                          title: 'Avg Accuracy',
                          value: '92.4%',
                          trend: '+3.2%',
                          icon: Icons.track_changes,
                          iconColor: Colors.green,
                        ),
                        StatCard(
                          isDarkMode: isDarkMode,
                          title: 'Success Rate',
                          value: '96.8%',
                          trend: '+1.4%',
                          icon: Icons.bolt,
                          iconColor: Colors.orange,
                        ),
                      ],
                    ),
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

class StatCard extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDarkMode ? Color(0xFF1E2939) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode? Colors.grey.shade400 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode? Colors.white.withValues(alpha: 0.9) : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}