import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ibex/config/colors.dart';
import '../../bloc/theme/theme_state.dart';
import '../../config/constants.dart';
import '../../bloc/theme/theme_bloc.dart';
import 'my_theme.dart';
import './checkbox_tile.dart';

class TaskCheckListDetails extends StatefulWidget {
  final List<dynamic> userList;
  final List<dynamic> clientList;
  final String? title;
  final String? startDate;
  final String? endDate;
  final double? width;
  final int? id;
  final Function()? onTap;
  final Function(bool)? onCheckboxChanged;
  final bool isEditable; // ✅ Team leader эсэхийг шалгах

  const TaskCheckListDetails({
    super.key,
    required this.clientList,
    required this.userList,
    this.startDate,
    this.endDate,
    this.id,
    this.title,
    this.width,
    this.onTap,
    this.onCheckboxChanged,
    this.isEditable = true, // ✅ Default: editable
  });

  @override
  State<TaskCheckListDetails> createState() => _TaskCheckListDetailsState();
}

class _TaskCheckListDetailsState extends State<TaskCheckListDetails> {
  String? startDate;
  String? endDate;
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    _formatDates();
  }

  void _formatDates() {
    if (widget.startDate != null) {
      startDate = formatDateFromApi(widget.startDate ?? "", context);
      endDate = formatDateFromApi(widget.endDate ?? "", context);
    }
  }

  void _handleCheckboxChange(
    String title,
    bool value,
    BuildContext context,
    int id,
  ) {
    // ✅ Зөвхөн editable үед өөрчлөлт хийх
    if (!widget.isEditable) return;

    setState(() {
      isChecked = value;
    });
    widget.onCheckboxChanged?.call(value);
  }

  Widget _buildTaskRow() {
    return Row(
      children: [
        // Container(
        //   width: 20.w,
        //   child: CustomText(
        //     text: "${widget.id.toString()}.",
        //     size: 12.sp,
        //     color: Theme.of(context).colorScheme.textClrChange,
        //     fontWeight: FontWeight.w700,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        // ),
        Expanded(
          child: AbsorbPointer(
            absorbing:
                !widget.isEditable, // ✅ Read-only үед interaction-ыг хаах
            child: Opacity(
              opacity: widget.isEditable
                  ? 1.0
                  : 0.6, // ✅ Read-only үед бага зэрэг бүдгэрүүлэх
              child: CustomCheckboxListTile(
                title: widget.title ?? "No Title",
                id: widget.id ?? 0,
                isChecked: isChecked,
                onChanged: _handleCheckboxChange,
                onTap: widget.isEditable
                    ? widget.onTap
                    : null, // ✅ Read-only үед tap хаах
                context: context,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.read<ThemeBloc>();
    final isLightTheme = themeBloc.currentThemeState is LightThemeState;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Container(
        width: 400.w,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.lightWhite,
          borderRadius: BorderRadius.circular(17.4),
          border: Border.all(
            color: Theme.of(context).colorScheme.gray,
            width: 1,
          ),
          boxShadow: [
            isLightTheme ? MyThemes.lightThemeShadow : MyThemes.darkThemeShadow,
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 15.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildTaskRow()],
          ),
        ),
      ),
    );
  }
}
