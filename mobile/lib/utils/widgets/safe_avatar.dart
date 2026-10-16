import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../config/colors.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SafeAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData defaultIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  const SafeAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 20,
    this.defaultIcon = Icons.person,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasValidImage = imageUrl != null && imageUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.greyColor.withValues(alpha: 0.2),
      backgroundImage: hasValidImage ? NetworkImage(imageUrl!) : null,
      onBackgroundImageError: hasValidImage
          ? (exception, stackTrace) {
              if (kDebugMode) {
                logger.d('⚠️ Error loading avatar: $exception');
              }
            }
          : null,
      child: !hasValidImage
          ? Icon(
              defaultIcon,
              size: radius,
              color: iconColor ?? AppColors.greyColor,
            )
          : null,
    );
  }
}
