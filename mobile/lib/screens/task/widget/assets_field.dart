import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';

import 'package:ibex/config/colors.dart';
import 'package:ibex/config/constants.dart';
import 'package:ibex/screens/widgets/no_data.dart';

import '../../../bloc/asset/asset_bloc.dart';
import '../../../bloc/asset/asset_event.dart';
import '../../../bloc/asset/asset_state.dart';

import '../../../bloc/theme/theme_bloc.dart';
import '../../../bloc/theme/theme_state.dart';
import '../../../config/strings.dart';
import '../../../data/model/task/task_model.dart';
import '../../../src/generated/i18n/app_localizations.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/my_theme.dart';
import '../../widgets/custom_cancel_create_button.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AssetField extends StatefulWidget {
  final bool? isRequired;
  final bool isCreate;
  final bool? isMeeting;
  final List<String> assetname;
  final List<int> assetid;
  final List<Tasks> project;
  final Function(List<String>, List<int>) onSelected;
  const AssetField({
    super.key,
    assetField,
    this.isRequired = false,
    required this.assetid,
    required this.isCreate,
    this.isMeeting,
    required this.assetname,
    required this.project,
    required this.onSelected,
  });

  @override
  State<AssetField> createState() => _AssetFieldState();
}

class _AssetFieldState extends State<AssetField> {
  String? projectsname;
  int? projectsId;
  List<int> userSelectedId = [];
  List<String> userSelectedname = [];
  String searchWord = "";
  int? userId;
  String? currentUserId;
  final TextEditingController _userSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserId().then((_) {
      if (widget.isCreate && userId != null) {
        userSelectedId.add(userId!);
      }
      BlocProvider.of<AssetBloc>(context).add(AssetList());
    });
  }

  Future<void> getUserId() async {
    var userbox = await Hive.openBox(userBox);
    userId = userbox.get('user_id');
    currentUserId = userbox.get('user_uuid')?.toString();
  }

  // ✅ Helper method with null check
  void _showAssetDialog() {
    // if (currentUserId == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('User information not loaded. Please wait...'),
    //       backgroundColor: AppColors.red,
    //       duration: Duration(seconds: 2),
    //     ),
    //   );
    //   return;
    // }

    showDialog(
      context: context,
      builder: (ctx) => _AssetDialogContent(
        searchWord: searchWord,
        userSelectedId: userSelectedId,
        userSelectedname: userSelectedname,
        onSelected: widget.onSelected,
        assetid: widget.assetid,
        currentUserId: currentUserId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < widget.assetid.length; i++) {
      final id = widget.assetid[i];
      if (!userSelectedId.contains(id)) {
        userSelectedId.add(id);
        if (widget.assetname.isNotEmpty) {
          userSelectedname.add(widget.assetname[i]);
        }
      }
    }

    final themeBloc = context.read<ThemeBloc>();
    final currentTheme = themeBloc.currentThemeState;
    bool isLightTheme = currentTheme is LightThemeState;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              Row(
                children: [
                  CustomText(
                    text: AppLocalizations.of(context)!.asset,
                    color: Theme.of(context).colorScheme.textClrChange,
                    size: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  if (widget.isRequired == true)
                    const CustomText(
                      text: " *",
                      color: AppColors.red,
                      size: 15,
                      fontWeight: FontWeight.w400,
                    ),
                ],
              ),
            ],
          ),
        ),
        BlocBuilder<AssetBloc, AssetState>(
          builder: (context, state) {
            // ✅ Common container widget
            Widget buildContainer() {
              return AbsorbPointer(
                absorbing: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5.h),
                    InkWell(
                      splashColor: Colors.transparent,
                      onTap: () {
                        if (state is AssetInitial) {
                          BlocProvider.of<AssetBloc>(context).add(AssetList());
                        }
                        _showAssetDialog(); // ✅ Use helper method
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        height: 40.h,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.greyColor),
                          color: state is AssetSuccess
                              ? Theme.of(context).colorScheme.containerDark
                              : null,
                          boxShadow: state is AssetSuccess
                              ? [
                                  isLightTheme
                                      ? MyThemes.lightThemeShadow
                                      : MyThemes.darkThemeShadow,
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomText(
                                text: widget.isCreate
                                    ? (userSelectedname.isNotEmpty
                                          ? userSelectedname.join(", ")
                                          : AppLocalizations.of(
                                              context,
                                            )!.selectasset)
                                    : (widget.assetname.isNotEmpty
                                          ? widget.assetname.join(", ")
                                          : AppLocalizations.of(
                                              context,
                                            )!.selectasset),
                                fontWeight: FontWeight.w500,
                                size: state is AssetSuccess ? 12.sp : 14.sp,
                                color: Theme.of(
                                  context,
                                ).colorScheme.textClrChange,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // ✅ All states use the same container
            return buildContainer();
          },
        ),
      ],
    );
  }
}

// ✅ _AssetDialogContent - currentUserId optional parameter
class _AssetDialogContent extends StatefulWidget {
  final String searchWord;
  final List<int> userSelectedId;
  final List<String> userSelectedname;
  final Function(List<String>, List<int>) onSelected;
  final List<int> assetid;
  final String? currentUserId;

  const _AssetDialogContent({
    required this.searchWord,
    required this.userSelectedId,
    required this.userSelectedname,
    required this.onSelected,
    required this.assetid,
    this.currentUserId,
  });

  @override
  State<_AssetDialogContent> createState() => _AssetDialogContentState();
}

class _AssetDialogContentState extends State<_AssetDialogContent> {
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  String searchWord = "";
  Timer? _debounce; // ✅ Add debounce timer

  @override
  void initState() {
    super.initState();
    searchWord = widget.searchWord;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0) {
        final state = context.read<AssetBloc>().state;

        if (state is AssetPaginated) {
          if (!state.hasReachedMax && !state.isLoading) {
            context.read<AssetBloc>().add(
              LoadMoreAsset(searchQuery: searchWord),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // ✅ Cancel timer
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // ✅ Cancel previous timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // ✅ Update local state immediately
    setState(() {
      searchWord = value;
    });

    // ✅ Debounce API call
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AssetBloc>().add(SearchAsset(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetBloc, AssetState>(
      builder: (context, state) {
        if (state is AssetSuccess || state is AssetPaginated) {
          final assets = state is AssetSuccess
              ? state.asset
              : (state as AssetPaginated).asset;
          final hasReachedMax = state is AssetSuccess
              ? true
              : (state as AssetPaginated).hasReachedMax;
          final isLoading = state is AssetPaginated ? state.isLoading : false;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.alertBoxBackGroundColor,
            contentPadding: EdgeInsets.zero,
            title: Center(
              child: Column(
                children: [
                  CustomText(
                    text: AppLocalizations.of(context)!.selectasset,
                    fontWeight: FontWeight.w800,
                    size: 20,
                    color: Theme.of(context).colorScheme.whitepurpleChange,
                  ),
                  const Divider(),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 35.h,
                    child: TextField(
                      controller: _searchController,
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
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
            content: Container(
              constraints: BoxConstraints(maxHeight: 400.h),
              width: MediaQuery.of(context).size.width,
              child: assets.isEmpty
                  ? NoData(isImage: true)
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        // ✅ Alternative scroll listener
                        if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                          final state = context.read<AssetBloc>().state;

                          if (state is AssetPaginated) {
                            if (!state.hasReachedMax && !state.isLoading) {
                              context.read<AssetBloc>().add(
                                LoadMoreAsset(searchQuery: searchWord),
                              );
                            }
                          } else {
                            logger.d(
                              '⚠️ State is not AssetPaginated: ${state.runtimeType}',
                            );
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        physics:
                            const AlwaysScrollableScrollPhysics(), // ✅ Enable scrolling
                        itemCount: hasReachedMax
                            ? assets.length
                            : assets.length + 1,
                        itemBuilder: (BuildContext context, int index) {
                          if (index < assets.length) {
                            final isSelected = widget.userSelectedId.contains(
                              assets[index].id!,
                            );

                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 2.h,
                                horizontal: 20.w,
                              ),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      final removeIndex = widget.userSelectedId
                                          .indexOf(assets[index].id!);
                                      widget.userSelectedId.removeAt(
                                        removeIndex,
                                      );
                                      widget.userSelectedname.removeAt(
                                        removeIndex,
                                      );
                                      widget.assetid.removeAt(removeIndex);
                                    } else {
                                      widget.userSelectedId.add(
                                        assets[index].id!,
                                      );
                                      widget.userSelectedname.add(
                                        assets[index].asset_code ?? 'Unknown',
                                      );
                                      widget.assetid.add(assets[index].id!);
                                    }

                                    widget.onSelected(
                                      widget.userSelectedname,
                                      widget.userSelectedId,
                                    );

                                    context.read<AssetBloc>().add(
                                      SelectedAsset(
                                        id: assets[index].id!,
                                        title:
                                            assets[index].asset_code ??
                                            'Unknown',
                                        isSelected: !isSelected,
                                      ),
                                    );
                                  });
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundImage:
                                                    assets[index].image != null
                                                    ? NetworkImage(
                                                        '${activePictureUrl}/${assets[index].image}',
                                                      )
                                                    : null,
                                                child:
                                                    assets[index].image == null
                                                    ? const Icon(
                                                        Icons.person,
                                                        size: 20,
                                                      )
                                                    : null,
                                              ),
                                              SizedBox(width: 10.w),
                                              Expanded(
                                                child: CustomText(
                                                  text:
                                                      assets[index]
                                                          .asset_code ??
                                                      'Unknown',
                                                  fontWeight: FontWeight.w500,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  size: 14.sp,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .textClrChange,
                                                ),
                                              ),
                                            ],
                                          ),
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
                          } else {
                            // ✅ Loading indicator
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: hasReachedMax
                                    ? const SizedBox.shrink()
                                    : Column(
                                        children: [
                                          const SpinKitFadingCircle(
                                            color: AppColors.primary,
                                            size: 40.0,
                                          ),
                                          SizedBox(height: 10.h),
                                          const Text('Loading more...'),
                                        ],
                                      ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: CreateCancelButtom(
                  title: "OK",
                  onpressCancel: () {
                    _searchController.clear();
                    Navigator.pop(context);
                  },
                  onpressCreate: () {
                    _searchController.clear();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          );
        } else if (state is AssetLoading) {
          return const Center(
            child: SpinKitFadingCircle(color: AppColors.primary, size: 50.0),
          );
        } else if (state is AssetError) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(state.errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
