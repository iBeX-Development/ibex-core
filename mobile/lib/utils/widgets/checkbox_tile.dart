// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../bloc/workspace/workspace_bloc.dart';
// import '../../config/colors.dart';
//
// typedef TitleValueChanged = void Function(String title, bool value,BuildContext context,int id);
//
// class CustomCheckboxListTile extends StatefulWidget {
//   final String title;
//   final int id;
//   final bool isChecked;
//   final TitleValueChanged onChanged;
//   final BuildContext context;
//
//   const CustomCheckboxListTile({super.key,
//     required this.title,
//     required this.id,
//     required this.isChecked,
//     required this.onChanged,
//     required this.context
//   });
//
//   @override
//   State<CustomCheckboxListTile> createState() => _CustomCheckboxListTileState();
// }
//
// class _CustomCheckboxListTileState extends State<CustomCheckboxListTile> {
//   bool? _isChecked;
//
//   @override
//   void initState() {
//     super.initState();
//     // _isChecked = widget.initialValue;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: (){
//
//       },
//       child: ListTile(
//         leading: Checkbox(
//           activeColor: AppColors.primary,
//           value: widget.isChecked,
//           onChanged: (value) {
//             setState(() {
//               _isChecked = value;
//               context.read<WorkspaceBloc>().workspcaIsSelected;
//             });
//             widget.onChanged(widget.title, _isChecked!,context,widget.id);
//           },
//         ),
//         title: Text(widget.title),
//         onTap: () {
//           setState(() {
//             widget.onChanged(widget.title, _isChecked!,context,widget.id);
//           });
//
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../../config/colors.dart';

typedef TitleValueChanged = void Function(
    String title, bool value, BuildContext context, int id);

class CustomCheckboxListTile extends StatefulWidget {
  final String title;
  final int id;
  final bool isChecked;
  final TitleValueChanged onChanged;
  final BuildContext context;
  final VoidCallback? onTap;

  const CustomCheckboxListTile({
    super.key,
    required this.title,
    required this.id,
    required this.isChecked,
    required this.onChanged,
    required this.context,
    this.onTap,
  });

  @override
  State<CustomCheckboxListTile> createState() => _CustomCheckboxListTileState();
}

class _CustomCheckboxListTileState extends State<CustomCheckboxListTile> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.isChecked;
  }

  @override
  void didUpdateWidget(covariant CustomCheckboxListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      setState(() {
        _isChecked = widget.isChecked;
      });
    }
  }

  void _toggleCheckbox() {
    final newValue = !_isChecked;
    setState(() {
      _isChecked = newValue;
    });
    widget.onChanged(widget.title, newValue, widget.context, widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: widget.onTap,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 35,
      horizontalTitleGap: 4,
      leading: Transform.translate(
        offset: const Offset(-8, 0),
        child: GestureDetector(
          onTap: _toggleCheckbox,
          behavior: HitTestBehavior.opaque,
          child: Checkbox(
            activeColor: AppColors.primary,
            value: _isChecked,
            onChanged: (_) => _toggleCheckbox(),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-8, 0),
        child: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
