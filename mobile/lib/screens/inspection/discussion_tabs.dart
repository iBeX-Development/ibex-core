import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:hive/hive.dart';
import 'package:ibex/screens/inspection/discussion_screen/part_screen.dart';
import 'package:ibex/screens/inspection/discussion_screen/trade_screen.dart';
import 'package:mobkit_dashed_border/mobkit_dashed_border.dart';
import 'package:ibex/bloc/inspection_discussion/inspection_media/inspection_media_bloc.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/data/model/inspection/part.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import 'package:image_picker/image_picker.dart'; // ✅ Add this import at the top

import '../../bloc/activity_log/activity_log_bloc.dart';
import '../../bloc/activity_log/activity_log_event.dart';
import '../../bloc/permissions/permissions_bloc.dart';
import '../../bloc/permissions/permissions_event.dart';

import '../../bloc/inspection_discussion/inspection_part/inspection_part_bloc.dart';
import '../../bloc/inspection_discussion/inspection_part/inspection_part_event.dart';
import '../../bloc/inspection_discussion/inspection_trade/inspection_trade_bloc.dart';
import '../../bloc/inspection_discussion/inspection_trade/inspection_trade_event.dart';

import '../../bloc/theme/theme_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../config/internet_connectivity.dart';
import '../../config/strings.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/back_arrow.dart';
import '../widgets/speech_to_text.dart';
import 'discussion_screen/activity_log.dart';
import 'discussion_screen/media_screen.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionDiscussionTabs extends StatefulWidget {
  final bool? fromDetail;
  final int? id;
  final String? type;
  const InspectionDiscussionTabs(
      {super.key, this.fromDetail, this.id, this.type});

  @override
  State<InspectionDiscussionTabs> createState() =>
      _InspectionDiscussionTabsState();
}

class _InspectionDiscussionTabsState extends State<InspectionDiscussionTabs>
    with TickerProviderStateMixin {
  ConnectivityResult connectivityCheck = ConnectivityResult.none;
  bool? isLoading = true;
  bool isLoadingMore = false;
  int _selectedIndex = 0;
  String? selectedColorName;
  final Connectivity _connectivity = Connectivity();
  TextEditingController searchController = TextEditingController();
  TextEditingController mediaSearchController = TextEditingController();
  TextEditingController activityLogSearchController = TextEditingController();
  TextEditingController startController = TextEditingController();
  TextEditingController endController = TextEditingController();
  String fromDate = "";
  String toDate = "";
  TextEditingController startDateBetweenController = TextEditingController();
  TextEditingController endDateBetweenController = TextEditingController();
  TextEditingController startDateBetweenstartController =
      TextEditingController();
  TextEditingController endDateBetweenendController = TextEditingController();
  String fromDateBetween = "";
  String toDateBetween = "";
  String fromEndDateBetweenStart = "";
  String toDateEndBetweenEnd = "";
  late SpeechToTextHelper speechHelper;
  String selectedTabText = "";
  int isWhichIndex = 0;
  DateTime selectedDateStarts = DateTime.now();
  DateTime? selectedDateEnds = DateTime.now();
  DateTime selectedDateBetweenStarts = DateTime.now();
  DateTime? selectedDateBetweenEnds = DateTime.now();
  DateTime selectedDateEndBetweenStarts = DateTime.now();
  DateTime? selectedDateEndBetweenEnds = DateTime.now();
  bool? isFirstTimeUSer;
  bool? isFirst;
  String partSearchQuery = '';
  String mediaSearchQuery = '';
  String activityLogSearchQuery = '';

  TextEditingController titleController = TextEditingController();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  late TabController _tabController;

  String? workType;
  String? statusname;
  bool isDownloading = false;
  double progress = 0.0;

  List<String> status = ["Complete", "Incomplete"];
  final ValueNotifier<String> filterNameNotifier = ValueNotifier<String>(
    'Date between',
  );

  String filterName = 'Date between';

  void _navigateToIndex(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  _getFirstTimeUser() async {
    var box = await Hive.openBox(authBox);
    isFirstTimeUSer = box.get(firstTimeUserKey) ?? true;
  }

  _setIsFirst(value) async {
    isFirst = value;
    var box = await Hive.openBox(authBox);
    box.put("isFirstCase", value);
  }

  void onShowCaseCompleted() {
    _setIsFirst(false);
  }

  @override
  void initState() {
    super.initState();

    workType = widget.type ?? 'open';
    if (workType == 'request') {
      _selectedIndex = 2;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (workType == 'request' && mounted) {
          // ✅ Calculate media tab index
          int mediaTabIndex = 2;

          setState(() {
            _selectedIndex = 2;
            _tabController.animateTo(mediaTabIndex);
          });

          if (kDebugMode) {

            logger.d("📱 Auto-navigated to Media tab (index: $mediaTabIndex)");

          }
        }
      });
    }
    // Use local variable, no need to store as field
    CheckInternet.initConnectivity().then((List<ConnectivityResult> results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {}
    });

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {}
    });

    searchController.addListener(() {
      setState(() {});
    });
    mediaSearchController.addListener(() {
      setState(() {});
    });
    activityLogSearchController.addListener(() {
      setState(() {});
    });

    _tabController = TabController(length: 4, vsync: this);

    speechHelper = SpeechToTextHelper(
      onSpeechResultCallback: (result) {
        setState(() {
          searchController.text = result;
          context.read<InspectionPartBloc>().add(
                SearchInspectionPart(
                  widget.id,
                  partSearchQuery,
                  "",
                  "",
                  "",
                  "",
                  "",
                  "",
                  "",
                ),
              );
        });
        Navigator.pop(context);
      },
    );
    speechHelper.initSpeech();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _getFirstTimeUser();
    // ✅ Load initial data for all tabs
    BlocProvider.of<InspectionPartBloc>(
      context,
    ).add(InspectionPartList(id: widget.id));
    BlocProvider.of<InspectionTradeBloc>(
      context,
    ).add(InspectionTradeList(id: widget.id));
    BlocProvider.of<ActivityLogBloc>(
      context,
    ).add(AllActivityLogList(type: "project", typeId: widget.id));
    BlocProvider.of<InspectionMediaBloc>(context)
        .add(MediaList(id: widget.id)); // ✅ This is correct

    BlocProvider.of<PermissionsBloc>(context).add(GetPermissions());
    // BlocProvider.of<InspectionStatusTimelineBloc>(
    //   context,
    // ).add(StatusTimelineList(id: widget.id));
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    // if your SpeechToTextHelper needs disposal
    _tabController.dispose();
    searchController.dispose();
    mediaSearchController.dispose();
    activityLogSearchController.dispose();
    super.dispose();
  }

  ValueNotifier<List<File>> selectedFilesNotifier = ValueNotifier([]);

  final ImagePicker _imagePicker = ImagePicker(); // ✅ Add this

  // ✅ New method to take photo from camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress to 85% quality
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        File photoFile = File(photo.path);

        // Add to selected files
        selectedFilesNotifier.value = [
          ...selectedFilesNotifier.value,
          photoFile,
        ];

        if (kDebugMode) {

          logger.d("📸 Photo taken: ${photo.path}");

        }
        if (kDebugMode) {
          logger.d("📸 File size: ${photoFile.lengthSync()} bytes");
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Photo added successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error taking photo: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ New method to pick from gallery
  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        List<File> imageFiles = images.map((img) => File(img.path)).toList();

        selectedFilesNotifier.value = [
          ...selectedFilesNotifier.value,
          ...imageFiles,
        ];

        if (kDebugMode) {

          logger.d("🖼️ Selected ${images.length} image(s) from gallery");

        }
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error picking from gallery: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _pickFile() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'jpg',
          'png'
          // 'xls',
          // 'xlsx',
        ],
      );

      if (result != null) {
        List<File> pickedFiles =
            result.paths.whereType<String>().map((path) => File(path)).toList();

        // Update the ValueNotifier
        selectedFilesNotifier.value = [
          ...selectedFilesNotifier.value,
          ...pickedFiles,
        ];

        if (kDebugMode) {

          logger.d("Selected Files work: ${selectedFilesNotifier.value}");

        }
      }
    }

    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;
    if (kDebugMode) {
      logger.d("Selected type: ${workType} ${_selectedIndex}");
    }

    bool isLightTheme = currentTheme is LightThemeState;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backGroundColor,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              _appBar(isLightTheme),
              SizedBox(height: 20.h),

              Expanded(
                child: TabBarView(
                  physics:
                      NeverScrollableScrollPhysics(), // 👈 this disables sliding

                  controller: _tabController,
                  children: [
                    // ✅ Tab 0: Parts

                    if (context.read<PermissionsBloc>().isManagePart == true &&
                        workType != "request")
                      InspectionPartScreen(id: widget.id)
                    else
                      SizedBox.shrink(),

                    // ✅ Tab 1: Trade (same as Parts for now)
                    if (context.read<PermissionsBloc>().isManageTrade == true &&
                        workType != "request")
                      InspectionTradeScreen(id: widget.id)
                    else
                      SizedBox.shrink(),

                    // ✅ Tab 2: Media
                    if (context.read<PermissionsBloc>().isManageMedia == true)
                      MediaScreen(id: widget.id)
                    else
                      SizedBox.shrink(),

                    // ✅ Tab 3: Activity Log
                    if (context.read<PermissionsBloc>().isManageActivityLog ==
                        true)
                      InspectionActivityLogScreen(id: widget.id)
                    else
                      SizedBox.shrink(),
                  ],
                ),
              ),
              // Add bottom space to ensure content is visible behind the floating bar
              // SizedBox(height: 60.h),
            ],
          ),

          // Floating action button
          Visibility(
            visible: _selectedIndex != 3, // Hide for index 3
            child: Positioned(
              right: 20.w,
              bottom: 100.h,
              child: Visibility(
                visible: _shouldShowFAB(), // ✅ Helper method
                child: FloatingActionButton(
                  isExtended: true,
                  onPressed: () {
                    if (_selectedIndex == 0 &&
                        workType != "request" &&
                        context.read<PermissionsBloc>().iscreatePart == true) {
                      // Part tab + permission
                      router.push(
                        "/inspectionpart",
                        extra: {
                          "isCreate": true,
                          "workId": widget.id,
                          "part": InspectionsPart(
                            id: 0,
                            title: "",
                            status: "",
                            endDate: "",
                            progress: 0,
                            createdAt: "",
                            cost: "",
                            createdBy: "",
                            updatedAt: "",
                          ),
                        },
                      );
                    } else if (_selectedIndex == 1 &&
                        workType != "request" &&
                        context.read<PermissionsBloc>().iscreatePart == true) {
                      // Part tab + permission
                      router.push(
                        "/inspectiontrade",
                        extra: {
                          "isCreate": true,
                          "workId": widget.id,
                          "trade": InspectionsPart(
                            id: 0,
                            title: "",
                            status: "",
                            endDate: "",
                            progress: 0,
                            createdAt: "",
                            cost: "",
                            createdBy: "",
                            updatedAt: "",
                          ),
                        },
                      );
                    } else if (_selectedIndex == 2 &&
                        context.read<PermissionsBloc>().iscreateMedia == true) {
                      // Media tab + permission
                      _uploadFile(
                        pickFile: _pickFile,
                        selectedFileName: selectedFilesNotifier,
                      );
                    } else {
                      // No permission: do nothing or show a toast/snackbar if you want
                    }
                  },
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, color: AppColors.whiteColor),
                ),
                // return empty widget if condition not met
              ),
            ),
          ),

          // Floating bottom navigation
          Positioned(
            bottom: 20.h,
            left: 18.w,
            right: 18.w,
            child: _floatingBottomNavBar(context, isLightTheme),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(HeroIcons icon, String text, Color color, int index) {
    bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        _navigateToIndex(index);
        isWhichIndex = index;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroIcon(
            icon,
            style: HeroIconStyle.outline,
            size: 18.sp,
            color: color,
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: isSelected
                ? Padding(
                    padding: EdgeInsets.only(top: 3.h),
                    child: Text(
                      text,
                      key: ValueKey(text), // Smooth transition
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _appBar(isLightTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: BackArrow(
        onTap: () {
          router.pop();
        },
        projectId: widget.id,
        discussionScreen: "projectDiscussion",
        iSBackArrow: true,
        iscreatePermission: true,
        title: (() {
          switch (_selectedIndex) {
            case 0:
              return AppLocalizations.of(context)!.part;
            case 1:
              return AppLocalizations.of(context)!.trade;
            case 2:
              return AppLocalizations.of(context)!.media;
            case 3:
              return AppLocalizations.of(context)!.activityLog;
            default:
              return AppLocalizations.of(context)!.part;
          }
        })(),
        onPress: () {
          // _createEditStatus(isLightTheme: isLightTheme, isCreate: true);
        },
      ),
    );
  }

  Widget _floatingBottomNavBar(BuildContext context, bool isLightTheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          height: 50.h, // Reduced height
          decoration: BoxDecoration(
            color: isLightTheme
                ? Colors.white.withValues(
                    alpha: 0.15,
                  ) // More transparent for light theme
                : Colors.black.withValues(
                    alpha: 0.15,
                  ), // More transparent for dark theme
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isLightTheme
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isLightTheme
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (context.read<PermissionsBloc>().isManagePart == true &&
                  workType != "request")
                _tabItem(
                  HeroIcons.listBullet,
                  "Part",
                  AppColors.mileStoneColor,
                  0,
                ),
              if (context.read<PermissionsBloc>().isManageTrade == true &&
                  workType != "request")
                _tabItem(HeroIcons.bars3, "Trade", AppColors.primary, 1),
              if (context.read<PermissionsBloc>().isManageMedia == true)
                _tabItem(HeroIcons.photo, "Media",
                    const Color.fromARGB(255, 46, 118, 11), 2),
              if (context.read<PermissionsBloc>().isManageActivityLog == true)
                _tabItem(
                  HeroIcons.checkCircle,
                  "Activity",
                  AppColors.activityLogColor,
                  3,
                ),
            ],
          ),
        ),
      ),
    );
  }

// ✅ Helper method to determine if FAB should be visible
  bool _shouldShowFAB() {
    switch (_selectedIndex) {
      case 0: // Parts
        return context.read<PermissionsBloc>().iscreatePart == true &&
            workType != "request";
      case 1: // Trade (Media upload)
        return context.read<PermissionsBloc>().iscreateTrade == true &&
            workType != "request";
      case 2: // Media is hidden by your existing logic
        return context.read<PermissionsBloc>().iscreateMedia == true;
      case 3: //
        return false;
      default:
        return false;
    }
  }

// ✅ Helper method to handle FAB press
  void _handleFABPress() {
    switch (_selectedIndex) {
      case 0: // Parts
        if (context.read<PermissionsBloc>().iscreatePart == true) {
          router.push(
            "/inspectionpart",
            extra: {
              "isCreate": true,
              "workId": widget.id,
              "part": InspectionsPart(
                id: 0,
                title: "",
                status: "",
                endDate: "",
                progress: 0,
                createdAt: "",
                cost: "",
                createdBy: "",
                updatedAt: "",
              ),
            },
          );
        }
        break;
      case 1: // Trade (Media upload)
        if (context.read<PermissionsBloc>().iscreateMedia == true) {
          // _uploadFile(
          //   pickFile: _pickFile,
          //   selectedFileName: selectedFilesNotifier,
          // );
        }
        break;
      default:
        break;
    }
  }

// ✅ Helper method to get file icon
  HeroIcons _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return HeroIcons.documentText;
      case 'doc':
      case 'docx':
        return HeroIcons.document;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return HeroIcons.photo;
      default:
        return HeroIcons.documentText;
    }
  }

  Future<void> _uploadFile({pickFile, selectedFileName}) {
    if (kDebugMode) {
      logger.d("Upload file called");
    }
    return showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: const [],
              borderRadius: BorderRadius.circular(25),
              color: Theme.of(context).colorScheme.backGroundColor,
            ),
            height: 550.h, // ✅ Increased height
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 40.h,
                            width: 40.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.greyColor.withValues(alpha: 0.3),
                            ),
                            child: HeroIcon(
                              HeroIcons.cloudArrowUp,
                              style: HeroIconStyle.outline,
                              size: 25.sp,
                              color: AppColors.greyColor,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 10.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Upload files",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Take photo or select files",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // ✅ Camera and Gallery buttons row
                  Row(
                    children: [
                      // Camera button
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            await _takePhoto();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                HeroIcon(
                                  HeroIcons.camera,
                                  style: HeroIconStyle.solid,
                                  size: 16.sp,
                                  color: AppColors.whiteColor,
                                ),
                                SizedBox(height: 8.h),
                                CustomText(
                                  text: "Take Photo",
                                  size: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.whiteColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Gallery button
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            await _pickFromGallery();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade600,
                                  Colors.green.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                HeroIcon(
                                  HeroIcons.photo,
                                  style: HeroIconStyle.solid,
                                  size: 16.sp,
                                  color: AppColors.whiteColor,
                                ),
                                SizedBox(height: 8.h),
                                CustomText(
                                  text: "Gallery",
                                  size: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.whiteColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Divider with "OR"
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: CustomText(
                          text: "OR",
                          size: 12.sp,
                          color: AppColors.greyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // File picker area (existing code)
                  Container(
                    decoration: const BoxDecoration(
                      border: DashedBorder.fromBorderSide(
                        dashLength: 15,
                        side: BorderSide(color: AppColors.greyColor, width: 1),
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    width: double.infinity,
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      children: [
                        CustomText(
                          text: "Browse documents",
                          size: 12.sp,
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.textClrChange,
                        ),
                        CustomText(
                          text: "PDF, DOC, DOCX, JPG, PNG",
                          color: AppColors.greyColor,
                          size: 10.sp,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 10.h),
                        InkWell(
                          onTap: pickFile,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.greyColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.greyColor,
                                width: 1,
                              ),
                            ),
                            height: 25.h,
                            width: 80.w,
                            child: CustomText(
                              text: "Browse files",
                              size: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Selected files list (existing ValueListenableBuilder code)
                  Expanded(
                    child: ValueListenableBuilder<List<File>>(
                      valueListenable: selectedFilesNotifier,
                      builder: (context, files, child) {
                        if (files.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HeroIcon(
                                  HeroIcons.documentPlus,
                                  style: HeroIconStyle.outline,
                                  size: 40.sp,
                                  color: AppColors.greyColor
                                      .withValues(alpha: 0.5),
                                ),
                                SizedBox(height: 8.h),
                                CustomText(
                                  text: "No files selected",
                                  size: 14.sp,
                                  color: AppColors.greyColor,
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Files header
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      HeroIcon(
                                        HeroIcons.documentCheck,
                                        style: HeroIconStyle.solid,
                                        size: 16.sp,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 6.w),
                                      CustomText(
                                        text:
                                            "${files.length} file(s) selected",
                                        size: 13.sp,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      selectedFilesNotifier.value = [];
                                    },
                                    style: TextButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.w),
                                    ),
                                    child: CustomText(
                                      text: "Clear all",
                                      size: 12.sp,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 8.h),

                            // Files list
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  final fileName = file.path.split('/').last;
                                  final fileSize = (file.lengthSync() / 1024)
                                      .toStringAsFixed(1);
                                  final isImage = fileName
                                          .toLowerCase()
                                          .endsWith('.jpg') ||
                                      fileName
                                          .toLowerCase()
                                          .endsWith('.jpeg') ||
                                      fileName.toLowerCase().endsWith('.png');

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 10.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // ✅ Show thumbnail for images
                                          if (isImage)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.file(
                                                file,
                                                width: 45.w,
                                                height: 45.h,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          else
                                            Container(
                                              padding: EdgeInsets.all(8.w),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: HeroIcon(
                                                _getFileIcon(fileName),
                                                style: HeroIconStyle.solid,
                                                size: 18.sp,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CustomText(
                                                  text: fileName,
                                                  size: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                CustomText(
                                                  text: "$fileSize KB",
                                                  size: 11.sp,
                                                  color: AppColors.greyColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              final newList =
                                                  List<File>.from(files);
                                              newList.removeAt(index);
                                              selectedFilesNotifier.value =
                                                  newList;
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(6.w),
                                              decoration: BoxDecoration(
                                                color: Colors.red
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                size: 16.sp,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Upload button (existing code)
                  ValueListenableBuilder<List<File>>(
                    valueListenable: selectedFilesNotifier,
                    builder: (context, files, child) {
                      final hasFiles = files.isNotEmpty;

                      return InkWell(
                        onTap: () {
                          if (!hasFiles) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select files first'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          context.read<InspectionMediaBloc>().add(
                                UploadMedia(
                                  id: widget.id!,
                                  media: files,
                                ),
                              );
                          selectedFilesNotifier.value = [];
                          router.pop();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: hasFiles
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withValues(alpha: 0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.greyColor
                                          .withValues(alpha: 0.3),
                                      AppColors.greyColor
                                          .withValues(alpha: 0.2),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: hasFiles
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          height: 45.h,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HeroIcon(
                                HeroIcons.cloudArrowUp,
                                style: HeroIconStyle.solid,
                                size: 20.sp,
                                color: hasFiles
                                    ? AppColors.pureWhiteColor
                                    : AppColors.greyColor,
                              ),
                              SizedBox(width: 8.w),
                              CustomText(
                                text: hasFiles
                                    ? "Upload ${files.length} file${files.length > 1 ? 's' : ''}"
                                    : AppLocalizations.of(context)!.upload,
                                size: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: hasFiles
                                    ? AppColors.pureWhiteColor
                                    : AppColors.greyColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget StatusOfPartField() {
    return StatefulBuilder(
      builder: (BuildContext context, void Function(void Function()) setState) {
        return Container(
          constraints: BoxConstraints(maxHeight: 900.h),
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: status.length,
            itemBuilder: (BuildContext context, int index) {
              final isSelected = statusname == status[index];

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: InkWell(
                  highlightColor: Colors.transparent, // No highlight on tap
                  splashColor: Colors.transparent,
                  onTap: () {
                    setState(() {
                      statusname = status[index];
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      width: double.infinity,
                      height: 35.h,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.purpleShade
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.purple
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 120.w,
                                // color: Colors.red,
                                child: CustomText(
                                  text: status[index],
                                  fontWeight: FontWeight.w500,
                                  size: 18.sp,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  color: isSelected
                                      ? AppColors.purple
                                      : Theme.of(
                                          context,
                                        ).colorScheme.textClrChange,
                                ),
                              ),
                              isSelected
                                  ? const HeroIcon(
                                      HeroIcons.checkCircle,
                                      style: HeroIconStyle.solid,
                                      color: AppColors.purple,
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void showToastWithProgress(BuildContext context, double progress) {
    OverlayState overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17.4),
              color: Theme.of(context).colorScheme.containerDark,
            ),

            // height: 50.h,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              child: Column(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text:
                        "Downloading... ${(progress * 100).toStringAsFixed(0)} %",
                    color: Theme.of(context).colorScheme.textClrChange,
                    size: 15.sp,
                  ),
                  SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.textClrChange,
                    minHeight: 8.h,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // Remove after a few seconds or upon completion
    Future.delayed(Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }
}
