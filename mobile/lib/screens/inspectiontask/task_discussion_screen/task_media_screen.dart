import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hive/hive.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../bloc/inspectiontask_discussion/task_media/task_media_bloc.dart';
import '../../../bloc/permissions/permissions_bloc.dart';
import '../../../bloc/permissions/permissions_event.dart';

import '../../../bloc/inspectiontask_discussion/task_media/task_media_bloc.dart';
import '../../../bloc/inspectiontask_discussion/task_media/task_media_state.dart';

import '../../../bloc/theme/theme_bloc.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../config/strings.dart';
import '../../../data/model/inspectiontask/media.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../../utils/widgets/custom_dimissible.dart';
import '../../../utils/widgets/custom_text.dart';

import '../../../utils/widgets/shake_widget.dart';
import '../../../utils/widgets/toast_widget.dart';
import '../../notes/widgets/notes_shimmer_widget.dart';
import '../../widgets/custom_container.dart';
import '../../widgets/no_data.dart';
import '../../widgets/no_permission_screen.dart';

import '../../widgets/speech_to_text.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TaskMediaScreen extends StatefulWidget {
  final int? id;
  const TaskMediaScreen({super.key, this.id});

  @override
  State<TaskMediaScreen> createState() => _TaskMediaScreenState();
}

class _TaskMediaScreenState extends State<TaskMediaScreen> {
  TextEditingController mediaSearchController = TextEditingController();
  bool isLoading = true;
  String mediaSearchQuery = '';
  bool isFirst = false;
  bool isLoadingMore = false;
  bool isFirstTimeUSer = true;
  final GlobalKey _one = GlobalKey();
  OverlayEntry? _overlayEntry;

  // Store last media list for rendering during download
  List<InspectionTaskMediaModel> lastInspectionTaskMediaList = [];
  bool hasReachedMax = false;

  late SpeechToTextHelper speechHelper;

  @override
  void initState() {
    super.initState();
    speechHelper = SpeechToTextHelper(
      onSpeechResultCallback: (result) {
        setState(() {
          mediaSearchController.text = result;
          mediaSearchQuery = result;
        });
        context.read<InspectionTaskMediaBloc>().add(
          InspectionTaskSearchMedia(result, widget.id),
        );
        Navigator.pop(context);
      },
    );
    _getFirstTimeUser();
    context.read<InspectionTaskMediaBloc>().add(
      InspectionTaskMediaList(id: widget.id),
    );
    speechHelper.initSpeech();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    mediaSearchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      isLoading = true;
    });
    BlocProvider.of<InspectionTaskMediaBloc>(
      context,
    ).add(InspectionTaskMediaList(id: widget.id));
    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getFirstTimeUser() async {
    var box = await Hive.openBox(authBox);
    setState(() {
      isFirstTimeUSer = box.get(firstTimeUserKey) ?? true;
      isFirst = box.get("isFirstCase") ?? false;
    });
  }

  Future<void> _setIsFirst(bool value) async {
    setState(() {
      isFirst = value;
    });
    var box = await Hive.openBox(authBox);
    await box.put("isFirstCase", value);
  }

  void onShowCaseCompleted() {
    _setIsFirst(false);
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;
    bool isLightTheme = currentTheme is LightThemeState;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Theme.of(context).colorScheme.backGroundColor,
      onRefresh: _onRefresh,
      child: context.read<PermissionsBloc>().isManageTask == true
          ? Column(
              children: [
                // CustomSearchField(
                //   isLightTheme: isLightTheme,
                //   controller: mediaSearchController,
                // suffixIcon: Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 10.w),
                // child: Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     if (mediaSearchController.text.isNotEmpty)
                //       SizedBox(
                //         width: 20.w,
                //         child: IconButton(
                //           highlightColor: Colors.transparent,
                //           padding: EdgeInsets.zero,
                //           icon: Icon(
                //             Icons.clear,
                //             size: 20.sp,
                //             color: Theme.of(context)
                //                 .colorScheme
                //                 .textFieldColor,
                //           ),
                //           onPressed: () {
                //             setState(() {
                //               mediaSearchController.clear();
                //               mediaSearchQuery = '';
                //             });
                //             context.read<InspectionTaskMediaBloc>().add(
                //                 InspectionTaskSearchMedia("", widget.id));
                //           },
                //         ),
                //       ),
                //     SizedBox(
                //       width: 30.w,
                //       child: IconButton(
                //         icon: Icon(
                //           !speechHelper.isListening
                //               ? Icons.mic_off
                //               : Icons.mic,
                //           size: 20.sp,
                //           color:
                //               Theme.of(context).colorScheme.textFieldColor,
                //         ),
                //         onPressed: () {
                //           if (speechHelper.isListening) {
                //             speechHelper.stopListening();
                //           } else {
                //             speechHelper.startListening(context,
                //                 mediaSearchController, SearchPopUp());
                //           }
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                // ),
                //   onChanged: (value) {
                //     setState(() {
                //       mediaSearchQuery = value;
                //     });
                //     context
                //         .read<InspectionTaskMediaBloc>()
                //         .add(InspectionTaskSearchMedia(value, widget.id));
                //   },
                // ),
                SizedBox(height: 10.h),
                Expanded(
                  child: BlocConsumer<InspectionTaskMediaBloc, InspectionTaskMediaState>(
                    listener: (context, state) {
                      if (state is InspectionTaskMediaPaginated) {
                        lastInspectionTaskMediaList = state.TaskMediaList;
                        hasReachedMax = state.hasReachedMax;
                        isLoadingMore = false;
                        setState(() {});
                      } else if (state is InspectionTaskDownloadSuccess) {
                        _removeProgressOverlay(); // Remove overlay on success
                        flutterToastCustom(
                          msg: "Download completed: ${state.fileName}",
                          color: AppColors.primary,
                        );
                        Future.delayed(Duration(milliseconds: 500), () {
                          context.read<InspectionTaskMediaBloc>().add(
                            InspectionTaskSilentMediaRefresh(id: widget.id),
                          );
                        });
                      } else if (state is InspectionTaskDownloadFailure) {
                        _removeProgressOverlay(); // Remove overlay on failure
                        flutterToastCustom(
                          msg: "Download failed: ${state.error}",
                          color: AppColors.red,
                        );
                      } else if (state is InspectionTaskDownloadInProgress) {
                        showToastWithProgress(
                          context,
                          state.progress,
                          state.fileName,
                        );
                      } else if (state is InspectionTaskMediaDeleteSuccess) {
                        flutterToastCustom(
                          msg: AppLocalizations.of(
                            context,
                          )!.deletedsuccessfully,
                          color: AppColors.red,
                        );
                        context.read<InspectionTaskMediaBloc>().add(
                          InspectionTaskMediaList(id: widget.id),
                        );
                      } else if (state is InspectionTaskMediaError) {
                        flutterToastCustom(
                          msg: state.errorMessage,
                          color: AppColors.red,
                        );
                      }
                    },
                    builder: (context, state) {
                      Widget buildInspectionTaskMediaList(
                        List<InspectionTaskMediaModel> mediaList,
                        bool reachedMax,
                      ) {
                        // ✅ Бүх медиа харуулах (photos хоосон ч гэсэн)
                        final filteredMediaList = mediaList;

                        return NotificationListener<ScrollNotification>(
                          onNotification: (scrollInfo) {
                            if (scrollInfo is ScrollStartNotification) {
                              FocusScope.of(context).unfocus();
                            }
                            if (!reachedMax &&
                                scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent &&
                                !isLoadingMore) {
                              isLoadingMore = true;
                              setState(() {});
                            }
                            return false;
                          },
                          child:
                              context.read<PermissionsBloc>().isManageTask ==
                                  true
                              ? filteredMediaList.isNotEmpty
                                    ? ListView.builder(
                                        padding: EdgeInsets.only(
                                          left: 18.w,
                                          right: 18.w,
                                          bottom: 70.h,
                                        ),
                                        shrinkWrap: true,
                                        itemCount: reachedMax
                                            ? filteredMediaList.length
                                            : filteredMediaList.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index <
                                              filteredMediaList.length) {
                                            InspectionTaskMediaModel media =
                                                filteredMediaList[index];
                                            String? startDate;
                                            String? endDate;

                                            if (media.updatedAt != null) {
                                              startDate = parseDateTimeFormat(
                                                media.updatedAt!,
                                              );
                                            }
                                            if (media.createdAt != null) {
                                              endDate = parseDateTimeFormat(
                                                media.createdAt!,
                                              );
                                            }

                                            return (index == 0 &&
                                                    isFirstTimeUSer)
                                                ? ShakeWidget(
                                                    child: Showcase(
                                                      onTargetClick: () {
                                                        ShowCaseWidget.of(
                                                          context,
                                                        ).completed(_one);
                                                        if (ShowCaseWidget.of(
                                                              context,
                                                            ).activeWidgetId ==
                                                            1) {
                                                          onShowCaseCompleted();
                                                        }
                                                        _setIsFirst(false);
                                                      },
                                                      disposeOnTap: true,
                                                      key: _one,
                                                      title:
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.swipe,
                                                      titleAlignment:
                                                          Alignment.center,
                                                      descriptionAlignment:
                                                          Alignment.center,
                                                      description:
                                                          "${AppLocalizations.of(context)!.swipelefttodelete} \n${AppLocalizations.of(context)!.swiperighttoedit}",
                                                      tooltipBackgroundColor:
                                                          AppColors.primary,
                                                      textColor: Colors.white,
                                                      child: ShakeWidget(
                                                        child: mediaCard(
                                                          filteredMediaList,
                                                          index,
                                                          media,
                                                          startDate,
                                                          endDate,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : mediaCard(
                                                    filteredMediaList,
                                                    index,
                                                    media,
                                                    startDate,
                                                    endDate,
                                                  );
                                          } else {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 0,
                                                  ),
                                              child: Center(
                                                child: reachedMax
                                                    ? const Text('')
                                                    : const SpinKitFadingCircle(
                                                        color:
                                                            AppColors.primary,
                                                        size: 40.0,
                                                      ),
                                              ),
                                            );
                                          }
                                        },
                                      )
                                    : NoData(isImage: true)
                              : NoPermission(),
                        );
                      }

                      if (state is InspectionTaskMediaLoading) {
                        return const NotesShimmer();
                      } else if (state is InspectionTaskMediaPaginated) {
                        return buildInspectionTaskMediaList(
                          state.TaskMediaList,
                          state.hasReachedMax,
                        );
                      } else if (state is InspectionTaskDownloadInProgress) {
                        return buildInspectionTaskMediaList(
                          lastInspectionTaskMediaList,
                          hasReachedMax,
                        );
                      } else if (state is InspectionTaskMediaUploadSuccess ||
                          state is InspectionTaskMediaError ||
                          state is InspectionTaskDownloadSuccess ||
                          state is InspectionTaskDownloadFailure ||
                          state is InspectionTaskMediaDeleteSuccess) {
                        if (lastInspectionTaskMediaList.isNotEmpty) {
                          return buildInspectionTaskMediaList(
                            lastInspectionTaskMediaList,
                            hasReachedMax,
                          );
                        } else {
                          return NoData(isImage: true);
                        }
                      }

                      return lastInspectionTaskMediaList.isNotEmpty
                          ? buildInspectionTaskMediaList(
                              lastInspectionTaskMediaList,
                              hasReachedMax,
                            )
                          : NoData(isImage: true);
                    },
                  ),
                ),
              ],
            )
          : const NoPermission(),
    );
  }

  void _removeProgressOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void showToastWithProgress(
    BuildContext context,
    double progress,
    String fileName,
  ) {
    // print("Attempting to show overlay for $fileName with progress: $progress");
    _removeProgressOverlay(); // Remove any existing overlay
    OverlayState? overlayState = Overlay.of(context);
    if (overlayState == "") {
      if (kDebugMode) {
        logger.d("Error: OverlayState is null, cannot insert overlay");
      }
      return;
    }

    _overlayEntry = OverlayEntry(
      opaque:
          false, // Allow underlying content to show through semi-transparent background
      builder: (context) {
        // Debug: Print the resolved containerDark color
        final containerColor = Theme.of(context).colorScheme.containerDark;
        // print("Resolved containerDark color: $containerColor");

        // Use a fallback color if containerDark is pure white or transparent
        final backgroundColor =
            (containerColor == Colors.white || containerColor.a < 50)
            ? AppColors
                  .pureWhiteColor // Fallback to blue for visibility
            : containerColor.withValues(alpha: 0.9);

        return AbsorbPointer(
          absorbing: true, // Block all user input
          child: Stack(
            children: [
              // Semi-transparent background to dim the entire screen
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.5,
                  ), // Dim the background
                ),
              ),
              // Centered progress dialog
              Center(
                child: Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(17.4),
                  color: Colors
                      .transparent, // Material is transparent to show Container
                  child: Container(
                    width: 300.w, // Fixed width for the dialog
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17.4),
                      color: backgroundColor, // Use computed background color
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Minimize column size
                        children: [
                          CustomText(
                            text: "Downloading $fileName",
                            color: Theme.of(context).colorScheme.textClrChange,
                            size: 16.sp,
                            fontWeight: FontWeight.bold,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10.h),
                          CustomText(
                            text:
                                "${(progress.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%",
                            color: Theme.of(context).colorScheme.textClrChange,
                            size: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          SizedBox(height: 15.h),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            minHeight: 8.h,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    overlayState.insert(_overlayEntry!);
  }

  Widget mediaCard(
    List<InspectionTaskMediaModel> InspectionTaskMediaList,
    int index,
    InspectionTaskMediaModel media,
    String? startDate,
    String? endDate,
  ) {
    return DismissibleCard(
      key: ValueKey(media.id),
      direction: context.read<PermissionsBloc>().isdeleteTask == true
          ? DismissDirection.endToStart
          : DismissDirection.none,
      title: index.toString(),
      confirmDismiss: (DismissDirection direction) async {
        // print("confirmDismiss called with direction: $media");
        if (direction == DismissDirection.startToEnd) {
          // Handle edit if needed
        }
        if (direction == DismissDirection.endToStart &&
            context.read<PermissionsBloc>().isdeleteTask == true) {
          try {
            final result = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.alertBoxBackGroundColor,
                  title: Text(AppLocalizations.of(context)!.confirmDelete),
                  content: Text(AppLocalizations.of(context)!.areyousure),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(AppLocalizations.of(context)!.ok),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                  ],
                );
              },
            );

            // print("Dialog result received: $result");
            // print("About to return from confirmDismiss: ${result ?? false}");

            // If user confirmed deletion, handle it here instead of in onDismissed
            if (result == true) {
              // print("Handling deletion directly in confirmDismiss");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  InspectionTaskMediaList.removeAt(index);
                });
                context.read<InspectionTaskMediaBloc>().add(
                  InspectionTaskDeleteMedia(media.id, null),
                );
              });
              // Return false to prevent the dismissible from animating
              return false;
            }

            return false; // Always return false since we handle deletion manually
          } catch (e) {
            if (kDebugMode) {
              logger.d("Error in dialog: $e");
            }
            return false;
          }
        }
        return false; // Default case
      },
      onDismissed: (DismissDirection direction) {
        if (direction == DismissDirection.endToStart &&
            context.read<PermissionsBloc>().isdeleteTask == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              InspectionTaskMediaList.removeAt(index);
            });
            context.read<InspectionTaskMediaBloc>().add(
              InspectionTaskDeleteMedia(media.id, null),
            );
          });
        }
      },
      dismissWidget: Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: customContainer(
          context: context,
          addWidget: Padding(
            padding: EdgeInsets.all(15.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: "#${media.id.toString()}",
                      size: 14.sp,
                      color: Theme.of(context).colorScheme.textClrChange,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (media.canDownload)
                      InkWell(
                        onTap: () {
                          context.read<InspectionTaskMediaBloc>().add(
                            InspectionTaskStartDownload(
                              fileUrl: media.downloadUrl,
                              fileName: media.displayFileName,
                            ),
                          );
                        },
                        child: GlowContainer(
                          shape: BoxShape.circle,
                          glowColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.6),
                          child: CircleAvatar(
                            radius: 15.sp,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.backGroundColor,
                            child: HeroIcon(
                              HeroIcons.arrowDown,
                              style: HeroIconStyle.outline,
                              size: 15.sp,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),

                // ✅ Show all photos in separate rows
                if (media.photos != null && media.photos!.isNotEmpty)
                  Column(
                    children: media.photos!.asMap().entries.map((entry) {
                      int photoIndex = entry.key;
                      var photo = entry.value;
                      return InkWell(
                        onTap: () {
                          // Show photo preview
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        photo.fileUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          child: Row(
                            children: [
                              // Photo preview
                              Container(
                                margin: EdgeInsets.all(10),
                                height: 50.h,
                                width: 50.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(photo.fileUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5.w),
                              // File info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text:
                                          photo.filenameDownload ??
                                          "Photo ${photoIndex + 1}",
                                      size: 15.sp,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.textClrChange,
                                      fontWeight: FontWeight.w700,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 3.h),
                                    CustomText(
                                      text: photo.formattedFileSize,
                                      size: 12.sp,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.textClrChange,
                                      fontWeight: FontWeight.w600,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Download button for each photo
                              // Delete button for each photo
                              InkWell(
                                onTap: () async {
                                  // Show confirmation dialog
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.alertBoxBackGroundColor,
                                        title: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.confirmDelete,
                                        ),
                                        content: Text(
                                          'Are you sure you want to delete "${photo.filenameDownload ?? "this photo"}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.cancel,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: Text(
                                              AppLocalizations.of(context)!.ok,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (confirm == true) {
                                    // Use junction table ID to delete the specific photo
                                    // If junctionId is available, delete just this photo
                                    // Otherwise, delete the entire media item
                                    final deleteId =
                                        photo.junctionId ?? media.id;

                                    context.read<InspectionTaskMediaBloc>().add(
                                      InspectionTaskDeleteMedia(deleteId, null),
                                    );

                                    // ScaffoldMessenger.of(context).showSnackBar(
                                    //   SnackBar(
                                    //     content:
                                    //         Text('Photo deleted successfully'),
                                    //     backgroundColor: Colors.green,
                                    //   ),
                                    // );
                                  }
                                },
                                child: GlowContainer(
                                  shape: BoxShape.circle,
                                  glowColor: Colors.red.withValues(alpha: 0.4),
                                  child: CircleAvatar(
                                    radius: 15.sp,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.backGroundColor,
                                    child: HeroIcon(
                                      HeroIcons.trash,
                                      style: HeroIconStyle.outline,
                                      size: 15.sp,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              InkWell(
                                onTap: () {
                                  context.read<InspectionTaskMediaBloc>().add(
                                    InspectionTaskStartDownload(
                                      fileUrl: photo.downloadUrl,
                                      fileName:
                                          photo.filenameDownload ??
                                          "photo_${photoIndex + 1}",
                                    ),
                                  );
                                },
                                child: GlowContainer(
                                  shape: BoxShape.circle,
                                  glowColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.6),
                                  child: CircleAvatar(
                                    radius: 15.sp,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.backGroundColor,
                                    child: HeroIcon(
                                      HeroIcons.arrowDown,
                                      style: HeroIconStyle.outline,
                                      size: 15.sp,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                // ✅ Fallback to old single preview if no photos array
                if (media.photos == null || media.photos!.isEmpty)
                  Column(
                    children: [
                      if (media.preview != null && media.preview!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            media.preview!,
                            height: 180.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180.h,
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (media.fileName != null &&
                                    media.fileName!.isNotEmpty)
                                  CustomText(
                                    text: media.fileName ?? "",
                                    size: 14.sp,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.textClrChange,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (media.fileSize != null &&
                                    media.fileSize!.isNotEmpty) ...[
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: media.fileSize ?? "",
                                    size: 12.sp,
                                    color: AppColors.greyColor,
                                    fontWeight: FontWeight.w500,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (startDate != null || endDate != null) ...[
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (startDate != null)
                              CustomText(
                                text: startDate,
                                size: 11.sp,
                                color: AppColors.greyColor,
                                fontWeight: FontWeight.w500,
                              ),
                            if (startDate != null && endDate != null)
                              Icon(
                                Icons.arrow_forward,
                                color: AppColors.greyColor,
                                size: 16.sp,
                              ),
                            if (endDate != null)
                              CustomText(
                                text: endDate,
                                size: 11.sp,
                                color: AppColors.greyColor,
                                fontWeight: FontWeight.w500,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
