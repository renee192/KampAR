import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => OnboardingPageState();
}

class OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showHome', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() => isLastPage = index == 3);
          },
          children: [
            buildPage(
              color: Color(0xFF071739),
              icon: Icons.touch_app,
              title: 'Explore Places',
              subtitle:
                  'Scroll through the list and tap on a place you want to explore.',
            ),
            buildPage(
              color: Color(0xFF0C3871),
              icon: Icons.camera_alt,
              title: 'Scan Surroundings',
              subtitle:
                  'Use your camera to scan the area around you in Live Capture page.',
            ),
            buildPage(
              color: Color(0xFF071739),
              icon: Icons.ads_click,
              title: 'Interact with Labels',
              subtitle:
                  'When an AR label appears on your screen, tap it to learn more!',
            ),
            buildPage(
              color: Color(0xFF0C3871),
              icon: Icons.map,
              title: 'View the Map',
              subtitle:
                  'Find these locations easily by tapping the View Map button.',
            ),
          ],
        ),
      ),
      bottomSheet: isLastPage
          ? Container(
              color: const Color(0xFF0C3871),
              height: 100,
              padding: const EdgeInsets.all(20),
              child: TextButton(
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  foregroundColor: Colors.black,
                  backgroundColor: const Color(0xFFFFFFFF),
                  minimumSize: const Size.fromHeight(
                    60,
                  ),
                ),
                onPressed: _completeOnboarding,
                child: const Text(
                  'Start to Explore!',
                  style: TextStyle(fontSize: 20, fontFamily: "Montserrat-Bold"),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _controller.jumpToPage(3),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA4B5C4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: "Montserrat-Bold",
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('SKIP'),
                  ),

                  ElevatedButton(
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C3871),
                      foregroundColor: Colors.white,
                      elevation: 2, // Slight shadow
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: "Montserrat-Bold",
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('NEXT'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildPage({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Color(0xFFA4B5C4)),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: "Montserrat-Bold",
              color: Color(0xFFFFFFFF),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: "Montserrat",
              color: Color(0xFFFFFFFF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
