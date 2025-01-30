import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, String> settings = {
    'Theme': 'Auto',
    'Language': 'English',
    'Name': 'Jose P. Rizal',
    'Email': 'pepe.rizal@gmail.com',
    'Password': '********',
    'Preferred Hand': 'Right',
    'Translation Speed': 'Normal',
    'Voice Selection': 'Male',
    'Speech Speed': 'Normal',
    'Pitch Control': 'Normal',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text('Settings', style: TextStyle(color: Colors.black))),
        backgroundColor: Color(0xFFFEFFFE),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Container(
        color: Color(0xFFFEFFFE),
        child: ListView(
          children: [
            _buildSectionHeader('GENERAL'),
            _buildListTile(
              context,
              'Theme',
              settings['Theme']!,
              Icons.brightness_6,
              ['Auto', 'Light', 'Dark'],
            ),
            _buildListTile(
              context,
              'Language',
              settings['Language']!,
              Icons.language,
              ['English', 'Spanish', 'French', 'Filipino'],
            ),
            _buildSectionHeader('ACCOUNT'),
            _buildListTile(
                context, 'Name', settings['Name']!, Icons.person, []),
            _buildListTile(
                context, 'Email', settings['Email']!, Icons.email, []),
            _buildListTile(
                context, 'Password', settings['Password']!, Icons.lock, []),
            _buildSectionHeader('AR and FSL'),
            _buildListTile(
              context,
              'Preferred Hand',
              settings['Preferred Hand']!,
              Icons.pan_tool,
              ['Right', 'Left'],
            ),
            _buildListTile(
              context,
              'Translation Speed',
              settings['Translation Speed']!,
              Icons.speed,
              ['Slow', 'Normal', 'Fast'],
            ),
            _buildSectionHeader('Text to Speech'),
            _buildListTile(
              context,
              'Voice Selection',
              settings['Voice Selection']!,
              Icons.record_voice_over,
              ['Male', 'Female'],
            ),
            _buildListTile(
              context,
              'Speech Speed',
              settings['Speech Speed']!,
              Icons.slow_motion_video,
              ['Slow', 'Normal', 'Fast'],
            ),
            _buildListTile(
              context,
              'Pitch Control',
              settings['Pitch Control']!,
              Icons.tune,
              ['Low', 'Normal', 'High'],
            ),
            _buildSectionHeader('About and Support'),
            _buildListTile(context, 'App Version', '', Icons.info, []),
            _buildListTile(
                context, 'Privacy Policy', '', Icons.privacy_tip, []),
            _buildListTile(
                context, 'Feedback and Support', '', Icons.support, []),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, String title, String trailing,
      IconData icon, List<String> options) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey),
          title: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: trailing.isNotEmpty
              ? Text(
                  trailing,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                )
              : null,
          onTap: title == 'Privacy Policy'
              ? () => _showPrivacyPolicy(context)
              : options.isNotEmpty
                  ? () => _showOptionsDialog(context, title, options)
                  : null,
        ),
        Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: Colors.grey[300]),
      ],
    );
  }

  void _showOptionsDialog(
      BuildContext context, String title, List<String> options) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFEFFFE),
          title: Text('Select $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return ListTile(
                title: Text(option),
                onTap: () {
                  setState(() {
                    settings[title] = option;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFEFFFE),
          title: Text('Privacy Policy for LinguaAR'),
          content: const SingleChildScrollView(
            child: Text(
              '''Effective Date: [January 32, 2025]

Thank you for using LinguaAR. Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our application.

1. Information We Collect

LinguaAR requires user account creation, and we collect the following types of information:

Personal Information: We collect personal information that you voluntarily provide when creating your account, such as your name, email address, and password.

Usage Data: We may collect anonymized data related to app usage, such as feature engagement, error logs, and general statistics to improve our services.

Device Information: We may collect information about the device you use, including device type, operating system, and language preferences to optimize your experience.

Speech & Gesture Data: Any speech or gesture inputs processed by the app remain on your device and are not stored or shared.

2. How We Use Your Information

The data we collect is used solely to enhance your experience with LinguaAR. Specifically, we use it to:

- Improve app functionality and performance.
- Troubleshoot technical issues.
- Understand how users interact with our features.

3. Data Sharing and Security

We do not sell, rent, or share your personal information with third parties.

All data processing occurs within your device, ensuring privacy and security.

If third-party services (such as text-to-speech engines or gesture recognition APIs) are used, they may have their own privacy policies, which we recommend reviewing.

4. Third-Party Services

LinguaAR may integrate third-party tools such as:

- Google Text-to-Speech for voice output.
- Gesture Recognition APIs for sign language processing.

These services may process data according to their respective privacy policies.

5. Your Rights & Choices

You can disable certain features (e.g., speech recognition) in the app settings.

You may contact us to request data deletion if applicable.

6. Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be reflected in the app and updated with a new effective date.

7. Contact Us

If you have any questions or concerns regarding this Privacy Policy, please contact us at:

dacl.ramos.up@phinmaed.com

By using LinguaAR, you agree to this Privacy Policy.

              ''',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}
