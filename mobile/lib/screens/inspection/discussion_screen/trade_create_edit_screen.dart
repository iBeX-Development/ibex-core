import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/data/model/inspection/trade.dart';

import '../../../bloc/inspection_discussion/inspection_trade/inspection_trade_bloc.dart';
import '../../../bloc/inspection_discussion/inspection_trade/inspection_trade_event.dart';
import '../../../bloc/inspection_discussion/inspection_trade/inspection_trade_state.dart';
import '../../../bloc/theme/theme_bloc.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../config/constants.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../../routes/routes.dart';
import '../../../utils/widgets/back_arrow.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/my_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../utils/widgets/toast_widget.dart';
import '../../style/design_config.dart';
import '../../widgets/custom_cancel_create_button.dart';
import '../../widgets/custom_date.dart';
import '../../widgets/custom_textfields/custom_textfield.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class InspectionTradeCreateEditScreen extends StatefulWidget {
  final bool? isCreate;
  final InspectionsTrade partModel;
  final int inspectionId;
  const InspectionTradeCreateEditScreen({
    super.key,
    this.isCreate,
    required this.partModel,
    required this.inspectionId,
  });

  @override
  State<InspectionTradeCreateEditScreen> createState() =>
      _InspectionTradeCreateEditScreenState();
}

class _InspectionTradeCreateEditScreenState
    extends State<InspectionTradeCreateEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController budgetController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController startsController = TextEditingController();
  TextEditingController endController = TextEditingController();

  DateTime selectedDateStarts = DateTime.now();
  DateTime? selectedDateEnds = DateTime.now();
  String? fromDate;
  String? toDate;
  String? selectedStatus;
  double _value = 0;
  double valueInProgress = 0;
  String? formattedend;
  String? formattedstart;

  @override
  void initState() {
    if (kDebugMode) {
      logger.d("esrjfm,jn ${widget.inspectionId}");
    }
    if (widget.isCreate == false) {
      if (widget.partModel.startDate != null &&
          widget.partModel.startDate!.isNotEmpty &&
          widget.partModel.startDate != "") {
        DateTime parsedDateStart = parseDateStringFromApi(
          widget.partModel.startDate!,
        );
        formattedstart = dateFormatConfirmed(parsedDateStart, context);
        selectedDateStarts = parsedDateStart;
        "${dateFormatConfirmed(selectedDateStarts, context)}  ↔️  ${dateFormatConfirmed(selectedDateEnds!, context)}";
      }
      if (widget.partModel.endDate != null &&
          widget.partModel.endDate!.isNotEmpty &&
          widget.partModel.endDate != "") {
        DateTime parsedDateEnd = parseDateStringFromApi(
          widget.partModel.endDate!,
        );
        formattedend = dateFormatConfirmed(parsedDateEnd, context);
        selectedDateEnds = parsedDateEnd;
        startsController.text =
            "${dateFormatConfirmed(selectedDateStarts, context)}  ↔️  ${dateFormatConfirmed(selectedDateEnds!, context)}";
      }
      titleController = TextEditingController(
        text: widget.partModel.title,
      );
      budgetController = TextEditingController(
        text: widget.partModel.cost,
      );
      descController = TextEditingController(
        text: removeHtmlTags(widget.partModel.description!),
      );
      selectedStatus = widget.partModel.status;
      _value = widget.partModel.progress!.toDouble() / 100;
    }

    super.initState();
  }

  void _handleStatusSelected(String category) {
    setState(() {
      selectedStatus = category;
    });
  }

  void _onUpdateInspectionTrade(value) {
    if (titleController.text.isNotEmpty &&
        budgetController.text.isNotEmpty &&
        selectedStatus != null) {
      String cost = budgetController.text.replaceAll(RegExp(r'[^\d.]'), '');
      context.read<InspectionTradeBloc>().add(
            UpdateTradeInspection(
              id: widget.partModel.id!,
              workId: widget.inspectionId,
              title: titleController.text,
              progress: valueInProgress.round(),
              startDate: formattedstart ?? widget.partModel.startDate!,
              endDate: formattedend ?? widget.partModel.endDate!,
              desc: descController.text,
              status: selectedStatus ?? widget.partModel.status!,
              cost: cost,
            ),
          );
    } else {
      flutterToastCustom(
        msg: AppLocalizations.of(context)!.pleasefilltherequiredfield,
      );
    }
  }

  void _onAddInspectionTrade() {
    if (titleController.text.isNotEmpty &&
        budgetController.text.isNotEmpty &&
        selectedStatus != null) {
      context.read<InspectionTradeBloc>().add(
            InspectionTradeCreated(
              projId: widget.inspectionId,
              title: titleController.text,
              startDate: fromDate ?? "",
              endDate: toDate ?? "",
              desc: descController.text.isNotEmpty ? descController.text : "",
              status: selectedStatus ?? "",
              cost:
                  budgetController.text.isNotEmpty ? budgetController.text : "",
            ),
          );
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

    bool isLightTheme = currentTheme is LightThemeState;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          router.pop(context);
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
                    // if (widget.fromDetail == true && widget.isCreate == false) {
                    //
                    //   BlocProvider.of<InspectionidBloc>(context).add(InspectionIdListId(widget.id));
                    //   router.pop(context);
                    // } else {
                    //   router.pop(context);
                    // }
                  },
                  child: BackArrow(
                    title: widget.isCreate == false
                        ? AppLocalizations.of(context)!.editpart
                        : AppLocalizations.of(context)!.addpart,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body(isLightTheme) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFields(
              title: AppLocalizations.of(context)!.title,
              hinttext: AppLocalizations.of(context)!.pleaseentertitle,
              controller: titleController,
              onSaved: (value) {},
              isLightTheme: isLightTheme,
              isRequired: true,
            ),
            SizedBox(height: 15.h),
            CustomTextFields(
              currency: true,
              title: AppLocalizations.of(context)!.cost,
              hinttext: AppLocalizations.of(context)!.pleaseentercost,
              controller: budgetController,
              onSaved: (value) {},
              keyboardType: TextInputType.number,
              isLightTheme: isLightTheme,
              isRequired: true,
            ),
            SizedBox(height: 15.h),
            CustomTextFields(
              height: 112.h,
              keyboardType: TextInputType.multiline,
              title: AppLocalizations.of(context)!.description,
              hinttext: AppLocalizations.of(context)!.pleaseenterdescription,
              controller: descController,
              onSaved: (value) {},
              isLightTheme: isLightTheme,
              isRequired: false,
            ),

            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: DateRangePickerWidget(
                dateController: startsController,
                title: AppLocalizations.of(context)!.date,
                titlestartend: AppLocalizations.of(context)!.selectstartenddate,
                selectedDateEnds: selectedDateEnds,
                selectedDateStarts: selectedDateStarts,
                isLightTheme: isLightTheme,
                onTap: (start, end) {
                  setState(() {
                    // Ensure the start date is not before the current date

                    // If the end date is not selected or is null, set it to the start date
                    if (selectedDateEnds == null) {
                      end =
                          start; // Set the end date to the start date if not selected
                    }
                    startsController.text =
                        "${dateFormatConfirmed(selectedDateStarts, context)} <-> ${dateFormatConfirmed(selectedDateEnds!, context)}";
                    endController.text = dateFormatConfirmed(
                      selectedDateEnds!,
                      context,
                    );
                    fromDate = dateFormatConfirmedToApi(start!);
                    toDate = dateFormatConfirmedToApi(end!);
                  });
                },
              ),
            ),
            SizedBox(height: 15.h),
            widget.isCreate == false
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        child: CustomText(
                          text: AppLocalizations.of(context)!.progress,
                          size: 14.sp,
                          color: Theme.of(context).colorScheme.textClrChange,
                          fontWeight: FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _value,
                              onChanged: (v) {
                                setState(() {
                                  _value = v;
                                  valueInProgress = v * 100;
                                  if (kDebugMode) {
                                    logger.d("efjhgzdsbc  $valueInProgress");
                                  }
                                });
                              },
                              label: _value.toStringAsFixed(2),
                            ),
                          ),
                          CustomText(
                            text: "${(_value * 100).toStringAsFixed(0)}%",
                            size: 15.sp,
                            color: Theme.of(context).colorScheme.textClrChange,
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ],
                  )
                : SizedBox.shrink(),
            SizedBox(height: 15.h),
            BlocBuilder<InspectionTradeBloc, InspectionTradeState>(
              builder: (context, state) {
                if (state is InspectionTradeTradePaginated) {
                  if (kDebugMode) {
                    logger.d("kjrfdhnv $valueInProgress");
                  }
                  return CreateCancelButtom(
                    isLoading: false,
                    isCreate: widget.isCreate,
                    onpressCancel: () {
                      Navigator.pop(context);
                    },
                    onpressCreate: widget.isCreate == true
                        ? () async {
                            // _onCreate();
                          }
                        : () {
                            _onUpdateInspectionTrade(valueInProgress);
                          },
                  );
                }
                if (state is InspectionTradeCreateSuccess) {
                  Navigator.pop(context);
                  flutterToastCustom(
                    msg: AppLocalizations.of(context)!.createdsuccessfully,
                    color: AppColors.primary,
                  );
                  BlocProvider.of<InspectionTradeBloc>(
                    context,
                  ).add(InspectionTradeList(id: widget.inspectionId));
                }
                if (state is InspectionTradeCreateError) {
                  flutterToastCustom(
                    msg: state.errorMessage,
                    color: AppColors.primary,
                  );
                  BlocProvider.of<InspectionTradeBloc>(
                    context,
                  ).add(InspectionTradeList(id: widget.inspectionId));
                }
                if (state is InspectionTradeEditSuccess) {
                  BlocProvider.of<InspectionTradeBloc>(
                    context,
                  ).add(InspectionTradeList(id: widget.inspectionId));
                  router.pop(context);
                }
                return CreateCancelButtom(
                  isLoading: false,
                  isCreate: widget.isCreate,
                  onpressCancel: () {
                    Navigator.pop(context);
                  },
                  onpressCreate: widget.isCreate == true
                      ? () async {
                          _onAddInspectionTrade();
                        }
                      : () {
                          _onUpdateInspectionTrade(valueInProgress);
                        },
                );
              },
            ),
            // CreateCancelButtom(),
          ],
        ),
      ),
    );
  }
}
