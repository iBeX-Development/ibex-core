import 'package:flutter/material.dart';
import 'package:ibex/config/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../routes/routes.dart';

/// Reusable BackBar widget that displays a back button
/// positioned at the right side of the screen.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     YourContent(),
///     BackBar(),
///   ],
/// )
/// ```
class BackBar extends StatelessWidget {
  /// Custom callback when back button is pressed
  /// If null, will use Navigator.pop()
  final VoidCallback? onPressed;

  /// Bottom position of the back bar
  final double? bottom;

  /// Width of the back bar
  final double? width;

  /// Height of the back bar
  final double? height;

  /// Right offset when sidebar is open
  final double? rightOffset;

  /// Whether sidebar is currently open (for responsive offset calculation)
  final bool isSidebarOpen;

  const BackBar({
    super.key,
    this.onPressed,
    this.bottom,
    this.width,
    this.height,
    this.rightOffset,
    this.isSidebarOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Calculate responsive offset based on device width
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isIPad = screenWidth > 600;

    // ✅ Auto-calculate rightOffset if not provided and sidebar is open
    final calculatedRightOffset =
        rightOffset ?? (isSidebarOpen ? (isIPad ? 22.w : 52.w) : 0.w);

    // ✅ Calculate bottom position for better iPad support
    final buttonHeight = height ?? 60.h;
    final calculatedBottom = bottom ??
        (isSidebarOpen
            ? (isIPad
                ? (screenHeight * 0.5 - (buttonHeight / 2))
                : (screenHeight / 2 - 110.h))
            : screenHeight / 2 - 110.h);

    return Positioned(
      right: calculatedRightOffset,
      bottom: calculatedBottom,
      child: InkWell(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: onPressed ?? () => router.pop(context),
        child: Container(
          width: width ?? 40.w,
          height: height ?? 60.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.backGroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(70),
              bottomLeft: Radius.circular(70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(-2, 2),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
