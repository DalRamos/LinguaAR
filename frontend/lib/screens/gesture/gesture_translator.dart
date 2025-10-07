import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingua_arv1/screens/text_to_speech/gesture_voice_translator.dart';
import 'package:lingua_arv1/screens/gesture/text_to_3dAnimation.dart';

class GestureTranslator extends StatefulWidget {
  @override
  _GestureTranslatorState createState() => _GestureTranslatorState();
}

class _GestureTranslatorState extends State<GestureTranslator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() => _currentTabIndex = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1D1D1D) : Colors.white,
      appBar: AppBar(
        title: const Text('Gesture Translator'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1D1D1D) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          indicatorColor: isDark ? Colors.purpleAccent : Colors.deepPurple,
          tabs: const [
            Tab(text: 'Word'),
            Tab(text: '3D Text'),
          ],
        ),
      ),
      body: FutureBuilder<List<CameraDescription>>(
        future: availableCameras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final cameras = snapshot.data!;
            return TabBarView(
              controller: _tabController,
              children: [
                GestureVoiceTab(
                  cameras: cameras,
                  isActive: _currentTabIndex == 0,
                ),
                TextTo3DTab(
                  cameras: cameras,
                  isActive: _currentTabIndex == 1,
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}