import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../widgets/next_prayer_banner.dart';
import '../widgets/prayer_list.dart';
import '../widgets/hijri_date_card.dart';
import '../utils/theme.dart';
import 'qibla_screen.dart';
import 'mosques_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

// ── Shell ─────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _countdownTimer;

  static const _navItems = [
    _NavItem(Icons.access_time_outlined, Icons.access_time_filled,   'Prières'),
    _NavItem(Icons.explore_outlined,      Icons.explore,              'Qibla'),
    _NavItem(Icons.mosque_outlined,       Icons.mosque,               'Mosquées'),
    _NavItem(Icons.calendar_month_outlined,Icons.calendar_month,      'Calendrier'),
    _NavItem(Icons.settings_outlined,     Icons.settings,             'Réglages'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final loc   = context.read<LocationService>();
    final pray  = context.read<PrayerService>();
    await pray.loadSettings();
    await loc.fetchLocation();
    if (loc.hasLocation) {
      await pray.calculate(loc.latitude!, loc.longitude!);
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
      const MosquesScreen(),
      const CalendarScreen(),
      const SettingsScreen(),
    ];

    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final colW = constraints.maxWidth.clamp(0.0, 430.0);
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: colW,
              height: constraints.maxHeight,
              child: MediaQuery(
                // Reserve space for the floating nav bar in all child screens
                data: mq.copyWith(
                  padding: mq.padding.copyWith(bottom: 96),
                ),
                child: Stack(
                  children: [
                    IndexedStack(index: _currentIndex, children: screens),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _FloatingNav(
                        items: _navItems,
                        currentIndex: _currentIndex,
                        onTap: (i) => setState(() => _currentIndex = i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Floating navigation ───────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

class _FloatingNav extends StatefulWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<_FloatingNav> {
  static const double _itemHeight = 52;
  static const double _indicatorH = 2.0;
  static const double _indicatorW = 28.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final n = widget.items.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, math.max(bottom + 12, 20)),
      child: Container(
        height: _itemHeight + 16, // fixed: 8px top + 8px bottom padding
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;
            final slotW = totalW / n;
            final indicatorLeft =
                slotW * widget.currentIndex + (slotW - _indicatorW) / 2;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Sliding indicator
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: indicatorLeft),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  builder: (context, x, _) => Positioned(
                    left: x,
                    bottom: 8,
                    child: Container(
                      width: _indicatorW,
                      height: _indicatorH,
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                // Items
                Row(
                  children: List.generate(n, (i) {
                    final item = widget.items[i];
                    final selected = i == widget.currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: _itemHeight + 16,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  selected ? item.selectedIcon : item.icon,
                                  key: ValueKey(selected),
                                  color: selected
                                      ? AppColors.greenLight
                                      : AppColors.textMuted,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedOpacity(
                                opacity: selected ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: AppColors.greenLight,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Prayer home ───────────────────────────────────────────────────────────────

class _PrayerHome extends StatelessWidget {
  const _PrayerHome();

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>();
    final prayers  = context.watch<PrayerService>();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _PrayerHeader(location: location)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HijriDateCard(),
                const SizedBox(height: 16),
                if (location.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.green,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (prayers.nextPrayer != null)
                  NextPrayerBanner(
                    prayer: prayers.nextPrayer!,
                    timeToNext: prayers.timeToNext,
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'HORAIRES DU JOUR',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        if (prayers.todayPrayers.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: PrayerList(prayers: prayers.todayPrayers),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
      ],
    );
  }
}

// ── Header with Islamic geometric pattern ─────────────────────────────────────

class _PrayerHeader extends StatelessWidget {
  final LocationService location;
  const _PrayerHeader({required this.location});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).viewPadding.top;
    final prayers = context.read<PrayerService>();

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF081A10), Color(0xFF0A1628), AppColors.bgDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, 0.5, 1],
        ),
      ),
      child: Stack(
        children: [
          // Subtle Islamic geometric pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _StarPatternPainter(
                AppColors.green.withOpacity(0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              location.isUsingFallback
                                  ? Icons.location_off_outlined
                                  : Icons.gps_fixed,
                              size: 13,
                              color: location.isUsingFallback
                                  ? AppColors.textMuted
                                  : AppColors.greenLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              location.hasLocation
                                  ? (location.cityName.isNotEmpty
                                      ? location.cityName
                                      : 'Mayotte')
                                  : 'Mayotte',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'الصلوات الخمس',
                          style: AppFonts.arabic(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const Text(
                          'Les cinq prières',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  _HeaderButton(
                    icon: location.isLoading
                        ? Icons.hourglass_top_outlined
                        : Icons.my_location,
                    onTap: () async {
                      await location.fetchLocation();
                      if (location.hasLocation) {
                        await prayers.calculate(
                            location.latitude!, location.longitude!);
                      }
                    },
                  ),
                ],
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: -0.04, end: 0, duration: 500.ms),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceLo,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Islamic 8-pointed star pattern ───────────────────────────────────────────

class _StarPatternPainter extends CustomPainter {
  final Color color;
  _StarPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const step = 54.0;
    const r = 16.0;

    for (double x = step / 2; x < size.width + step; x += step) {
      for (double y = step / 2; y < size.height + step; y += step) {
        _drawStar(canvas, paint, Offset(x, y), r);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset c, double r) {
    const n = 8;
    final path = Path();
    for (int i = 0; i < n * 2; i++) {
      final angle = i * math.pi / n - math.pi / 2;
      final radius = i.isEven ? r : r * 0.38;
      final x = c.dx + radius * math.cos(angle);
      final y = c.dy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPatternPainter o) => o.color != color;
}
