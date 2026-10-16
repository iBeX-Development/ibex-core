import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/utils/widgets/custom_text.dart';

import '../../utils/widgets/my_theme.dart';

/// Reusable WorkDetails AppBar widget that displays a menu button
/// and title.
///

class CustomAppBar extends StatelessWidget {
  /// Title text to display
  final String title;

  /// Callback when menu button is pressed
  final VoidCallback onMenuPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          isLightTheme ? MyThemes.lightThemeShadow : MyThemes.darkThemeShadow,
        ],
      ),
      // height: 120,
      child: Padding(
        padding: EdgeInsets.only(top: 35.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: onMenuPressed,
                    child: Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: HeroIcon(
                        size: 25.sp,
                        HeroIcons.bars3BottomLeft,
                        style: HeroIconStyle.outline,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                    ),
                  ),
                  // SizedBox(width: 10.w),
                  CustomText(
                    text: title,
                    fontWeight: FontWeight.w700,
                    size: 18,
                    color: Theme.of(context).colorScheme.textClrChange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
