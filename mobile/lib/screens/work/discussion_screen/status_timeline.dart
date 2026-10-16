import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../../bloc/Work/work_state.dart';
import '../../../bloc/permissions/permissions_bloc.dart';
import '../../../bloc/permissions/permissions_event.dart';
import '../../../bloc/work_discussion/work_media/work_media_state.dart';
import '../../../bloc/work_discussion/work_milestone/work_milestone_bloc.dart';
import '../../../bloc/work_discussion/work_milestone/work_milestone_event.dart';
import '../../../bloc/work_discussion/work_timeline/status_timeline_bloc.dart';

import '../../../config/colors.dart';
import '../../../config/strings.dart';
import '../../../data/model/work/status_timeline.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../notes/widgets/notes_shimmer_widget.dart';
import '../../widgets/custom_container.dart';
import '../../widgets/no_data.dart';
import '../../widgets/no_permission_screen.dart';

class StatusTimeline extends StatefulWidget {
  final int? id;
  const StatusTimeline({super.key, this.id});

  @override
  State<StatusTimeline> createState() => _StatusTimelineState();
}

class _StatusTimelineState extends State<StatusTimeline> {
  bool? isFirst;
  bool isLoadingMore = false;
  bool? isFirstTimeUSer;
  TextEditingController milestoneSearchController = TextEditingController();
  bool? isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    context
        .read<WorkMilestoneBloc>()
        .add(SearchWorkMilestone(widget.id, "", "", "", "", "", "", "", ""));
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
    });
    // filterCount = 0;
    BlocProvider.of<WorkMilestoneBloc>(context)
        .add(WorkMileStoneList(id: widget.id));
    BlocProvider.of<WorkMilestoneBloc>(context)
        .add(WorkMileStoneList(id: widget.id));

    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());

    setState(() {
      isLoading = false;
    });
  }

  void onShowCaseCompleted() {
    _setIsFirst(false);
  }

  _setIsFirst(value) async {
    isFirst = value;
    var box = await Hive.openBox(authBox);
    box.put("isFirstCase", value);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        color: AppColors.primary, // Spinner color
        backgroundColor: Theme.of(context).colorScheme.backGroundColor,
        onRefresh: _onRefresh,
        child: context.read<PermissionsBloc>().isManageWork == true
            ? Column(
                children: [
                  Expanded(
                    child: BlocConsumer<WorkStatusTimelineBloc,
                        StatusTimelineState>(
                      listener: (context, state) {
                        if (state is WorkStatusTimelinePaginated) {
                          isLoading = false;
                          setState(() {});
                        }
                      },
                      builder: (context, state) {
                        if (state is WorkMediaLoading) {
                          return const NotesShimmer();
                        } else if (state is WorkStatusTimelinePaginated) {
                          // Show notes list with pagination
                          return NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo is ScrollStartNotification) {
                                FocusScope.of(context)
                                    .unfocus(); // Dismiss keyboard
                              }
                              // Check if the user has scrolled to the end and load more notes if needed
                              if (!state.hasReachedMax &&
                                  scrollInfo.metrics.pixels ==
                                      scrollInfo.metrics.maxScrollExtent &&
                                  isLoading == false) {
                                isLoading = true;
                                setState(() {});
                                // context.read<WorkMilestoneBloc>().add(
                                //     WorkMilestoneLoadMore(
                                //         widget.id,
                                //         mileStoneSearchQuery,
                                //         "",
                                //         "",
                                //         "",
                                //         "",
                                //         "",
                                //         "",
                                //         ""));
                              }
                              return false;
                            },
                            child: context
                                        .read<PermissionsBloc>()
                                        .isManageWork ==
                                    true
                                ? state.WorkTimeline.isNotEmpty
                                    ? ListView.builder(
                                        padding: EdgeInsets.only(
                                            left: 18.w,
                                            right: 18.w,
                                            bottom: 150.h),
                                        // physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: state.hasReachedMax
                                            ? state.WorkTimeline.length
                                            : state.WorkTimeline.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index <
                                              state.WorkTimeline.length) {
                                            StatusTimelineModel timline =
                                                state.WorkTimeline[index];
                                            return StatusTimelineCard(
                                                state.WorkTimeline,
                                                timline,
                                                index); // No
                                          } else {
                                            // Show a loading indicator when more notes are being loaded
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 0),
                                              child: Center(
                                                child: state.hasReachedMax
                                                    ? const Text('')
                                                    : const SpinKitFadingCircle(
                                                        color:
                                                            AppColors.primary,
                                                        size: 40.0,
                                                      ),
                                              ),
                                            );
                                          }
                                        })
                                    : NoData(
                                        isImage: true,
                                      )
                                : NoPermission(),
                          );
                        } else if (state is WorkError) {
                          // Show error message
                          return const NotesShimmer();
                        } else if (state is WorkSuccess) {}
                        // Handle other states
                        return Container();
                      },
                    ),
                  )
                ],
              )
            : const NoPermission());
  }

  Widget StatusTimelineCard(workTimelineList, workTimeline, index) {
    Color? colorOfNewStatus;
    Color? colorOfOldStatus;

    switch (workTimeline.oldColor) {
      case "primary":
        colorOfOldStatus = AppColors.primary;
        break;
      case "secondary":
        colorOfOldStatus = Color(0xFF8592a3);
        break;
      case "success":
        colorOfOldStatus = Colors.green;
        break;
      case "danger":
        colorOfOldStatus = Colors.red;
        break;
      case "warning":
        colorOfOldStatus = Color(0xFFfaab01);
        break;
      case "info":
        colorOfOldStatus = Color(0xFF36c3ec);
        break;
      case "dark":
        colorOfOldStatus = Colors.black;
        break;
      default:
        colorOfOldStatus = Colors.grey; // Fallback color
    }
    switch (workTimeline.newColor) {
      case "primary":
        colorOfNewStatus = AppColors.primary;
        break;
      case "secondary":
        colorOfNewStatus = Color(0xFF8592a3);
        break;
      case "success":
        colorOfNewStatus = Colors.green;
        break;
      case "danger":
        colorOfNewStatus = Colors.red;
        break;
      case "warning":
        colorOfNewStatus = Color(0xFFfaab01);
        break;
      case "info":
        colorOfNewStatus = Color(0xFF36c3ec);
        break;
      case "dark":
        colorOfNewStatus = Colors.black;
        break;
      default:
        colorOfNewStatus = Colors.grey; // Fallback color
    }
    // Output: 2025-03-03
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: TimelineTile(
        isFirst: index == 0,
        isLast: index == workTimelineList.length - 1,
        beforeLineStyle: LineStyle(color: colorOfNewStatus, thickness: 3),
        indicatorStyle: IndicatorStyle(
          width: 15.w,
          color: colorOfNewStatus,
        ),
        endChild: Padding(
          padding: const EdgeInsets.all(10.0),
          child: customContainer(
              addWidget: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          workTimeline.timeDiff,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.textClrChange),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    Text(
                      "${workTimeline.changedAt}  ${workTimeline.changedAtTime}",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    Text(
                      "changed status from ",
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.textClrChange),
                    ),
                    SizedBox(
                      height: 5.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          height: 20.h,
                          // width: 110.w, //
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color:
                                  colorOfOldStatus), // Set the height of the dropdown
                          child: Center(
                            child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                child: CustomText(
                                  text: workTimeline.previousStatus,
                                  color: AppColors.whiteColor,
                                  size: 12.sp,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ),
                        Text(
                          " >> ",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.textClrChange),
                        ),
                        Container(
                          alignment: Alignment.center,
                          height: 20.h,
                          // width: 110.w, //
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color:
                                  colorOfNewStatus), // Set the height of the dropdown
                          child: Center(
                            child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                child: CustomText(
                                  text: workTimeline.status,
                                  color: AppColors.whiteColor,
                                  size: 12.sp,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              context: context),
        ),
      ),
    );
  }
}
