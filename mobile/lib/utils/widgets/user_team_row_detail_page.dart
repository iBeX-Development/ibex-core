import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ibex/config/constants.dart';

import '../../config/colors.dart';
import 'custom_text.dart';

class UserTeamRowDetailPage extends StatefulWidget {
  final List<dynamic> list;
  final String title;
  final Function(dynamic)? onRemove;
  const UserTeamRowDetailPage({
    super.key,
    required this.list,
    required this.title,
    this.onRemove,
  });

  @override
  State<UserTeamRowDetailPage> createState() => _UserTeamRowDetailPageState();
}

class _UserTeamRowDetailPageState extends State<UserTeamRowDetailPage> {
  String _getDisplayName(dynamic item) {
    try {
      if (item.team_name != null && item.team_name.toString().isNotEmpty) {
        return item.team_name;
      }
    } catch (e) {
      // Object doesn't have team_name
    }
    try {
      final firstName = item.firstName ?? '';
      final lastName = item.lastName ?? '';
      final fullName = '$firstName $lastName'.trim();
      return fullName.isNotEmpty ? fullName : 'Unknown';
    } catch (e) {
      // Object doesn't have firstName/lastName either
    }
    return 'Unknown';
  }

  bool _isTeam(dynamic item) {
    try {
      return item.team_name != null && item.team_name.toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  bool _isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    // UUID format: 8-4-4-4-12 hex characters
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  String? _getPhoto(dynamic item) {
    try {
      final photo = item.avatar;
      if (_isValidUuid(photo)) {
        return photo;
      }
      return null;
    } catch (e) {
      try {
        final photo = item.photo;
        if (_isValidUuid(photo)) {
          return photo;
        }
        return null;
      } catch (e) {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: widget.title,
          size: 14.sp,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.textClrChange,
        ),
        SizedBox(height: 15.h),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < widget.list.length; i++)
              if (i < 10)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 15.r,
                        backgroundColor: _isTeam(widget.list[i])
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.white,
                        child:
                            (_getPhoto(widget.list[i]) != null &&
                                _getPhoto(widget.list[i])!.isNotEmpty)
                            ? CircleAvatar(
                                backgroundColor: Colors.transparent,
                                radius: 15.r,
                                backgroundImage: NetworkImage(
                                  '$activePictureUrl/${_getPhoto(widget.list[i])!}',
                                ),
                              )
                            : Icon(
                                _isTeam(widget.list[i])
                                    ? Icons.groups
                                    : Icons.person,
                                size: 20,
                                color: _isTeam(widget.list[i])
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Row(
                          children: [
                            if (_isTeam(widget.list[i]))
                              Padding(
                                padding: EdgeInsets.only(right: 4.w),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CustomText(
                                    text: "Team",
                                    size: 9.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Flexible(
                              child: CustomText(
                                text: _getDisplayName(widget.list[i]),
                                color: Theme.of(
                                  context,
                                ).colorScheme.textClrChange,
                                size: 12.sp,
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                fontWeight: _isTeam(widget.list[i])
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onRemove != null && !_isTeam(widget.list[i]))
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18.sp,
                            color: Colors.red,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () {
                            widget.onRemove!(widget.list[i]);
                          },
                        ),
                    ],
                  ),
                ),
            if (widget.list.length > 10)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: CustomText(
                  text: '+${widget.list.length - 10} more',
                  color: AppColors.greyColor,
                  size: 11.sp,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
