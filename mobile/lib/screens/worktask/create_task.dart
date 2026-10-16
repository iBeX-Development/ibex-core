import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ibex/bloc/worktask/task_bloc.dart';
import 'package:ibex/bloc/theme/theme_state.dart';
import 'package:ibex/bloc/worktask_id/taskid_state.dart';
import 'package:ibex/config/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ibex/utils/widgets/back_arrow.dart';
import '../../bloc/worktask/task_event.dart';
import '../../bloc/worktask/task_state.dart';
import '../../bloc/worktask_id/taskid_bloc.dart';
import '../../bloc/worktask_id/taskid_event.dart';
import '../../bloc/theme/theme_bloc.dart';
import '../../config/constants.dart';
import '../../data/model/worktask/task_model.dart';
import '../../routes/routes.dart';
import '../../utils/widgets/my_theme.dart';
import '../../utils/widgets/toast_widget.dart';

import '../style/design_config.dart';
import '../widgets/custom_cancel_create_button.dart';
import '../widgets/custom_textfields/custom_textfield.dart';
import 'custom_fields_tasks/custom_field_task_page.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import 'package:ibex/screens/task/widget/const_list.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class CreateWorkTask extends StatefulWidget {
  final bool? isCreate;
  final bool? fromDetail;
  final String? title;
  final String? project;
  final String? user;
  final String? status;
  final bool? isSubTask;
  final int? parentId;
  final String? priority;
  final int? priorityId;
  final int? statusId;
  final int? id;
  final int? canClientDiscuss;
  final int? projectID;
  final String? desc;
  final String? note;
  final String? start;
  final String? end;
  final List<WorkTasks>? taskcreate;
  final List<WorkTaskUsers>? userList;
  final List<String>? users;
  final List<int>? usersid;
  final int? index;
  final WorkTasks? tasks;
  final String? billingType;
  final WorkTasks? tasksModel; // Remove `required` to allow null
  CreateWorkTask({
    super.key,
    this.isCreate,
    this.fromDetail,
    this.project,
    this.userList,
    this.tasks,
    this.title,
    this.usersid,
    this.parentId,
    this.isSubTask,
    this.priority,
    this.billingType,
    this.tasksModel,
    this.priorityId,
    this.projectID,
    this.users,
    this.canClientDiscuss,
    this.id,
    this.statusId,
    this.user,
    this.status,
    this.desc,
    this.note,
    this.start,
    this.end,
    this.taskcreate,
    this.index,
  });

  @override
  State<CreateWorkTask> createState() => _CreateWorkWorkTaskState();
}

class _CreateWorkWorkTaskState extends State<CreateWorkTask> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController numberOfOccurencesController = TextEditingController();
  TextEditingController projectController = TextEditingController();
  TextEditingController userController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController priorityController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  TextEditingController startsController = TextEditingController();
  TextEditingController startRecurrenceController = TextEditingController();
  TextEditingController endController = TextEditingController();
  TextEditingController startController = TextEditingController();

  DateTime? selectedDateStarts = DateTime.now();
  DateTime? selectedDateStartRecurrence = DateTime.now();
  DateTime? selectedDateEnds = DateTime.now();
  String? toPassStartDate = "";
  String? fromdate;
  String? billingType;
  String frequencyType = "daily";
  String taskType = "Check";
  int? dayOftheMonth;
  int? dayOftheMonthRecurring;
  int? monthOftheYearRecurring;
  int? dayOftheWeekRecurring;
  int? dayOftheWeek;

  ValueNotifier<String?> recurrencyFrequency = ValueNotifier<String?>("daily");

  int? monthOfYear;

  String? todate;
  String? selectedCategory;
  bool canClientDiscussWith = false;

  ValueNotifier<bool> enableRecurringTask = ValueNotifier<bool>(false);

  ValueNotifier<bool> enableReminder = ValueNotifier<bool>(false);

  List<String>? usersName;
  List<int>? selectedusersNameId;
  String? selectedStatus;
  int? selectedStatusId;
  late CustomFieldTaskPage _customFieldPageTask;
  final GlobalKey<CustomFieldTaskPageState> _customFieldTaskPageKey =
      GlobalKey<CustomFieldTaskPageState>(); // Add GlobalKey

  bool? isLoading;
  int? selectedPriorityId;
  String? selectedPriority;
  int? selectedID;

  String? selectedWork = '';

  String? selectedUser = '';
  // String selectedStatus = '';

  String? formattedStartDate;
  String? formattedEndDate;
  int? idStatus;
  int? idPriority;
  double? _value = 0;
  double valueInProgress = 0;
  TimeOfDay _timestart = const TimeOfDay(hour: 9, minute: 00);
  String? formattedTimeStart;
  void _handleAccessSelected(String type) {
    setState(() {
      billingType = type;
    });
  }

  void _handleTaskTypeSelected(String type) {
    setState(() {
      taskType = type;
    });
  }

  void _handleDayOfTheMonthSelected(int type) {
    setState(() {
      dayOftheMonth = type;
    });
  }

  void _handleDayOfTheMonthRecurringSelected(int type) {
    setState(() {
      dayOftheMonthRecurring = type;
    });
  }

  void _handleDayOfTheWeekSelected(int type) {
    setState(() {
      dayOftheWeek = type;
    });
  }

  void _handleDayOfTheWeekRecurringSelected(int type) {
    setState(() {
      dayOftheWeekRecurring = type;
    });
  }

  void _handleMonthOfYearSelected(int type) {
    setState(() {
      monthOfYear = type;
    });
  }

  void _handleRecurrencyFrequencySelected(String type) {
    setState(() {
      recurrencyFrequency.value = type;
    });
  }

  void _handleWorkSelected(String category, int catID) {
    setState(() {
      selectedCategory = category;
      selectedID = catID;
    });
  }

  void _selectstartTime() async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: _timestart,
    );

    if (newTime != null) {
      setState(() {
        _timestart = newTime;

        // Format as HH:MM:SS
        formattedTimeStart =
            '${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void canClientdiscussHandle(bool status) {
    setState(() {
      canClientDiscussWith = status;
    });
  }

  void enableRecurringTaskHandle(bool status) {
    setState(() {
      enableRecurringTask.value = status;
    });
  }

  void enableReminderHandle(bool status) {
    setState(() {
      enableReminder.value = status;
    });
  }

  void _handlePrioritySelected(String category, int catId) {
    setState(() {
      selectedPriority = category;
      selectedPriorityId = catId;
    });
  }

  void _handleStatusSelected(String category, int catId) {
    setState(() {
      selectedStatus = category;
      selectedStatusId = catId;
    });
  }

  void _handleTypeSelected(String category, int catId) {
    setState(() {
      selectedStatus = category;
      selectedStatusId = catId;
    });
  }

  void _onCreate() {
    List<String> missingFields = [];

    // Check standard fields with detailed logging

    if (titleController.text.isEmpty) {
      missingFields.add(AppLocalizations.of(context)!.title);
    }

    // if (selectedStatusId == null) {
    //   missingFields.add(AppLocalizations.of(context)!.status);
    // }

    if (selectedID == null) {
      missingFields.add(AppLocalizations.of(context)!.work);
    }

    // Check reminder fields with detailed logging
    if (enableReminder.value == true) {
      if (frequencyType.isEmpty ||
          formattedTimeStart == null ||
          formattedTimeStart!.trim().isEmpty) {
        missingFields.add(
          AppLocalizations.of(context)!.pleasefillfrequencyandtime,
        );
      }
    }

    // Check recurring task fields with detailed logging
    if (enableRecurringTask.value == true) {
      if (recurrencyFrequency.value == null ||
          recurrencyFrequency.value!.isEmpty ||
          numberOfOccurencesController.text.trim().isEmpty ||
          toPassStartDate == null) {
        missingFields.add(
          AppLocalizations.of(context)!.pleasefillrecurringfields,
        );
      }
    }

    // Custom fields validation with detailed logging
    final customFieldValues = _customFieldTaskPageKey.currentState
        ?.getFieldValues();

    bool customFieldsValid =
        _customFieldTaskPageKey.currentState?.validateFields() ?? true;
    if (!customFieldsValid) {
      missingFields.add("Custom field(s)");
    }

    if (missingFields.isEmpty) {
      String formattedTime = "";
      if (formattedTimeStart != null) {
        formattedTime = formattedTimeStart!.substring(0, 5);
      }

      // ✅ All fields validated, trigger the WorkTaskCreated event
      context.read<WorkTaskBloc>().add(
        WorkTaskCreated(
          isSubtask: widget.isSubTask ?? false,
          parentId: widget.parentId ?? 0,
          canClientDiscuss: canClientDiscussWith ? 0 : 1,
          title: titleController.text,
          statusId: selectedStatusId ?? 0,
          priorityId: selectedPriorityId ?? 0,
          startDate: fromdate ?? "",
          dueDate: todate ?? "",
          desc: descController.text,
          project: selectedID ?? 0,
          userId: selectedusersNameId ?? [],
          template_type: taskType,
          frequencyType: frequencyType.toLowerCase(),
          recurringFrequencyType:
              recurrencyFrequency.value?.toLowerCase() ?? "",
          note: noteController.text,
          enableRecurringTask: enableRecurringTask.value ? "on" : "off",
          enableReminder: enableReminder.value ? "on" : "off",
          billingType: billingType?.toLowerCase() ?? "none",
          completionPercentage: valueInProgress.toInt(),
          dayOfWeek: dayOftheWeek,
          dayOfMonth: dayOftheWeek,
          timeOfDay: formattedTime,
          recurrenceDayOfWeek: dayOftheWeekRecurring,
          recurrenceDayOfMonth: dayOftheMonthRecurring,
          recurrenceMonthOfYear: monthOftheYearRecurring,
          recurrenceStartsFrom: toPassStartDate,
          recurrenceOccurrences:
              numberOfOccurencesController.text.trim().isNotEmpty
              ? int.parse(numberOfOccurencesController.text.trim())
              : 0,
          customFieldValues: {},
        ),
      );
      // ✅ Set loading state
      setState(() {
        isLoading = true;
      });
      context.read<WorkTaskBloc>().stream.listen((event) {
        if (event is WorkTaskCreateSuccess) {
          // if (mounted) {
          //   // Navigator.of(context).push(
          //   //   CupertinoPageRoute(
          //   //     builder: (context) =>
          //   //         const DashBoard(initialIndex: 2), // Navigate to index 1
          //   //   ),
          //   // );
          //   isLoading = false;
          //   flutterToastCustom(
          //     msg: AppLocalizations.of(context)!.createdsuccessfully,
          //     color: AppColors.primary,
          //   );
          //   Navigator.pop(context);
          //   context
          //       .read<WorkTaskBloc>()
          //       .add(AllWorkTaskListOnTask(projectId: [selectedID ?? 0]));
          // }
          if (mounted) {
            // ✅ Show success toast
            flutterToastCustom(
              msg: AppLocalizations.of(context)!.createdsuccessfully,
              color: AppColors.primary,
            );

            // ✅ Refresh task list BEFORE popping
            context.read<WorkTaskBloc>().add(
              AllWorkTaskListOnTask(projectId: [selectedID ?? 0]),
            );

            // ✅ Delay pop to ensure event is processed
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        }
        if (event is WorkTaskCreateError) {
          flutterToastCustom(msg: event.errorMessage);
        }
      });
    } else {
      // ❌ Show missing fields as toast
      if (kDebugMode) {
        logger.d("Validation failed. Missing required fields: $missingFields");
      }
      String errorMessage =
          "${AppLocalizations.of(context)!.pleasefilltherequiredfield}: ${missingFields.join(', ')}";
      flutterToastCustom(msg: errorMessage);
    }
  }

  void _onWorkUpdateTask() {
    isLoading = true;

    if (enableReminder.value == true) {
      if (frequencyType == "" ||
          formattedTimeStart == null ||
          formattedTimeStart!.trim().isEmpty) {
        flutterToastCustom(
          msg: AppLocalizations.of(context)!.pleasefillfrequencyandtime,
        );
        return;
      }
    }

    // Check for recurring task fields
    if (enableRecurringTask.value == true) {
      if (recurrencyFrequency.value == null ||
          recurrencyFrequency.value.toString().isEmpty ||
          numberOfOccurencesController.text.trim().isEmpty ||
          toPassStartDate == null) {
        flutterToastCustom(
          msg: AppLocalizations.of(context)!.pleasefillrecurringfields,
        );
        return;
      }
    }
    final customFieldValues = _customFieldPageTask.getFieldValues();
    // Handle time formatting safely
    String? formattedTime;
    if (formattedTimeStart != null && formattedTimeStart!.isNotEmpty) {
      // Check if time format is HH:mm or HH:mm:ss
      if (formattedTimeStart!.length > 5) {
        formattedTime = formattedTimeStart!.substring(0, 5); // Take only HH:mm
      } else {
        formattedTime =
            formattedTimeStart; // Use as is if already in HH:mm format
      }
    }
    context.read<WorkTaskBloc>().add(
      WorkUpdateTask(
        isSubtask: widget.isSubTask ?? false,
        parentId: widget.parentId ?? 0,
        enableRecurringTask: enableRecurringTask.value == false ? "off" : "on",
        frequencyType: frequencyType,
        template_type: taskType,
        recurringFrequencyType: recurrencyFrequency.value,
        enableReminder: enableReminder.value == false ? "off" : "on",
        billingType: billingType?.toLowerCase().replaceAll(' ', '-') ?? "none",

        completionPercentage: valueInProgress.toInt(),
        canClientDiscuss: canClientDiscussWith ? 0 : 1,
        id: widget.id!,
        title: titleController.text,
        statusId: selectedStatusId == null
            ? widget.statusId!
            : selectedStatusId!,
        priorityId: selectedPriorityId == null
            ? widget.priorityId!
            : selectedPriorityId!,
        startDate: fromdate ?? widget.start!,
        desc: descController.text,
        userId: selectedusersNameId!,
        note: noteController.text,
        dueDate: todate ?? widget.end!,
        dayOfWeek: dayOftheWeek,

        dayOfMonth: dayOftheWeek,
        timeOfDay: formattedTime,
        recurrenceDayOfWeek: dayOftheWeekRecurring,
        recurrenceDayOfMonth: dayOftheMonthRecurring,
        recurrenceMonthOfYear: monthOftheYearRecurring,
        recurrenceStartsFrom: toPassStartDate,
        customFieldValues: {},
        // recurrenceOccurrences: numberOfOccurencesController.text.to,
      ),
    );

    // ✅ Set loading state
    setState(() {
      isLoading = true;
    });
    context.read<WorkTaskBloc>().stream.listen((event) {
      if (event is WorkTaskEditSuccess) {
        if (mounted) {
          flutterToastCustom(
            msg: AppLocalizations.of(context)!.updatedsuccessfully,
            color: AppColors.primary,
          );

          if (widget.fromDetail == true) {
            // Refresh detail page
            BlocProvider.of<WorkTaskidBloc>(
              context,
            ).add(WorkTaskIdListId(widget.id));
          } else {
            // Refresh list
            context.read<WorkTaskBloc>().add(
              AllWorkTaskListOnTask(projectId: [selectedID ?? 0]),
            );
          }

          // ✅ Delay pop
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
        // if (mounted) {
        //   isLoading = false;
        //   if (widget.fromDetail == true) {
        //     BlocProvider.of<WorkTaskidBloc>(
        //       context,
        //     ).add(WorkTaskIdListId(widget.id));
        //   } else {
        //     context
        //         .read<WorkTaskBloc>()
        //         .add(AllWorkTaskListOnTask(projectId: [selectedID ?? 0]));
        //     Navigator.pop(context);

        //     // Navigator.of(context).push(
        //     //   CupertinoPageRoute(
        //     //     builder: (context) =>
        //     //         const DashBoard(initialIndex: 2), // Navigate to index 1
        //     //   ),
        //     // );
        //   }

        //   flutterToastCustom(
        //     msg: AppLocalizations.of(context)!.updatedsuccessfully,
        //     color: AppColors.primary,
        //   );
        //   router.pop(context);
        // }
      } else if (event is WorkTaskEditError) {
        if (mounted) {
          flutterToastCustom(msg: event.errorMessage);
          context.read<WorkTaskBloc>().add(AllWorkTaskList());
        }
      }
    });

    //   return;
    // }
    // context.read<WorkTaskBloc>().add(AllWorkTaskList());
    // Navigator.pop(context);
    // CustomToast(message: "Fill all the fields");
  }

  FocusNode? titleFocus,
      budgetFocus,
      descFocus,
      startsFocus,
      endFocus = FocusNode();
  List tags = [
    "development",
    "E-Commerce",
    "Marketing",
    "Marketing",
    "Marketing",
  ];

  void _handleUsersSelected(List<String> category, List<int> catId) {
    setState(() {
      usersName = category;
      selectedusersNameId = catId;
    });
  }

  bool? token;
  @override
  void initState() {
    if (widget.isCreate == false) {
      String? formattedstart;
      String? formattedend;
      String? formattedRecurstart;

      enableReminder.value = widget.tasksModel!.enableReminder == 0
          ? false
          : true;
      enableRecurringTask.value = widget.tasksModel!.enableRecurringTask == 0
          ? false
          : true;
      frequencyType = widget.tasksModel!.frequencyType ?? "".toLowerCase();
      taskType =
          widget.tasksModel!.template_type?.toString() ?? "".toLowerCase();
      recurrencyFrequency.value =
          widget.tasksModel!.recurrenceFrequency ?? "".toLowerCase();
      if (widget.tasksModel!.recurrenceStartsFrom != null) {
        DateTime parsedDateEnd = parseDateStringFromApi(
          widget.tasksModel!.recurrenceStartsFrom!,
        );
        formattedRecurstart = dateFormatConfirmed(parsedDateEnd, context);
        // fromdate = f
        selectedDateStartRecurrence = parsedDateEnd;
      }

      if (widget.tasksModel!.timeOfDay != null) {
        DateTime parsedDateEnd = parseDateStringFromApi(widget.end!);
        formattedend = dateFormatConfirmed(parsedDateEnd, context);
        _timestart = TimeOfDay.fromDateTime(parsedDateEnd);
        formattedTimeStart = widget.tasksModel!.timeOfDay;
      }
      formattedTimeStart = widget.tasksModel!.timeOfDay;
      recurrencyFrequency.value =
          widget.tasksModel!.recurrenceFrequency ?? "".toLowerCase();
      numberOfOccurencesController.text = widget
          .tasksModel!
          .recurrenceOccurrences
          .toString();
      selectedusersNameId = widget.usersid;

      if (widget.start != null &&
          widget.start!.isNotEmpty &&
          widget.start != "") {
        DateTime parsedDate = parseDateStringFromApi(widget.start!);
        formattedstart = dateFormatConfirmed(parsedDate, context);
        selectedDateStarts = parseDateStringFromApi(widget.start!);
      }
      if (widget.end != null && widget.end!.isNotEmpty && widget.end != "") {
        DateTime parsedDate = parseDateStringFromApi(widget.end!);
        formattedend = dateFormatConfirmed(parsedDate, context);
        selectedDateEnds = parseDateStringFromApi(widget.end!);
      }
      if (widget.tasksModel!.recurrenceStartsFrom != null &&
          widget.tasksModel!.recurrenceStartsFrom!.isNotEmpty &&
          widget.tasksModel!.recurrenceStartsFrom != "") {
        DateTime parsedDate = parseDateStringFromApi(
          widget.tasksModel!.recurrenceStartsFrom!,
        );
        formattedRecurstart = dateFormatConfirmed(parsedDate, context);
        selectedDateStartRecurrence = parseDateStringFromApi(
          widget.tasksModel!.recurrenceStartsFrom!,
        );
      }
      if (widget.canClientDiscuss == 1) {
        canClientDiscussWith = true;
      } else {
        canClientDiscussWith = false;
      }
      // if(){}else{}

      titleController = TextEditingController(text: widget.title);
      projectController = TextEditingController(text: widget.project);
      selectedCategory = widget.project;
      selectedID = widget.projectID;
      selectedStatusId = widget.statusId;
      selectedPriority = widget.priority;
      selectedStatus = widget.status;
      usersName = widget.users;
      startsController = TextEditingController(
        text: (formattedstart != null && formattedend != null)
            ? "$formattedstart - $formattedend"
            : '',
      );
      startRecurrenceController = TextEditingController(
        text: formattedRecurstart != null ? formattedRecurstart : "",
      );

      descController = TextEditingController(
        text: removeHtmlTags(widget.desc!),
      );
      noteController = TextEditingController(text: widget.note);
      _customFieldPageTask = CustomFieldTaskPage(
        tasksModel: widget.tasksModel!,
        isCreate: widget.isCreate!,
        key: _customFieldTaskPageKey,
      );
    } else {
      // titleController = TextEditingController();
      titleController = TextEditingController(text: widget.title);
      projectController = TextEditingController(text: widget.project);
      selectedCategory = widget.project;
      selectedID = widget.projectID;
      selectedStatusId = widget.statusId;
      selectedPriority = widget.priority;
      selectedStatus = widget.status;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    for (var i in widget.userList!) {
      selectedusersNameId!.add(i.id!);
    }
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;

    bool isLightTheme = currentTheme is LightThemeState;
    return BlocListener<WorkTaskBloc, WorkTaskState>(
      listener: (context, state) {
        if (state is WorkTaskCreateSuccess) {
          if (mounted) {
            // ✅ Show success toast
            flutterToastCustom(
              msg: AppLocalizations.of(context)!.createdsuccessfully,
              color: AppColors.primary,
            );

            // ✅ Refresh task list BEFORE popping
            context.read<WorkTaskBloc>().add(
              AllWorkTaskListOnTask(projectId: [selectedID ?? 0]),
            );

            // ✅ Delay pop to ensure event is processed
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        }

        if (state is WorkTaskCreateError) {
          if (kDebugMode) {
            logger.d("❌ WorkTaskCreateError: ${state.errorMessage}");
          }
          flutterToastCustom(msg: state.errorMessage);
        }

        if (state is WorkTaskEditSuccess) {
          if (mounted) {
            flutterToastCustom(
              msg: AppLocalizations.of(context)!.updatedsuccessfully,
              color: AppColors.primary,
            );

            if (widget.fromDetail == true) {
              // Refresh detail page
              BlocProvider.of<WorkTaskidBloc>(
                context,
              ).add(WorkTaskIdListId(widget.id));
            } else {
              // Refresh list
              context.read<WorkTaskBloc>().add(
                AllWorkTaskListOnTask(projectId: [selectedID ?? 0]),
              );
            }

            // ✅ Delay pop
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          }
        }

        if (state is WorkTaskEditError) {
          if (kDebugMode) {
            logger.d("❌ WorkTaskEditError: ${state.errorMessage}");
          }
          flutterToastCustom(msg: state.errorMessage);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (!didPop) {
            if (widget.fromDetail == true && widget.isCreate == false) {
              BlocProvider.of<WorkTaskidBloc>(
                context,
              ).add(WorkTaskIdListId(widget.id));
              router.pop();
            } else {
              router.pop();
            }
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.backGroundColor,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _createEditAppbar(isLightTheme),
                SizedBox(height: 30.h),
                _taskBody(isLightTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _taskBody(isLightTheme) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: BlocBuilder<WorkTaskBloc, WorkTaskState>(
          builder: (context, state) {
            if (state is WorkTaskLoading) {
              return _form([], isLightTheme, false);
            }
            if (state is WorkTaskCreateSuccessLoading) {
              return _form([], isLightTheme, false);
            }
            if (state is WorkTaskEditSuccessLoading) {
              return _form([], isLightTheme, false);
            }
            if (state is WorkTaskCreateError) {
              flutterToastCustom(msg: state.errorMessage);
              context.read<WorkTaskBloc>().add(AllWorkTaskList());

              router.pop(context);
            }
            if (state is WorkTaskError) {
              flutterToastCustom(msg: state.errorMessage);
              context.read<WorkTaskBloc>().add(AllWorkTaskList());

              router.pop(context);
            }
            if (state is AllWorkTaskSuccess) {
              return _form([], isLightTheme, false);
            } else if (state is WorkTaskPaginated ||
                state is WorkTaskidWithId) {
              List<int> id = [];

              if (widget.isCreate == false) {
                // ✅ state.task хоосон эсвэл null эсэхийг шалгах
                final tasks = state is WorkTaskPaginated
                    ? state.task
                    : (state as WorkTaskidWithId).task;

                if (tasks.isNotEmpty) {
                  for (var task in tasks) {
                    // ✅ task.users null эсвэл хоосон эсэхийг шалгах
                    if (task.users != null && task.users!.isNotEmpty) {
                      for (var user in task.users!) {
                        // ✅ user.id null эсэхийг шалгах
                        if (user.id != null) {
                          id.add(user.id!);
                        }
                      }
                    }
                  }
                }
              }

              return _form(
                state is WorkTaskPaginated
                    ? state.task
                    : (state as WorkTaskidWithId).task,
                isLightTheme,
                true,
              );
            } else if (state is WorkTaskCreateSuccess) {
              return _form(state, isLightTheme, true);
            }
            // ✅ WorkTaskInitial state-ийг шалгах
            else if (state is WorkTaskInitial) {
              return _form(state, isLightTheme, false);
            }
            return Container();
          },
        ),
      ),
    );
  }

  Widget _createEditAppbar(isLightTheme) {
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
                      BlocProvider.of<WorkTaskidBloc>(
                        context,
                      ).add(WorkTaskIdListId(widget.id));
                      router.pop();
                    } else {
                      context.read<WorkTaskBloc>().add(AllWorkTaskList());
                      Navigator.pop(context);

                      // Navigator.of(context).push(
                      //   CupertinoPageRoute(
                      //     builder: (context) => const DashBoard(
                      //       initialIndex: 2,
                      //     ), // Navigate to index 1
                      //   ),
                      // );
                    }
                  },
                  child: BackArrow(
                    title: widget.isCreate == false
                        ? AppLocalizations.of(context)!.edittask
                        : AppLocalizations.of(context)!.createtask,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _form(tasks, isLightTheme, isPaginatedState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextFields(
          title: AppLocalizations.of(context)!.title,
          hinttext: AppLocalizations.of(context)!.pleaseentertitle,
          controller: titleController,
          onSaved: (value) {},
          onFieldSubmitted: (value) {},
          isLightTheme: isLightTheme,
          isRequired: true,
        ),

        // SizedBox(height: 15.h),
        // StatusField(
        //   isRequired: true,
        //   status: widget.statusId,
        //   isCreate: widget.isCreate!,
        //   name: selectedStatus ?? "",
        //   index: widget.index!,
        //   onSelected: _handleStatusSelected,
        // ),
        SizedBox(height: 15.h),

        BilingListField(
          access: widget.tasksModel!.template_type?.toString() ?? taskType,
          isRequired: true,
          isCreate: widget.isCreate!,
          name: taskType,
          from: "taskType",
          onSelected: _handleTaskTypeSelected,
        ),
        SizedBox(height: 15.h),

        // selectedID != null && selectedID != ""
        //     ? UsersFieldWork(
        //         projectId: widget.isCreate == true
        //             ? selectedID!
        //             : widget.tasksModel!.projectId!,
        //         isCreate: widget.isCreate!,
        //         usersname: usersName ?? [],
        //         project: const [],
        //         usersid: widget.usersid!,
        //         onSelected: _handleUsersSelected,
        //       )
        //     : SizedBox(),
        SizedBox(height: 15.h),
        CustomTextFields(
          height: 112.h,
          keyboardType: TextInputType.multiline,
          title: AppLocalizations.of(context)!.description,
          hinttext: AppLocalizations.of(context)!.pleaseenterdescription,
          controller: descController,
          onSaved: (value) {},
          onFieldSubmitted: (value) {},
          isLightTheme: isLightTheme,
          isRequired: false,
        ),

        SizedBox(height: 15.h),

        Divider(),

        SizedBox(height: 15.h),
        CreateCancelButtom(
          isLoading: false,
          isCreate: widget.isCreate,
          onpressCancel: () {
            Navigator.pop(context);
          },
          onpressCreate: widget.isCreate == true
              ? () async {
                  // isPaginatedState == true ? _onCreate() : null;
                  _onCreate();
                  // Navigator.pop(context);
                }
              : () {
                  // isPaginatedState == true ? _onWorkUpdateTask() : null;
                  _onWorkUpdateTask();
                },
        ),
        SizedBox(height: 25.h),
      ],
    );
  }
}
