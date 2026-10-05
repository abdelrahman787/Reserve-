import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// MedStock logo lockup: the mark + the wordmark ("Med" dark, "Stock" primary).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.markSize = 48, this.showWordmark = true});

  final double markSize;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture.asset(
      'assets/brand/logo_mark.svg',
      height: markSize,
      width: markSize,
    );
    if (!showWordmark) return mark;

    final onDark = Theme.of(context).brightness == Brightness.dark;
    final medColor = onDark ? Colors.white : AppColors.primaryDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: markSize * 0.28),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: markSize * 0.62,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(text: 'Med', style: TextStyle(color: medColor)),
              const TextSpan(
                  text: 'Stock', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}
