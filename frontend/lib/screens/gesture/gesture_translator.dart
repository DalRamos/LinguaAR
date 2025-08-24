import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lingua_arv1/screens/gesture/text_to_3dAnimation.dart';
import 'package:lingua_arv1/screens/text_to_speech/gesture_voice_translator.dart';
import 'package:lingua_arv1/screens/gesture/gesture_word_tab.dart';

class GestureTranslator extends StatefulWidget {
  @override
  _GestureTranslatorState createState() => _GestureTranslatorState();
}

class _GestureTranslatorState extends State<GestureTranslator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<CameraDescription>? _cameras;
  int _currentTabIndex = 0;

  _GestureTranslatorState() : _cameras = null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Gesture Translator'),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
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
            return TabBarView(
              controller: _tabController,
              children: [
                GestureWordTab(
                  cameras: snapshot.data!,
                  isActive: _currentTabIndex == 0,
                ),
                TextTo3DTab(
                  isActive: _currentTabIndex == 1,
                ),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
