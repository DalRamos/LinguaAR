import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/bloc/Change_disability/change_disability_bloc.dart';
import 'package:lingua_arv1/bloc/Change_email/change_email_bloc.dart';
import 'package:lingua_arv1/bloc/Change_password/change_password_bloc.dart';
import 'package:lingua_arv1/bloc/Otp/otp_bloc.dart';
import 'package:lingua_arv1/repositories/change_disability_repositories/change_disability_repository_impl.dart';
import 'package:lingua_arv1/repositories/change_email_repositories/change_email_repository_impl.dart';
import 'package:lingua_arv1/repositories/change_password_repositories/reset_password_repository.dart';
import 'package:lingua_arv1/repositories/change_password_repositories/reset_password_repository_impl.dart';
import 'package:lingua_arv1/repositories/otp_repositories/otp_repository_impl.dart';
import 'package:lingua_arv1/screens/authentication/login/login_page.dart';
import 'package:lingua_arv1/screens/settings/Dialog/dialogs.dart';
import 'package:lingua_arv1/screens/settings/Lists/setting_list_tile.dart';
import 'package:lingua_arv1/screens/settings/Update_Accounts/update_disability_page.dart';
import 'package:lingua_arv1/screens/settings/Update_Accounts/update_email_page.dart';
import 'package:lingua_arv1/screens/settings/Update_Accounts/update_password_page.dart';
import 'package:lingua_arv1/screens/settings/theme/theme_provider.dart';
import 'package:lingua_arv1/validators/token.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userId;
  Map<String, String> settings = {};
  bool _isLoading = true; // ✅ shimmer flag

  Future<void> _loadUserId() async {
    String? fetchedUserId = await TokenService.getUserId();
    String? fetchedEmail = await TokenService.getEmail();
    String? fetchedDisability = await TokenService.getDisability();
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (mounted) {
      setState(() {
        userId = fetchedUserId ?? 'Unknown';
        settings['Email'] = fetchedEmail ?? 'No Email Found';
        settings['Theme'] = isDarkMode ? 'Dark' : 'Light';
        settings['Disability'] = fetchedDisability ?? 'None';
        _isLoading = false; // ✅ stop shimmer
      });
    }
  }

  late ScrollController _scrollController;
  Color appBarColor = Color(0xFFFEFFFE);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Simulate load
    Future.delayed(const Duration(seconds: 2), _loadUserId);
  }

  void _onScroll() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    setState(() {
      appBarColor = _scrollController.offset > 50
          ? const Color(0xFF4A90E2)
          : (isDarkMode ? Color(0xFF273236) : const Color(0xFFFEFFFE));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showUpdateEmailModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => OtpBloc(OtpRepositoryImpl())),
          BlocProvider(
              create: (context) => ResetEmailBloc(ResetEmailRepositoryImpl())),
        ],
        child: UpdateEmailModal(),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Choose Theme"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("Light"),
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(false);
                  setState(() {
                    settings['Theme'] = 'Light';
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text("Dark"),
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(true);
                  setState(() {
                    settings['Theme'] = 'Dark';
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUpdatePasswordlModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => OtpBloc(OtpRepositoryImpl())),
          BlocProvider(
              create: (context) => ChangePasswordBloc(PasswordRepositoryImpl(),
                  resetPasswordRepository: null)),
        ],
        child: UpdatePasswordModal(),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_scrollController.hasClients && _scrollController.offset > 50) {
      appBarColor = const Color(0xFF4A90E2);
    } else {
      appBarColor = isDarkMode
          ? const Color.fromARGB(255, 29, 29, 29)
          : const Color(0xFFFEFFFE);
    }

    final subtitleFontSize = screenWidth * 0.04;
    final listTileFontSize = screenWidth * 0.035;
    final sectionHeaderPadding = EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenHeight * 0.02,
    );
    final listTilePadding = EdgeInsets.symmetric(
      horizontal: screenWidth * 0.04,
      vertical: screenHeight * 0.015,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Color(0xFF273236)
          : Color(0xFFFEFFFE),
      body: _isLoading
          ? _buildShimmerList() // ✅ shimmer while loading
          : NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    automaticallyImplyLeading: false,
                    backgroundColor: appBarColor,
                    elevation: 4,
                    expandedHeight: kToolbarHeight,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : (appBarColor == const Color(0xFFFEFFFE)
                                  ? Colors.black
                                  : Colors.white),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: ListView(
                children: [
                  _buildSectionHeader(
                      'GENERAL', sectionHeaderPadding, subtitleFontSize),
                  SettingListTile(
                    title: 'Theme',
                    value: settings['Theme'] ?? 'Light',
                    icon: Icons.brightness_6,
                    onTap: () => _showThemeDialog(context),
                  ),
                  _buildSectionHeader(
                      'ACCOUNT', sectionHeaderPadding, subtitleFontSize),
                  SettingListTile(
                    title: 'Email',
                    value: settings['Email'] ?? 'No Email Found',
                    icon: Icons.email,
                    onTap: () => _showUpdateEmailModal(context),
                  ),
                  SettingListTile(
                    title: 'Password',
                    value: settings['Password'] ?? '********',
                    icon: Icons.lock,
                    onTap: () => _showUpdatePasswordlModal(context),
                  ),
                  SettingListTile(
                    title: 'Disability',
                    value: settings['Disability'] ?? 'None',
                    icon: Icons.accessibility,
                    onTap: () async {
                      await showUpdateDisabilityModal(context);
                      _loadUserId(); // refresh after modal
                    },
                  ),
                  _buildSectionHeader('About and Support', sectionHeaderPadding,
                      subtitleFontSize),
                  SettingListTile(
                    title: 'Privacy Policy',
                    value: '',
                    icon: Icons.privacy_tip,
                    onTap: () => showPrivacyPolicy(context),
                  ),
                  Padding(
                    padding: listTilePadding,
                    child: ListTile(
                      leading: Icon(Icons.exit_to_app, color: Colors.red),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: listTileFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      onTap: () => showLogoutDialog(context),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(
      String title, EdgeInsets padding, double fontSize) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
