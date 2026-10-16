import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../bloc/languages/language_switcher_bloc.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../data/localStorage/hive.dart';
import 'custom_text.dart';
import '../../../src/generated/i18n/app_localizations.dart';

class RowDashboard extends StatefulWidget {
  final List<dynamic> list;
  final String title;
  final bool? isusertitle;
  final bool? fromNotification;
  final bool? isnotificationusers;
  final bool? isnotificationclient;

  const RowDashboard({
    super.key,
    required this.list,
    this.isnotificationclient = false,
    this.isnotificationusers,
    required this.title,
    this.isusertitle,
    this.fromNotification,
  });

  @override
  State<RowDashboard> createState() => _RowDashboardState();
}

class _RowDashboardState extends State<RowDashboard> {
  bool isRtl = false;
  Future<void> _checkRtlLanguage() async {
    final languageCode = await HiveStorage().getLanguage();
    isRtl = LanguageBloc.instance.isRtlLanguage(
      languageCode ?? defaultLanguage,
    );
    setState(() {});
  }

  String? _getPhoto(dynamic item) {
    if (widget.isnotificationusers == true) {
      return item.avatar;
    }
    return item.photo;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkRtlLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return widget.title == "client"
        ? SizedBox(
            // color: Colors.yellow,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // Aligning to the end for 'client'
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  child: CustomText(
                    text:
                        widget.isnotificationclient != null &&
                            widget.isnotificationclient == true
                        ? AppLocalizations.of(context)!.notificationclients
                        : AppLocalizations.of(context)!.clients,
                    color: Theme.of(context).colorScheme.textClrChange,
                    textAlign: TextAlign.end,
                  ),
                ),
                widget.list.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Stack(
                          children: [
                            Padding(
                              padding: widget.list.length > 2
                                  ? EdgeInsets.only(right: 0.w)
                                  : EdgeInsets.only(right: 0.w, left: 0),
                              child: isRtl
                                  ? Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: SizedBox(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .end, // Client should be aligned at the end
                                          children: [
                                            for (
                                              int i = 0;
                                              i < (widget.list.length);
                                              i++
                                            )
                                              if (i < 2)
                                                Align(
                                                  widthFactor: 0.75.w,
                                                  child: CircleAvatar(
                                                    radius: 15.r,
                                                    backgroundColor:
                                                        Colors.white,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: AppColors
                                                              .greyColor,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: CircleAvatar(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        radius: 15.r,
                                                        backgroundImage:
                                                            _getPhoto(
                                                                  widget
                                                                      .list[i],
                                                                ) !=
                                                                null
                                                            ? NetworkImage(
                                                                '$activePictureUrl/${_getPhoto(widget.list[i])}',
                                                              )
                                                            : null,
                                                        child:
                                                            _getPhoto(
                                                                  widget
                                                                      .list[i],
                                                                ) ==
                                                                null
                                                            ? Icon(
                                                                Icons.person,
                                                                size: 20,
                                                              )
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            // Add the custom text if there are more than 2 items in the list (for LTR)
                                            if (widget.list.length > 2)
                                              Align(
                                                widthFactor: 0.75.w,
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  height: 30.r,
                                                  width: 30.r,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                  child: CustomText(
                                                    text:
                                                        '+${widget.list.length - 2}',
                                                    color: AppColors
                                                        .pureWhiteColor,
                                                  ),
                                                ),
                                              ),

                                            // Loop through the list and display the first two avatars

                                            // Add the custom text if there are more than 2 items in the list (for RTL)
                                          ],
                                        ),
                                      ),
                                    )
                                  : Directionality(
                                      //do not touch
                                      textDirection: TextDirection.ltr,
                                      child: SizedBox(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .end, // Client should be aligned at the end
                                          children: [
                                            // Add the custom text if there are more than 2 items in the list (for LTR)

                                            // Loop through the list and display the first two avatars
                                            for (
                                              int i = 0;
                                              i < (widget.list.length);
                                              i++
                                            )
                                              if (i < 2)
                                                Align(
                                                  widthFactor: 0.75.w,
                                                  child: CircleAvatar(
                                                    radius: 15.r,
                                                    backgroundColor:
                                                        Colors.white,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: AppColors
                                                              .greyColor,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: CircleAvatar(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        radius: 15.r,
                                                        backgroundImage:
                                                            _getPhoto(
                                                                  widget
                                                                      .list[i],
                                                                ) !=
                                                                null
                                                            ? NetworkImage(
                                                                '$activePictureUrl/${_getPhoto(widget.list[i])}',
                                                              )
                                                            : null,
                                                        child:
                                                            _getPhoto(
                                                                  widget
                                                                      .list[i],
                                                                ) ==
                                                                null
                                                            ? Icon(
                                                                Icons.person,
                                                                size: 20,
                                                              )
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                            // Add the custom text if there are more than 2 items in the list (for RTL)
                                            if (widget.list.length > 2)
                                              Align(
                                                widthFactor: 0.75.w,
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  height: 30.r,
                                                  width: 30.r,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                  child: CustomText(
                                                    text:
                                                        '+${widget.list.length - 2}',
                                                    color: AppColors
                                                        .pureWhiteColor,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        // color: AppColors.red,
                        height: 30.h,
                        child: Padding(
                          padding: EdgeInsets.only(top: 5.h),
                          child: CustomText(
                            text: AppLocalizations.of(context)!.noclient,
                            color: Theme.of(context).colorScheme.textClrChange,
                            size: 10.sp,
                          ),
                        ),
                      ),
              ],
            ),
          )
        : SizedBox(
            // color: Colors.red,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Aligning to the end for 'client'
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomText(
                  text: widget.isnotificationusers == true
                      ? AppLocalizations.of(context)!.notificationusers
                      : AppLocalizations.of(context)!.workspace,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
                widget.list.isEmpty
                    ? SizedBox(
                        height: 30,
                        child: Padding(
                          padding: EdgeInsets.only(top: 5.h),
                          child: CustomText(
                            text: AppLocalizations.of(context)!.unclear,
                            color: Theme.of(context).colorScheme.textClrChange,
                            size: 10.sp,
                          ),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Stack(
                          children: [
                            Padding(
                              padding: widget.list.length > 2
                                  ? EdgeInsets.only(right: 0.w)
                                  : EdgeInsets.only(right: 0.w, left: 0),
                              child: isRtl
                                  ? Directionality(
                                      // rtl
                                      textDirection: TextDirection.ltr,
                                      child: SizedBox(
                                        // color:  Colors.white10,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .start, // Client should be aligned at the end
                                          children: [
                                            for (
                                              int i = 0;
                                              i < (widget.list.length);
                                              i++
                                            )
                                              if (i < 2)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    right: 4.w,
                                                  ),
                                                  child: Container(
                                                    constraints: BoxConstraints(
                                                      maxWidth: 120.w,
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          width: 30.r,
                                                          height: 30.r,
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color: AppColors
                                                                  .greyColor,
                                                              width: 1.5,
                                                            ),
                                                            image:
                                                                _getPhoto(
                                                                      widget
                                                                          .list[i],
                                                                    ) !=
                                                                    null
                                                                ? DecorationImage(
                                                                    image: NetworkImage(
                                                                      '$activePictureUrl/${_getPhoto(widget.list[i])}',
                                                                    ),
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  )
                                                                : null,
                                                            color: Colors.white,
                                                          ),
                                                          child:
                                                              _getPhoto(
                                                                    widget
                                                                        .list[i],
                                                                  ) ==
                                                                  null
                                                              ? Icon(
                                                                  Icons.person,
                                                                  size: 20,
                                                                )
                                                              : null,
                                                        ),
                                                        SizedBox(width: 6.w),
                                                        Flexible(
                                                          child: Opacity(
                                                            opacity: 0.8,
                                                            child: CustomText(
                                                              text:
                                                                  widget.isnotificationusers ==
                                                                      true
                                                                  ? '${widget.list[i].firstName ?? ''} ${widget.list[i].lastName ?? ''}'
                                                                        .trim()
                                                                  : widget
                                                                            .list[i]
                                                                            .team_name ??
                                                                        '',
                                                              color:
                                                                  Colors.black,
                                                              size: 12.sp,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            if (widget.list.length > 2)
                                              Align(
                                                widthFactor: 0.75.w,
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  height: 30.r,
                                                  width: 30.r,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                  child: CustomText(
                                                    text:
                                                        '+${widget.list.length - 2}',
                                                    color: AppColors
                                                        .pureWhiteColor,
                                                  ),
                                                ),
                                              ),
                                            // Add the custom text if there are more than 2 items in the list (for RTL)gfgdghgfhgfhghuyuy
                                          ],
                                        ),
                                      ),
                                    )
                                  : Directionality(
                                      //do not touch
                                      textDirection: TextDirection.ltr,
                                      child: SizedBox(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .start, // Client should be aligned at the end
                                          children: [
                                            for (
                                              int i = 0;
                                              i < (widget.list.length);
                                              i++
                                            )
                                              if (i < 2)
                                                Align(
                                                  widthFactor: 0.75.w,
                                                  child: CircleAvatar(
                                                    radius: 15.r,
                                                    backgroundColor:
                                                        Colors.white,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: AppColors
                                                              .greyColor,
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      child: CircleAvatar(
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        radius: 15.r,
                                                        backgroundImage:
                                                            _getPhoto(
                                                                  widget
                                                                      .list[i],
                                                                ) !=
                                                                null
                                                            ? NetworkImage(
                                                                '$activePictureUrl/${_getPhoto(widget.list[i])}',
                                                              )
                                                            : null,
                                                        child:
                                                            _getPhoto(
                                                                  widget
                                                                      .list[i],
                                                                ) ==
                                                                null
                                                            ? Icon(
                                                                Icons.person,
                                                                size: 20,
                                                              )
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                            // Add the custom text if there are more than 2 items in the list (for RTL)gfgdghgfhgfhghuyuy
                                            if (widget.list.length > 2)
                                              Align(
                                                widthFactor: 0.75.w,
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  height: 30.r,
                                                  width: 30.r,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.primary,
                                                  ),
                                                  child: CustomText(
                                                    text:
                                                        '+${widget.list.length - 2}',
                                                    color: AppColors
                                                        .pureWhiteColor,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          );
  }
}
