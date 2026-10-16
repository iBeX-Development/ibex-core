import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/routes/routes.dart';
import 'package:ibex/src/generated/i18n/app_localizations.dart';
import 'package:ibex/utils/widgets/my_theme.dart';
import '../../screens/dash_board/bottomNavWidget.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isLightTheme;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.isLightTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // child: BackdropFilter(
      // filter: ImageFilter.blur(sigmaX: 40.4, sigmaY: 83.4),
      child: _buildNavBarContainer(context),
      // ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    HeroIcons icon,
    int index,
    String tooltip,
  ) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: GlowIconButton(
          icon: icon,
          isSelected: selectedIndex == index,
          glowColor: Colors.white,
          selectedColor: Theme.of(context).colorScheme.textClrChange,
          unselectedColor: AppColors.greyForgetColor,
          onTap: () => onTap(index),
        ),
      ),
    );
  }

  Widget _buildNavBarContainer(BuildContext context) {
    return SizedBox(
      height: 80.h, // Increased height to accommodate floating button
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: BottomNavPainter(
                color: Colors.white,
                isLight: isLightTheme,
              ),
              child: Container(
                height: 60.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavButton(
                      context,
                      HeroIcons.home,
                      0,
                      AppLocalizations.of(context)!.home,
                    ),
                    _buildNavButton(
                      context,
                      HeroIcons.chartBar,
                      1,
                      AppLocalizations.of(context)!.statistics,
                    ),
                    SizedBox(width: 60.w),
                    _buildNavButton(
                      context,
                      HeroIcons.documentCheck,
                      2,
                      AppLocalizations.of(context)!.requestWorks,
                    ),
                    _buildNavButton(
                      context,
                      HeroIcons.cog8Tooth,
                      3,
                      AppLocalizations.of(context)!.settings,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0, // Changed from -20.h to 0
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: AppColors.primary.withValues(alpha: 0.3),
                  //     blurRadius: 10,
                  //     offset: Offset(0, 4),
                  //     spreadRadius: 1,
                  //   ),
                  // ],
                ),
                child: _buildAddWorkButton(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update _buildAddWorkButton to remove Transform
  Widget _buildAddWorkButton(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: const HeroIcon(
          HeroIcons.plus,
          style: HeroIconStyle.solid,
          color: Colors.white,
        ),
        onPressed: () {
          router.push(
            '/createworkrequest',
            extra: {
              "id": 0,
              "isCreate": true,
              "fromDetail": false,
              'priority': '1',
              'priorityId': 1,
              'statusId': 1,
              'status': '1',
              'woStatus': 1,
              'createdType': 'request'
            },
          );
        },
        tooltip: AppLocalizations.of(context)!.creatework,
      ),
    );
  }
}

class BottomNavPainter extends CustomPainter {
  final Color color;
  final bool isLight;

  BottomNavPainter({required this.color, required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();
    double centerX = size.width / 2;
    double notchRadius = 32.0;

    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius - 20, 0);

    // Left curve
    path.quadraticBezierTo(
      centerX - notchRadius - 10,
      0,
      centerX - notchRadius - 5,
      5,
    );

    // Bottom arc
    path.arcToPoint(
      Offset(centerX + notchRadius + 5, 5),
      radius: Radius.circular(notchRadius + 5),
      clockwise: false,
    );

    // Right curve
    path.quadraticBezierTo(
      centerX + notchRadius + 10,
      0,
      centerX + notchRadius + 20,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw border
    Paint borderPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);

    // Draw shadow
    if (isLight) {
      canvas.drawShadow(path, Colors.black.withValues(alpha: 0.1), 3, true);
    } else {
      canvas.drawShadow(path, Colors.black.withValues(alpha: 0.3), 3, true);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
