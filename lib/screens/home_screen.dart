import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/event_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentEventIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final events = context.read<EventProvider>().events;
      if (events.length > 1 && mounted) {
        setState(() {
          _currentEventIndex = (_currentEventIndex + 1) % events.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DCRUST Portal'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'DCRUST',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigo,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Welcome to the University Portal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The DCRUST Portal is a one-stop student portal for Deenbandhu Chhotu Ram University of Science and Technology (DCRUST), Murthal. Check your attendance, search previous year exam papers, stay updated with events, and find seniors on the alumni directory.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Dynamic Events Banner
              Consumer<EventProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (provider.events.isNotEmpty) {
                    final currentEvent = provider.events[_currentEventIndex];
                    return GestureDetector(
                      onTap: () {
                        context.push('/events');
                      },
                      child: Container(
                        height: 250,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomNetworkImage(
                              imageUrl: currentEvent.imageUrl,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.5),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'FEATURED EVENT',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    currentEvent.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentEvent.description,
                                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${currentEvent.date.day}/${currentEvent.date.month}/${currentEvent.date.year}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.location_on, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          currentEvent.location,
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.indigo, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Welcome to DCRUST Portal',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Access all your university services in one place.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Get Started'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              
              // Portal Features
              const Text(
                'Portal Features',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Everything you can do right here on the DCRUST Portal',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _FeatureCard(
                    title: 'Attendance',
                    icon: Icons.check_box,
                    color: Colors.purple,
                    onTap: () => context.push('/attendance'),
                  ),
                  _FeatureCard(
                    title: 'Exam Papers',
                    icon: Icons.book,
                    color: Colors.orange,
                    onTap: () => context.push('/papers'),
                  ),
                  _FeatureCard(
                    title: 'Events',
                    icon: Icons.calendar_month,
                    color: Colors.red,
                    onTap: () => context.push('/events'),
                  ),
                  _FeatureCard(
                    title: 'Alumni Directory',
                    icon: Icons.school,
                    color: Colors.indigo,
                    onTap: () => context.push('/alumni'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Quick Links
              const Text(
                'Quick Links',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Fast access to essential university services',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _FeatureCard(
                    title: 'Student Portal',
                    icon: Icons.account_balance,
                    color: Colors.blue,
                    onTap: () => _launchUrl('https://www.dcrustedp.in/myexamlogin.php'),
                  ),
                  _FeatureCard(
                    title: 'Boys Mess',
                    icon: Icons.restaurant,
                    color: Colors.teal,
                    onTap: () => _launchUrl('https://paydirect.eduqfix.com/app/payment/2663/35606/'),
                  ),
                  _FeatureCard(
                    title: 'Girls Mess',
                    icon: Icons.restaurant_menu,
                    color: Colors.green,
                    onTap: () => _launchUrl('https://onlinesbi.sbi.bank.in/'),
                  ),
                  _FeatureCard(
                    title: 'Date Sheet',
                    icon: Icons.event_note,
                    color: Colors.pink,
                    onTap: () => _launchUrl('https://www.dcrustedp.in/datesheetNew.php'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
