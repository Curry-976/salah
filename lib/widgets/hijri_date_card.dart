import 'package:flutter/material.dart';
import '../utils/hijri_converter.dart';
import '../utils/theme.dart';

class HijriDateCard extends StatelessWidget {
  const HijriDateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijri = HijriDate.fromGregorian(now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, color: AppColors.gold, size: 18),
          const SizedBox(width: 10),
          Text(
            hijri.format(),
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
