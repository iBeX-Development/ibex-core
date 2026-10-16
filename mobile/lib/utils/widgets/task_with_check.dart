import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import 'my_theme.dart';

class TaskCheckListDetails extends StatefulWidget {
  final int? id;
  final String? startDate;
  final String? endDate;
  final List<String>? clientList;
  final List<String>? userList;
  final String title;
  final String? workType;
  final bool? isCompleted;
  final bool? addSubTask;
  final bool isEditable; // ✅ Team leader эсэхийг шалгах
  final VoidCallback? onTap;
  final Function(bool)? onCheckChanged;
  final VoidCallback? onCreateSubTask; // ✅ Шинэ callback нэмэх

  const TaskCheckListDetails({
    Key? key,
    this.id,
    this.startDate,
    this.endDate,
    this.clientList,
    this.userList,
    required this.title,
    this.isCompleted,
    this.addSubTask,
    this.workType,
    this.isEditable = true, // ✅ Default: editable
    this.onTap,
    this.onCheckChanged,
    this.onCreateSubTask, // ✅ Нэмэх
  }) : super(key: key);

  @override
  State<TaskCheckListDetails> createState() => _TaskCheckListDetailsState();
}

class _TaskCheckListDetailsState extends State<TaskCheckListDetails> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.isCompleted ?? false;
  }

  @override
  void didUpdateWidget(TaskCheckListDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Update local state when parent updates the prop
    if (widget.isCompleted != oldWidget.isCompleted) {
      setState(() {
        _isChecked = widget.isCompleted ?? false;
      });
    }
  }

  bool get isReadOnly =>
      widget.workType?.toLowerCase() == 'completed' ||
      !widget.isEditable; // ✅ Team member бол readonly

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final isLightTheme = themeBloc.currentThemeState is LightThemeState;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.lightWhite,
        borderRadius: BorderRadius.circular(17.4.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.gray,
          width: 1,
        ),
        boxShadow: [
          isLightTheme ? MyThemes.lightThemeShadow : MyThemes.darkThemeShadow,
        ],
      ),
      child: Row(
        children: [
          // ✅ Checkbox
          SizedBox(
            width: 20.w,
            height: 20.h,
            child: Checkbox(
              value: _isChecked,
              activeColor: isReadOnly
                  ? AppColors.greyColor
                      .withValues(alpha: 0.5) // ✅ Disabled color
                  : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
              side: BorderSide(
                color: isReadOnly
                    ? AppColors.greyColor
                        .withValues(alpha: 0.3) // ✅ Disabled border
                    : Theme.of(context)
                        .colorScheme
                        .black
                        .withValues(alpha: 0.6),
                width: 1.5,
              ),
              onChanged: isReadOnly
                  ? null // ✅ Disable checkbox if completed
                  : (value) {
                      setState(() {
                        _isChecked = value ?? false;
                      });
                      widget.onCheckChanged?.call(_isChecked);
                    },
            ),
          ),

          SizedBox(width: 10.w),

          // ✅ Title (clickable)
          Expanded(
            child: InkWell(
              onTap: isReadOnly
                  ? null
                  : widget.onTap, // ✅ Disable tap if completed
              child: CustomText(
                text: widget.title,
                size: 14.sp,
                fontWeight: FontWeight.w500,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                color: _isChecked || isReadOnly
                    ? Theme.of(context)
                        .colorScheme
                        .textClrChange
                        .withValues(alpha: 0.5) // ✅ Faded color
                    : Theme.of(context).colorScheme.textClrChange,
                textDecoration: _isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // ✅ Plus icon with border (clickable)
          if (widget.addSubTask == true)
            InkWell(
              onTap: isReadOnly ? null : widget.onCreateSubTask,
              borderRadius: BorderRadius.circular(6.r),
              child: Container(
                width: 20.w,
                height: 20.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isReadOnly
                        ? AppColors.greyColor
                            .withValues(alpha: 0.3) // ✅ Disabled border
                        : AppColors.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  color: isReadOnly
                      ? AppColors.greyColor
                          .withValues(alpha: 0.05) // ✅ Disabled bg
                      : AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: HeroIcon(
                    isReadOnly
                        ? HeroIcons.lockClosed
                        : HeroIcons.plus, // ✅ Different icon
                    size: 12.sp,
                    style: HeroIconStyle.outline,
                    color: isReadOnly
                        ? AppColors.greyColor
                            .withValues(alpha: 0.5) // ✅ Disabled color
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
