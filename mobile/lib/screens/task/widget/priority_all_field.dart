import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/screens/widgets/no_data.dart';
import '../../../bloc/theme/theme_bloc.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../widgets/custom_cancel_create_button.dart';
import '../../../config/constants.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class PriorityAllField extends StatefulWidget {
  final bool isCreate;
  final String? name;
  final int? priority;
  final bool? isRequired;
  final int? index;
  final Function(String, int) onSelected;

  const PriorityAllField({
    super.key,
    this.name,
    required this.isCreate,
    required this.priority,
    this.isRequired,
    required this.index,
    required this.onSelected,
  });

  @override
  State<PriorityAllField> createState() => _PriorityAllFieldState();
}

class _PriorityAllFieldState extends State<PriorityAllField> {
  String? projectsname;
  String? name;
  int? projectsId;
  final TextEditingController _prioritySearchController =
      TextEditingController();

  // ✅ late хассан, default value өгсөн
  List<Map<String, dynamic>> priorities = [];
  List<Map<String, dynamic>> filteredPriorities = [];

  @override
  void initState() {
    super.initState();

    name = widget.name;
    if (!widget.isCreate) {
      projectsId = widget.priority;
    }

    // ✅ Constant priorities-ийг авах (error handling-тэй)
    try {
      priorities = getContstantPriorities();
      filteredPriorities = List.from(priorities); // ✅ Copy хийх
    } catch (e) {
      if (kDebugMode) {
        logger.d('Error loading priorities: $e');
      }
      // ✅ Fallback priorities
      priorities = [
        {'value': 1, 'label': 'Low'},
        {'value': 2, 'label': 'Medium'},
        {'value': 3, 'label': 'High'},
        {'value': 4, 'label': 'Urgent'},
      ];
      filteredPriorities = List.from(priorities);
    }
  }

  String _getDisplayText() {
    if (projectsname != null && projectsname!.isNotEmpty) {
      return projectsname!;
    }

    if (!widget.isCreate && widget.name != null && widget.name!.isNotEmpty) {
      return widget.name!;
    }

    return AppLocalizations.of(context)!.selectpriority;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPriorities = List.from(priorities); // ✅ Copy хийх
      } else {
        filteredPriorities = priorities
            .where(
              (p) => (p['label'] ?? '').toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;
    bool isLightTheme = currentTheme is LightThemeState;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              CustomText(
                text: AppLocalizations.of(context)!.priority,
                color: Theme.of(context).colorScheme.textClrChange,
                size: 16,
                fontWeight: FontWeight.w700,
              ),
              if (widget.isRequired == true)
                CustomText(
                  text: "*",
                  color: AppColors.red,
                  size: 15,
                  fontWeight: FontWeight.w400,
                ),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        InkWell(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: _showPriorityDialog,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            height: 40.h,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: _getDisplayText(),
                  fontWeight: FontWeight.w500,
                  size: 14.sp,
                  color: Theme.of(context).colorScheme.textClrChange,
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPriorityDialog() {
    _prioritySearchController.clear();
    filteredPriorities = List.from(priorities);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.alertBoxBackGroundColor,
            title: Center(
              child: Column(
                children: [
                  CustomText(
                    text: AppLocalizations.of(context)!.selectpriority,
                    fontWeight: FontWeight.w800,
                    size: 20,
                    color: Theme.of(context).colorScheme.whitepurpleChange,
                  ),
                  const Divider(),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 35.h,
                    child: TextField(
                      controller: _prioritySearchController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: (35.h - 20.sp) / 2,
                          horizontal: 10.w,
                        ),
                        hintText: AppLocalizations.of(context)!.search,
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
                        setDialogState(() {
                          _onSearchChanged(value);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            content: Container(
              constraints: BoxConstraints(maxHeight: 400.h),
              width: MediaQuery.of(context).size.width,
              child: filteredPriorities.isEmpty
                  ? NoData(isImage: true)
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredPriorities.length,
                      itemBuilder: (context, index) {
                        final priority = filteredPriorities[index];
                        final isSelected = priority['value'] == projectsId;

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 2.h,
                            horizontal: 20.w,
                          ),
                          child: InkWell(
                            highlightColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            onTap: () {
                              setState(() {
                                projectsname = priority['label'];
                                projectsId = priority['value'];
                              });

                              widget.onSelected(
                                priority['label'] ?? '',
                                priority['value'] ?? 0,
                              );

                              Navigator.pop(context);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.purpleShade
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                              height: 40.h,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    CustomText(
                                      text: priority['label'] ?? '',
                                      fontWeight: FontWeight.w500,
                                      size: 18,
                                      color: isSelected
                                          ? AppColors.purple
                                          : Theme.of(
                                              context,
                                            ).colorScheme.textClrChange,
                                    ),
                                    if (isSelected)
                                      const HeroIcon(
                                        HeroIcons.checkCircle,
                                        style: HeroIconStyle.solid,
                                        color: AppColors.purple,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: CreateCancelButtom(
                  title: "OK",
                  onpressCancel: () {
                    _prioritySearchController.clear();
                    Navigator.pop(context);
                  },
                  onpressCreate: () {
                    _prioritySearchController.clear();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _prioritySearchController.dispose();
    super.dispose();
  }
}
