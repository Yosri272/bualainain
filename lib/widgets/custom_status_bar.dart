import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomStatusBar extends StatelessWidget {
  const CustomStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/battery.svg',
              height: 12,
            ),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/icons/wifi.svg',
              height: 12,
            ),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/icons/network.svg',
              height: 12,
            ),
            const Spacer(),
            const Text(
              '10:00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}