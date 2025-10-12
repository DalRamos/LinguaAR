import 'package:flutter/material.dart';
import 'package:lingua_arv1/screens/authentication/login/login_page.dart';
import 'package:animate_do/animate_do.dart';

class GetStartedPage1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: Center(
                child: FadeIn(
                  duration: Duration(seconds: 2),
                  child: Image.asset(
                    'assets/illustrations/welcome.png',
                    width: size.width * 0.8,
                    height: size.height * 0.4,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Color(0xFF273236),
              padding:
                  EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BounceInDown(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: "Lingua",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: "AR",
                            style: TextStyle(color: Color(0xFF4A90E2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 10),
                  FadeIn(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: "Bridging Communities",
                            style: TextStyle(
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                          TextSpan(
                            text: ", Empowering Communication",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 15 : 20),
                  ZoomIn(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        backgroundColor: Color(0xFF4A90E2),
                        padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: isSmallScreen ? 25 : 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
