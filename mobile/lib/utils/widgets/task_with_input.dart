import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/theme/theme_state.dart';
import '../../bloc/theme/theme_bloc.dart';
import 'my_theme.dart';

class TaskInputListDetails extends StatefulWidget {
  final int? id;
  final String? startDate;
  final String? endDate;
  final List<String>? clientList;
  final List<String>? userList;
  final String title;
  final String? value;
  final String? workType;
  final VoidCallback? onTap;
  final bool? isReadOnly;
  final bool? addSubTask;
  final bool isEditable; // ✅ Team leader эсэхийг шалгах

  final Function(String)? onValueChanged;
  final VoidCallback? onCreateSubTask; // ✅ Шинэ callback

  const TaskInputListDetails({
    Key? key,
    this.id,
    this.startDate,
    this.endDate,
    this.clientList,
    this.userList,
    required this.title,
    this.value,
    this.onTap,
    this.isReadOnly,
    this.addSubTask,
    this.workType,
    this.onValueChanged,
    this.onCreateSubTask, // ✅ Нэмэх
    this.isEditable = true, // ✅ Default: editable
  }) : super(key: key);

  @override
  State<TaskInputListDetails> createState() => _TaskInputListDetailsState();
}

class _TaskInputListDetailsState extends State<TaskInputListDetails> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          // ✅ Title (clickable)
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: widget.onTap,
              child: CustomText(
                text: widget.title,
                size: 14.sp,
                fontWeight: FontWeight.w500,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                color: Theme.of(context).colorScheme.textClrChange,
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // ✅ Input field
          Expanded(
            flex: 1,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.right,
              enabled: widget.isEditable, // ✅ Read-only үед disable хийх
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.textClrChange.withOpacity(
                      widget.isEditable
                          ? 1.0
                          : 0.6, // ✅ Read-only үед бүдгэрүүлэх
                    ),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 6.h,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.gray,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.gray,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.gray.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) {
                if (widget.isEditable) {
                  widget.onValueChanged?.call(value);
                }
              },
              onSubmitted: (value) {
                if (widget.isEditable) {
                  widget.onValueChanged?.call(value);
                }
              },
            ),
          ),

          SizedBox(width: 8.w),

          // ✅ Plus icon with border (clickable)
          if (widget.addSubTask == true)
            InkWell(
              onTap: widget.onCreateSubTask,
              borderRadius: BorderRadius.circular(6.r),
              child: Container(
                width: 20.w,
                height: 20.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: HeroIcon(
                    HeroIcons.plus,
                    size: 12.sp,
                    style: HeroIconStyle.outline,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
