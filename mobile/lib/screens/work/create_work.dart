import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ibex/bloc/setting/settings_bloc.dart';
import 'package:ibex/bloc/theme/theme_state.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/config/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ibex/data/model/Work/all_work.dart';
import '../../../utils/widgets/notes_shimmer_widget.dart';
import 'package:ibex/utils/widgets/back_arrow.dart';
import '../../bloc/work/work_bloc.dart';
import '../../bloc/work/work_event.dart';
import '../../bloc/work/work_state.dart';
import '../../bloc/work_id/workid_bloc.dart';
import '../../bloc/work_id/workid_event.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/my_theme.dart';
import '../../utils/widgets/toast_widget.dart';
import '../dash_board/dashboard.dart';
import '../style/design_config.dart';
import '../task/Widget/priority_all_field.dart';
import '../task/Widget/status_field.dart';
import '../widgets/custom_date.dart';
import '../widgets/custom_cancel_create_button.dart';
import '../../../src/generated/i18n/app_localizations.dart';

import '../widgets/custom_textfields/custom_textfield.dart';
import '../../screens/work/work_lists.dart';
import '../task/widget/teams_field.dart';
import '../task/widget/assets_field.dart';

class CreateWork extends StatefulWidget {
  final bool? isCreate;
  final bool? fromDetail;
  final String? title;
  final String? user;
  final String? status;
  final String? priority;
  final String? budget;
  final int? priorityId;
  final int? statusId;
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

  CreateWork({
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
  State<CreateWork> createState() => _CreateWorkState();
}

class _CreateWorkState extends State<CreateWork> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController budgetController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  TextEditingController startsController = TextEditingController();
  TextEditingController endController = TextEditingController();
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

  String selectedUser = '';
  List<String>? usersName;
  List<int>? selectedusersNameId;

  List<String>? teamsName;
  List<String>? assetNames;
  List<int>? selectedteamsNameId;

  List<int>? selectedassetsNameId;
  // String selectedStatus = '';

  String? formattedStartDate;
  String? formattedEndDate;
  int? idStatus;
  int? idPriority;
  String? currency;
  String? currencyPosition;
  WorkModel? customFieldReInitialized; // Moved to State class
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

  void _fieldFocusChange(
    BuildContext context,
    FocusNode currentFocus,
    FocusNode? nextFocus,
  ) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  FocusNode? titleFocus,
      budgetFocus,
      descFocus,
      startsFocus,
      endFocus = FocusNode();

  @override
  void initState() {
    currency = context.read<SettingsBloc>().currencySymbol;
    currencyPosition = context.read<SettingsBloc>().currencyPosition;
    customFieldReInitialized = widget.customFieldsModel;
    if (widget.isCreate == false) {
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
      titleController = TextEditingController(text: widget.title);
      budgetController = TextEditingController(text: widget.budget);
      usersName = widget.userNames!;
      teamsName = widget.userNames!;
      assetNames = widget.assetNames!;
      if (widget.canClientDiscuss == 1) {
        canClientDiscussWith = true;
      } else {
        canClientDiscussWith = false;
      }
      if (widget.enable == 1) {
        taskTimeEntries = true;
      } else {
        taskTimeEntries = false;
      }
      selectedClient = widget.clientNames!;
      selectedTag = widget.tagNames!;
      selectedStatus = widget.status;
      selectedaccess = widget.access;
      selectedPriority = widget.priority;
      startsController = TextEditingController(
        text: "$formattedstart - $formattedend",
      );
      endController = TextEditingController(text: formattedend);
      descController = TextEditingController(
        text: removeHtmlTags(widget.desc!),
      );
      noteController = TextEditingController(text: widget.note);
    } else {}
    super.initState();
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

  void _handleTeamsSelected(List<String> category, List<int> catId) {
    setState(() {
      teamsName = category;
      selectedteamsNameId = catId;
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
    context.read<WorkBloc>().add(WorkDashBoardList());

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

  void _onCreate() {
    if (selectedaccess == "Work Users" || selectedaccess == "Assigned User") {
      selectedaccess = "project_users";
    }

    List<String> missingFields = [];

    // Check standard fields
    if (titleController.text.isEmpty) {
      missingFields.add(AppLocalizations.of(context)!.title);
    }
    if (selectedStatusId == null) {
      missingFields.add(AppLocalizations.of(context)!.status);
    }

    // if (selectedaccess == null) {
    //   missingFields.add(AppLocalizations.of(context)!.taskaccessibility);
    // }

    if (missingFields.isEmpty) {
      context.read<WorkBloc>().add(
        WorkCreated(
          enable: taskTimeEntries ? 1 : 0,
          clientCanDiscuss: canClientDiscussWith ? 1 : 0,
          title: titleController.text,
          statusId: selectedStatusId!,
          priorityId: selectedPriorityId ?? 0,
          startDate: fromDate ?? "",
          endDate: toDate ?? "",
          desc: descController.text,
          createdType: 'open',
          taskAccess: selectedaccess ?? "Assigned User",
          userId: selectedteamsNameId ?? [],
          note: noteController.text,
          budget: budgetController.text,
          clientId: selectedClientId ?? [],
          tagId: selectedTagId ?? [],
          customFieldValues: {},
        ),
      );

      context.read<WorkBloc>().stream.listen((state) {
        if (state is WorkCreateSuccess) {
          if (mounted) {
            flutterToastCustom(
              msg: AppLocalizations.of(context)!.createdsuccessfully,
              color: AppColors.primary,
            );
            if (widget.fromDetail == true) {
              BlocProvider.of<WorkidBloc>(context).add(WorkIdListId(widget.id));
              router.pop(context);
            } else {
              screen_type = 'open';
              if (selectedPriorityId == 1) {
                screen_type = 'completed';
              } else if (selectedPriorityId == 2) {
                screen_type = 'request';
              } else if (selectedPriorityId == 3) {
                screen_type = 'open';
              } else if (selectedPriorityId == 4) {
                screen_type = 'assigned';
              }
              context.read<WorkBloc>().add(WorkDashBoardList());
              _navigateToWorkScreen(context, selectedPriorityId);
            }
          }
        } else if (state is WorkCreateLoading) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
          }
        } else if (state is WorkCreateError) {
          if (mounted) {
            Navigator.of(context).pop();
            flutterToastCustom(msg: state.errorMessage);
          }
        }
      });
    } else {
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
          userId: selectedteamsNameId == null
              ? widget.userId!
              : selectedteamsNameId!,
          assetId: selectedassetsNameId == null
              ? widget.assetId!
              : selectedassetsNameId!,
          taskAccess: selectedaccess == null ? widget.access! : selectedaccess!,
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
              BlocProvider.of<WorkBloc>(context).add(WorkDashBoardList());
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const WorkScreen(type: "open"),
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
        body: SingleChildScrollView(
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
    );
  }

  Widget _body(isLightTheme) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: BlocBuilder<WorkBloc, WorkState>(
          builder: (context, state) {
            if (state is WorkLoading) {
              return SizedBox(
                height: MediaQuery.of(
                  context,
                ).size.height, // Ensure defined height
                width: MediaQuery.of(
                  context,
                ).size.width, // Ensure defined width
                child: const NotesShimmer(),
              );
            }
            if (state is WorkCreateLoading) {
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
                      _fieldFocusChange(context, titleFocus!, budgetFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: true,
                  ),

                  // SizedBox(height: 15.h),
                  // UsersField(
                  //   isRequired: false,
                  //   isCreate: widget.isCreate!,
                  //   usersname: usersName ?? [],
                  //   usersid: widget.userId!,
                  //   project: const [],
                  //   onSelected: _handleUsersSelected,
                  // ),
                  SizedBox(height: 15.h),
                  TeamsField(
                    isRequired: false,
                    isCreate: widget.isCreate!,
                    teamsname: teamsName ?? [],
                    teamsid: selectedteamsNameId ?? [],
                    project: const [],
                    onSelected: _handleTeamsSelected,
                  ),

                  // SizedBox(height: 15.h),
                  // AssetField(
                  //   isRequired: false,
                  //   isCreate: widget.isCreate!,
                  //   assetname: assetNames ?? [],
                  //   assetid: selectedassetsNameId ?? [],
                  //   project: const [],
                  //   onSelected: _handleAssetsSelected,
                  // ),

                  // SizedBox(height: 15.h),
                  // AccessibiltyField(
                  //   access: widget.access,
                  //   isRequired: true,
                  //   isCreate: widget.isCreate!,
                  //   name: selectedaccess ?? "",
                  //   index: widget.index!,
                  //   onSelected: _handleAccessSelected,
                  // ),
                  SizedBox(height: 15.h),
                  StatusField(
                    status: widget.statusId,
                    isRequired: true,
                    isCreate: widget.isCreate!,
                    name: selectedStatus ?? "",
                    index: widget.index!,
                    onSelected: _handleStatusSelected,
                  ),
                  SizedBox(height: 15.h),
                  PriorityAllField(
                    priority: widget.priorityId,
                    name: (widget.priority != null
                        ? widget.priority! + 'dsds'
                        : "dsds"),
                    isRequired: true,
                    isCreate: widget.isCreate!,
                    index: widget.index!,
                    onSelected: _handlePrioritySelected,
                  ),

                  SizedBox(height: 15.h),

                  CustomTextFields(
                    height: 112.h,
                    keyboardType: TextInputType.multiline,
                    title: AppLocalizations.of(context)!.description,
                    hinttext: AppLocalizations.of(
                      context,
                    )!.pleaseenterdescription,
                    controller: descController,
                    onSaved: (value) {},
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(context, descFocus!, startsFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: false,
                  ),
                  SizedBox(height: 15.h),
                  CustomTextFields(
                    keyboardType: TextInputType.multiline,
                    height: 112.h,
                    title: AppLocalizations.of(context)!.note,
                    hinttext: AppLocalizations.of(context)!.pleaseenternotes,
                    controller: noteController,
                    onSaved: (value) {},
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(context, descFocus!, startsFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: false,
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: DateRangePickerWidget(
                      dateController: startsController,
                      title: AppLocalizations.of(context)!.starts,
                      titlestartend: AppLocalizations.of(
                        context,
                      )!.selectstartenddate,
                      selectedDateEnds: selectedDateEnds,
                      selectedDateStarts: selectedDateStarts,
                      isLightTheme: isLightTheme,
                      onTap: (start, end) {
                        setState(() {
                          selectedDateEnds = end;
                          selectedDateStarts = start!;

                          // Update the startsController to show BOTH dates
                          startsController.text =
                              "${dateFormatConfirmed(selectedDateStarts, context)} - ${dateFormatConfirmed(selectedDateEnds!, context)}";

                          // Keep fromDate and toDate separately for API submission
                          fromDate = dateFormatConfirmedToApi(start);
                          toDate = dateFormatConfirmedToApi(end!);
                        });
                      },
                    ),
                  ),

                  SizedBox(height: 15.h),
                  Divider(),
                  SizedBox(height: 15.h),

                  SizedBox(height: 15.h),

                  CreateCancelButtom(
                    isLoading: true,
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
                  // CreateCancelButtom(),
                ],
              );
            }
            if (state is WorkEditLoading) {
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
                      _fieldFocusChange(context, titleFocus!, budgetFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: true,
                  ),

                  // SizedBox(height: 15.h),
                  // UsersField(
                  //   isRequired: false,
                  //   isCreate: widget.isCreate!,
                  //   usersname: usersName ?? [],
                  //   usersid: widget.userId!,
                  //   project: const [],
                  //   onSelected: _handleUsersSelected,
                  // ),

                  // SizedBox(height: 15.h),
                  // AccessibiltyField(
                  //   access: widget.access,
                  //   isRequired: true,
                  //   isCreate: widget.isCreate!,
                  //   name: selectedaccess ?? "",
                  //   index: widget.index!,
                  //   onSelected: _handleAccessSelected,
                  // ),
                  SizedBox(height: 15.h),
                  StatusField(
                    status: widget.statusId,
                    isRequired: true,
                    isCreate: widget.isCreate!,
                    name: selectedStatus ?? "",
                    index: widget.index!,
                    onSelected: _handleStatusSelected,
                  ),
                  SizedBox(height: 15.h),
                  PriorityAllField(
                    priority: widget.priorityId,
                    isRequired: true,
                    isCreate: widget.isCreate!,
                    name: (widget.priority != null
                        ? widget.priority! + 'dsds2'
                        : "dsds2"),
                    index: widget.index!,
                    onSelected: _handlePrioritySelected,
                  ),

                  SizedBox(height: 15.h),
                  CustomTextFields(
                    height: 112.h,
                    keyboardType: TextInputType.multiline,
                    title: AppLocalizations.of(context)!.description,
                    hinttext: AppLocalizations.of(
                      context,
                    )!.pleaseenterdescription,
                    controller: descController,
                    onSaved: (value) {},
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(context, descFocus!, startsFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: false,
                  ),
                  SizedBox(height: 15.h),
                  CustomTextFields(
                    keyboardType: TextInputType.multiline,
                    height: 112.h,
                    title: AppLocalizations.of(context)!.note,
                    hinttext: AppLocalizations.of(context)!.pleaseenternotes,
                    controller: noteController,
                    onSaved: (value) {},
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(context, descFocus!, startsFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: false,
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: DateRangePickerWidget(
                      dateController: startsController,
                      title: AppLocalizations.of(context)!.starts,
                      titlestartend: AppLocalizations.of(
                        context,
                      )!.selectstartenddate,
                      selectedDateEnds: selectedDateEnds,
                      selectedDateStarts: selectedDateStarts,
                      isLightTheme: isLightTheme,
                      onTap: (start, end) {
                        if (start != null && end != null) {
                          setState(() {
                            selectedDateStarts = start;
                            selectedDateEnds = end;

                            // ✅ Convert for API
                            fromDate = dateFormatConfirmedToApi(start);
                            toDate = dateFormatConfirmedToApi(end);
                          });
                        }
                      },
                    ),
                  ),

                  // startsField(isLightTheme),

                  // tagsField(isLightTheme),
                  SizedBox(height: 15.h),
                  Divider(),
                  SizedBox(height: 15.h),

                  SizedBox(height: 15.h),

                  CreateCancelButtom(
                    isLoading: true,
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
                  // CreateCancelButtom(),
                ],
              );
            }
            if (state is WorkSuccess) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextFields(
                    isPassword: false,
                    title: AppLocalizations.of(context)!.title,
                    hinttext: AppLocalizations.of(context)!.pleaseentertitle,
                    controller: titleController,
                    onSaved: (value) {},
                    onFieldSubmitted: (value) {},
                    isLightTheme: isLightTheme,
                  ),

                  // SizedBox(height: 15.h),
                  // UsersField(
                  //   isRequired: false,
                  //   isCreate: widget.isCreate!,
                  //   usersname: usersName ?? [],
                  //   usersid: const [],
                  //   project: const [],
                  //   onSelected: _handleUsersSelected,
                  // ),

                  // SizedBox(height: 15.h),
                  // AccessibiltyField(
                  //   access: widget.access,
                  //   isRequired: true,
                  //   isCreate: widget.isCreate!,
                  //   name: selectedaccess ?? "",
                  //   index: widget.index!,
                  //   onSelected: _handleAccessSelected,
                  // ),
                  SizedBox(height: 15.h),
                  StatusField(
                    status: widget.statusId,
                    isCreate: widget.isCreate!,
                    name: selectedStatus ?? "",
                    index: widget.index!,
                    onSelected: _handleStatusSelected,
                  ),
                  SizedBox(height: 15.h),
                  PriorityAllField(
                    isRequired: false,
                    priority: widget.priorityId,
                    isCreate: widget.isCreate!,
                    name: (widget.priority != null
                        ? widget.priority! + 'dsds3'
                        : "dsds3"),
                    index: widget.index!,
                    onSelected: _handlePrioritySelected,
                  ),
                  SizedBox(height: 15.h),
                  CustomTextFields(
                    height: 112.h,
                    keyboardType: TextInputType.multiline,
                    title: AppLocalizations.of(context)!.description,
                    hinttext: AppLocalizations.of(
                      context,
                    )!.pleaseenterdescription,
                    controller: descController,
                    onSaved: (value) {},
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(context, descFocus!, startsFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: false,
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: DateRangePickerWidget(
                      dateController: startsController,
                      title: AppLocalizations.of(context)!.starts,
                      titlestartend: AppLocalizations.of(
                        context,
                      )!.selectstartenddate,
                      selectedDateEnds: selectedDateEnds,
                      selectedDateStarts: selectedDateStarts,
                      isLightTheme: isLightTheme,
                      onTap: (start, end) {
                        setState(() {
                          selectedDateEnds = end;
                          selectedDateStarts = start!;

                          // Update the startsController to show BOTH dates
                          startsController.text =
                              "${dateFormatConfirmed(selectedDateStarts, context)} - ${dateFormatConfirmed(selectedDateEnds!, context)}";

                          // Keep fromDate and toDate separately for API submission
                          fromDate = dateFormatConfirmedToApi(start);
                          toDate = dateFormatConfirmedToApi(end!);
                        });
                      },
                    ),
                  ),

                  // startsField(isLightTheme),

                  // tagsField(isLightTheme),
                  SizedBox(height: 15.h),
                  Divider(),
                  SizedBox(height: 15.h),

                  SizedBox(height: 15.h),

                  CreateCancelButtom(
                    isCreate: widget.isCreate,
                    onpressCancel: () {
                      Navigator.pop(context);
                    },
                    onpressCreate: widget.isCreate == true
                        ? () async {}
                        : () {},
                  ),
                ],
              );
            } else if (state is WorkPaginated) {
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
                      _fieldFocusChange(context, titleFocus!, budgetFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: true,
                  ),

                  // SizedBox(height: 15.h),
                  // UsersField(
                  //   isRequired: false,
                  //   isCreate: widget.isCreate!,
                  //   usersname: usersName ?? [],
                  //   usersid: widget.userId!,
                  //   project: const [],
                  //   onSelected: _handleUsersSelected,
                  // ),
                  SizedBox(height: 15.h),
                  TeamsField(
                    isRequired: false,
                    isCreate: widget.isCreate!,
                    teamsname: teamsName ?? [],
                    teamsid: selectedteamsNameId ?? [],
                    project: const [],
                    onSelected: _handleTeamsSelected,
                  ),
                  SizedBox(height: 15.h),

                  AssetField(
                    isRequired: false,
                    isCreate: widget.isCreate!,
                    assetname: assetNames ?? [],
                    assetid: selectedassetsNameId ?? [],
                    project: const [],
                    onSelected: _handleAssetsSelected,
                  ),

                  // SizedBox(height: 15.h),
                  // AccessibiltyField(
                  //   access: widget.access,
                  //   isRequired: true,
                  //   isCreate: widget.isCreate!,
                  //   name: selectedaccess ?? "",
                  //   index: widget.index!,
                  //   onSelected: _handleAccessSelected,
                  // ),
                  SizedBox(height: 15.h),
                  StatusField(
                    status: widget.statusId,
                    isRequired: true,
                    isCreate: widget.isCreate!,
                    name: selectedStatus ?? "",
                    index: widget.index!,
                    onSelected: _handleStatusSelected,
                  ),
                  SizedBox(height: 15.h),
                  PriorityAllField(
                    priority: widget.priorityId,
                    isRequired: false,
                    isCreate: widget.isCreate!,
                    name: (widget.priority != null
                        ? widget.priority! + 'dsds4'
                        : "dsds4"),
                    index: widget.index!,
                    onSelected: _handlePrioritySelected,
                  ),

                  SizedBox(height: 15.h),

                  CustomTextFields(
                    height: 112.h,
                    keyboardType: TextInputType.multiline,
                    title: AppLocalizations.of(context)!.description,
                    hinttext: AppLocalizations.of(
                      context,
                    )!.pleaseenterdescription,
                    controller: descController,
                    onSaved: (value) {},
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(context, descFocus!, startsFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: false,
                  ),
                  SizedBox(height: 15.h),
                  CustomTextFields(
                    keyboardType: TextInputType.multiline,
                    height: 112.h,
                    title: AppLocalizations.of(context)!.note,
                    hinttext: AppLocalizations.of(context)!.pleaseenternotes,
                    controller: noteController,
                    onSaved: (value) {},
                    onFieldSubmitted: (value) {
                      _fieldFocusChange(context, descFocus!, startsFocus);
                    },
                    isLightTheme: isLightTheme,
                    isRequired: false,
                  ),
                  SizedBox(height: 15.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: DateRangePickerWidget(
                      dateController:
                          startsController, // Use only one controller
                      title: AppLocalizations.of(context)!.date,

                      titlestartend: AppLocalizations.of(
                        context,
                      )!.selectstartenddate,
                      selectedDateEnds: selectedDateEnds,
                      selectedDateStarts: selectedDateStarts,
                      isLightTheme: isLightTheme,
                      onTap: (start, end) {
                        setState(() {
                          selectedDateEnds = end;
                          selectedDateStarts = start!;

                          // Update the startsController to show BOTH dates
                          startsController.text =
                              "${dateFormatConfirmed(selectedDateStarts, context)} - ${dateFormatConfirmed(selectedDateEnds!, context)}";

                          // Keep fromDate and toDate separately for API submission
                          fromDate = dateFormatConfirmedToApi(start);
                          toDate = dateFormatConfirmedToApi(end!);
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Divider(),
                  SizedBox(height: 15.h),

                  SizedBox(height: 15.h),

                  SizedBox(height: 15.h),
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
                  // CreateCancelButtom(),
                ],
              );
            }
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
                    _fieldFocusChange(context, titleFocus!, budgetFocus);
                  },
                  isLightTheme: isLightTheme,
                  isRequired: true,
                ),
                // SizedBox(height: 15.h),
                // UsersField(
                //   isRequired: false,
                //   isCreate: widget.isCreate!,
                //   usersname: usersName ?? [],
                //   usersid: widget.userId!,
                //   project: const [],
                //   onSelected: _handleUsersSelected,
                // ),

                // SizedBox(height: 15.h),
                // TeamsField(
                //   isRequired: false,
                //   isCreate: widget.isCreate!,
                //   teamsname: teamsName ?? [],
                //   teamsid: selectedteamsNameId ?? [],
                //   project: const [],
                //   onSelected: _handleTeamsSelected,
                // ),

                // SizedBox(height: 15.h),
                // TagsField(
                //   tagsid: widget.tagId ?? [],
                //   isRequired: false,
                //   isCreate: widget.isCreate!,
                //   usersname: selectedTag ?? [],
                //   project: const [],
                //   index: widget.index,
                //   onSelected: _handleTagsSelected,
                // ),
                // SizedBox(height: 15.h),
                // AccessibiltyField(
                //   access: widget.access,
                //   isRequired: true,
                //   isCreate: widget.isCreate!,
                //   name: selectedaccess ?? "",
                //   index: widget.index!,
                //   onSelected: _handleAccessSelected,
                // ),
                SizedBox(height: 15.h),
                StatusField(
                  status: widget.statusId,
                  isRequired: true,
                  isCreate: widget.isCreate!,
                  name: selectedStatus ?? "",
                  index: widget.index!,
                  onSelected: _handleStatusSelected,
                ),
                SizedBox(height: 15.h),
                PriorityAllField(
                  priority: widget.priorityId,
                  isRequired: false,
                  isCreate: widget.isCreate!,
                  name: (widget.priority != null
                      ? widget.priority! + 'dsds5'
                      : "dsds5"),
                  index: widget.index!,
                  onSelected: _handlePrioritySelected,
                ),
                SizedBox(height: 15.h),
                CustomTextFields(
                  height: 112.h,
                  keyboardType: TextInputType.multiline,
                  title: AppLocalizations.of(context)!.description,
                  hinttext: AppLocalizations.of(
                    context,
                  )!.pleaseenterdescription,
                  controller: descController,
                  onSaved: (value) {},
                  onFieldSubmitted: (value) {
                    _fieldFocusChange(context, descFocus!, startsFocus);
                  },
                  isLightTheme: isLightTheme,
                  isRequired: false,
                ),
                SizedBox(height: 15.h),
                CustomTextFields(
                  keyboardType: TextInputType.multiline,
                  height: 112.h,
                  title: AppLocalizations.of(context)!.note,
                  hinttext: AppLocalizations.of(context)!.pleaseenternotes,
                  controller: noteController,
                  onSaved: (value) {},
                  onFieldSubmitted: (value) {
                    _fieldFocusChange(context, descFocus!, startsFocus);
                  },
                  isLightTheme: isLightTheme,
                  isRequired: false,
                ),
                SizedBox(height: 15.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: DateRangePickerWidget(
                    dateController: startsController, // Show both dates here
                    title: AppLocalizations.of(context)!.starts,

                    titlestartend: AppLocalizations.of(
                      context,
                    )!.selectstartenddate,
                    selectedDateEnds: selectedDateEnds,
                    selectedDateStarts: selectedDateStarts,
                    isLightTheme: isLightTheme,
                    onTap: (start, end) {
                      setState(() {
                        selectedDateEnds = end;
                        selectedDateStarts = start!;

                        // Update the startsController to show BOTH dates
                        startsController.text =
                            "${dateFormatConfirmed(selectedDateStarts, context)} - ${dateFormatConfirmed(selectedDateEnds!, context)}";

                        // Keep fromDate and toDate separately for API submission
                        fromDate = dateFormatConfirmedToApi(start);
                        toDate = dateFormatConfirmedToApi(end!);
                      });
                    },
                  ),
                ),

                // startsField(isLightTheme),
                SizedBox(height: 15.h),
                // Padding(
                //   padding:  EdgeInsets.symmetric(horizontal: 18.w),
                //   child: DatePickerWidget(
                //     dateController: endController,
                //     title: AppLocalizations.of(context)!.ends,
                //     isLightTheme: isLightTheme,
                //   ),
                // ),
                Divider(),
                SizedBox(height: 15.h),

                SizedBox(height: 15.h),

                // tagsField(isLightTheme),
                SizedBox(height: 15.h),
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
                // CreateCancelButtom(),
              ],
            );
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
                        ? AppLocalizations.of(context)!.editwork
                        : AppLocalizations.of(context)!.creatework,
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
