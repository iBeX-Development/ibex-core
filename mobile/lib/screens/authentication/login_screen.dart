import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ibex/bloc/auth/auth_state.dart';
import 'package:ibex/bloc/auth/auth_bloc.dart';
import 'package:ibex/bloc/auth/auth_event.dart';
import 'package:ibex/bloc/permissions/permissions_bloc.dart';
import 'package:ibex/bloc/permissions/permissions_event.dart';
import 'package:ibex/bloc/setting/settings_bloc.dart';
import 'package:ibex/bloc/setting/settings_event.dart';
import 'package:ibex/bloc/status/status_bloc.dart';
import 'package:ibex/bloc/user_profile/user_profile_bloc.dart';
import 'package:ibex/bloc/user_profile/user_profile_event.dart';
import 'package:ibex/bloc/theme/theme_bloc.dart';
import 'package:ibex/bloc/theme/theme_event.dart';
import 'package:ibex/bloc/theme/theme_state.dart';

import 'package:ibex/config/app_images.dart';
import 'package:ibex/config/colors.dart';
import 'package:ibex/config/constants.dart';
import 'package:ibex/config/end_points.dart';
import 'package:ibex/config/internet_connectivity.dart';
import 'package:ibex/config/strings.dart';
import 'package:ibex/data/localStorage/hive.dart';
import 'package:ibex/data/repositories/Auth/auth_repo.dart';
import 'package:ibex/routes/routes.dart';
import 'package:ibex/screens/authentication/widgets/auth_textfield.dart';
import 'package:ibex/utils/widgets/custom_text.dart';
import 'package:ibex/utils/widgets/no_internet_screen.dart';
import 'package:ibex/utils/widgets/toast_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/status/status_event.dart';
import '../../bloc/workspace/workspace_bloc.dart';
import '../../bloc/workspace/workspace_event.dart';
import '../../src/generated/i18n/app_localizations.dart';
import '../widgets/custom_button.dart';
import '../widgets/validation.dart';

/// An enum to represent different user types for login
enum UserType { admin, member, client, none }

/// Service class for handling FCM token operations
class FCMService {
  static Future<String?> getFCMToken() async {
    if (Firebase.apps.isEmpty) return null;
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    if (token != null) {
      await HiveStorage.setFcm(token);
      // auth_repo
      AuthRepository().getFcmId(fcmId: token);
    }
    return token;
  }
}

/// A screen that handles user authentication through login
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  bool _showPassword = true;
  bool _rememberMe = false;
  UserType _userType = UserType.none;
  String? _fcmToken;

  // Connectivity variables
  List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadSavedCredentials();
    _markFirstTimeVisit();
    _attachAuthListener();
    _emailController.addListener(_persistRememberedCredentials);
    _passwordController.addListener(_persistRememberedCredentials);
    // initFCM(); // neeh FCM token
  }

  /// Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    final results = await CheckInternet.initConnectivity();
    setState(() {
      _connectionStatus = results;
    });

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  /// Update connection status based on connectivity changes
  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    if (results.isNotEmpty) {
      final updatedStatus = await CheckInternet.updateConnectionStatus(results);
      setState(() {
        _connectionStatus = updatedStatus;
      });
    } else {
      _showNoInternetToast();
    }
  }

  /// Initialize FCM token
  // Future<void> _initFCM() async {
  //   final token = await FCMService.getFCMToken();
  //   if (mounted) {
  //     setState(() {
  //       _fcmToken = token;
  //     });
  //   }
  // }
  final fcmService = FCMService();

  void initFCM() async {
    final token = await FCMService.getFCMToken();
    if (token != null) {
      // Send token to your backend if needed
    }
  }

  /// Mark app as not first time visit
  void _markFirstTimeVisit() {
    HiveStorage.setIsFirstTime(false);
  }

  /// Load saved credentials if remember me was checked
  Future<void> _loadSavedCredentials() async {
    // Import policy: do not populate credentials from stored or preset accounts.
    _rememberMe = false;
}

  /// Save credentials to local storage
  Future<void> _saveCredentials() async {
    // Manual login remains available; credential persistence is disabled.
}

  Future<void> _setRememberMe(bool value) async {
    setState(() { _rememberMe = false; });
    if (value) flutterToastCustom(msg: 'Credential autofill is disabled.', color: AppColors.red);
}

  Future<void> _persistRememberedCredentials() async {
    // No credential persistence or autofill in the import copy.
}

  /// Show toast message for no internet connection
  void _showNoInternetToast() {
    if (!mounted) return;
    flutterToastCustom(
      msg: AppLocalizations.of(context)!.nointernet,
      color: AppColors.red,
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_persistRememberedCredentials);
    _passwordController.removeListener(_persistRememberedCredentials);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _connectivitySubscription.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Handle user login based on selected user type
  void _handleDemoLogin(UserType type) {
    FocusScope.of(context).unfocus();
    flutterToastCustom(msg: 'Credential autofill is disabled. Enter your credentials manually.', color: AppColors.red);
}

  /// Set login credentials in controllers and Bloc
  void _setLoginCredentials({required String email, required String password}) {
    _emailController.text = email;
    _passwordController.text = password;
    context.read<AuthBloc>().add(GetEmail(email: email));
    context.read<AuthBloc>().add(GetPassword(password: password));
  }

  /// Submit login form and handle authentication
  void _submitLoginForm() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showValidationErrorToast();
      return;
    }

    context.read<AuthBloc>().add(GetEmail(email: _emailController.text.trim()));
    context.read<AuthBloc>().add(
          GetPassword(password: _passwordController.text),
        );
    await _saveCredentials();
    BlocProvider.of<AuthBloc>(context).add(AuthSignIn());
  }

  /// Show appropriate validation error toast
  void _showValidationErrorToast() {
    if (_emailController.text.isEmpty && _passwordController.text.isEmpty) {
      flutterToastCustom(msg: AppLocalizations.of(context)!.emailpassreq);
    } else if (_emailController.text.isEmpty) {
      flutterToastCustom(msg: AppLocalizations.of(context)!.emailreq);
    } else if (_passwordController.text.isEmpty) {
      flutterToastCustom(msg: AppLocalizations.of(context)!.pasreq);
    }
  }

  /// Listen to authentication events and handle responses
  void _attachAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = context.read<AuthBloc>().stream.listen((event) {
      if (!mounted) return;

      if (event is AuthLoadSuccess) {
        _handleAuthSuccess();
      } else if (event is AuthLoadFailure) {
        flutterToastCustom(msg: event.message, color: AppColors.red);
      }
    });
  }

  /// Handle successful authentication
  void _handleAuthSuccess() {
    flutterToastCustom(
      msg: AppLocalizations.of(context)!.successfullyloggedIn,
      color: AppColors.primary,
    );

    // Dispatch events after successful login
    context.read<SettingsBloc>().add(const SettingsList("general_settings"));
    context.read<PermissionsBloc>().add(GetPermissions());
    context.read<WorkspaceBloc>().add(WorkspaceList());
    context.read<UserProfileBloc>().add(ProfileListGet());
    BlocProvider.of<StatusBloc>(context).add(StatusList());

    _listenToSettingsEvents();
  }

  /// Listen to settings events after successful login
  void _listenToSettingsEvents() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        router.go('/dashboard');
      }
    });

    // final settingsBloc = context.read<SettingsBloc>();
    // settingsBloc.stream.listen((state) {
    //   if (!mounted) return;

    //   if (state is SettingsSuccess) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       router.go('/dashboard');
    //     });
    //   } else if (state is SettingsError) {
    //     router.go("/emailVerification");
    //     flutterToastCustom(msg: state.errorMessage);
    //   }
    // });
  }

  /// Launch URL for forgot password
  Future<void> _launchForgotPasswordUrl() async {
    final url = Uri.parse(forgetPasswordUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      flutterToastCustom(
        msg: 'Could not open the link: ${e.toString()}',
        color: AppColors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionStatus.contains(ConnectivityResult.none)) {
      return const NoInternetScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.backGroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(overscroll: false),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 34.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 40.h),
                          _buildTopBar(),
                          Spacer(),
                          _buildLoginForm(),
                          Spacer(),
                          Center(
                            child: CustomText(
                              text: 'iBeX',
                              size: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greyForgetColor,
                            ),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the top bar with logo and theme toggle
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 44.w,
          width: 44.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.greyForgetColor.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: ClipOval(
            child: Image.asset(AppImages.splashLogo, fit: BoxFit.cover),
          ),
        ),
        BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final isDark = state is DarkThemeState;
            return InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => context.read<ThemeBloc>().add(ToggleThemeEvent()),
              child: Container(
                height: 36.w,
                width: 36.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.greyForgetColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 18.sp,
                  color: isDark
                      ? AppColors.yellow
                      : AppColors.orangeYellowishColor,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds the login form
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel(AppLocalizations.of(context)!.email),
            SizedBox(height: 8.h),
            _buildEmailField(),
            SizedBox(height: 22.h),
            _buildFieldLabel(AppLocalizations.of(context)!.password),
            SizedBox(height: 8.h),
            _buildPasswordField(),
            SizedBox(height: 12.h),
            _buildRememberMeRow(),
            SizedBox(height: 52.h),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return CustomText(
      text: text,
      size: 12.sp,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.textFieldColor,
    );
  }

  /// Builds the email input field
  Widget _buildEmailField() {
    return AuthCustomTextField(
      controller: _emailController,
      focusNode: _emailFocus,
      labelText: '',
      hintText: AppLocalizations.of(context)!.email,
      prefixIcon: Icon(
        Icons.person_outline,
        color: Theme.of(context).colorScheme.textFieldColor,
        size: 20.sp,
      ),
      fillColor: AppColors.disableColor,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      validator: (value) => StringValidation.validateEmail(value ?? ''),
      onSaved: (value) {
        if (value != null) {
          context.read<AuthBloc>().add(GetEmail(email: value));
        }
      },
      onChanged: (val) {
        context.read<AuthBloc>().add(GetEmail(email: val));
      },
    );
  }

  /// Builds the password input field
  Widget _buildPasswordField() {
    return AuthCustomTextField(
      controller: _passwordController,
      focusNode: _passFocus,
      labelText: '',
      hintText: AppLocalizations.of(context)!.password,
      prefixIcon: Icon(
        Icons.lock_outline,
        color: Theme.of(context).colorScheme.textFieldColor,
        size: 20.sp,
      ),
      fillColor: AppColors.disableColor,
      keyboardType: TextInputType.visiblePassword,
      obscureText: _showPassword,
      autofillHints: const [AutofillHints.password],
      inputFormatters: [FilteringTextInputFormatter.deny(RegExp('[ ]'))],
      validator: (value) => StringValidation.validatePass(
        value ?? '',
        AppLocalizations.of(context)!.pasreq,
        "please enter valid password",
        onlyRequired: false,
      ),
      onSaved: (value) {
        if (value != null) {
          context.read<AuthBloc>().add(GetPassword(password: value));
        }
      },
      onChanged: (val) {
        context.read<AuthBloc>().add(GetPassword(password: val));
      },
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _showPassword = !_showPassword;
          });
        },
        icon: Icon(
          _showPassword ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).colorScheme.fontColor.withValues(alpha: 0.4),
          size: 22.sp,
        ),
      ),
    );
  }

  /// Builds the remember me checkbox and forgot password link
  Widget _buildRememberMeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                _setRememberMe(value ?? false);
              },
              activeColor: AppColors.primary,
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.fontColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () {
                _setRememberMe(!_rememberMe);
              },
              child: CustomText(
                text: 'Сануулах',
                size: 12.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.fontColor,
              ),
            ),
          ],
        ),
        InkWell(
          splashColor: Colors.transparent,
          onTap: _launchForgotPasswordUrl,
          child: Padding(
            padding: EdgeInsets.only(right: 5.w),
            child: CustomText(
              text: AppLocalizations.of(context)!.forgetPassword,
              size: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.greyForgetColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return InkWell(
      splashColor: Colors.transparent,
      onTap: _launchForgotPasswordUrl,
      child: Padding(
        padding: EdgeInsets.only(right: 2.w),
        child: CustomText(
          text: AppLocalizations.of(context)!.forgetPassword,
          size: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Builds the login button
  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _submitLoginForm();
      },
      child: Center(
        child: CustomButton(
          height: 50.h,
          // width: 310.w,
          isLoading: false,
          isLogin: true,
          isBorder: true,
          text: AppLocalizations.of(context)!.login,
          textcolor: AppColors.pureWhiteColor,
        ),
      ),
    );
  }
}
