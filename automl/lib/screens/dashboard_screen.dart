import 'package:automl/main.dart';
import 'package:automl/utils/snackbar_helper.dart';
import 'package:automl/widgets/common_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:automl/core/firebase_setup.dart';
import 'package:automl/screens/job/job_creation/job_creation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'job/results_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _handleLogout() async {
    await signOut();
    if (mounted) {
      showCustomSnackbar(context, 'Signed out successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = auth.currentUser?.email ?? 'Anonymous';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final myAppState = MyApp.of(context);
    final user = auth.currentUser;

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
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  shadowColor: Colors.black.withOpacity(0.4),
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
              const SizedBox(height: 40),
              if (user != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('dashboard')
                      .doc('summary')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final summaryData =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final totalJobs =
                        summaryData['totalJobs']?.toString() ?? '0';
                    final modelsTrained =
                        summaryData['totalModelsTrained']?.toString() ?? '0';

                    return ConstrainedBox(
                      constraints:
                      BoxConstraints(maxWidth: isDesktop ? 1200 : 500),
                      child: GridView.count(
                        crossAxisCount: isDesktop ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isDesktop ? 1.6 : 1.2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          StatCard(
                            isDarkMode: isDarkMode,
                            title: 'Total Jobs',
                            value: totalJobs,
                            trend: '',
                            icon: Icons.show_chart,
                            iconColor: Colors.blue,
                          ),
                          StatCard(
                            isDarkMode: isDarkMode,
                            title: 'Models Trained',
                            value: modelsTrained,
                            trend: '',
                            icon: Icons.hub_outlined,
                            iconColor: Colors.purple,
                          ),
                          StatCard(
                            isDarkMode: isDarkMode,
                            title: 'Avg Accuracy',
                            value: 'N/A',
                            trend: '',
                            icon: Icons.track_changes,
                            iconColor: Colors.green,
                          ),
                          StatCard(
                            isDarkMode: isDarkMode,
                            title: 'Success Rate',
                            value: 'N/A',
                            trend: '',
                            icon: Icons.bolt,
                            iconColor: Colors.orange,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 40),
              Text(
                'Job History',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (user != null) JobHistoryList(userId: user.uid),
            ],
          ),
        ),
      ),
    );
  }
}

class JobHistoryList extends StatelessWidget {
  final String userId;
  const JobHistoryList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('jobs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No job history found. Run a job to see it here!"),
            ),
          );
        }

        final jobDocs = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobDocs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final job = jobDocs[index].data() as Map<String, dynamic>;
            final taskId = job['taskId'] as String? ?? 'No ID';
            final timestamp = (job['timestamp'] as Timestamp?)?.toDate();
            final resultsData = job['resultsData'] as Map<String, dynamic>?;
            final modelCount = (resultsData?['results'] as Map?)?.length ?? 0;

            final formattedDate = timestamp != null
                ? DateFormat('MMM d, yyyy  h:mm a').format(timestamp)
                : 'No date';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.history_rounded),
                ),
                title: Text(
                  'Task ID: $taskId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                    'Completed on $formattedDate\n$modelCount models trained'),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
                onTap: () {
                  if (resultsData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResultsScreen(resultsData: resultsData),
                      ),
                    );
                  } else {
                    showCustomSnackbar(
                        context, 'No results data found for this job.');
                  }
                },
              ),
            );
          },
        );
      },
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
      color: isDarkMode ? const Color(0xFF1E2939) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                      isDarkMode ? Colors.grey.shade400 : Colors.black54,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.9),
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
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
                ),
                textScaler: const TextScaler.linear(2.2),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
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