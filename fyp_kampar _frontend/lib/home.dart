import 'package:flutter/material.dart';
import 'live_capture.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void openPlace(BuildContext context, String placeName, String placeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LiveCapturePage(placeName: placeName, placeId: placeId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          Stack(
            children: [
              PhysicalShape(
                clipper: CurveLine2(),
                elevation: 8,
                color: const Color(0xFFA4B5C4),
                child: Container(height: screenHeight / 2.5),
              ),
              PhysicalShape(
                elevation: 8.0,
                clipper: CurveLine(),
                color: const Color.fromARGB(
                  255,
                  138,
                  136,
                  136,
                ).withValues(alpha: 0),
                child: Container(height: screenHeight / 3),
              ),
              ClipPath(
                clipper: CurveLine(),
                child: Container(
                  height: screenHeight / 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0.3, 0.8],
                      colors: [
                        Color.fromARGB(255, 7, 23, 57),
                        Color.fromARGB(255, 12, 56, 113),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 60,
                left: 20,
                right: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome to",
                      style: TextStyle(
                        fontFamily: "Montserrat-Bold",
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: const Text(
                        "KampAR!",
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontFamily: "Montserrat-Bold",
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              children: [
                Align(
                  child: GestureDetector(
                    onTap: () => openPlace(
                      context,
                      "UTAR Grand Hall",
                      "utar_grand_hall",
                    ),
                    child: placeCard(
                      "UTAR Grand Hall",
                      "assets/places/utar_grand_hall.jpg",
                      screenWidth,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Align(
                  child: GestureDetector(
                    onTap: () => openPlace(
                      context,
                      "Kampar Chinese Temple",
                      "kampar_chinese_temple",
                    ),
                    child: placeCard(
                      "Kampar Chinese Temple",
                      "assets/places/kampar_temple.jpg",
                      screenWidth,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Align(
                  child: GestureDetector(
                    onTap: () => openPlace(
                      context,
                      "Kampar Lu Ban Temple",
                      "kampar_lu_ban__temple",
                    ),
                    child: placeCard(
                      "Kampar Lu Ban Temple",
                      "assets/places/kampar_lu_ban_temple.jpg",
                      screenWidth,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Align(
                  child: GestureDetector(
                    onTap: () => openPlace(
                      context,
                      "Kampar Seng Fatt Temple",
                      "kampar_seng_fatt_temple",
                    ),
                    child: placeCard(
                      "Kampar Seng Fatt Temple",
                      "assets/places/kampar_seng_fatt_temple.jpg",
                      screenWidth,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget placeCard(String title, String image, double width) {
    return Container(
      width: width / 1.3,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3C39D),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(96, 0, 0, 0),
            spreadRadius: 2,
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: "Montserrat",
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              image,
              height: 100,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class CurveLine extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 10);
    var gravityPoint = Offset(size.width / 2.5, size.height / 2.2);
    var firstEndPoint = Offset(size.width / 1.7, size.height / 1.3);

    path.quadraticBezierTo(
      gravityPoint.dx,
      gravityPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondGravityPoint = Offset(
      size.width - (size.width / 6),
      size.height + 30,
    );
    var secondEndPoint = Offset(size.width, size.height - 80);

    path.quadraticBezierTo(
      secondGravityPoint.dx,
      secondGravityPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class CurveLine2 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 20);
    var gravityPoint = Offset(size.width / 6, size.height / 1.8);
    var firstEndPoint = Offset(size.width / 1.8, size.height / 1.3);

    path.quadraticBezierTo(
      gravityPoint.dx,
      gravityPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondGravityPoint = Offset(
      size.width - (size.width / 10),
      size.height,
    );
    var secondEndPoint = Offset(size.width, size.height - 130);

    path.quadraticBezierTo(
      secondGravityPoint.dx,
      secondGravityPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
