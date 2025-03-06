import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lingua_arv1/bloc/Change_email/change_email_bloc.dart';
import 'package:lingua_arv1/bloc/Change_password/change_password_bloc.dart';
import 'package:lingua_arv1/bloc/Otp/otp_bloc.dart';
import 'package:lingua_arv1/repositories/change_email_repositories/change_email_repository_impl.dart';
import 'package:lingua_arv1/repositories/change_password_repositories/reset_password_repository.dart';
import 'package:lingua_arv1/repositories/change_password_repositories/reset_password_repository_impl.dart';
import 'package:lingua_arv1/repositories/otp_repositories/otp_repository_impl.dart';
import 'package:lingua_arv1/screens/login_signup/login_page.dart';
import 'package:lingua_arv1/settings/Dialog/dialogs.dart';
import 'package:lingua_arv1/settings/Lists/setting_list_tile.dart';
import 'package:lingua_arv1/settings/Update_Accounts/update_email_page.dart';
import 'package:lingua_arv1/settings/Update_Accounts/update_password_page.dart';
import 'package:lingua_arv1/validators/token.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userId;

  Future<void> _loadUserId() async {
    String? fetchedUserId = await TokenService.getUserId();
    String? fetchedEmail = await TokenService.getEmail();

    if (mounted) {
      setState(() {
        userId = fetchedUserId ?? 'Unknown';
        settings['Email'] = fetchedEmail ?? 'No Email Found';
      });
    }
  }

  Map<String, String> settings = {
    'Theme': 'Light',
    'Language': 'English',
    'Password': '********',
    'Preferred Hand': 'Right',
    'Translation Speed': 'Normal',
    'Voice Selection': 'Male',
    'Speech Speed': 'Normal',
    'Pitch Control': 'Normal',
  };

  late ScrollController _scrollController;
  Color appBarColor = Color(0xFFFEFFFE);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        appBarColor = _scrollController.offset > 50
            ? Color(0xFF4A90E2)
            : Color(0xFFFEFFFE);
      });
    });
    _loadUserId();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Function to show the Update Email Modal
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
        child: UpdateEmailModal(), // Now it's correctly provided.
      ),
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
              create: (context) => ChangePasswordBloc(PasswordRepositoryImpl())),
        ],
        child: UpdatePasswordModal(), // Now it's correctly provided.
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
      backgroundColor: Color(0xFFFEFFFE),
      body: NestedScrollView(
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
                    color: appBarColor == Color(0xFFFEFFFE)
                        ? Colors.black
                        : Colors.white,
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
              options: ['Auto', 'Light', 'Dark'],
              settings: settings,
            ),
            SettingListTile(
              title: 'Language',
              value: settings['Language'] ?? 'English',
              icon: Icons.language,
              options: ['English', 'Spanish', 'French', 'Filipino'],
              settings: settings,
            ),
            _buildSectionHeader(
                'ACCOUNT', sectionHeaderPadding, subtitleFontSize),
            SettingListTile(
              title: 'Email',
              value: settings['Email'] ?? 'No Email Found',
              icon: Icons.email,
              onTap: () => _showUpdateEmailModal(context), // ✅ Show modal
            ),
            SettingListTile(
              title: 'Password',
              value: settings['Password'] ?? '********',
              icon: Icons.lock,
              onTap: () => _showUpdatePasswordlModal(context), // ✅ Show modal
            ),
            _buildSectionHeader(
                'About and Support', sectionHeaderPadding, subtitleFontSize),
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
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
