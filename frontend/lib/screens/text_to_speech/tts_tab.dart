import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lingua_arv1/screens/gesture/text_to_3dAnimation.dart';
import 'package:lingua_arv1/screens/text_to_speech/gesture_voice_translator.dart';

class LinguaTabs extends StatefulWidget {
  @override
  _LinguaTabsState createState() => _LinguaTabsState();
}

class _LinguaTabsState extends State<LinguaTabs>
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
        title: const Text('LinguaVoice'),
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(255, 29, 29, 29)
            : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          tabs: const [
            Tab(text: 'Text to Speech'),
            Tab(text: 'Gesture Voice'),
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
                GestureVoiceTab(
                  cameras: snapshot.data!,
                  isActive: _currentTabIndex == 1,
                ),
                TextTo3DTab(
                  cameras: snapshot.data!, // ADDED THIS LINE
                  isActive: _currentTabIndex == 0,
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