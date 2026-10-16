import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';

import 'package:ibex/config/colors.dart';
import 'package:ibex/screens/widgets/no_data.dart';

import '../../../bloc/location/location_bloc.dart';
import '../../../bloc/location/location_event.dart';
import '../../../bloc/location/location_state.dart';

import '../../../bloc/theme/theme_bloc.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../config/strings.dart';
import '../../../data/model/task/task_model.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/my_theme.dart';
import '../../widgets/custom_cancel_create_button.dart';

class LocationField extends StatefulWidget {
  final bool? isRequired;
  final bool isCreate;
  final bool? isMeeting;
  final List<String> locationName;
  final List<int> locationId;
  final List<Tasks> project;
  final Function(List<String>, List<int>) onSelected;
  const LocationField({
    super.key,
    teamsField,
    this.isRequired = false,
    required this.locationId,
    required this.isCreate,
    this.isMeeting,
    required this.locationName,
    required this.project,
    required this.onSelected,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  String? projectsname;
  int? projectsId;
  List<int> userSelectedId = [];
  List<String> userSelectedname = [];
  String searchWord = "";
  int? userId;
  String? currentUserId;
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserId().then((_) {
      if (widget.isCreate && userId != null) {
        userSelectedId.add(userId!);
      }
      // Always load users regardless of isCreate flag
      BlocProvider.of<LocationBloc>(context).add(LocationList());
    });
  }

  Future<void> getUserId() async {
    var userbox = await Hive.openBox(userBox);
    userId = userbox.get('user_id');
    currentUserId = userbox.get('user_uuid')?.toString(); // ✅ UUID авах
  }

  @override
  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < widget.locationId.length; i++) {
      final id = widget.locationId[i];
      if (!userSelectedId.contains(id)) {
        userSelectedId.add(id);
        if (i < widget.locationName.length) {
          userSelectedname.add(widget.locationName[i]);
        }
      }
    }

    final themeBloc = context.read<ThemeBloc>();
    final isLightTheme = themeBloc.currentThemeState is LightThemeState;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              CustomText(
                text: AppLocalizations.of(context)!.location,
                color: Theme.of(context).colorScheme.textClrChange,
                size: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              if (widget.isRequired == true)
                const CustomText(
                  text: " *",
                  color: AppColors.red,
                  size: 15,
                  fontWeight: FontWeight.w400,
                ),
            ],
          ),
        ),
        BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5.h),
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () {
                    if (state is! LocationPaginated) {
                      BlocProvider.of<LocationBloc>(context).add(LocationList());
                    }
                    _userSearchController.clear();
                    searchWord = "";
                    _showLocationDialog(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    height: 40.h,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.greyColor),
                      color: Theme.of(context).colorScheme.containerDark,
                      boxShadow: [
                        isLightTheme
                            ? MyThemes.lightThemeShadow
                            : MyThemes.darkThemeShadow,
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CustomText(
                            text: userSelectedname.isNotEmpty
                                ? userSelectedname.join(", ")
                                : (widget.locationName.isNotEmpty
                                    ? widget.locationName.join(", ")
                                    : AppLocalizations.of(context)!.selectlocation),
                            fontWeight: FontWeight.w500,
                            size: 14.sp,
                            color: Theme.of(context).colorScheme.textClrChange,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (state is LocationLoading)
                          SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.purple,
                            ),
                          )
                        else
                          const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showLocationDialog(BuildContext outerContext) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) => BlocProvider.value(
        value: BlocProvider.of<LocationBloc>(outerContext),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.alertBoxBackGroundColor,
              contentPadding: EdgeInsets.zero,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: AppLocalizations.of(context)!.selectlocation,
                    fontWeight: FontWeight.w800,
                    size: 18.sp,
                    color: Theme.of(context).colorScheme.whitepurpleChange,
                  ),
                  const Divider(),
                  SizedBox(
                    height: 38.h,
                    child: TextField(
                      cursorColor: AppColors.greyForgetColor,
                      cursorWidth: 1,
                      controller: _userSearchController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: (38.h - 20.sp) / 2,
                          horizontal: 10.w,
                        ),
                        hintText: AppLocalizations.of(context)!.search,
                        hintStyle: TextStyle(
                          color: AppColors.greyForgetColor,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.greyForgetColor,
                          size: 18.sp,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.greyForgetColor,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(
                            color: AppColors.purple,
                            width: 1.0,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() => searchWord = value);
                        if (value.isEmpty) {
                          BlocProvider.of<LocationBloc>(context).add(LocationList());
                        } else {
                          BlocProvider.of<LocationBloc>(context).add(
                            SearchLocation(value, currentUserId ?? ""),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: BlocBuilder<LocationBloc, LocationState>(
                  builder: (context, state) {
                    if (state is LocationLoading) {
                      return SizedBox(
                        height: 200.h,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.purple,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    List<dynamic> locations = [];
                    bool hasReachedMax = true;
                    ScrollController scrollController = ScrollController();

                    if (state is LocationPaginated) {
                      locations = state.location;
                      hasReachedMax = state.hasReachedMax;
                      scrollController.addListener(() {
                        if (scrollController.position.atEdge &&
                            scrollController.position.pixels != 0) {
                          BlocProvider.of<LocationBloc>(context).add(
                            LoadMoreLocation(searchQuery: searchWord),
                          );
                        }
                      });
                    } else if (state is LocationSuccess) {
                      locations = state.location;
                    }

                    if (locations.isEmpty) {
                      return SizedBox(
                        height: 200.h,
                        child: NoData(isImage: true),
                      );
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 400.h),
                      child: ListView.separated(
                        controller: scrollController,
                        shrinkWrap: true,
                        itemCount: hasReachedMax
                            ? locations.length
                            : locations.length + 1,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.greyForgetColor.withOpacity(0.2),
                        ),
                        itemBuilder: (context, index) {
                          if (index >= locations.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.purple,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final location = locations[index];
                          final isSelected = userSelectedId.contains(location.id);

                          return InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  final removeIndex =
                                      userSelectedId.indexOf(location.id!);
                                  if (removeIndex != -1) {
                                    userSelectedId.removeAt(removeIndex);
                                    userSelectedname.removeAt(removeIndex);
                                  }
                                } else {
                                  userSelectedId.add(location.id!);
                                  userSelectedname.add(
                                    location.title ?? 'Unknown',
                                  );
                                }
                                widget.onSelected(
                                  userSelectedname,
                                  userSelectedId,
                                );
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.purple.withOpacity(0.08)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomText(
                                      text: location.title ?? 'Unknown',
                                      fontWeight: FontWeight.w500,
                                      size: 14.sp,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      color: isSelected
                                          ? AppColors.purple
                                          : Theme.of(context)
                                              .colorScheme
                                              .textClrChange,
                                    ),
                                  ),
                                  if (isSelected)
                                    HeroIcon(
                                      HeroIcons.checkCircle,
                                      style: HeroIconStyle.solid,
                                      color: AppColors.purple,
                                      size: 20.sp,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
                  child: CreateCancelButtom(
                    title: "OK",
                    onpressCancel: () {
                      _userSearchController.clear();
                      searchWord = "";
                      Navigator.pop(context);
                      BlocProvider.of<LocationBloc>(context).add(LocationList());
                    },
                    onpressCreate: () {
                      _userSearchController.clear();
                      searchWord = "";
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
