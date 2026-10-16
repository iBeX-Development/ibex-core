import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/user_profile/user_profile_bloc.dart';
import '../../../bloc/user_profile/user_profile_state.dart';
import '../../../config/colors.dart';
import '../../../config/constants.dart';
import '../../../../src/generated/i18n/app_localizations.dart';
import '../../../utils/widgets/custom_text.dart';
import '../../../utils/widgets/my_theme.dart';

class WelcomeCard extends StatelessWidget {
  final bool isLightTheme;
  final String? greetingMessage;
  final String? greetingEmoji;
  final String? photo;

  const WelcomeCard({
    super.key,
    required this.isLightTheme,
    required this.greetingMessage,
    required this.greetingEmoji,
    this.photo,
  });

  // Helper method to validate UUID format
  bool _isValidUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    // UUID format: 8-4-4-4-12 hex characters
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Container(
        decoration: BoxDecoration(
            boxShadow: [
              isLightTheme
                  ? MyThemes.lightThemeShadow
                  : MyThemes.darkThemeShadow,
            ],
            color: Theme.of(context).colorScheme.containerDark,
            borderRadius: BorderRadius.circular(12)),
        width: double.infinity,
        height: 100.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocConsumer<UserProfileBloc, UserProfileState>(
                  listener: (context, state) {
                if (state is UserProfileSuccess) {
                } else if (state is UserProfileError) {
                  // Show error message
                }
              }, builder: (context, state) {
                if (state is UserProfileSuccess) {
                  final firstNameUser =
                      context.read<UserProfileBloc>().firstname ?? "First Name";
                  final photoWidget =
                      context.read<UserProfileBloc>().profilePic ?? "Photo";

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      state.profile.isNotEmpty
                          ? Row(
                              children: [
                                InkWell(
                                    onTap: () {
                                      // router.push("/profile");
                                    },
                                    child: SizedBox(
                                      width: 60.w,
                                      child: GlowContainer(
                                          shape: BoxShape.circle,
                                          glowColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          spreadRadius: 10,
                                          child: CircleAvatar(
                                            radius: 35.r,
                                            backgroundImage:
                                                (photoWidget != "Photo" &&
                                                        photoWidget.isNotEmpty)
                                                    ? NetworkImage(photoWidget)
                                                    : null,
                                            backgroundColor: Colors.grey[200],
                                            child: (photoWidget == "Photo" ||
                                                    photoWidget.isEmpty)
                                                ? Icon(
                                                    Icons.person,
                                                    color: Colors.grey,
                                                    size: 30.r,
                                                  )
                                                : null,
                                          )),
                                    )),
                                SizedBox(
                                  width: 25.w,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: AppLocalizations.of(context)!.hey,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .textClrChange,
                                      size: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    CustomText(
                                      text:
                                          "${context.read<UserProfileBloc>().firstname} ${context.read<UserProfileBloc>().lastName} !",
                                      color: Theme.of(context)
                                          .colorScheme
                                          .textClrChange,
                                      size: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Padding(
                              padding: EdgeInsets.only(top: 0.h),
                              child: Row(
                                children: [
                                  InkWell(
                                      onTap: () {
                                        // router.push("/profile");
                                      },
                                      child: SizedBox(
                                        width: 60.w,
                                        child: GlowContainer(
                                          shape: BoxShape.circle,
                                          glowColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.transparent,
                                            radius: 36.r,
                                            child: (photoWidget != "Photo" &&
                                                    photoWidget.isNotEmpty)
                                                ? CircleAvatar(
                                                    radius: 35.r,
                                                    backgroundImage:
                                                        NetworkImage(
                                                            photoWidget),
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                  )
                                                : CircleAvatar(
                                                    radius: 35.r,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.grey,
                                                      size: 30.r,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      )),
                                  SizedBox(
                                    width: 25.w,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        text: AppLocalizations.of(context)!.hey,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .textClrChange,
                                        size: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      CustomText(
                                        text:
                                            "${context.read<UserProfileBloc>().firstname} !",
                                        color: Theme.of(context)
                                            .colorScheme
                                            .textClrChange,
                                        size: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SizedBox(
                    width: 50.w,
                    child: CircleAvatar(
                      radius: 26.r,
                      backgroundColor:
                          Theme.of(context).colorScheme.backGroundColor,
                      child: CircleAvatar(
                        radius: 25.r,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
