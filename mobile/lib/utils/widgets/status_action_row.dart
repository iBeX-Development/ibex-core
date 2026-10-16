import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart'; //

import '../../config/colors.dart';
import 'custom_text.dart';

Widget statusActionRow(
  String status,
  BuildContext context, {
  bool detailPage = false,
}) {
  HeroIcons icon;
  Color color;

  switch (status.toLowerCase()) {
    case 'approved':
      icon = HeroIcons.checkCircle;
      color = Colors.green;
      break;
    case 'pending':
      icon = HeroIcons.clock;
      color = Colors.orange;
      break;
    case 'assigned':
      icon = HeroIcons.userGroup;
      color = Colors.blue;
      break;
    case 'return':
      icon = HeroIcons.xCircle;
      color = Colors.red;
      break;
    default:
      icon = HeroIcons.questionMarkCircle;
      color = Colors.grey;
  }

  return Row(
    mainAxisAlignment:
        MainAxisAlignment.end, // 👈 Row-г баруун талд шахаж байрлуулна
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      HeroIcon(
        icon,
        style: HeroIconStyle.solid,
        color: color,
        size: 20,
      ),
      SizedBox(width: 6.w),
      CustomText(
        text: status.isNotEmpty
            ? '${status[0].toUpperCase()}${status.substring(1)}'
            : status,
        size: 14,
        color: Theme.of(context).colorScheme.textClrChange,
        fontWeight: FontWeight.w700,
      ),
    ],
  );
}

Widget statusActionRowInt(
  int status,
  BuildContext context, {
  bool detailPage = false,
  String? workId,
  String? workPrefix,
}) {
  HeroIcons icon;
  Color color;
  String action_status = 'created';

  switch (status) {
    case 1:
      icon = HeroIcons.checkCircle;
      action_status = 'created';
      color = Colors.orange;

      break;
    case 5:
      icon = HeroIcons.clock;
      action_status = 'accepted';
      color = Colors.blue;

      break;
    case 6:
      icon = HeroIcons.xCircle;
      action_status = 'declined';
      color = Colors.red;

      break;
    case 2:
      icon = HeroIcons.lockClosed;
      action_status = 'approved';
      color = Colors.green;

      break;
    case 4:
      // icon = HeroIcons.arrowUturnLeft;
      icon = HeroIcons.userGroup;
      action_status = 'assigned';
      color = Colors.purple;
      break;
    case 3:
      icon = HeroIcons.xCircle;
      action_status = 'returned';
      color = Colors.red;
      break;
    default:
      icon = HeroIcons.questionMarkCircle;
      action_status = 'waiting';
      color = Colors.grey;
  }

  return Row(
    mainAxisAlignment:
        MainAxisAlignment.end, // 👈 Row-г баруун талд шахаж байрлуулна
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      HeroIcon(icon, style: HeroIconStyle.solid, color: color, size: 20),
      SizedBox(width: 6.w),
      CustomText(
        text: action_status.isNotEmpty
            ? '${action_status[0].toUpperCase()}${action_status.substring(1)}'
            : action_status,
        size: 14,
        color: Theme.of(context).colorScheme.textClrChange,
        fontWeight: FontWeight.w700,
      ),
      if (workId != null) ...[
        SizedBox(width: 8.w),
        CustomText(
          text: workPrefix != null ? '$workPrefix #$workId' : '#$workId',
          size: 14,
          color: Theme.of(context).colorScheme.textClrChange,
          fontWeight: FontWeight.w600,
        ),
      ],
    ],
  );
}
