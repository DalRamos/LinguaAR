import 'package:flutter/material.dart';
import 'package:lingua_arv1/screens/home/home_screen.dart';

class GetStartedPage5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Color(0xFF191E20)
          : Color(0xFFFEFEFF),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 40 : screenWidth * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/illustrations/all_set.png',
                  width: isLargeScreen ? 400 : screenWidth * 0.6,
                  height: isLargeScreen ? 300 : screenHeight * 0.3,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.check_circle,
                      size: isLargeScreen ? 200 : screenWidth * 0.4,
                      color: Color(0xFF4A90E2),
                    );
                  },
                ),
                SizedBox(height: isLargeScreen ? 30 : screenHeight * 0.03),
                Text(
                  'You Are All Set!',
                  style: TextStyle(
                    fontSize: isLargeScreen ? 32 : screenWidth * 0.07,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Color(0xFF273236),
                  ),
                ),
                SizedBox(height: isLargeScreen ? 10 : screenHeight * 0.01),
                Text(
                  'Thank you for setting up LinguaAR.\nYou can now explore its features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 20 : screenWidth * 0.045,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black54,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 40 : screenHeight * 0.05),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to home screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      backgroundColor: Color(0xFF4A90E2),
                      padding: EdgeInsets.all(
                          isLargeScreen ? 40 : screenWidth * 0.07),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: isLargeScreen ? 40 : screenWidth * 0.08,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}