import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:heroicons/heroicons.dart';
import 'package:ibex/config/colors.dart';
import '../../bloc/work/work_event.dart';
import '../../bloc/work/work_state.dart';
import '../../bloc/permissions/permissions_bloc.dart';
import '../../bloc/permissions/permissions_event.dart';

import '../../bloc/work/work_bloc.dart';
import '../../bloc/setting/settings_bloc.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../config/constants.dart';
import '../../config/internet_connectivity.dart';
import '../../data/model/Work/all_work.dart';
import '../../data/repositories/Work/work_repo.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/back_arrow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/widgets/custom_text.dart';
import '../../utils/widgets/my_theme.dart';
import '../../utils/widgets/row_dashboard.dart';
import '../../utils/widgets/search_pop_up.dart';
import '../../utils/widgets/shake_widget.dart';
import '../../utils/widgets/status_priority_row.dart';
import '../../utils/widgets/toast_widget.dart';
import '../notes/widgets/notes_shimmer_widget.dart';
import '../widgets/html_widget.dart';
import '../widgets/no_data.dart';
import '../widgets/no_permission_screen.dart';
import '../widgets/search_field.dart';
import '../widgets/speech_to_text.dart';
import '../widgets/user_client_box.dart';
import '../../../src/generated/i18n/app_localizations.dart';

class WorkFavouriteScreen extends StatefulWidget {
  const WorkFavouriteScreen({super.key});

  @override
  State<WorkFavouriteScreen> createState() => _WorkFavouriteScreenState();
}

class _WorkFavouriteScreenState extends State<WorkFavouriteScreen>
    with TickerProviderStateMixin {
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  late SpeechToTextHelper speechHelper;
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _pinnedcController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
    value: 1.0,
  );
  String searchWord = "";
  bool? isLoading = false;
  bool isLoadingMore = false;

  String? currency;
  String? currencyPosition;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  void _initializeApp() {
    searchController.addListener(() {
      setState(() {});
    });
    speechHelper = SpeechToTextHelper(
      onSpeechResultCallback: (result) {
        setState(() {
          searchController.text = result;
          // context.read<ActivityLogBloc>().add(SearchActivityLog(result));
        });
        Navigator.pop(context);
      },
    );
    speechHelper.initSpeech();

    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());

    BlocProvider.of<WorkBloc>(context).add(WorkDashBoardFavList(isFav: 1));
  }

  @override
  void dispose() {
    super.dispose();
    _connectivitySubscription.cancel();
  }

  @override
  void initState() {
    CheckInternet.initConnectivity().then((List<ConnectivityResult> results) {
      if (results != "ConnectivityResult.none") {
        setState(() {
          _connectionStatus = results;
        });
        _initializeApp();
      }
    });

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results != "ConnectivityResult.none") {
        CheckInternet.updateConnectionStatus(results).then((value) {
          setState(() {
            _connectionStatus = value;
          });
          _initializeApp();
        });
      }
    });
    speechHelper = SpeechToTextHelper(
      onSpeechResultCallback: (result) {
        setState(() {
          searchController.text = result;
          // context.read<ActivityLogBloc>().add(SearchActivityLog(result));
        });
        Navigator.pop(context);
      },
    );
    speechHelper.initSpeech();
    currency = context.read<SettingsBloc>().currencySymbol;
    currencyPosition = context.read<SettingsBloc>().currencyPosition;
    super.initState();
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
    });
    BlocProvider.of<WorkBloc>(context).add(WorkDashBoardFavList(isFav: 1));
    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());

    setState(() {
      isLoading = false;
    });
  }

  TextEditingController searchController = TextEditingController();
  ConnectivityResult connectivityCheck = ConnectivityResult.none;
  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;

    bool isLightTheme = currentTheme is LightThemeState;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          router.pop();
          BlocProvider.of<WorkBloc>(context).add(WorkDashBoardList());
        }
      },
      child: _connectionStatus.contains(connectivityCheck)
          ? NoInternetScreen()
          : Scaffold(
              backgroundColor: Theme.of(context).colorScheme.backGroundColor,
              body: Container(
                color: Theme.of(context).colorScheme.backGroundColor,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: BackArrow(
                        onTap: () {
                          router.pop();
                          BlocProvider.of<WorkBloc>(
                            context,
                          ).add(WorkDashBoardList());
                        },
                        // iSBackArrow: true,
                        fromDash: false,
                        title: AppLocalizations.of(context)!.favWorks,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    CustomSearchField(
                      isLightTheme: isLightTheme,
                      controller: searchController,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (searchController.text.isNotEmpty)
                            SizedBox(
                              width: 20.w,
                              // color: AppColors.red,
                              child: IconButton(
                                highlightColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.clear,
                                  size: 20.sp,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.textFieldColor,
                                ),
                                onPressed: () {
                                  searchController.clear();
                                  // context
                                  //     .read<WorkBloc>()
                                  //     .add(SearchWork('', [], []));
                                },
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              !speechHelper.isListening
                                  ? Icons.mic_off
                                  : Icons.mic,
                              size: 20.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.textFieldColor,
                            ),
                            onPressed: () {
                              if (speechHelper.isListening) {
                                speechHelper.stopListening();
                              } else {
                                speechHelper.startListening(
                                  context,
                                  searchController,
                                  SearchPopUp(),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      onChanged: (value) {
                        searchWord = value;
                        // context.read<WorkBloc>().add(SearchWork(value, [], []));
                      },
                    ),
                    SizedBox(height: 20.h),
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.primary, // Spinner color
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.backGroundColor,
                        onRefresh: _onRefresh,
                        child: context.read<PermissionsBloc>().isManageWork ==
                                true
                            ? BlocConsumer<WorkBloc, WorkState>(
                                listener: (context, state) {
                                  if (state is WorkPaginated) {
                                    isLoadingMore = false;
                                    setState(() {});
                                  }
                                },
                                builder: (context, state) {
                                  if (state is WorkLoading) {
                                    return const NotesShimmer();
                                  } else if (state is WorkFavPaginated) {
                                    // Show notes list with pagination
                                    return NotificationListener<
                                        ScrollNotification>(
                                      onNotification: (scrollInfo) {
                                        if (scrollInfo
                                            is ScrollStartNotification) {
                                          FocusScope.of(
                                            context,
                                          ).unfocus(); // Dismiss keyboard
                                        }
                                        // Check if the user has scrolled to the end and load more notes if needed
                                        if (!state.hasReachedMax &&
                                            scrollInfo.metrics.pixels ==
                                                scrollInfo
                                                    .metrics.maxScrollExtent &&
                                            isLoadingMore == false) {
                                          isLoadingMore = true;
                                          setState(() {});
                                          context.read<WorkBloc>().add(
                                                WorkLoadMore(
                                                    searchWord, [], []),
                                              );
                                        }
                                        return false;
                                      },
                                      child: context
                                                  .read<PermissionsBloc>()
                                                  .isManageWork ==
                                              true
                                          ? state.work.isNotEmpty
                                              ? isLoading == true
                                                  ? NotesShimmer()
                                                  : ListView.builder(
                                                      padding: EdgeInsets.only(
                                                        left: 18.w,
                                                        right: 18.w,
                                                        bottom: 70.h,
                                                      ),
                                                      // physics: NeverScrollableScrollPhysics(),
                                                      shrinkWrap: true,
                                                      itemCount: state
                                                              .hasReachedMax
                                                          ? state.work.length
                                                          : state.work.length +
                                                              1,
                                                      itemBuilder:
                                                          (context, index) {
                                                        if (index <
                                                            state.work.length) {
                                                          WorkModel work =
                                                              state.work[index];
                                                          String? date;

                                                          if (work.startDate !=
                                                              null) {
                                                            date =
                                                                formatDateFromApi(
                                                              work.startDate!,
                                                              context,
                                                            );
                                                          }
                                                          return index == 0
                                                              ? ShakeWidget(
                                                                  child:
                                                                      workList(
                                                                    state.work,
                                                                    index,
                                                                    work,
                                                                    date,
                                                                    isLightTheme,
                                                                  ),
                                                                )
                                                              : workList(
                                                                  state.work,
                                                                  index,
                                                                  work,
                                                                  date,
                                                                  isLightTheme,
                                                                );
                                                        } else {
                                                          // Show a loading indicator when more notes are being loaded
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              vertical: 0,
                                                            ),
                                                            child: Center(
                                                              child: state
                                                                      .hasReachedMax
                                                                  ? const Text(
                                                                      '',
                                                                    )
                                                                  : const SpinKitFadingCircle(
                                                                      color: AppColors
                                                                          .primary,
                                                                      size:
                                                                          40.0,
                                                                    ),
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    )
                                              : NoData(isImage: true)
                                          : NoPermission(),
                                    );
                                  } else if (state is WorkError) {
                                    // Show error message
                                    return const NotesShimmer();
                                  } else if (state is WorkDeleteSuccess) {
                                    if (mounted) {
                                      flutterToastCustom(
                                        msg: AppLocalizations.of(
                                          context,
                                        )!
                                            .deletedsuccessfully,
                                        color: AppColors.primary,
                                      );
                                      BlocProvider.of<WorkBloc>(
                                        context,
                                      ).add(WorkDashBoardFavList(isFav: 1));
                                    }
                                  } else if (state is WorkDeleteError) {
                                    if (mounted) {
                                      flutterToastCustom(
                                        msg: state.errorMessage,
                                        color: AppColors.primary,
                                      );
                                    }
                                    BlocProvider.of<WorkBloc>(
                                      context,
                                    ).add(WorkDashBoardFavList(isFav: 1));
                                  }
                                  // Handle other states
                                  return Container();
                                },
                              )
                            : const NoPermission(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget workList(stateWork, index, work, date, isLightTheme) {
    return Padding(
      padding: EdgeInsets.only(top: 18.h),
      child: InkWell(
        onTap: () {
          router.push(
            '/projectdetails',
            extra: {
              "id": stateWork[index].id,
              "from": "dashboard",
              "workModel": stateWork[index],
            },
          );
        },
        child: Container(
          // height: 250.h,
          decoration: BoxDecoration(
            boxShadow: [
              isLightTheme
                  ? MyThemes.lightThemeShadow
                  : MyThemes.darkThemeShadow,
            ],
            color: Theme.of(context).colorScheme.containerDark,
            borderRadius: BorderRadius.circular(12),
          ),
          width: double.infinity,
          // color: Colors.yellow,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: "#${work.id.toString()}",
                      size: 14.sp,
                      color: Theme.of(context).colorScheme.textClrChange,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              work.pinned = work.pinned == 1 ? 0 : 1;
                              WorkRepo().updateWorkPinned(
                                id: stateWork[index].id,
                                isPinned: work.pinned,
                              );
                            });
                            _pinnedcController.reverse().then(
                                  (value) => _pinnedcController.forward(),
                                );
                          },
                          child: Container(
                            width: 40.w,
                            height: 30.h,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.backGroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: ScaleTransition(
                              scale: Tween(begin: 0.7, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _pinnedcController,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: Icon(
                                work.pinned == 1
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                size: 20,
                                color: work.pinned == 1
                                    ? Colors.blue
                                    : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              work.favorite = work.favorite == 1 ? 0 : 1;
                              WorkRepo().updateWorkFavorite(
                                id: stateWork[index].id,
                                isFavorite: work.favorite,
                              );
                            });
                            _controller.reverse().then(
                                  (value) => _controller.forward(),
                                );
                          },
                          child: Container(
                            width: 40.w,
                            height: 30.h,
                            decoration: BoxDecoration(
                              boxShadow: [
                                isLightTheme
                                    ? MyThemes.lightThemeShadow
                                    : MyThemes.darkThemeShadow,
                              ],
                              color: Theme.of(
                                context,
                              ).colorScheme.backGroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: ScaleTransition(
                              scale: Tween(begin: 0.7, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _controller,
                                  curve: Curves.easeOut,
                                ),
                              ),
                              child: Icon(
                                work.favorite == 1
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: work.favorite == 1
                                    ? Colors.red
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        HeroIcon(
                          HeroIcons.clipboardDocumentList,
                          style: HeroIconStyle.outline,
                          color: AppColors.primary,
                        ),
                        work.taskCount != null && work.taskCount > 1
                            ? CustomText(
                                text:
                                    " ${work.taskCount.toString()} ${AppLocalizations.of(context)!.tasksFromDrawer}",
                                size: 14.sp,
                                color: Theme.of(
                                  context,
                                ).colorScheme.textClrChange,
                                fontWeight: FontWeight.w700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : work.taskCount == 1
                                ? CustomText(
                                    text:
                                        " ${work.taskCount} ${AppLocalizations.of(context)!.task}",
                                    size: 14.sp,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.textClrChange,
                                    fontWeight: FontWeight.w700,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : CustomText(
                                    text:
                                        " 0 ${AppLocalizations.of(context)!.task}",
                                    size: 14.sp,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.textClrChange,
                                    fontWeight: FontWeight.w700,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                      ],
                    ),
                    work.budget != null && work.budget!.isNotEmpty
                        ? Row(
                            children: [
                              // CircleAvatar(
                              //   backgroundColor: Colors.transparent,
                              //   radius: 10.0,
                              //   child: Image.asset(
                              //     AppImages.budgetImage,
                              //     height: 50,
                              //   ),
                              // ),
                              Container(
                                alignment: Alignment.centerRight,
                                // color: Colors.teal,
                                // width: 100.w,
                                height: 40.h,
                                child: CustomText(
                                  text:
                                      " ${currency != null ? "$currency" : ""}${work.budget}",
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.textClrChange,
                                  fontWeight: FontWeight.w700,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : SizedBox.shrink(),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 0.h),
                  child: SizedBox(
                    width: 300.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          // color: Colors.teal,
                          width: 200.w,
                          height: 40.h,
                          child: CustomText(
                            text: work.title!,
                            size: 24,
                            color: Theme.of(context).colorScheme.textClrChange,
                            fontWeight: FontWeight.w700,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                work.description == null || work.description == ""
                    ? const SizedBox.shrink()
                    : SizedBox(height: 5.h),
                work.description == null || work.description == ""
                    ? SizedBox()
                    : htmlWidget(work.description!, context, height: 38.h),
                SizedBox(height: 5.h),
                SizedBox(
                  // color: Colors.red,
                  width: 300.w,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.h),
                    child: statusClientRow(
                      work.status,
                      work.priority,
                      context,
                      false,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: SizedBox(
                    // color: Colors.tealAccent,
                    height: 60.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              userClientDialog(
                                context: context,
                                from: "user",
                                isFrom: "homescreen",
                                title: AppLocalizations.of(context)!.allusers,
                                list: work.users.isEmpty ? [] : work.users,
                              );
                            },
                            child: RowDashboard(
                              list: work.users ?? [],
                              title: "user",
                            ),
                          ),
                        ),
                        (work.users?.isEmpty ?? true)
                            ? const SizedBox.shrink()
                            : SizedBox(width: 40.w),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              userClientDialog(
                                context: context,
                                from: "client",
                                title: work.clients.isNotEmpty
                                    ? AppLocalizations.of(context)!.allclients
                                    : AppLocalizations.of(context)!.allclients,
                                list: work.clients.isEmpty ? [] : work.clients,
                              );
                            },
                            child: RowDashboard(
                              list: work.clients ?? [],
                              title: "client",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                date != null
                    ? Padding(
                        padding: EdgeInsets.only(top: 5.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 15.w,
                                  // color: Colors.yellow,
                                  child: const HeroIcon(
                                    HeroIcons.calendar,
                                    style: HeroIconStyle.outline,
                                    // color: colors.blueColor,
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                CustomText(
                                  text: date,
                                  size: 12.26,
                                  fontWeight: FontWeight.w300,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.textClrChange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
    // return Stack(
    //     children: [
    //       Padding(
    //           padding: EdgeInsets.symmetric(vertical: 10.h),
    //           child: DismissibleCard(
    //             direction:
    //             context.read<PermissionsBloc>().isdeleteWork == true &&
    //                 context.read<PermissionsBloc>().iseditWork == true
    //                 ? DismissDirection.horizontal // Allow both directions
    //                 : context.read<PermissionsBloc>().isdeleteWork == true
    //                 ? DismissDirection.endToStart // Allow delete
    //                 : context.read<PermissionsBloc>().iseditWork == true
    //                 ? DismissDirection.startToEnd // Allow edit
    //                 : DismissDirection.none,
    //             title: stateWork[index].id.toString(),
    //             confirmDismiss: (DismissDirection direction) async {
    //               if (direction == DismissDirection.startToEnd) {
    //                 if (context.read<PermissionsBloc>().iseditWork == true) {
    //                   // Navigate to the edit page
    //                   List<String>? userList = [];
    //                   List<String>? clientList = [];
    //                   List<String>? tagList = [];
    //
    //                   if (work.users != null) {
    //                     for (var user in work.users!) {
    //                       userList.add(user.firstName!);
    //                     }
    //                   }
    //
    //                   if (work.clients != null) {
    //                     for (var client in work.clients!) {
    //                       clientList.add(client.firstName!);
    //                     }
    //                   }
    //
    //                   if (work.tags != null) {
    //                     for (var tag in work.tags!) {
    //                       tagList.add(tag.title!);
    //                     }
    //                   }
    //
    //                   router.push(
    //                     '/createproject',
    //                     extra: {
    //                       "id": work.id,
    //                       "isCreate": false,
    //                       "title": work.title,
    //                       "desc": work.description,
    //                       "start": work.startDate ?? "",
    //                       "end": work.endDate ?? "",
    //                       "budget": work.budget,
    //                       'priority': work.priority,
    //                       'priorityId': work.priorityId,
    //                       'statusId': work.statusId,
    //                       'note': work.note,
    //                       "clientNames": clientList,
    //                       "userNames": userList,
    //                       "tagNames": tagList,
    //                       "userId": work.userId,
    //                       "tagId": work.tagIds,
    //                       "canClientDiscuss": work.clientCanDiscuss,
    //                       "clientId": work.clientId,
    //                       "access": work.taskAccessibility,
    //                       'status': work.status,
    //                     },
    //                   );
    //
    //                   // Prevent the widget from being dismissed
    //                   return false;
    //                 } else {
    //                   // No edit permission, prevent swipe
    //                   return false;
    //                 }
    //               }
    //
    //               // Handle deletion confirmation
    //               if (direction == DismissDirection.endToStart) {
    //                 return await showDialog<bool>(
    //                   context: context,
    //                   builder: (context) {
    //                     return AlertDialog(
    //                       title:
    //                       Text(AppLocalizations.of(context)!.confirmDelete),
    //                       content:
    //                       Text(AppLocalizations.of(context)!.areyousure),
    //                       actions: [
    //                         TextButton(
    //                           onPressed: () =>
    //                               Navigator.of(context).pop(true), // Confirm
    //                           child: const Text('Delete'),
    //                         ),
    //                         TextButton(
    //                           onPressed: () =>
    //                               Navigator.of(context).pop(false), // Cancel
    //                           child: const Text('Cancel'),
    //                         ),
    //                       ],
    //                     );
    //                   },
    //                 ) ??
    //                     false; // Default to false if dialog is dismissed without action
    //               }
    //
    //               return false; // Default case for other directions
    //             },
    //             onDismissed: (DismissDirection direction) {
    //               if (direction == DismissDirection.endToStart &&
    //                   context.read<PermissionsBloc>().isdeleteWork == true) {
    //                 setState(() {
    //                   stateWork.removeAt(index);
    //                   _onDeleteWork(id: work.id);
    //                 });
    //               } else if (direction == DismissDirection.startToEnd &&
    //                   context.read<PermissionsBloc>().iseditWork == true) {}
    //             },
    //             dismissWidget: Padding(
    //               padding:  EdgeInsets.only(top: 18.h),
    //               child: InkWell(
    //                 onTap: () {
    //                   router.push('/projectdetails', extra: {
    //                     'from':"fav",
    //                     "id": stateWork[index].id,
    //                   });
    //                 },
    //                 child: Container(
    //                   // height: 250.h,
    //                   decoration: BoxDecoration(
    //                       boxShadow: [
    //                         isLightTheme
    //                             ? MyThemes.lightThemeShadow
    //                             : MyThemes.darkThemeShadow,
    //                       ],
    //                       color: Theme.of(context).colorScheme.containerDark,
    //                       borderRadius: BorderRadius.circular(12)),
    //                   width: double.infinity,
    //                   // color: Colors.yellow,
    //                   child: Padding(
    //                     padding:
    //                     EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
    //                     child: Column(
    //                       mainAxisAlignment: MainAxisAlignment.start,
    //                       crossAxisAlignment: CrossAxisAlignment.start,
    //                       children: [
    //                         Row(
    //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                           children: [
    //                             CustomText(
    //                               text: "#${work.id.toString()}",
    //                               size: 14.sp,
    //                               color:
    //                               Theme.of(context).colorScheme.textClrChange,
    //                               fontWeight: FontWeight.w700,
    //                               maxLines: 1,
    //                               overflow: TextOverflow.ellipsis,
    //                             ),
    //
    //                             Row(
    //                               children: [
    //                                 HeroIcon(
    //                                   HeroIcons.clipboardDocumentList,
    //                                   style: HeroIconStyle.outline,
    //                                   color: AppColors.primary,
    //                                 ),
    //                                 work.taskCount != null &&
    //                                     work.taskCount > 1
    //                                     ? CustomText(
    //                                   text:
    //                                   " ${work.taskCount.toString()} ${AppLocalizations.of(context)!.tasksFromDrawer}",
    //                                   size: 14.sp,
    //                                   color: Theme.of(context)
    //                                       .colorScheme
    //                                       .textClrChange,
    //                                   fontWeight: FontWeight.w700,
    //                                   maxLines: 1,
    //                                   overflow: TextOverflow.ellipsis,
    //                                 )
    //                                     : work.taskCount == 1
    //                                     ? CustomText(
    //                                   text:
    //                                   " ${work.taskCount} ${AppLocalizations.of(context)!.task}",
    //                                   size: 14.sp,
    //                                   color: Theme.of(context)
    //                                       .colorScheme
    //                                       .textClrChange,
    //                                   fontWeight: FontWeight.w700,
    //                                   maxLines: 1,
    //                                   overflow: TextOverflow.ellipsis,
    //                                 )
    //                                     : CustomText(
    //                                   text:
    //                                   " 0 ${AppLocalizations.of(context)!.task}",
    //                                   size: 14.sp,
    //                                   color: Theme.of(context)
    //                                       .colorScheme
    //                                       .textClrChange,
    //                                   fontWeight: FontWeight.w700,
    //                                   maxLines: 1,
    //                                   overflow: TextOverflow.ellipsis,
    //                                 ),
    //                               ],
    //                             ),
    //                           ],
    //                         ),
    //                         Padding(
    //                           padding: EdgeInsets.only(top: 0.h),
    //                           child: SizedBox(
    //                             width: 300.w,
    //                             child: Row(
    //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                               children: [
    //                                 Container(
    //                                   alignment: Alignment.centerLeft,
    //                                   // color: Colors.teal,
    //                                   width: 200.w,
    //                                   height: 40.h,
    //                                   child: CustomText(
    //                                     text: work.title!,
    //                                     size: 24,
    //                                     color: Theme.of(context)
    //                                         .colorScheme
    //                                         .textClrChange,
    //                                     fontWeight: FontWeight.w700,
    //                                     maxLines: 1,
    //                                     overflow: TextOverflow.ellipsis,
    //                                   ),
    //                                 ),
    //                                 work.budget != null &&
    //                                     work.budget!.isNotEmpty
    //                                     ? Container(
    //                                   alignment: Alignment.centerRight,
    //                                   // color: Colors.teal,
    //                                   width: 100.w,
    //                                   height: 40.h,
    //                                   child: CustomText(
    //                                     text:
    //                                     "${currency != null ? "$currency" : ""}${work.budget}",
    //                                     size: 14,
    //                                     color: Theme.of(context)
    //                                         .colorScheme
    //                                         .textClrChange,
    //                                     fontWeight: FontWeight.w700,
    //                                     maxLines: 1,
    //                                     overflow: TextOverflow.ellipsis,
    //                                   ),
    //                                 )
    //                                     : SizedBox.shrink(),
    //                               ],
    //                             ),
    //                           ),
    //                         ),
    //                         work.description == null || work.description == ""
    //                             ? const SizedBox.shrink()
    //                             : SizedBox(
    //                           height: 5.h,
    //                         ),
    //                         work.description == null || work.description == ""
    //                             ? SizedBox()
    //                             : htmlWidget(work.description!, context,
    //                             height: 38.h),
    //                         SizedBox(height: 5.h),
    //                         SizedBox(
    //                           // color: Colors.red,
    //                           width: 300.w,
    //                           child: Padding(
    //                               padding: EdgeInsets.symmetric(vertical: 0.h),
    //                               child: statusClientRow(work.status,
    //                                   work.priority, context, false)),
    //                         ),
    //                         Padding(
    //                             padding: EdgeInsets.only(top: 10.h),
    //                             child: SizedBox(
    //                               // color: Colors.tealAccent,
    //                               height: 60.h,
    //                               child: Row(
    //                                 mainAxisAlignment:
    //                                 MainAxisAlignment.spaceBetween,
    //                                 crossAxisAlignment: CrossAxisAlignment.start,
    //                                 children: [
    //                                   Expanded(
    //                                     child: InkWell(
    //                                         onTap: () {
    //                                           userClientDialog(
    //                                               context: context,
    //                                               from: "user",
    //                                               isFrom: "homescreen",
    //                                               title:
    //                                               AppLocalizations.of(context)!
    //                                                   .allusers,
    //                                               list: work.users.isEmpty
    //                                                   ? []
    //                                                   : work.users);
    //                                         },
    //                                         child: RowDashboard(
    //                                             list: work.users!,
    //                                             title: "user")),
    //                                   ),
    //                                   work.users!.isEmpty
    //                                       ? const SizedBox.shrink()
    //                                       : SizedBox(
    //                                     width: 40.w,
    //                                   ),
    //                                   Expanded(
    //                                     child: InkWell(
    //                                         onTap: () {
    //                                           userClientDialog(
    //                                             context: context,
    //                                             from: "client",
    //                                             title: work.clients.isNotEmpty
    //                                                 ? AppLocalizations.of(context)!
    //                                                 .allclients
    //                                                 : AppLocalizations.of(context)!
    //                                                 .allclients,
    //                                             list: work.clients.isEmpty
    //                                                 ? []
    //                                                 : work.clients,
    //                                           );
    //                                         },
    //                                         child: RowDashboard(
    //                                             list: work.clients!,
    //                                             title: "client")),
    //                                   )
    //                                 ],
    //                               ),
    //                             )),
    //                         date != null
    //                             ? Padding(
    //                           padding: EdgeInsets.only(top: 5.h),
    //                           child: Row(
    //                             children: [
    //                               SizedBox(
    //                                 width: 15.w,
    //                                 // color: Colors.yellow,
    //                                 child: const HeroIcon(
    //                                   HeroIcons.calendar,
    //                                   style: HeroIconStyle.outline,
    //                                   // color: colors.blueColor,
    //                                 ),
    //                               ),
    //                               SizedBox(
    //                                 width: 5.w,
    //                               ),
    //                               CustomText(
    //                                 text: date,
    //                                 size: 12.26,
    //                                 fontWeight: FontWeight.w300,
    //                                 color: Theme.of(context)
    //                                     .colorScheme
    //                                     .textClrChange,
    //                               )
    //                             ],
    //                           ),
    //                         )
    //                             : SizedBox.shrink(),
    //                       ],
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           )),
    //       Positioned(
    //         right: 3.w,
    //         top: 5.h,
    //         child: Row(
    //           children: [
    //             GlowContainer(
    //                 shape: BoxShape.circle,
    //                 glowColor:
    //                 Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
    //
    //                 child: InkWell(
    //                   onTap: () {
    //                     setState(() {
    //                       work.pinned = work.pinned == 1 ? 0 : 1;
    //                       WorkRepo().updateWorkPinned( id:stateWork.id, isPinned: work.pinned,);
    //                     });
    //                     _pinnedcController.reverse().then((value) => _pinnedcController.forward());
    //                   },
    //                   child: Container(
    //                       width: 40.w,
    //                       height: 30.h,
    //                       decoration: BoxDecoration(
    //                           color: Theme.of(context).colorScheme.backGroundColor,
    //                           shape: BoxShape.circle),
    //                       child: ScaleTransition(
    //                         scale: Tween(begin: 0.7, end: 1.0).animate(
    //                             CurvedAnimation(
    //                                 parent: _pinnedcController, curve: Curves.easeOut)),
    //                         child: Icon(
    //                           work.pinned == 1
    //                               ? Icons.push_pin
    //                               : Icons.push_pin_outlined,
    //                           size: 20,
    //                           color: work.pinned == 1 ? Colors.red : Colors.grey,
    //                         ),
    //                       )),
    //                 )),
    //             GlowContainer(
    //                 shape: BoxShape.circle,
    //                 glowColor:
    //                 Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
    //
    //                 child: InkWell(
    //                   onTap: () {
    //                     setState(() {
    //                       work.favorite = work.favorite == 1 ? 0 : 1;
    //                       WorkRepo().updateWorkFavorite( id:stateWork[index].id, isFavorite: work.favorite,);
    //
    //                     });
    //                     _controller.reverse().then((value) => _controller.forward());
    //                     isLoading = true;
    //                     BlocProvider.of<WorkBloc>(context).add(WorkDashBoardFavList(isFav: 1));
    //                     isLoading = false;
    //
    //                   },
    //                   child: Container(
    //                       width: 40.w,
    //                       height: 30.h,
    //                       decoration: BoxDecoration(
    //                           color: Theme.of(context).colorScheme.backGroundColor,
    //                           shape: BoxShape.circle),
    //                       child: ScaleTransition(
    //                         scale: Tween(begin: 0.7, end: 1.0).animate(
    //                             CurvedAnimation(
    //                                 parent: _controller, curve: Curves.easeOut)),
    //                         child: Icon(
    //                           work.favorite == 1
    //                               ? Icons.favorite
    //                               : Icons.favorite_border,
    //                           size: 20,
    //                           color: work.favorite == 1 ? Colors.red : Colors.grey,
    //                         ),
    //                       )),
    //                 )),
    //           ],
    //         ),
    //       )]);
  }
}
