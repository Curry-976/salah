import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../widgets/next_prayer_banner.dart';
import '../widgets/prayer_list.dart';
import '../widgets/hijri_date_card.dart';
import 'qibla_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final locationService = context.read<LocationService>();
    final prayerService = context.read<PrayerService>();

    await prayerService.loadSettings();
    await locationService.fetchLocation();

    if (locationService.hasLocation) {
      await prayerService.calculate(
        locationService.latitude!,
        locationService.longitude!,
      );
      _startCountdown();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      context.read<PrayerService>().updateTimeToNext();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _PrayerHome(),
      const QiblaScreen(),
      const CalendarScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Prières',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Qibla',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendrier',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}

class _PrayerHome extends StatelessWidget {
  const _PrayerHome();

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>();
    final prayers = context.watch<PrayerService>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              location.cityName.isNotEmpty ? location.cityName : 'Mayotte',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () async {
                await location.fetchLocation();
                if (location.hasLocation) {
                  await prayers.calculate(
                    location.latitude!,
                    location.longitude!,
                  );
                }
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const HijriDateCard(),
                const SizedBox(height: 16),
                if (location.isLoading)
                  const CircularProgressIndicator()
                else if (prayers.nextPrayer != null)
                  NextPrayerBanner(
                    prayer: prayers.nextPrayer!,
                    timeToNext: prayers.timeToNext,
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        if (prayers.todayPrayers.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: PrayerList(prayers: prayers.todayPrayers),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}
