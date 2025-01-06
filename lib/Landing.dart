import 'package:chatapp/avatarname.dart';
import 'package:chatapp/main.dart';
import 'package:chatapp/new.dart';
import 'package:flutter/material.dart';

// ignore: camel_case_types
class Landing_page extends StatefulWidget {
  const Landing_page({super.key});

  @override
  State<Landing_page> createState() => _Landing_pageState();
}

class _Landing_pageState extends State<Landing_page> {
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Landing Page',
        style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Color.fromARGB(255, 189, 233, 176)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Chat with your Sevak and get anything done!",
                    textAlign: TextAlign.center,
                    
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      backgroundColor: const Color.fromARGB(255, 212, 230, 213),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Start Chat",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(width: 10,),
               ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => audioScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                      backgroundColor: const Color.fromARGB(255, 212, 230, 213),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Start Audio",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: screenHeight * 0.02,
                    crossAxisSpacing: screenWidth * 0.02,
                    padding: const EdgeInsets.all(20),
                    childAspectRatio: 0.85,
                    children: [
                      _buildDashboardItem(
                        context,
                        'assets/images/book.png',
                        "Flight Booking",
                        ChatScreen(),
                      ),
                      _buildDashboardItem(
                        context,
                        'assets/images/broom.png',
                        "Bus Booking",
                        ChatScreen(),
                      ),
                      _buildDashboardItem(
                        context,
                        'assets/images/electronic-ticket.png',
                        "Book a Cab",
                        ChatScreen(),
                      ),
                      _buildDashboardItem(
                        context,
                        'assets/images/delivery-man.png',
                        "Order Groceries",
                        ChatScreen(),
                      ),
                      _buildDashboardItem(
                        context,
                        'assets/images/food-delivery.png',
                        "Order Food",
                        ChatScreen(),
                      ),
                      _buildDashboardItem(
                        context,
                        'assets/images/food.png',
                        "Laundry",
                        ChatScreen(),
                      ),
                      _buildDashboardItem(
                        context,
                        'assets/images/laundry-machine.png',
                        "Book a Tailor",
                        ChatScreen(),
                      ),
                      _buildDashboardItem(
                        context,
                        'assets/images/mobile-app.png',
                        "Local Courier",
                        ChatScreen(),
                      ),
                      _buildDashboardItem(
                        context,
                        'assets/images/sewing.png',
                        "Book Home Cleaning",
                        ChatScreen(),
                      ),
                    ],
                  );
                }),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, String imgPath,
      String imgName, Widget destination) {
    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (ctx) => destination));
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        shadowColor: Colors.deepPurpleAccent.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  imgPath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                imgName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
