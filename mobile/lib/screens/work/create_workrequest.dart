import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';

import 'package:flutter/cupertino.dart';
import 'package:ibex/bloc/setting/settings_bloc.dart';
import 'package:ibex/bloc/theme/theme_state.dart';
import 'package:ibex/bloc/work_discussion/work_media/work_media_bloc.dart';
import 'package:ibex/bloc/work_discussion/work_media/work_media_state.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/config/constants.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/data/model/Work/all_work.dart';
import 'package:ibex/data/repositories/work/work_repo.dart';
import 'package:ibex/src/generated/i18n/app_localizations.dart';
import 'package:ibex/screens/task/widget/location_field.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ibex/utils/widgets/notes_shimmer_widget.dart';
import 'package:ibex/utils/widgets/back_arrow.dart';
import 'package:ibex/bloc/work/work_bloc.dart';
import 'package:ibex/bloc/work/work_event.dart';
import 'package:ibex/bloc/work/work_state.dart';
import 'package:ibex/bloc/work_id/workid_bloc.dart';
import 'package:ibex/bloc/work_id/workid_event.dart';
import 'package:ibex/bloc/theme/theme_bloc.dart';
import 'package:ibex/routes/routes.dart';
import 'package:ibex/utils/user_id_mapper.dart' show UserIdMapper;
import 'package:ibex/utils/widgets/my_theme.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import 'package:ibex/screens/dash_board/dashboard.dart';
import 'package:ibex/screens/style/design_config.dart';
import 'package:ibex/screens/task/Widget/users_field.dart';
import 'package:ibex/screens/widgets/custom_cancel_create_button.dart';
import 'package:ibex/screens/widgets/custom_textfields/custom_textfield.dart';
import 'package:ibex/screens/work/work_lists.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class CreateWorkRequest extends StatefulWidget {
  final bool? isCreate;
  final bool? fromDetail;
  final String? title;
  final String? user;
  // final String? status;
  // final String? priority;
  final String? budget;
  final dynamic priority; // ✅ Can be int or String
  final int? priorityId;
  final int? statusId;
  final dynamic status; // ✅ Can be int or String
  final String? createdType; // ✅ Add this
  final int? woStatus; // ✅ Add this
  final int? id;
  final int? canClientDiscuss;
  final int? enable;
  final String? desc;
  final String? note;
  final String? start;
  final String? end;
  final String? access;
  final int? index;
  final List<int>? userId;
  final List<int>? assetId;
  final List<int>? clientId;
  final List<int>? tagId;
  final List<String>? userNames;
  final List<String>? assetNames;
  final List<String>? clientNames;
  final List<String>? tagNames;
  final WorkModel? customFieldsModel;

  CreateWorkRequest({
    super.key,
    this.isCreate,
    this.fromDetail,
    this.title,
    this.priority,
    this.priorityId,
    this.budget,
    this.enable,
    this.id,
    this.statusId,
    this.createdType,
    this.woStatus,
    this.user,
    this.status,
    this.desc,
    this.note,
    this.access,
    this.canClientDiscuss,
    this.start,
    this.end,
    this.index,
    this.userId,
    this.assetId,
    this.clientId,
    this.tagId,
    this.userNames,
    this.assetNames,
    this.clientNames,
    this.tagNames,
    this.customFieldsModel,
  });

  @override
  State<CreateWorkRequest> createState() => _CreateWorkRequestState();
}

class _CreateWorkRequestState extends State<CreateWorkRequest> {
  // ✅ FIX: Properly initialize GlobalKey with unique identifier
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController titleController;
  late TextEditingController phoneController;
  late TextEditingController budgetController;
  late TextEditingController descController;
  late TextEditingController passwordController;
  late TextEditingController noteController;
  late TextEditingController startsController;
  late TextEditingController endController;

  // ✅ FIX: Properly initialize FocusNodes separately
  late FocusNode titleFocus;
  late FocusNode phonenumberFocus;
  late FocusNode descFocus;
  late FocusNode startsFocus;
  late FocusNode endFocus;

  DateTime selectedDateStarts = DateTime.now();
  DateTime? selectedDateEnds = DateTime.now();
  String? fromDate;
  String? toDate;
  bool canClientDiscussWith = false;
  bool taskTimeEntries = false;
  String? selectedCategory;
  String? selectedStatus;
  String? selectedaccess;
  String? screen_type;
  int? selectedStatusId;
  int? selectedPriorityId;
  String? selectedPriority;
  List<int>? selectedTagId;
  List<String>? selectedTag;
  List<int>? selectedClientId;
  List<String>? selectedClient;
  int? selectedID;
  String? selectedCategoryy;

  String selectedWork = '';
  String requestProblem = '';

  String userPhone = '';
  String userName = '';
  String selectedUser = '';
  List<String>? usersName;
  List<String>? usersId;
  List<int>? selectedusersNameId;

  List<String>? locationName;
  List<String>? assetNames;
  List<int>? selectedlocationNameId;
  List<int>? selectedassetsNameId;

  String? formattedStartDate;
  String? formattedEndDate;
  int? idStatus;
  int? idPriority;
  String? currency;
  String? currencyPosition;
  WorkModel? customFieldReInitialized;
  String selectedOption = "Option 1";
  bool isCheckBox = false;
  String? selectedFromSelect;
  List<String> fieldTypes = [
    'number',
    'password',
    'textarea',
    'radio',
    'date',
    'checkbox',
    'select',
  ];

  // ✅ ADD these new fields
  int? _createdWorkId;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize all controllers
    titleController = TextEditingController();
    phoneController = TextEditingController();
    budgetController = TextEditingController();
    descController = TextEditingController();
    passwordController = TextEditingController();
    noteController = TextEditingController();
    startsController = TextEditingController();
    endController = TextEditingController();

    // ✅ Initialize all FocusNodes
    titleFocus = FocusNode();
    phonenumberFocus = FocusNode();
    descFocus = FocusNode();
    startsFocus = FocusNode();
    endFocus = FocusNode();

    currency = context.read<SettingsBloc>().currencySymbol;
    currencyPosition = context.read<SettingsBloc>().currencyPosition;
    customFieldReInitialized = widget.customFieldsModel;

    // ✅ Load user data
    _loadUserData();

    // ✅ If editing, populate fields
    if (widget.isCreate == false) {
      _initializeEditMode();
    }
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

  // ✅ NEW: Separate method for edit mode initialization
  void _initializeEditMode() {
    String formattedend = "";
    String formattedstart = "";

    if (widget.start != null &&
        widget.start!.isNotEmpty &&
        widget.start != "") {
      DateTime parsedDate = parseDateStringFromApi(widget.start!);
      formattedstart = dateFormatConfirmed(parsedDate, context);
      selectedDateStarts = parseDateStringFromApi(widget.start!);
    }

    if (widget.end != null && widget.end!.isNotEmpty && widget.end != "") {
      DateTime parsedDateEnd = parseDateStringFromApi(widget.end!);
      formattedend = dateFormatConfirmed(parsedDateEnd, context);
      selectedDateEnds = parsedDateEnd;
    }

    titleController.text = widget.title ?? '';
    budgetController.text = widget.budget ?? '';
    descController.text = removeHtmlTags(widget.desc ?? '');
    noteController.text = widget.note ?? '';
    startsController.text = "$formattedstart - $formattedend";
    endController.text = formattedend;

    usersName = widget.userNames;
    locationName = widget.userNames;
    assetNames = widget.assetNames;
    selectedClient = widget.clientNames;
    selectedTag = widget.tagNames;
    selectedStatus = widget.status;
    selectedaccess = widget.access;
    selectedPriority = widget.priority;

    canClientDiscussWith = (widget.canClientDiscuss == 1);
    taskTimeEntries = (widget.enable == 1);
  }

  // ✅ FIXED: Async function to load user data
  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic> userData = await HiveStorage.getUserInfoDatas();

      if (mounted) {
        setState(() {
          userPhone = userData['phone']?.toString() ?? '';
          userName =
              '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                  .trim();

          // ✅ Pre-fill only if creating new request
          if (widget.isCreate == true) {
            phoneController.text = userPhone;

            if (userData['first_name'] != null) {
              usersName = [userName];
            }

            if (userData['id'] != null) {
              String userIdUuid = userData['id'].toString();

              // ✅ FIX: Convert UUID to int using UserIdMapper
              int? mappedIntId = UserIdMapper().getIntId(userIdUuid);

              usersId = [userIdUuid]; // Keep UUID string for display
              selectedusersNameId = [mappedIntId]; // Use mapped int for API
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error loading user data: $e");
      }
    }
  }

  // ✅ IMPORTANT: Dispose all controllers and focus nodes
  @override
  void dispose() {
    // Dispose controllers
    titleController.dispose();
    phoneController.dispose();
    budgetController.dispose();
    descController.dispose();
    passwordController.dispose();
    noteController.dispose();
    startsController.dispose();
    endController.dispose();

    // Dispose focus nodes
    titleFocus.dispose();
    phonenumberFocus.dispose();
    descFocus.dispose();
    startsFocus.dispose();
    endFocus.dispose();

    super.dispose();
  }

  void _fieldFocusChange(
    BuildContext context,
    FocusNode currentFocus,
    FocusNode nextFocus,
  ) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  void _handlePrioritySelected(String category, int catId) {
    setState(() {
      selectedPriority = category;
      selectedPriorityId = catId;
    });
  }

  void _handleTagsSelected(List<String> category, List<int> catId) {
    setState(() {
      selectedTag = category;
      selectedTagId = catId;
    });
  }

  void _handleClientSelected(List<String> category, List<int> catId) {
    setState(() {
      selectedClient = category;
      selectedClientId = catId;
    });
  }

  void _handleUsersSelected(List<String> category, List<int> catId) {
    setState(() {
      usersName = category;
      selectedusersNameId = catId;
    });
  }

  void _handleLocationSelected(List<String> category, List<int> catId) {
    setState(() {
      locationName = category;
      selectedlocationNameId = catId;
    });
  }

  void _handleAssetsSelected(List<String> category, List<int> catId) {
    setState(() {
      assetNames = category;
      selectedassetsNameId = catId;
    });
  }

  void canClientdiscussHandle(bool status) {
    setState(() {
      canClientDiscussWith = status;
    });
  }

  void canTaskLimitEntriesHandle(bool status) {
    setState(() {
      taskTimeEntries = status;
    });
  }

  void _handleStatusSelected(String category, int catId) {
    setState(() {
      selectedStatus = category;
      selectedStatusId = catId;
    });
  }

  void _handleAccessSelected(String category) {
    setState(() {
      selectedaccess = category;
    });
  }

  String _getScreenTypeFromPriority(int? priorityId) {
    switch (priorityId) {
      case 1:
        return 'completed';
      case 2:
        return 'request';
      case 3:
        return 'open';
      case 4:
        return 'assigned';
      default:
        return 'open';
    }
  }

  void _navigateToWorkScreen(BuildContext context, int? priorityId) {
    final screenType = _getScreenTypeFromPriority(priorityId);

    // Update work list
    context
        .read<WorkBloc>()
        .add(WorkDashBoardList(workType: 'request', createType: 'request'));

    // Navigate to work screen with determined type
    if (screenType == 'request') {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const DashBoard(initialIndex: 2),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => WorkScreen(type: screenType)),
      );
    }
  }

// ✅ UPDATE _uploadFile method - remove edit mode check
  Future<void> _uploadFile({pickFile, selectedFileName}) {
    // ✅ In create mode, just show file picker - files will be uploaded after work creation
    return showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.backGroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.r),
              topRight: Radius.circular(25.r),
            ),
          ),
          height: 400.h,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                SizedBox(height: 16.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Attach files",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.textClrChange,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // Camera button
                _fileSourceButton(
                  icon: HeroIcons.camera,
                  label: "Take Photo",
                  onTap: () async {
                    Navigator.pop(context);
                    await _takePhoto();
                  },
                  color: AppColors.primary,
                ),

                SizedBox(height: 12.h),

                // Gallery button
                _fileSourceButton(
                  icon: HeroIcons.photo,
                  label: "Choose from Gallery",
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromGallery();
                  },
                  color: Colors.green,
                ),

                SizedBox(height: 12.h),

                // // Documents button
                // _fileSourceButton(
                //   icon: HeroIcons.documentText,
                //   label: "Browse Documents",
                //   onTap: () async {
                //     Navigator.pop(context);
                //     await pickFile();
                //   },
                //   color: Colors.blue,
                // ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ ADD NEW METHOD: File source button widget
  Widget _fileSourceButton({
    required HeroIcons icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: HeroIcon(
                icon,
                style: HeroIconStyle.solid,
                size: 20.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            CustomText(
              text: label,
              size: 15.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ADD NEW METHOD: Upload files after work is created
  Future<void> _uploadFilesAfterCreation(int workOrderId) async {
    if (selectedFilesNotifier.value.isEmpty) {
      if (kDebugMode) {
        logger.d("📤 No files to upload");
      }
      return;
    }
    try {
      context.read<WorkMediaBloc>().add(
            UploadMedia(
              id: workOrderId,
              media: selectedFilesNotifier.value,
            ),
          );
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error uploading files: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;
    final isLightTheme = currentTheme is LightThemeState;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          if (widget.fromDetail == true && widget.isCreate == false) {
            BlocProvider.of<WorkidBloc>(context).add(WorkIdListId(widget.id));
            router.pop(context);
          } else {
            router.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.backGroundColor,
        // ✅ REPLACE BlocListener with MultiBlocListener
        body: MultiBlocListener(
          listeners: [
            // ✅ WorkBloc listener
            BlocListener<WorkBloc, WorkState>(
              listener: (context, state) async {
                if (state is WorkCreateSuccess) {
                  _createdWorkId = state.createdWorkId;

                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }

                  if (state.createdWorkId != null) {
                    await _createRelatedItems(state.createdWorkId!);

                    // ✅ Upload files after work is created
                    if (selectedFilesNotifier.value.isNotEmpty) {
                      await _uploadFilesAfterCreation(state.createdWorkId!);
                    }
                  }

                  flutterToastCustom(
                    msg: AppLocalizations.of(context)!.createdsuccessfully,
                    color: AppColors.primary,
                  );

                  if (widget.fromDetail == true) {
                    BlocProvider.of<WorkidBloc>(context)
                        .add(WorkIdListId(widget.id));
                    router.pop(context);
                  } else {
                    if (kDebugMode) {
                      logger.d('   adding work dashboard list event');
                    }
                    screen_type = 'request';
                    selectedPriorityId = 2;
                    context.read<WorkBloc>().add(WorkDashBoardList(
                        workType: 'request', createType: 'request'));
                    _navigateToWorkScreen(context, selectedPriorityId);
                  }
                } else if (state is WorkCreateLoading) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => PopScope(
                      canPop: false,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                } else if (state is WorkCreateError) {
                  if (kDebugMode) {
                    logger.d("❌ Work create error: ${state.errorMessage}");
                  }
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                  flutterToastCustom(
                    msg: state.errorMessage,
                    color: Colors.red,
                  );
                }
              },
            ),

            // ✅ WorkMediaBloc listener for file upload
            BlocListener<WorkMediaBloc, WorkMediaState>(
              listener: (context, state) {
                if (state is WorkMediaUploadSuccess) {
                  if (kDebugMode) {
                    logger.d("✅ Files uploaded successfully");
                  }

                  setState(() {
                    _isUploading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8.w),
                          Text(
                              '${selectedFilesNotifier.value.length} file(s) uploaded'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );

                  selectedFilesNotifier.value = [];
                } else if (state is WorkMediaLoading) {
                  setState(() {
                    _isUploading = true;
                  });
                } else if (state is WorkMediaError) {
                  if (kDebugMode) {
                    logger.d("❌ File upload error: ${state.errorMessage}");
                  }

                  setState(() {
                    _isUploading = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Upload failed: ${state.errorMessage}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: SingleChildScrollView(
            child: Column(
              children: [
                _appBar(isLightTheme),
                SizedBox(height: 30.h),
                _body(isLightTheme),
                SizedBox(height: 50.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ✅ NEW: Create related items after work order is created
  Future<void> _createRelatedItems(int workOrderId) async {
    try {
      // Get current user ID
      int? myId = await HiveStorage.getUserId();
      String? myIdString = UserIdMapper().getUuid(myId);

      // ✅ 1. Create Work_order_actions
      final actionsResult = await WorkRepo().createWorkOrderActions(
        woId: workOrderId,
        firstUser: myIdString ?? '',
        actionStatus: 1,
        type: 'request',
      );

      // ✅ 2. Create Work_order_item
      final itemResult = await WorkRepo().createWorkOrderItem(
        status: 1,
        label: 'Label',
        workorder: workOrderId,
        name: 'Resolve problem',
        requestInfo: requestProblem, // ✅ Use the request problem HTML
        createdType: 'request_info',
      );
    } catch (e) {
      if (kDebugMode) {
        logger.d("❌ Error creating related items: $e");
      }
      // Don't block the user flow if this fails
    }
  }

// ✅ Simplified _onCreate - remove stream.listen
  void _onCreate() {
    if (selectedaccess == "Work Users" || selectedaccess == "Assigned User") {
      selectedaccess = "project_users";
    }

    List<String> missingFields = [];

    if (titleController.text.isEmpty) {
      missingFields.add(AppLocalizations.of(context)!.title);
    }

    if (missingFields.isEmpty) {
      // ✅ Build request problem HTML
      requestProblem = '''
      The following was reported through a Work Request Portal.<br/>
      <b>Problem</b>: ${titleController.text}<br/>
      <b>Requester</b>: ${userName}, ${phoneController.text}<br/>
       ${descController.text}
    ''';

      // ✅ Just add event, BlocListener will handle the response
      context.read<WorkBloc>().add(
            WorkCreated(
              enable: taskTimeEntries ? 1 : 0,
              title: titleController.text,
              statusId: selectedStatusId ?? 1,
              workType: 3,
              actionStatus: 1,
              desc: descController.text.isNotEmpty ? descController.text : null,
              createdType: 'request',
              userIdString: (usersId?.isNotEmpty ?? false) ? usersId![0] : null,
              locationId: selectedlocationNameId ?? [],
              note: noteController.text.isNotEmpty ? noteController.text : null,
              customFieldValues: null,
              // ✅ Don't send empty string dates - send null instead
              startDate: null,
              endDate: null,
            ),
          );
    } else {
      if (kDebugMode) {
        logger.d("❌ Validation failed. Missing required fields: $missingFields");
      }
      String errorMessage =
          "${AppLocalizations.of(context)!.pleasefilltherequiredfield}: ${missingFields.join(', ')}";
      flutterToastCustom(msg: errorMessage);
    }
  }

  void _onUpdateWork() {
    if (selectedaccess == "Work Users") {
      selectedaccess = "project_users";
    } else if (selectedaccess == "Assigned User") {
      selectedaccess = "project_users";
    }
    if (titleController.text.isNotEmpty) {
      context.read<WorkBloc>().add(
            UpdateWork(
              id: widget.id!,
              enable: taskTimeEntries ? 1 : 0,
              clientCanDiscuss: canClientDiscussWith ? 1 : 0,
              title: titleController.text,
              statusId: selectedStatusId == null
                  ? widget.statusId!
                  : selectedStatusId!,
              priorityId: selectedPriorityId == null
                  ? widget.priorityId!
                  : selectedPriorityId!,
              startDate: fromDate ?? widget.start!,
              endDate: toDate ?? widget.end!,
              desc: descController.text,
              userId: selectedlocationNameId == null
                  ? widget.userId!
                  : selectedlocationNameId!,
              assetId: selectedassetsNameId == null
                  ? widget.assetId!
                  : selectedassetsNameId!,
              taskAccess:
                  selectedaccess == null ? widget.access! : selectedaccess!,
              note: noteController.text,
              budget: budgetController.text,
              clientId: selectedClientId == null
                  ? widget.clientId!
                  : selectedClientId!,
              tagId: selectedTagId == null ? widget.tagId! : selectedTagId!,
              customFieldValues: {},
            ),
          );
      context.read<WorkBloc>().stream.listen((event) {
        if (event is WorkEditSuccess) {
          if (mounted) {
            // isLoading = false;
            if (widget.fromDetail == true) {
              BlocProvider.of<WorkidBloc>(context).add(WorkIdListId(widget.id));
              router.pop(context);
            } else {
              BlocProvider.of<WorkBloc>(context).add(WorkDashBoardList(
                  workType: 'request', createType: 'request'));
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const WorkScreen(type: "request"),
                  // const DashBoard(initialIndex: 1), // Navigate to index 1
                ),
              );
            }

            flutterToastCustom(
              msg: AppLocalizations.of(context)!.updatedsuccessfully,
              color: AppColors.primary,
            );
          }
        }
        if (event is WorkEditError) {
          flutterToastCustom(msg: event.errorMessage);
        }
      });
    } else {
      flutterToastCustom(
        msg: AppLocalizations.of(context)!.pleasefilltherequiredfield,
      );
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

  Widget _body(isLightTheme) {
    // print("WorkBloc State rebuild ${widget}");

    Future<void> _pickFile() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null) {
        List<File> pickedFiles =
            result.paths.whereType<String>().map((path) => File(path)).toList();

        selectedFilesNotifier.value = [
          ...selectedFilesNotifier.value,
          ...pickedFiles,
        ];
      }
    }

    // ✅ Single form builder - DRY principle
    Widget buildFormFields() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextFields(
            title: AppLocalizations.of(context)!.title,
            hinttext: AppLocalizations.of(context)!.pleaseentertitle,
            controller: titleController,
            onSaved: (value) {},
            onFieldSubmitted: (value) {
              _fieldFocusChange(context, titleFocus, phonenumberFocus);
            },
            isLightTheme: isLightTheme,
            isRequired: true,
          ),

          SizedBox(height: 15.h),
          LocationField(
            isRequired: true,
            isCreate: widget.isCreate!,
            locationName: locationName ?? [],
            locationId: selectedlocationNameId ?? [],
            project: const [],
            onSelected: _handleLocationSelected,
          ),

          SizedBox(height: 15.h),
          UsersField(
            isRequired: false,
            isCreate: widget.isCreate!,
            usersname: usersName ?? [],
            usersid: usersId != null
                ? usersId!.map((e) => int.tryParse(e) ?? 0).toList()
                : [],
            project: const [],
            onSelected: _handleUsersSelected,
          ),

          SizedBox(height: 15.h),
          CustomTextFields(
            title: AppLocalizations.of(context)!.phonenumber,
            hinttext: AppLocalizations.of(context)!.pleaseenterphonenumber,
            controller: phoneController,
            onSaved: (value) {},
            onFieldSubmitted: (value) {
              _fieldFocusChange(context, phonenumberFocus, descFocus);
            },
            isLightTheme: isLightTheme,
            isRequired: true,
          ),

          SizedBox(height: 15.h),
          CustomTextFields(
            height: 112.h,
            keyboardType: TextInputType.multiline,
            title: AppLocalizations.of(context)!.whatishavingtheproblem,
            hinttext: AppLocalizations.of(context)!.pleaseenterdescription,
            controller: descController,
            onSaved: (value) {},
            onFieldSubmitted: (value) {
              _fieldFocusChange(context, descFocus, startsFocus);
            },
            isLightTheme: isLightTheme,
            isRequired: false,
          ),

          SizedBox(height: 15.h),
          Divider(color: Theme.of(context).colorScheme.dividerClrChange),
          SizedBox(height: 15.h),

          // ✅ File upload button - ALWAYS show
          InkWell(
            onTap: () {
              _uploadFile(
                pickFile: _pickFile,
                selectedFileName: selectedFilesNotifier,
              );
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeroIcon(
                    HeroIcons.paperClip,
                    style: HeroIconStyle.solid,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  CustomText(
                    text: widget.isCreate == true
                        ? "Attach files"
                        : "Upload files",
                    size: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // ✅ Show selected files preview
          SizedBox(height: 12.h),
          ValueListenableBuilder<List<File>>(
            valueListenable: selectedFilesNotifier,
            builder: (context, files, child) {
              if (files.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            HeroIcon(
                              HeroIcons.paperClip,
                              style: HeroIconStyle.solid,
                              size: 16.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6.w),
                            CustomText(
                              text: "${files.length} file(s) attached",
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
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                          ),
                          child: CustomText(
                            text: "Clear all",
                            size: 11.sp,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...files.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      final fileName = file.path.split('/').last;
                      final fileSize =
                          (file.lengthSync() / 1024).toStringAsFixed(1);

                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          children: [
                            HeroIcon(
                              _getFileIcon(fileName),
                              style: HeroIconStyle.solid,
                              size: 14.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: fileName,
                                    size: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  CustomText(
                                    text: "$fileSize KB",
                                    size: 10.sp,
                                    color: AppColors.greyColor,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                final newList = List<File>.from(files);
                                newList.removeAt(index);
                                selectedFilesNotifier.value = newList;
                              },
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                child: Icon(
                                  Icons.close,
                                  size: 16.sp,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 15.h),

          // ✅ Show uploading indicator
          if (_isUploading) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  CustomText(
                    text: "Uploading files...",
                    size: 13.sp,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
          ],

          CreateCancelButtom(
            isCreate: widget.isCreate,
            onpressCancel: () {
              Navigator.pop(context);
            },
            onpressCreate: widget.isCreate == true
                ? () async {
                    _onCreate();
                  }
                : () {
                    _onUpdateWork();
                  },
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: BlocBuilder<WorkBloc, WorkState>(
          builder: (context, state) {
            // ✅ Show loading shimmer
            if (state is WorkLoading) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: const NotesShimmer(),
              );
            }

            // ✅ Always return the same form for all states
            return buildFormFields();
          },
        ),
      ),
    );
  }

  Widget _appBar(isLightTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 0.h),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    isLightTheme
                        ? MyThemes.lightThemeShadow
                        : MyThemes.darkThemeShadow,
                  ],
                ),
                // color: Colors.red,
                // width: 300.w,
                child: InkWell(
                  onTap: () {
                    if (widget.fromDetail == true && widget.isCreate == false) {
                      BlocProvider.of<WorkidBloc>(
                        context,
                      ).add(WorkIdListId(widget.id));
                      router.pop(context);
                    } else {
                      router.pop(context);
                    }
                  },
                  child: BackArrow(
                    title: widget.isCreate == false
                        ? AppLocalizations.of(context)!.editworkrequest
                        : AppLocalizations.of(context)!.createworkrequest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
