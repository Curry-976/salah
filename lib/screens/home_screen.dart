import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/prayer_model.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../utils/hijri_converter.dart';
import '../utils/theme.dart';
import '../utils/prayer_formatter.dart';
import '../widgets/prayer_list.dart';
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
    _NavItem(Icons.access_time_outlined,      Icons.access_time_filled,   'Prières'),
    _NavItem(Icons.explore_outlined,           Icons.explore,              'Qibla'),
    _NavItem(Icons.mosque_outlined,            Icons.mosque,               'Mosquées'),
    _NavItem(Icons.calendar_month_outlined,    Icons.calendar_month,       'Calendrier'),
    _NavItem(Icons.settings_outlined,          Icons.settings,             'Réglages'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final loc  = context.read<LocationService>();
    final pray = context.read<PrayerService>();
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
        height: _itemHeight + 16,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;
            final slotW  = totalW / n;
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
                    final item     = widget.items[i];
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
// Structure inspirée de SalahTime : horloge live géante + date hégirienne
// + section "prochaine prière" + liste des horaires.

class _PrayerHome extends StatelessWidget {
  const _PrayerHome();

  /// "dimanche 7 juin 2026" → "Dimanche 7 Juin 2026"
  static String _titleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>();
    final prayers  = context.watch<PrayerService>();
    final now      = DateTime.now();
    final topPad   = MediaQuery.of(context).viewPadding.top;
    final hijri    = HijriDate.fromGregorian(now);

    final city = location.hasLocation && location.cityName.isNotEmpty
        ? location.cityName
        : 'Mayotte';

    final dateStr = _titleCase(
      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(now),
    );

    final clockStr = DateFormat('HH:mm:ss').format(now);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, topPad + 24, 24, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── Header : ville + date ─────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    await location.fetchLocation();
                    if (location.hasLocation) {
                      await context.read<PrayerService>().calculate(
                            location.latitude!, location.longitude!);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        location.isLoading
                            ? Icons.hourglass_top_outlined
                            : location.isUsingFallback
                                ? Icons.location_off_outlined
                                : Icons.gps_fixed,
                        size: 12,
                        color: location.isUsingFallback
                            ? AppColors.textMuted
                            : AppColors.greenLight,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        city,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 48),

            // ── Date hégirienne ───────────────────────────────────────
            Text(
              '${hijri.format()} H',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 450.ms, delay: 60.ms)
                .slideY(begin: 0.06, end: 0, duration: 450.ms, delay: 60.ms),

            const SizedBox(height: 8),

            // ── Horloge live ──────────────────────────────────────────
            Text(
              clockStr,
              style: AppFonts.mono(
                color: AppColors.textPrimary,
                fontSize: 72,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
                height: 1,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .slideY(begin: 0.08, end: 0, duration: 500.ms, delay: 100.ms, curve: Curves.easeOut),

            const SizedBox(height: 36),

            // ── Séparateur ────────────────────────────────────────────
            const Divider(color: AppColors.border, height: 1)
                .animate()
                .fadeIn(duration: 400.ms, delay: 160.ms),

            const SizedBox(height: 28),

            // ── Prochaine prière ──────────────────────────────────────
            if (location.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  color: AppColors.green,
                  strokeWidth: 2,
                ),
              )
            else if (prayers.nextPrayer != null) ...[
              const Text(
                'PROCHAINE PRIÈRE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              )
                  .animate()
                  .fadeIn(duration: 380.ms, delay: 200.ms),

              const SizedBox(height: 10),

              Text(
                prayers.nextPrayer!.name.displayName,
                style: const TextStyle(
                  color: AppColors.greenLight,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              )
                  .animate()
                  .fadeIn(duration: 480.ms, delay: 240.ms)
                  .slideY(begin: 0.06, end: 0, duration: 480.ms, delay: 240.ms, curve: Curves.easeOut),

              const SizedBox(height: 6),

              Text(
                PrayerFormatter.formatCountdown(prayers.timeToNext),
                style: AppFonts.mono(
                  color: AppColors.textSecondary,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(duration: 380.ms, delay: 280.ms),
            ],

            const SizedBox(height: 44),

            // ── Horaires du jour ──────────────────────────────────────
            if (prayers.todayPrayers.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'HORAIRES DU JOUR',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              ...prayers.todayPrayers.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final next = i + 1 < prayers.todayPrayers.length
                    ? prayers.todayPrayers[i + 1].time
                    : null;
                final gap = next != null
                    ? (next.difference(p.time).inMinutes / 60 * 6.0)
                        .clamp(4.0, 16.0)
                    : 4.0;
                return PrayerTile(prayer: p, bottomMargin: gap)
                    .animate(delay: (i * 55).ms)
                    .fadeIn(duration: 380.ms, curve: Curves.easeOut)
                    .slideX(begin: -0.06, end: 0, duration: 380.ms, curve: Curves.easeOut);
              }),
            ],
          ],
        ),
      ),
    );
  }
}
