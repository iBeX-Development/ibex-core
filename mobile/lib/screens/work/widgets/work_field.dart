import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ibex/config/colors.dart';
import '../../../bloc/Work/work_state.dart';
import '../../../bloc/single_select_work/single_select_work_bloc.dart';
import '../../../bloc/single_select_work/single_select_work_event.dart';
import '../../../bloc/single_select_work/single_select_work_state.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/no_data.dart';
import '../../widgets/custom_cancel_create_button.dart';

class WorkField extends StatefulWidget {
  final bool isCreate;
  final bool openDropdown;
  final String? name;
  final int? work;
  final bool? isRequired;
  // final List<StatusModel> status;
  final int? index;
  final Function(String, int) onSelected;
  const WorkField({
    super.key,
    this.name,
    this.openDropdown = false,
    required this.isCreate,
    required this.work,
    this.isRequired,
    required this.index,
    required this.onSelected,
  });

  @override
  State<WorkField> createState() => _WorkFieldState();
}

class _WorkFieldState extends State<WorkField> {
  String? worksname;
  int? worksId;
  bool isLoadingMore = false;
  String searchWord = "";

  String? name;
  final TextEditingController _workSearchController = TextEditingController();
  @override
  void initState() {
    name = widget.name!;
    if (!widget.isCreate) {
      worksId = widget.work;
      worksname = widget.name;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              CustomText(
                text: AppLocalizations.of(context)!.work,
                // text: getTranslated(context, 'myweeklyTask'),
                color: Theme.of(context).colorScheme.textClrChange,
                size: 16,
                fontWeight: FontWeight.w700,
              ),
              widget.isRequired == true
                  ? CustomText(
                      text: " *",
                      // text: getTranslated(context, 'myweeklyTask'),
                      color: AppColors.red,
                      size: 15,
                      fontWeight: FontWeight.w400,
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
        SizedBox(height: 5.h),
        BlocBuilder<SingleSelectWorkBloc, SingleSelectWorkState>(
          builder: (context, state) {
            if (state is SingleWorkInitial) {
              return AbsorbPointer(
                absorbing: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      highlightColor: Colors.transparent, // No highlight on tap
                      splashColor: Colors.transparent,
                      onTap: () {
                        _workSearchController.clear();

                        // Fetch initial work list
                        widget.isCreate == false
                            ? SizedBox()
                            : context.read<SingleSelectWorkBloc>().add(
                                SingleWorkList(),
                              );
                        widget.isCreate == false
                            ? SizedBox()
                            : showDialog(
                                context: context,
                                builder: (ctx) => BlocConsumer<SingleSelectWorkBloc, SingleSelectWorkState>(
                                  listener: (context, state) {
                                    if (state is SingleWorkSuccess) {
                                      isLoadingMore = false;
                                      setState(() {});
                                    }
                                  },
                                  builder: (context, state) {
                                    if (state is SingleWorkSuccess) {
                                      return NotificationListener<
                                        ScrollNotification
                                      >(
                                        onNotification: (scrollInfo) {
                                          // Check if the user has scrolled to the end and load more notes if needed
                                          if (!state.hasReachedMax &&
                                              scrollInfo.metrics.pixels ==
                                                  scrollInfo
                                                      .metrics
                                                      .maxScrollExtent) {
                                            // isLoadingMore = true;
                                            setState(() {});
                                            context
                                                .read<SingleSelectWorkBloc>()
                                                .add(
                                                  SingleWorkLoadMore(
                                                    searchWord,
                                                  ),
                                                );
                                          }
                                          // isLoadingMore = false;
                                          return false;
                                        },
                                        child: AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ), // Set the desired radius here
                                          ),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.alertBoxBackGroundColor,
                                          contentPadding: EdgeInsets.zero,
                                          title: Center(
                                            child: Column(
                                              children: [
                                                CustomText(
                                                  text: AppLocalizations.of(
                                                    context,
                                                  )!.selectworks,
                                                  fontWeight: FontWeight.w800,
                                                  size: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .whitepurpleChange,
                                                ),
                                                const Divider(),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 0.w,
                                                  ),
                                                  child: SizedBox(
                                                    // color: Colors.red,
                                                    height: 35.h,
                                                    width: double.infinity,
                                                    child: TextField(
                                                      cursorColor: AppColors
                                                          .greyForgetColor,
                                                      cursorWidth: 1,
                                                      controller:
                                                          _workSearchController,
                                                      decoration: InputDecoration(
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical:
                                                                  (35.h -
                                                                      20.sp) /
                                                                  2,
                                                              horizontal: 10.w,
                                                            ),
                                                        hintText:
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.search,
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: AppColors
                                                                .greyForgetColor, // Set your desired color here
                                                            width:
                                                                1.0, // Set the border width if needed
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.0,
                                                              ), // Optional: adjust the border radius
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: AppColors
                                                                .purple, // Border color when TextField is focused
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          searchWord = value;
                                                        });
                                                        context
                                                            .read<
                                                              SingleSelectWorkBloc
                                                            >()
                                                            .add(
                                                              SearchSingleWork(
                                                                value,
                                                              ),
                                                            );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 20.h),
                                              ],
                                            ),
                                          ),
                                          content: Container(
                                            constraints: BoxConstraints(
                                              maxHeight: 900.h,
                                            ),
                                            width: 200.w,
                                            child: state.work.isEmpty
                                                ? NoData(isImage: true)
                                                : ListView.builder(
                                                    // physics: const NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        state.hasReachedMax
                                                        ? state.work.length
                                                        : state.work.length + 1,
                                                    itemBuilder:
                                                        (
                                                          BuildContext context,
                                                          int index,
                                                        ) {
                                                          if (index <
                                                              state
                                                                  .work
                                                                  .length) {
                                                            final isSelected =
                                                                worksId !=
                                                                    null &&
                                                                state
                                                                        .work[index]
                                                                        .id ==
                                                                    worksId;
                                                            return Padding(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        2.h,
                                                                    horizontal:
                                                                        20.w,
                                                                  ),
                                                              child: InkWell(
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent, // No highlight on tap
                                                                splashColor: Colors
                                                                    .transparent,
                                                                onTap: () {
                                                                  setState(() {
                                                                    if (widget
                                                                            .isCreate ==
                                                                        true) {
                                                                      worksname = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksId = state
                                                                          .work[index]
                                                                          .id!;
                                                                      widget.onSelected(
                                                                        state
                                                                            .work[index]
                                                                            .title!,
                                                                        state
                                                                            .work[index]
                                                                            .id!,
                                                                      );
                                                                    } else {
                                                                      name = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksname = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksId = state
                                                                          .work[index]
                                                                          .id!;
                                                                      widget.onSelected(
                                                                        state
                                                                            .work[index]
                                                                            .title!,
                                                                        state
                                                                            .work[index]
                                                                            .id!,
                                                                      );
                                                                    }
                                                                  });

                                                                  BlocProvider.of<
                                                                        SingleSelectWorkBloc
                                                                      >(context)
                                                                      .add(
                                                                        SelectSingleWork(
                                                                          index,
                                                                          state
                                                                              .work[index]
                                                                              .title!,
                                                                        ),
                                                                      );

                                                                  BlocProvider.of<
                                                                        SingleSelectWorkBloc
                                                                      >(context)
                                                                      .add(
                                                                        SelectSingleWork(
                                                                          index,
                                                                          state
                                                                              .work[index]
                                                                              .title!,
                                                                        ),
                                                                      );
                                                                },
                                                                child: Container(
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        isSelected
                                                                        ? AppColors
                                                                              .purpleShade
                                                                        : Colors
                                                                              .transparent,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                    border: Border.all(
                                                                      color:
                                                                          isSelected
                                                                          ? AppColors.primary
                                                                          : Colors.transparent,
                                                                    ),
                                                                  ),
                                                                  width: double
                                                                      .infinity,
                                                                  height: 40.h,
                                                                  child: Center(
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10.w,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Expanded(
                                                                            flex:
                                                                                4,
                                                                            // width:200.w,
                                                                            child: CustomText(
                                                                              text: state.work[index].title!,
                                                                              fontWeight: FontWeight.w500,
                                                                              size: 18,
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
                                                                              ? Expanded(
                                                                                  flex: 1,
                                                                                  child: const HeroIcon(
                                                                                    HeroIcons.checkCircle,
                                                                                    style: HeroIconStyle.solid,
                                                                                    color: AppColors.purple,
                                                                                  ),
                                                                                )
                                                                              : const SizedBox.shrink(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            // Show a loading indicator when more notes are being loaded
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 0,
                                                                  ),
                                                              child: Center(
                                                                child:
                                                                    state
                                                                        .hasReachedMax
                                                                    ? const Text(
                                                                        '',
                                                                      )
                                                                    : const SpinKitFadingCircle(
                                                                        color: AppColors
                                                                            .primary,
                                                                        size:
                                                                            40.0,
                                                                      ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                  ),
                                          ),
                                          actions: <Widget>[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 20.h,
                                              ),
                                              child: CreateCancelButtom(
                                                title: "OK",
                                                onpressCancel: () {
                                                  _workSearchController.clear();
                                                  Navigator.pop(context);
                                                },
                                                onpressCreate: () {
                                                  _workSearchController.clear();
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const Center(
                                      child: Text('Loading...'),
                                    );
                                  },
                                ),
                              );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        height: 40.h,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: widget.isCreate == true
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.textfieldDisabled,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyColor),
                        ),
                        // decoration: DesignConfiguration.shadow(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                text: widget.isCreate
                                    ? (worksname?.isEmpty ?? true
                                          ? "Select Work"
                                          : worksname!)
                                    : (worksname?.isEmpty ?? true
                                          ? widget.name!
                                          : worksname!),
                                fontWeight: FontWeight.w500,
                                size: 14.sp,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                color: Theme.of(
                                  context,
                                ).colorScheme.textClrChange,
                              ),
                            ),
                            widget.isCreate == false
                                ? SizedBox()
                                : Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is SingleWorkLoading) {
              return AbsorbPointer(
                absorbing: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      highlightColor: Colors.transparent, // No highlight on tap
                      splashColor: Colors.transparent,
                      onTap: () {
                        _workSearchController.clear();

                        // Fetch initial work list
                        widget.isCreate == false
                            ? SizedBox()
                            : context.read<SingleSelectWorkBloc>().add(
                                SingleWorkList(),
                              );
                        widget.isCreate == false
                            ? SizedBox()
                            : showDialog(
                                context: context,
                                builder: (ctx) => BlocConsumer<SingleSelectWorkBloc, SingleSelectWorkState>(
                                  listener: (context, state) {
                                    if (state is SingleWorkSuccess) {
                                      isLoadingMore = false;
                                      setState(() {});
                                    }
                                  },
                                  builder: (context, state) {
                                    if (state is SingleWorkSuccess) {
                                      return NotificationListener<
                                        ScrollNotification
                                      >(
                                        onNotification: (scrollInfo) {
                                          // Check if the user has scrolled to the end and load more notes if needed
                                          if (!state.hasReachedMax &&
                                              scrollInfo.metrics.pixels ==
                                                  scrollInfo
                                                      .metrics
                                                      .maxScrollExtent) {
                                            // isLoadingMore = true;
                                            setState(() {});
                                            context
                                                .read<SingleSelectWorkBloc>()
                                                .add(
                                                  SingleWorkLoadMore(
                                                    searchWord,
                                                  ),
                                                );
                                          }
                                          // isLoadingMore = false;
                                          return false;
                                        },
                                        child: AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ), // Set the desired radius here
                                          ),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.alertBoxBackGroundColor,
                                          contentPadding: EdgeInsets.zero,
                                          title: Center(
                                            child: Column(
                                              children: [
                                                CustomText(
                                                  text: AppLocalizations.of(
                                                    context,
                                                  )!.selectworks,
                                                  fontWeight: FontWeight.w800,
                                                  size: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .whitepurpleChange,
                                                ),
                                                const Divider(),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 0.w,
                                                  ),
                                                  child: SizedBox(
                                                    // color: Colors.red,
                                                    height: 35.h,
                                                    width: double.infinity,
                                                    child: TextField(
                                                      cursorColor: AppColors
                                                          .greyForgetColor,
                                                      cursorWidth: 1,
                                                      controller:
                                                          _workSearchController,
                                                      decoration: InputDecoration(
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical:
                                                                  (35.h -
                                                                      20.sp) /
                                                                  2,
                                                              horizontal: 10.w,
                                                            ),
                                                        hintText:
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.search,
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: AppColors
                                                                .greyForgetColor, // Set your desired color here
                                                            width:
                                                                1.0, // Set the border width if needed
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.0,
                                                              ), // Optional: adjust the border radius
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: AppColors
                                                                .purple, // Border color when TextField is focused
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          searchWord = value;
                                                        });
                                                        context
                                                            .read<
                                                              SingleSelectWorkBloc
                                                            >()
                                                            .add(
                                                              SearchSingleWork(
                                                                value,
                                                              ),
                                                            );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 20.h),
                                              ],
                                            ),
                                          ),
                                          content: Container(
                                            constraints: BoxConstraints(
                                              maxHeight: 900.h,
                                            ),
                                            width: 200.w,
                                            child: state.work.isEmpty
                                                ? NoData(isImage: true)
                                                : ListView.builder(
                                                    // physics: const NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        state.hasReachedMax
                                                        ? state.work.length
                                                        : state.work.length + 1,
                                                    itemBuilder:
                                                        (
                                                          BuildContext context,
                                                          int index,
                                                        ) {
                                                          if (index <
                                                              state
                                                                  .work
                                                                  .length) {
                                                            final isSelected =
                                                                worksId !=
                                                                    null &&
                                                                state
                                                                        .work[index]
                                                                        .id ==
                                                                    worksId;
                                                            return Padding(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        2.h,
                                                                    horizontal:
                                                                        20.w,
                                                                  ),
                                                              child: InkWell(
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent, // No highlight on tap
                                                                splashColor: Colors
                                                                    .transparent,
                                                                onTap: () {
                                                                  setState(() {
                                                                    if (widget
                                                                            .isCreate ==
                                                                        true) {
                                                                      worksname = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksId = state
                                                                          .work[index]
                                                                          .id!;
                                                                      widget.onSelected(
                                                                        state
                                                                            .work[index]
                                                                            .title!,
                                                                        state
                                                                            .work[index]
                                                                            .id!,
                                                                      );
                                                                    } else {
                                                                      name = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksname = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksId = state
                                                                          .work[index]
                                                                          .id!;
                                                                      widget.onSelected(
                                                                        state
                                                                            .work[index]
                                                                            .title!,
                                                                        state
                                                                            .work[index]
                                                                            .id!,
                                                                      );
                                                                    }
                                                                  });

                                                                  BlocProvider.of<
                                                                        SingleSelectWorkBloc
                                                                      >(context)
                                                                      .add(
                                                                        SelectSingleWork(
                                                                          index,
                                                                          state
                                                                              .work[index]
                                                                              .title!,
                                                                        ),
                                                                      );

                                                                  BlocProvider.of<
                                                                        SingleSelectWorkBloc
                                                                      >(context)
                                                                      .add(
                                                                        SelectSingleWork(
                                                                          index,
                                                                          state
                                                                              .work[index]
                                                                              .title!,
                                                                        ),
                                                                      );
                                                                },
                                                                child: Container(
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        isSelected
                                                                        ? AppColors
                                                                              .purpleShade
                                                                        : Colors
                                                                              .transparent,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                    border: Border.all(
                                                                      color:
                                                                          isSelected
                                                                          ? AppColors.primary
                                                                          : Colors.transparent,
                                                                    ),
                                                                  ),
                                                                  width: double
                                                                      .infinity,
                                                                  height: 40.h,
                                                                  child: Center(
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10.w,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Expanded(
                                                                            flex:
                                                                                4,
                                                                            // width:200.w,
                                                                            child: CustomText(
                                                                              text: state.work[index].title!,
                                                                              fontWeight: FontWeight.w500,
                                                                              size: 18,
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
                                                                              ? Expanded(
                                                                                  flex: 1,
                                                                                  child: const HeroIcon(
                                                                                    HeroIcons.checkCircle,
                                                                                    style: HeroIconStyle.solid,
                                                                                    color: AppColors.purple,
                                                                                  ),
                                                                                )
                                                                              : const SizedBox.shrink(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            // Show a loading indicator when more notes are being loaded
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 0,
                                                                  ),
                                                              child: Center(
                                                                child:
                                                                    state
                                                                        .hasReachedMax
                                                                    ? const Text(
                                                                        '',
                                                                      )
                                                                    : const SpinKitFadingCircle(
                                                                        color: AppColors
                                                                            .primary,
                                                                        size:
                                                                            40.0,
                                                                      ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                  ),
                                          ),
                                          actions: <Widget>[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 20.h,
                                              ),
                                              child: CreateCancelButtom(
                                                title: "OK",
                                                onpressCancel: () {
                                                  _workSearchController.clear();
                                                  Navigator.pop(context);
                                                },
                                                onpressCreate: () {
                                                  _workSearchController.clear();
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const Center(
                                      child: Text('Loading...'),
                                    );
                                  },
                                ),
                              );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        height: 40.h,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: widget.isCreate == true
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.textfieldDisabled,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyColor),
                        ),
                        // decoration: DesignConfiguration.shadow(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                text: widget.isCreate
                                    ? (worksname?.isEmpty ?? true
                                          ? "Select Work"
                                          : worksname!)
                                    : (worksname?.isEmpty ?? true
                                          ? widget.name!
                                          : worksname!),
                                fontWeight: FontWeight.w500,
                                size: 14.sp,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                color: Theme.of(
                                  context,
                                ).colorScheme.textClrChange,
                              ),
                            ),
                            widget.isCreate == false
                                ? SizedBox()
                                : Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is SingleWorkSuccess) {
              return AbsorbPointer(
                absorbing: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      highlightColor: Colors.transparent, // No highlight on tap
                      splashColor: Colors.transparent,
                      onTap: () {
                        _workSearchController.clear();

                        // Fetch initial work list
                        widget.isCreate == false && widget.openDropdown == false
                            ? SizedBox()
                            : context.read<SingleSelectWorkBloc>().add(
                                SingleWorkList(),
                              );
                        widget.isCreate == false && widget.openDropdown == false
                            ? SizedBox()
                            : showDialog(
                                context: context,
                                builder: (ctx) => BlocConsumer<SingleSelectWorkBloc, SingleSelectWorkState>(
                                  listener: (context, state) {
                                    if (state is SingleWorkSuccess) {
                                      isLoadingMore = false;
                                      setState(() {});
                                    }
                                  },
                                  builder: (context, state) {
                                    if (state is SingleWorkSuccess) {
                                      return NotificationListener<
                                        ScrollNotification
                                      >(
                                        onNotification: (scrollInfo) {
                                          // Check if the user has scrolled to the end and load more notes if needed
                                          if (!state.hasReachedMax &&
                                              scrollInfo.metrics.pixels ==
                                                  scrollInfo
                                                      .metrics
                                                      .maxScrollExtent) {
                                            // isLoadingMore = true;
                                            setState(() {});
                                            context
                                                .read<SingleSelectWorkBloc>()
                                                .add(
                                                  SingleWorkLoadMore(
                                                    searchWord,
                                                  ),
                                                );
                                          }
                                          // isLoadingMore = false;
                                          return false;
                                        },
                                        child: AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ), // Set the desired radius here
                                          ),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.alertBoxBackGroundColor,
                                          contentPadding: EdgeInsets.zero,
                                          title: Center(
                                            child: Column(
                                              children: [
                                                CustomText(
                                                  text: AppLocalizations.of(
                                                    context,
                                                  )!.selectworks,
                                                  fontWeight: FontWeight.w800,
                                                  size: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .whitepurpleChange,
                                                ),
                                                const Divider(),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 0.w,
                                                  ),
                                                  child: SizedBox(
                                                    // color: Colors.red,
                                                    height: 35.h,
                                                    width: double.infinity,
                                                    child: TextField(
                                                      cursorColor: AppColors
                                                          .greyForgetColor,
                                                      cursorWidth: 1,
                                                      controller:
                                                          _workSearchController,
                                                      decoration: InputDecoration(
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical:
                                                                  (35.h -
                                                                      20.sp) /
                                                                  2,
                                                              horizontal: 10.w,
                                                            ),
                                                        hintText:
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.search,
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: AppColors
                                                                .greyForgetColor, // Set your desired color here
                                                            width:
                                                                1.0, // Set the border width if needed
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.0,
                                                              ), // Optional: adjust the border radius
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: AppColors
                                                                .purple, // Border color when TextField is focused
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          searchWord = value;
                                                        });
                                                        context
                                                            .read<
                                                              SingleSelectWorkBloc
                                                            >()
                                                            .add(
                                                              SearchSingleWork(
                                                                value,
                                                              ),
                                                            );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 20.h),
                                              ],
                                            ),
                                          ),
                                          content: Container(
                                            constraints: BoxConstraints(
                                              maxHeight: 900.h,
                                            ),
                                            width: 200.w,
                                            child: state.work.isEmpty
                                                ? NoData(isImage: true)
                                                : ListView.builder(
                                                    // physics: const NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        state.hasReachedMax
                                                        ? state.work.length
                                                        : state.work.length + 1,
                                                    itemBuilder:
                                                        (
                                                          BuildContext context,
                                                          int index,
                                                        ) {
                                                          if (index <
                                                              state
                                                                  .work
                                                                  .length) {
                                                            final isSelected =
                                                                worksId !=
                                                                    null &&
                                                                state
                                                                        .work[index]
                                                                        .id ==
                                                                    worksId;
                                                            return Padding(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        2.h,
                                                                    horizontal:
                                                                        20.w,
                                                                  ),
                                                              child: InkWell(
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent, // No highlight on tap
                                                                splashColor: Colors
                                                                    .transparent,
                                                                onTap: () {
                                                                  setState(() {
                                                                    if (widget
                                                                            .isCreate ==
                                                                        true) {
                                                                      worksname = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksId = state
                                                                          .work[index]
                                                                          .id!;
                                                                      widget.onSelected(
                                                                        state
                                                                            .work[index]
                                                                            .title!,
                                                                        state
                                                                            .work[index]
                                                                            .id!,
                                                                      );
                                                                    } else {
                                                                      name = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksname = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksId = state
                                                                          .work[index]
                                                                          .id!;
                                                                      widget.onSelected(
                                                                        state
                                                                            .work[index]
                                                                            .title!,
                                                                        state
                                                                            .work[index]
                                                                            .id!,
                                                                      );
                                                                    }
                                                                  });

                                                                  BlocProvider.of<
                                                                        SingleSelectWorkBloc
                                                                      >(context)
                                                                      .add(
                                                                        SelectSingleWork(
                                                                          index,
                                                                          state
                                                                              .work[index]
                                                                              .title!,
                                                                        ),
                                                                      );

                                                                  BlocProvider.of<
                                                                        SingleSelectWorkBloc
                                                                      >(context)
                                                                      .add(
                                                                        SelectSingleWork(
                                                                          index,
                                                                          state
                                                                              .work[index]
                                                                              .title!,
                                                                        ),
                                                                      );
                                                                },
                                                                child: Container(
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        isSelected
                                                                        ? AppColors
                                                                              .purpleShade
                                                                        : Colors
                                                                              .transparent,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                    border: Border.all(
                                                                      color:
                                                                          isSelected
                                                                          ? AppColors.primary
                                                                          : Colors.transparent,
                                                                    ),
                                                                  ),
                                                                  width: double
                                                                      .infinity,
                                                                  height: 40.h,
                                                                  child: Center(
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10.w,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Expanded(
                                                                            flex:
                                                                                4,
                                                                            // width:200.w,
                                                                            child: CustomText(
                                                                              text: state.work[index].title!,
                                                                              fontWeight: FontWeight.w500,
                                                                              size: 18,
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
                                                                              ? Expanded(
                                                                                  flex: 1,
                                                                                  child: const HeroIcon(
                                                                                    HeroIcons.checkCircle,
                                                                                    style: HeroIconStyle.solid,
                                                                                    color: AppColors.purple,
                                                                                  ),
                                                                                )
                                                                              : const SizedBox.shrink(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            // Show a loading indicator when more notes are being loaded
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 0,
                                                                  ),
                                                              child: Center(
                                                                child:
                                                                    state
                                                                        .hasReachedMax
                                                                    ? const Text(
                                                                        '',
                                                                      )
                                                                    : const SpinKitFadingCircle(
                                                                        color: AppColors
                                                                            .primary,
                                                                        size:
                                                                            40.0,
                                                                      ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                  ),
                                          ),
                                          actions: <Widget>[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 20.h,
                                              ),
                                              child: CreateCancelButtom(
                                                title: "OK",
                                                onpressCancel: () {
                                                  _workSearchController.clear();
                                                  Navigator.pop(context);
                                                },
                                                onpressCreate: () {
                                                  _workSearchController.clear();
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const Center(
                                      child: Text('Loading...'),
                                    );
                                  },
                                ),
                              );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        height: 40.h,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: widget.isCreate == true
                              ? Colors.transparent
                              : widget.openDropdown == true
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.textfieldDisabled,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyColor),
                        ),
                        // decoration: DesignConfiguration.shadow(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                text: widget.isCreate
                                    ? (worksname?.isEmpty ?? true
                                          ? "Select Work"
                                          : worksname!)
                                    : (worksname?.isEmpty ?? true
                                          ? widget.name!
                                          : worksname!),
                                fontWeight: FontWeight.w500,
                                size: 14.sp,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                color: Theme.of(
                                  context,
                                ).colorScheme.textClrChange,
                              ),
                            ),
                            widget.isCreate == false &&
                                    widget.openDropdown == false
                                ? SizedBox()
                                : Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is WorkError) {
              return AbsorbPointer(
                absorbing: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      highlightColor: Colors.transparent, // No highlight on tap
                      splashColor: Colors.transparent,
                      onTap: () {
                        _workSearchController.clear();

                        // Fetch initial work list
                        widget.isCreate == false
                            ? SizedBox()
                            : context.read<SingleSelectWorkBloc>().add(
                                SingleWorkList(),
                              );
                        widget.isCreate == false
                            ? SizedBox()
                            : showDialog(
                                context: context,
                                builder: (ctx) => BlocConsumer<SingleSelectWorkBloc, SingleSelectWorkState>(
                                  listener: (context, state) {
                                    if (state is SingleWorkSuccess) {
                                      isLoadingMore = false;
                                      setState(() {});
                                    }
                                  },
                                  builder: (context, state) {
                                    if (state is SingleWorkSuccess) {
                                      return NotificationListener<
                                        ScrollNotification
                                      >(
                                        onNotification: (scrollInfo) {
                                          // Check if the user has scrolled to the end and load more notes if needed
                                          if (!state.hasReachedMax &&
                                              scrollInfo.metrics.pixels ==
                                                  scrollInfo
                                                      .metrics
                                                      .maxScrollExtent) {
                                            // isLoadingMore = true;
                                            setState(() {});
                                            context
                                                .read<SingleSelectWorkBloc>()
                                                .add(
                                                  SingleWorkLoadMore(
                                                    searchWord,
                                                  ),
                                                );
                                          }
                                          // isLoadingMore = false;
                                          return false;
                                        },
                                        child: AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ), // Set the desired radius here
                                          ),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.alertBoxBackGroundColor,
                                          contentPadding: EdgeInsets.zero,
                                          title: Center(
                                            child: Column(
                                              children: [
                                                CustomText(
                                                  text: AppLocalizations.of(
                                                    context,
                                                  )!.selectworks,
                                                  fontWeight: FontWeight.w800,
                                                  size: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .whitepurpleChange,
                                                ),
                                                const Divider(),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 0.w,
                                                  ),
                                                  child: SizedBox(
                                                    // color: Colors.red,
                                                    height: 35.h,
                                                    width: double.infinity,
                                                    child: TextField(
                                                      cursorColor: AppColors
                                                          .greyForgetColor,
                                                      cursorWidth: 1,
                                                      controller:
                                                          _workSearchController,
                                                      decoration: InputDecoration(
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              vertical:
                                                                  (35.h -
                                                                      20.sp) /
                                                                  2,
                                                              horizontal: 10.w,
                                                            ),
                                                        hintText:
                                                            AppLocalizations.of(
                                                              context,
                                                            )!.search,
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: AppColors
                                                                .greyForgetColor, // Set your desired color here
                                                            width:
                                                                1.0, // Set the border width if needed
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.0,
                                                              ), // Optional: adjust the border radius
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10.0,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: AppColors
                                                                .purple, // Border color when TextField is focused
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          searchWord = value;
                                                        });
                                                        context
                                                            .read<
                                                              SingleSelectWorkBloc
                                                            >()
                                                            .add(
                                                              SearchSingleWork(
                                                                value,
                                                              ),
                                                            );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 20.h),
                                              ],
                                            ),
                                          ),
                                          content: Container(
                                            constraints: BoxConstraints(
                                              maxHeight: 900.h,
                                            ),
                                            width: 200.w,
                                            child: state.work.isEmpty
                                                ? NoData(isImage: true)
                                                : ListView.builder(
                                                    // physics: const NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    itemCount:
                                                        state.hasReachedMax
                                                        ? state.work.length
                                                        : state.work.length + 1,
                                                    itemBuilder:
                                                        (
                                                          BuildContext context,
                                                          int index,
                                                        ) {
                                                          if (index <
                                                              state
                                                                  .work
                                                                  .length) {
                                                            final isSelected =
                                                                worksId !=
                                                                    null &&
                                                                state
                                                                        .work[index]
                                                                        .id ==
                                                                    worksId;
                                                            return Padding(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    vertical:
                                                                        2.h,
                                                                    horizontal:
                                                                        20.w,
                                                                  ),
                                                              child: InkWell(
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent, // No highlight on tap
                                                                splashColor: Colors
                                                                    .transparent,
                                                                onTap: () {
                                                                  setState(() {
                                                                    if (widget
                                                                            .isCreate ==
                                                                        true) {
                                                                      worksname = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksId = state
                                                                          .work[index]
                                                                          .id!;
                                                                      widget.onSelected(
                                                                        state
                                                                            .work[index]
                                                                            .title!,
                                                                        state
                                                                            .work[index]
                                                                            .id!,
                                                                      );
                                                                    } else {
                                                                      name = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksname = state
                                                                          .work[index]
                                                                          .title!;
                                                                      worksId = state
                                                                          .work[index]
                                                                          .id!;
                                                                      widget.onSelected(
                                                                        state
                                                                            .work[index]
                                                                            .title!,
                                                                        state
                                                                            .work[index]
                                                                            .id!,
                                                                      );
                                                                    }
                                                                  });

                                                                  BlocProvider.of<
                                                                        SingleSelectWorkBloc
                                                                      >(context)
                                                                      .add(
                                                                        SelectSingleWork(
                                                                          index,
                                                                          state
                                                                              .work[index]
                                                                              .title!,
                                                                        ),
                                                                      );

                                                                  BlocProvider.of<
                                                                        SingleSelectWorkBloc
                                                                      >(context)
                                                                      .add(
                                                                        SelectSingleWork(
                                                                          index,
                                                                          state
                                                                              .work[index]
                                                                              .title!,
                                                                        ),
                                                                      );
                                                                },
                                                                child: Container(
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        isSelected
                                                                        ? AppColors
                                                                              .purpleShade
                                                                        : Colors
                                                                              .transparent,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                    border: Border.all(
                                                                      color:
                                                                          isSelected
                                                                          ? AppColors.primary
                                                                          : Colors.transparent,
                                                                    ),
                                                                  ),
                                                                  width: double
                                                                      .infinity,
                                                                  height: 40.h,
                                                                  child: Center(
                                                                    child: Container(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10.w,
                                                                      ),
                                                                      child: Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Expanded(
                                                                            flex:
                                                                                4,
                                                                            // width:200.w,
                                                                            child: CustomText(
                                                                              text: state.work[index].title!,
                                                                              fontWeight: FontWeight.w500,
                                                                              size: 18,
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
                                                                              ? Expanded(
                                                                                  flex: 1,
                                                                                  child: const HeroIcon(
                                                                                    HeroIcons.checkCircle,
                                                                                    style: HeroIconStyle.solid,
                                                                                    color: AppColors.purple,
                                                                                  ),
                                                                                )
                                                                              : const SizedBox.shrink(),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            // Show a loading indicator when more notes are being loaded
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 0,
                                                                  ),
                                                              child: Center(
                                                                child:
                                                                    state
                                                                        .hasReachedMax
                                                                    ? const Text(
                                                                        '',
                                                                      )
                                                                    : const SpinKitFadingCircle(
                                                                        color: AppColors
                                                                            .primary,
                                                                        size:
                                                                            40.0,
                                                                      ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                  ),
                                          ),
                                          actions: <Widget>[
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 20.h,
                                              ),
                                              child: CreateCancelButtom(
                                                title: "OK",
                                                onpressCancel: () {
                                                  _workSearchController.clear();
                                                  Navigator.pop(context);
                                                },
                                                onpressCreate: () {
                                                  _workSearchController.clear();
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const Center(
                                      child: Text('Loading...'),
                                    );
                                  },
                                ),
                              );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        height: 40.h,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: widget.isCreate == true
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.textfieldDisabled,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyColor),
                        ),
                        // decoration: DesignConfiguration.shadow(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                text: widget.isCreate
                                    ? (worksname?.isEmpty ?? true
                                          ? "Select Work"
                                          : worksname!)
                                    : (worksname?.isEmpty ?? true
                                          ? widget.name!
                                          : worksname!),
                                fontWeight: FontWeight.w500,
                                size: 14.sp,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                color: Theme.of(
                                  context,
                                ).colorScheme.textClrChange,
                              ),
                            ),
                            widget.isCreate == false
                                ? SizedBox()
                                : Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return AbsorbPointer(
              absorbing: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    highlightColor: Colors.transparent, // No highlight on tap
                    splashColor: Colors.transparent,
                    onTap: () {
                      _workSearchController.clear();

                      // Fetch initial work list
                      widget.isCreate == false
                          ? SizedBox()
                          : context.read<SingleSelectWorkBloc>().add(
                              SingleWorkList(),
                            );
                      widget.isCreate == false
                          ? SizedBox()
                          : showDialog(
                              context: context,
                              builder: (ctx) => BlocConsumer<SingleSelectWorkBloc, SingleSelectWorkState>(
                                listener: (context, state) {
                                  if (state is SingleWorkSuccess) {
                                    isLoadingMore = false;
                                    setState(() {});
                                  }
                                },
                                builder: (context, state) {
                                  if (state is SingleWorkSuccess) {
                                    return NotificationListener<
                                      ScrollNotification
                                    >(
                                      onNotification: (scrollInfo) {
                                        // Check if the user has scrolled to the end and load more notes if needed
                                        if (!state.hasReachedMax &&
                                            scrollInfo.metrics.pixels ==
                                                scrollInfo
                                                    .metrics
                                                    .maxScrollExtent) {
                                          // isLoadingMore = true;
                                          setState(() {});
                                          context
                                              .read<SingleSelectWorkBloc>()
                                              .add(
                                                SingleWorkLoadMore(searchWord),
                                              );
                                        }
                                        // isLoadingMore = false;
                                        return false;
                                      },
                                      child: AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ), // Set the desired radius here
                                        ),
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.alertBoxBackGroundColor,
                                        contentPadding: EdgeInsets.zero,
                                        title: Center(
                                          child: Column(
                                            children: [
                                              CustomText(
                                                text: AppLocalizations.of(
                                                  context,
                                                )!.selectworks,
                                                fontWeight: FontWeight.w800,
                                                size: 20,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.whitepurpleChange,
                                              ),
                                              const Divider(),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 0.w,
                                                ),
                                                child: SizedBox(
                                                  // color: Colors.red,
                                                  height: 35.h,
                                                  width: double.infinity,
                                                  child: TextField(
                                                    cursorColor: AppColors
                                                        .greyForgetColor,
                                                    cursorWidth: 1,
                                                    controller:
                                                        _workSearchController,
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            vertical:
                                                                (35.h - 20.sp) /
                                                                2,
                                                            horizontal: 10.w,
                                                          ),
                                                      hintText:
                                                          AppLocalizations.of(
                                                            context,
                                                          )!.search,
                                                      enabledBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color: AppColors
                                                              .greyForgetColor, // Set your desired color here
                                                          width:
                                                              1.0, // Set the border width if needed
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10.0,
                                                            ), // Optional: adjust the border radius
                                                      ),
                                                      focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10.0,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: AppColors
                                                              .purple, // Border color when TextField is focused
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                    ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        searchWord = value;
                                                      });
                                                      context
                                                          .read<
                                                            SingleSelectWorkBloc
                                                          >()
                                                          .add(
                                                            SearchSingleWork(
                                                              value,
                                                            ),
                                                          );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 20.h),
                                            ],
                                          ),
                                        ),
                                        content: Container(
                                          constraints: BoxConstraints(
                                            maxHeight: 900.h,
                                          ),
                                          width: 200.w,
                                          child: state.work.isEmpty
                                              ? NoData(isImage: true)
                                              : ListView.builder(
                                                  // physics: const NeverScrollableScrollPhysics(),
                                                  shrinkWrap: true,
                                                  itemCount: state.hasReachedMax
                                                      ? state.work.length
                                                      : state.work.length + 1,
                                                  itemBuilder: (BuildContext context, int index) {
                                                    if (index <
                                                        state.work.length) {
                                                      final isSelected =
                                                          worksId != null &&
                                                          state
                                                                  .work[index]
                                                                  .id ==
                                                              worksId;
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 2.h,
                                                              horizontal: 20.w,
                                                            ),
                                                        child: InkWell(
                                                          highlightColor: Colors
                                                              .transparent, // No highlight on tap
                                                          splashColor: Colors
                                                              .transparent,
                                                          onTap: () {
                                                            setState(() {
                                                              if (widget
                                                                      .isCreate ==
                                                                  true) {
                                                                worksname = state
                                                                    .work[index]
                                                                    .title!;
                                                                worksId = state
                                                                    .work[index]
                                                                    .id!;
                                                                widget.onSelected(
                                                                  state
                                                                      .work[index]
                                                                      .title!,
                                                                  state
                                                                      .work[index]
                                                                      .id!,
                                                                );
                                                              } else {
                                                                name = state
                                                                    .work[index]
                                                                    .title!;
                                                                worksname = state
                                                                    .work[index]
                                                                    .title!;
                                                                worksId = state
                                                                    .work[index]
                                                                    .id!;
                                                                widget.onSelected(
                                                                  state
                                                                      .work[index]
                                                                      .title!,
                                                                  state
                                                                      .work[index]
                                                                      .id!,
                                                                );
                                                              }
                                                            });

                                                            BlocProvider.of<
                                                                  SingleSelectWorkBloc
                                                                >(context)
                                                                .add(
                                                                  SelectSingleWork(
                                                                    index,
                                                                    state
                                                                        .work[index]
                                                                        .title!,
                                                                  ),
                                                                );

                                                            BlocProvider.of<
                                                                  SingleSelectWorkBloc
                                                                >(context)
                                                                .add(
                                                                  SelectSingleWork(
                                                                    index,
                                                                    state
                                                                        .work[index]
                                                                        .title!,
                                                                  ),
                                                                );
                                                          },
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: isSelected
                                                                  ? AppColors
                                                                        .purpleShade
                                                                  : Colors
                                                                        .transparent,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    isSelected
                                                                    ? AppColors
                                                                          .primary
                                                                    : Colors
                                                                          .transparent,
                                                              ),
                                                            ),
                                                            width:
                                                                double.infinity,
                                                            height: 40.h,
                                                            child: Center(
                                                              child: Container(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10.w,
                                                                    ),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                      flex: 4,
                                                                      // width:200.w,
                                                                      child: CustomText(
                                                                        text: state
                                                                            .work[index]
                                                                            .title!,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        size:
                                                                            18,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        color:
                                                                            isSelected
                                                                            ? AppColors.purple
                                                                            : Theme.of(
                                                                                context,
                                                                              ).colorScheme.textClrChange,
                                                                      ),
                                                                    ),
                                                                    isSelected
                                                                        ? Expanded(
                                                                            flex:
                                                                                1,
                                                                            child: const HeroIcon(
                                                                              HeroIcons.checkCircle,
                                                                              style: HeroIconStyle.solid,
                                                                              color: AppColors.purple,
                                                                            ),
                                                                          )
                                                                        : const SizedBox.shrink(),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    } else {
                                                      // Show a loading indicator when more notes are being loaded
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 0,
                                                            ),
                                                        child: Center(
                                                          child:
                                                              !state
                                                                  .hasReachedMax
                                                              ? const Text('')
                                                              : const SpinKitFadingCircle(
                                                                  color: AppColors
                                                                      .primary,
                                                                  size: 40.0,
                                                                ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                        ),
                                        actions: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(top: 20.h),
                                            child: CreateCancelButtom(
                                              title: "OK",
                                              onpressCancel: () {
                                                _workSearchController.clear();
                                                Navigator.pop(context);
                                              },
                                              onpressCreate: () {
                                                _workSearchController.clear();
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const Center(
                                    child: Text('Loading...'),
                                  );
                                },
                              ),
                            );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      height: 40.h,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: widget.isCreate == true
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.textfieldDisabled,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.greyColor),
                      ),
                      // decoration: DesignConfiguration.shadow(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: CustomText(
                              text: widget.isCreate
                                  ? (worksname?.isEmpty ?? true
                                        ? "Select Work"
                                        : worksname!)
                                  : (worksname?.isEmpty ?? true
                                        ? widget.name!
                                        : worksname!),
                              fontWeight: FontWeight.w500,
                              size: 14.sp,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              color: Theme.of(
                                context,
                              ).colorScheme.textClrChange,
                            ),
                          ),
                          widget.isCreate == false
                              ? SizedBox()
                              : Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
